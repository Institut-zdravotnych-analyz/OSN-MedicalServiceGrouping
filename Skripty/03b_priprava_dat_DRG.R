##### --------------------------------------------------------------------------
# Skript na spracovanie dat o hospitalizaciach od poistovni.
# Data sa vycistia, co najlepsie sa urcia veky a pospajaju do jednej premennej.
#
# CAST B: Priprava dat z tabuliek 02_HP, 03_PREKLADY, 04_VDG, 05_ZV
##### --------------------------------------------------------------------------

### --- Priprav data zo suboru 02_HP

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "HP")
drg <- main_df[tmp_names]
drg <- rbindlist(drg, use.names = T)

# Zmen typ pre datumy z textu na datumy
drg <- drg %>%
  mutate(DATUM_OD = as.IDate(DATUM_OD),
         DATUM_DO = as.IDate(DATUM_DO),
         DATUM_NAROD = as.IDate(DATUM_NAROD))

# Vyber potrebne stlpce a vyhod duplikaty
drg <- drg %>%
  select(ID_HP_PZS, ID_HP_ZP, BIC_POI, PZS_6, DATUM_OD, DATUM_DO,
         VEK_DNI, VEK_ROKY, HMOTNOST, UPV_DLZKA, DATUM_NAROD, HDG, DRG_SKUP,
         STAROST_TYP) %>%
  unique()


### --- Priprav data zo suboru 03_PREKLAD

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "PREKLAD")
prek <- main_df[tmp_names]
prek <- rbindlist(prek, use.names = T)

# Najdi datum zaciatku hospitalizacie, ktory sa bude pripajat k suboru 02_HP
prek <- prek %>%
  group_by(ID_HP_ZP) %>%
  mutate(DATUM_OD = ifelse(DATUM_OD == "", DATUM_DO, DATUM_OD),
         DATUM_OD = min(DATUM_OD, na.rm = T),
         DATUM_OD = as.IDate(DATUM_OD),
         DATUM_DO = max(DATUM_DO, na.rm = T),
         DATUM_DO = as.IDate(DATUM_DO)) %>%
  ungroup()

# Pridaj kod nemocnice podla prevodovnika na zaklade kodov oddeleni
tmp_nem <- read_xlsx(paste0(paths$prevody, files$hosp))[, c(2, 4, 5)]
prek <- prek %>%
  left_join(tmp_nem, by = c("PZS_12" = "kod_pzs"))

# Exportuj zoznam kodov oddeleni, ktorym nevieme priradit nemocnicu
if (sprav_export_chyb) {
  prek %>%
    filter(is.na(nemP01)) %>%
    select(PZS_12, nemP01) %>%
    unique() %>%
    fwrite(file = paste0(paths$vystupy, "chybne_pzs_", rok, "_subor_03.csv"),
           sep = "|", row.names = F)
}

# Priprav na pripojenie k suboru 02_HP
prek <- prek %>%
  mutate(pzs_join = substring(nemP01, 0, 6)) %>%
  select(ID_HP_ZP, nemP01, DATUM_OD, DATUM_DO, pzs_join) %>%
  unique()

# Exportuj zoznam hospitalizacii, ktore nie su zaznamenane v subore 03_PREKLADY
if (sprav_export_chyb) {
  drg %>%
    anti_join(prek, by = "ID_HP_ZP") %>%
    fwrite(file = paste0(paths$vystupy, "drg_hosp_nema_preklad_", rok, ".csv"),
           sep = "|", row.names = F)
}

# Pripoj kod nemocnice priradeny podla kodov oddeleni zo suboru 03_PREKLAD
# k suboru 02_HP. Pripaja sa ta nemocnica, ktora sa zhoduje s kodom PZS
# zaznamenanom v subore 02_HP.
drg <- drg %>%
  left_join(prek, by = c("ID_HP_ZP", "PZS_6" = "pzs_join"),
            suffix = c("", ".03"))

# Ak sa nepripojil kod nemocnice, lebo hospitalizacia nema zaznam v subore
# 03_PREKLADY, vytvor kod nemocnice ako 'PZS_6 + 0 + Y', kde Y sa zisti
# z polozky ID_HP_PZS ako (Z)RRYXXXXX. Y by nikdy nemalo byt 0, ale nemocnice
# si ho tak niekedy udavaju, takze sprav zmenu na 1.
drg <- drg %>%
  mutate(y = ifelse(startsWith(ID_HP_PZS, "Z"),
                    substring(ID_HP_PZS, 4, 4),
                    substring(ID_HP_PZS, 3, 3)),
         y = ifelse(y == "0", "1", y),
         nemP01_pzs = paste0(PZS_6, "0", y),
         nemP01 = ifelse(is.na(nemP01), nemP01_pzs, nemP01)) %>%
  select(-PZS_6, -ID_HP_PZS, -y, -nemP01_pzs) %>%
  unique()


### --- Priprav data zo suboru 04_VDG

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "VDG")
vdg <- main_df[tmp_names]
vdg <- rbindlist(vdg, use.names = T)

# Vyber potrebne stlpce a vyhod duplicity
vdg <- vdg %>%
  select(ID_HP_ZP, VDG) %>%
  unique()

# Pripoj vedlajsie diagnozy zo suboru 04_HP_VDG k suboru 02_HP
drg <- drg %>%
  left_join(vdg, by = "ID_HP_ZP")


### --- Priprav data zo suboru 05_VYKON

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "VYKON")
vyk <- main_df[tmp_names]
vyk <- rbindlist(vyk, use.names = T)

# Vytvor identifikator vykonu na zaklade jeho kodu, datumu vykonania a
# lokalizacie.
vyk <- vyk %>%
  mutate(KOD_VYKON = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VYKON)),
         vykon_lab = paste(KOD_VYKON, gsub("-", "", DATUM_VYKON),
                           VYKON_LOKAL, sep = "_"))

# Vyber potrebne stlpce
vyk <- vyk %>%
  select(ID_HP_ZP, KOD_VYKON, vykon_lab) %>%
  unique()

# Pripoj vykony zo suboru 05_VYKON k suboru 02_HP
drg <- drg %>%
  left_join(vyk, by = "ID_HP_ZP")


### --- Pripoj data zo suboru 09_POISTENCI

drg <- drg %>%
  left_join(poi, by = "BIC_POI", suffix = c("", ".0209"))
