##### --------------------------------------------------------------------------
# Skript na spracovanie dat o hospitalizaciach od poistovni.
# Data sa vycistia, co najlepsie sa urcia veky a pospajaju do jednej premennej.
##### --------------------------------------------------------------------------

### --- Priprav data zo suboru 01_UZS_JZS
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which((tmp_names %like% "UZS" | tmp_names %like% "JZS")
                   & tmp_names %like% "UDAJE")
uzs <- main_df[tmp_names]
uzs <- rbindlist(uzs, use.names = F)
# Vyluc riadky, kde typ hospitalizacie je "pripocitatelna polozka"
uzs <- uzs %>% filter(TYP_HOSP != "Z")
# Prirad cislo riadku ako ID hospitalizacie tam, kde ID nie je uvedene.
# Takato hospitalizacia sa neda naparovat na ostatne subory, ale je to lepsie
# ako ich vyhodit.
uzs <- uzs %>%
  mutate(ID_HOSP_ZP = ifelse(ID_HOSP_ZP == "", paste0("uzs", row_number()),
                             ID_HOSP_ZP))
# Cheme pracovat s diagnozou pri prijati, ale ak nie je, tak sa uspokojime aj s
# diagnozou pri prepusteni
uzs <- uzs %>%
  mutate(diag_uzs = fifelse(DGN_PRIJ == "", DGN_PREP, DGN_PRIJ))
# Zmen typ pre datumy z textu na datumy
uzs <- uzs %>%
  mutate(DAT_PRIJ = as.IDate(DAT_PRIJ),
         DAT_PREP = as.IDate(DAT_PREP))
# Vyber potrebne stlpce a vyhod duplikaty
uzs <- uzs %>%
  select(ID_POI_ZP, KOD_ODD, ID_HOSP_ZP, KOD_VYK_OPER, diag_uzs, DAT_PRIJ,
         DAT_PREP) %>%
  unique()
# Pridaj kod nemocnice podla prevodovnika na zaklade kodov oddeleni
tmp_nem <- read_xlsx(paste0(paths$prevody, files$hosp))[, c(2, 4)]
uzs <- uzs %>%
  left_join(tmp_nem, by = c("KOD_ODD" = "kod_pzs"))
# Vyhod kod oddelenia a vyhod duplicity
uzs <- uzs %>%
  select(-KOD_ODD) %>%
  unique()

### --- Priprav data zo suboru 02_HP_UDAJE
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "HP_UDAJE")
drg <- main_df[tmp_names]
drg <- rbindlist(drg, use.names = F)
# Natipuj vek podla toho co je napisane v datach
drg <- drg %>%
  mutate(VEK_DEN = as.numeric(VEK_DEN),
         VEK_DEN = ifelse(is.na(VEK_DEN), -1, VEK_DEN),
         VEK_ROKY = as.numeric(VEK_ROKY),
         VEK_ROKY = ifelse(is.na(VEK_ROKY), -1, VEK_ROKY),
         vek_zapis = VEK_ROKY,
         vek_zapis = ifelse(VEK_DEN > 0, 0, vek_zapis),
         HMOTNOST = as.numeric(HMOTNOST),
         HMOTNOST = ifelse(is.na(HMOTNOST), -1, HMOTNOST),
         vek_zapis = ifelse(HMOTNOST > 0, 0, vek_zapis))
# Zmen typ pre datumy z textu na datumy
drg <- drg %>%
  mutate(DAT_OD = as.IDate(DAT_OD),
         DAT_DO = as.IDate(DAT_DO))
# Vyber potrebne stlpce a vyhod duplikaty
drg <- drg %>%
  select(ID_HP_DZP, vek_zapis, HMOTNOST, UPV, KOD_DIAG_HL, KOD_DRG, DAT_OD,
         DAT_DO, KOD_PZS) %>%
  unique()

### --- Priprav data zo suboru 03_HP_PREKLADY
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "HP_PREKLADY")
prek <- main_df[tmp_names]
prek <- rbindlist(prek, use.names = F)
# Pridaj kod nemocnice podla prevodovnika na zaklade kodov oddeleni
prek <- prek %>%
  left_join(tmp_nem, by = c("KOD_PZS" = "kod_pzs"))
# Priprav na pripojenie k suboru 02_HP_UDAJE
prek <- prek %>%
  mutate(pzs_join = substring(nemP01, 0, 6)) %>%
  select(ID_HP_DZP, nemP01_s03 = nemP01, pzs_join) %>%
  unique()

# Pripoj kody oddeleni zo suboru 03_HP_PREKLADY k suboru 02_HP_UDAJE.
# Pripaja sa ta nemocnica, ktora sa zhoduje s kodom PZS zaznamenanom v subore
# 02_HP_UDAJE
drg <- drg %>%
  left_join(prek, by = c("ID_HP_DZP", "KOD_PZS" = "pzs_join")) %>%
  select(-KOD_PZS) %>%
  unique()

# Spoj subory 01_UZS_JZS a 02_HP_UDAJE
uzs_final <- uzs %>%
  full_join(drg, by = c("ID_HOSP_ZP" = "ID_HP_DZP"))

# Ak neexistuje podla kodu oddelenia v subre 01_UZS_JZS, tak pouzi nemocnicu
# podla kodu kodu oddelenia zo suboru 03_HP_PREKLADY
uzs_final <- uzs_final %>%
  mutate(nemP01 = ifelse(is.na(nemP01), nemP01_s03, nemP01)) %>%
  select(-nemP01_s03)

# Nepriradeny vek oznac ako -1
uzs_final <- uzs_final %>%
  mutate(vek_zapis = ifelse(is.na(vek_zapis), -1, vek_zapis))

# Nepriradenu hmotnost oznac ako -1
uzs_final <- uzs_final %>%
  mutate(HMOTNOST = ifelse(is.na(HMOTNOST), -1, HMOTNOST))

# Vyrad hospitalizacie ktore nekoncia vo vybranom roku
uzs_final <- uzs_final %>%
  filter(year(DAT_PREP) == rok | year(DAT_DO) == rok)

### --- Priprav data zo suboru 09_UZS_POISTENCI
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "POISTENCI")
poi <- main_df[tmp_names]
poi <- rbindlist(poi, use.names = F)
# Zmen typ pre datumy z textu na datumy
poi <- poi %>%
  mutate(DAT_NAROD = as.IDate(DAT_NAROD))
# Vyber potrebne stlpce a vyhod duplicity
poi <- poi %>%
  select(ID_POI, DAT_NAROD) %>%
  unique()

# Pripoj datum narodenia zo suboru 09_UZS_POISTENCI k UZS datam
uzs_final <- uzs_final %>%
  left_join(poi, by = c("ID_POI_ZP" = "ID_POI"))

# Natipuj vek podla datumov hospitalizacii a narodenia a toho, co bolo napisane.
# Z datumov hospitalizacii sa najde minimalny a podla neho a datumu narodenia
# sa urci vek pri hospitalizacii. Ak tento vek neexistuje, zoberie sa vek,
# ktory bol zaznamenany v subore 02_HP_UDAJE. Moze sa stat, ze datum narodenia
# je neskor ako datum prijatia, co by sposobilo zaporny vek, v takom pripade
# sa zoberie vek zo suboru 02_HP_UDAJE. Ak niekde este stale nie je vek, alebo
# je zaporny, tak sa priradi vek 42, aby hospitalizacia padla do kategorie
# "dospely".
uzs_final <- uzs_final %>%
  mutate(date_admission = pmin(DAT_OD, DAT_DO, DAT_PRIJ, DAT_PREP, na.rm = T),
         vek = floor(time_length(difftime(date_admission, DAT_NAROD), "years")),
         vek = ifelse(is.na(vek), vek_zapis, vek),
         vek = ifelse(is.na(vek), -1, vek),
         vek_2 = ifelse(DAT_NAROD > date_admission, vek_zapis, vek),
         vek = ifelse(is.na(vek_2), vek, vek_2),
         vek = ifelse(vek < 0, 42, vek))

# Zahod nepotrebne stlpce
uzs_final <- uzs_final %>%
  select(-ID_POI_ZP, -DAT_PRIJ, -DAT_PREP, -vek_zapis, -DAT_OD, -DAT_DO,
         -DAT_NAROD, -date_admission, -vek_2)

# Kvoli zlemu vypisovaniu veku sa vek musel dopocitavat z datumov hospitalizacie
# a narodenia, co moze viest k viacerym vekom pre tu istu hospitalizaciu,
# plus datum narodenia matky aj dietata mozu byt niekedy priradene tej istej
# hospitalizacii. Preto sa pre kazdu hospitalizaciu zoberie ten najmensi vek.
uzs_final <- uzs_final %>%
  group_by(ID_HOSP_ZP) %>%
  mutate(vek = min(vek, na.rm = T)) %>%
  ungroup() %>%
  unique()

### --- Priprav data zo suboru 04_HP_VDG
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "VDG")
vdg <- main_df[tmp_names]
vdg <- rbindlist(vdg, use.names = F)
# Vyber potrebne stlpce a vyhod duplicity
vdg <- vdg %>%
  select(ID_HP_DZP, KOD_VEDL_DIAG) %>%
  unique()

# Pripoj vedlajsie diagnozy zo suboru 04_HP_VDG k UZS datam
uzs_final <- uzs_final %>%
  left_join(vdg, by = c("ID_HOSP_ZP" = "ID_HP_DZP"))

### --- Priprav data zo suboru 05_HP_ZV
# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "ZV")
vyk <- main_df[tmp_names]
vyk <- rbindlist(vyk, use.names = F)
# Transformuj kod vykonu na male pismena, ktore budu pouzite ako standard
vyk <- vyk %>%
  mutate(KOD_VYKON = tolower(KOD_VYKON))
# Vyber potrebne stlpce a vyhod duplicity
vyk <- vyk %>%
  select(ID_HP_DZP, KOD_VYKON) %>%
  unique()

# Pripoj vykony zo suboru 05_HP_ZV k UZS_datam
uzs_final <- uzs_final %>%
  left_join(vyk, by = c("ID_HOSP_ZP" = "ID_HP_DZP"))

# Primarne sa berie vykon zo suboru 05_HP_ZV, ak taky neexistuje, tak sa zoberie
# vykon zo suboru 01_UZS_JZS.
uzs_final <- uzs_final %>%
  mutate(KOD_VYKON = ifelse(is.na(KOD_VYKON), KOD_VYK_OPER, KOD_VYKON))

# Z kodov vykonov sa odstrania ine znaky ako cisla a pismena (tie sa zmenia na
# male), aby vsetky kody vykonov mali tu istu strukturu
uzs_final <- uzs_final %>%
  mutate(KOD_VYKON = ifelse(is.na(KOD_VYKON), "", KOD_VYKON),
         KOD_VYKON = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VYKON)))

# Odstran duplicity z UZS dat
uzs_final <- uzs_final %>% unique()

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(uzs, drg, prek, poi, vdg, vyk)
rm(main_df)
invisible(gc())
