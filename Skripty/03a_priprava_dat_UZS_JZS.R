##### --------------------------------------------------------------------------
# Skript na spracovanie dat o hospitalizaciach od poistovni.
# Data sa vycistia, co najlepsie sa urcia veky a pospajaju do jednej premennej.
#
# CAST A: Priprava dat z tabuliek 01_UZS_JZS a 09_POISTENCI
##### --------------------------------------------------------------------------

### --- Priprav data zo suboru 01_UZS_JZS

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "01_UZS_JZS")
uzs <- main_df[tmp_names]
uzs <- rbindlist(uzs, use.names = TRUE) %>% unique()

# Vyluc riadky, kde typ hospitalizacie je "pripocitatelna polozka"
uzs <- uzs %>%
  filter(HOSP_TYP != "Z") %>%
  select(-HOSP_TYP)

# Exportuj riadky, kde chyba ID hosppitalizacie.
if (sprav_export_chyb) {
  uzs %>%
    filter(ID_HP_ZP == "") %>%
    fwrite(file = paste0(paths$vystupy, "chybajuce_ID_HOSP_", rok,
                         "_zaznamy.csv"),
           sep = "|", row.names = F)
}

# Prirad cislo riadku ako ID hospitalizacie tam, kde ID nie je uvedene.
# Takato hospitalizacia sa neda naparovat na ostatne subory, ale je to lepsie
# ako ich vyhodit.
uzs <- uzs %>%
  mutate(ID_HP_ZP = ifelse(ID_HP_ZP == "", paste0("uzs", row_number()),
                             ID_HP_ZP))

# Pridaj kod nemocnice podla prevodovnika na zaklade kodov oddeleni.
tmp_nem <- read_xlsx(paste0(paths$prevody, files$hosp))[, c(2, 4, 5)]
uzs <- uzs %>%
  left_join(tmp_nem, by = c("PZS_12" = "kod_pzs"))

# Exportuj kody oddeleni, ktorym nevieme priradit kod nemocnice
if (sprav_export_chyb) {
  uzs %>%
    filter(is.na(nemP01)) %>%
    select(PZS_12, nemP01) %>%
    unique() %>%
    fwrite(file = paste0(paths$vystupy, "chybne_pzs_", rok, "_subor_01.csv"),
           sep = "|", row.names = F)

  uzs %>%
    filter(is.na(nemP01)) %>%
    unique() %>%
    fwrite(file = paste0(paths$vystupy, "chybne_pzs_", rok,
                         "_subor_01_zaznamy.csv"),
           sep = "|", row.names = F)
}

# Zorad hospitalizacie podla ich ID, mesiaca a datumu prijatia, aby sa dali
# doplnit datumy prijatia a prepustenia, a diagnozy do riadkov kde nie su podla
# zvysnych riadkov pre danu hospitalizaciu.
uzs <- uzs %>%
  mutate(ROK_MESIAC = gsub("-", "", ROK_MESIAC)) %>%
  arrange(ID_HP_ZP, ROK_MESIAC, desc(DATUM_OD))

# Propaguj data vramci hospitalizacie:
#   datum prijatia na nasledujuce riadky pod nim, ak tam nie je vyplneny
#   datum prepustenia na predchadzajuce riadky nad nim, ak tam nie je vyplneny
#   diagnozu pri prijati na nasledujuce riadky pod nou, ak tam nie je vyplnena
#   diagnozu pri prepusteni na predchadzajuce riadky nad nou, ak nie je vyplnena
uzs <- uzs %>%
  mutate(DATUM_OD = ifelse(DATUM_OD == "", NA, DATUM_OD),
         DATUM_DO = ifelse(DATUM_DO == "", NA, DATUM_DO),
         DGN_PRIJ = ifelse(DGN_PRIJ == "", NA, DGN_PRIJ),
         DGN_PREP = ifelse(DGN_PREP == "", NA, DGN_PREP)) %>%
  group_by(ID_HP_ZP) %>%
  fill(DATUM_OD, .direction = "down") %>%
  fill(DATUM_DO, .direction = "up") %>%
  fill(DGN_PRIJ, .direction = "down") %>%
  fill(DGN_PREP, .direction = "up") %>%
  ungroup()

# Chceme pracovat s diagnozou pri prijati, ale ak nie je, tak sa uspokojime aj s
# diagnozou pri prepusteni.
uzs <- uzs %>%
  mutate(diag_uzs = fifelse((DGN_PRIJ == "") | (is.na(DGN_PRIJ)), DGN_PREP,
                            DGN_PRIJ))

# Zmen datovy typ pre datumy z textu na datum
uzs <- uzs %>%
  mutate(DATUM_OD = as.IDate(DATUM_OD),
         DATUM_DO = as.IDate(DATUM_DO))

# Ocisti kod vykonu na standardizovany tvar - len male pismena a cisla.
uzs <- uzs %>%
  mutate(KOD_VYKON_OPER = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VYKON_OPER)),
         KOD_VYKON_JZS = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VYKON_JZS)))

# Podla prevodovnika od CKSDRG premen kody JZS vykonov na DRG kody.
# Poznamka: Prevodovnik nie je 1:1, ale k 1 JZS kodu moze prisluchat viacero
#           DRG kodov, tak je ich potrebne naparovat vsetky.
#   Nacitaj prevodovnik
tmp_subor <- paste0(paths$prevody, files$jzs_drg)
tmp_harky <- excel_sheets(tmp_subor)
tmp_jzs <- list()
for (tmp_h in tmp_harky) {
  tmp_jzs[[tmp_h]] <- read_xlsx(tmp_subor, sheet = tmp_h,
                                col_names = c("kod_jzs", "jzs_name", "kod_drg",
                                              "drg_name", "note"),
                                skip = 1)
  # Odstran prazdne riadky, pridaj stlpec s kodom poistovne, nakopiruj kod JZS
  # do prazdnych poli pod nim, ktore nasleduju po hodnote a ocisti kody vykonov
  # na standardizovany tvar - len male pismena a cisla.
  tmp_jzs[[tmp_h]] <- tmp_jzs[[tmp_h]] %>%
    filter(!is.na(kod_drg)) %>%
    fill(kod_jzs, .direction = "down") %>%
    mutate(kod_jzs = gsub("[^0-9a-zA-Z]", "", tolower(kod_jzs)),
           kod_drg = gsub("[^0-9a-zA-Z]", "", tolower(kod_drg))) %>%
    select(kod_jzs, kod_drg)
}
tmp_jzs <- rbindlist(tmp_jzs, use.names = TRUE) %>%
  unique()
#   Prirad DRG kody k JZS kodom vykonov
uzs <- uzs %>%
  left_join(tmp_jzs, by = c("KOD_VYKON_JZS" = "kod_jzs"))
#   Exportuj kody, ktore sa nenachadzaju v prevodovniku od CKSDRG
if (sprav_export_chyb) {
  uzs %>%
    filter(KOD_VYKON_JZS != "", is.na(kod_drg)) %>%
    select(KOD_VYKON_JZS) %>%
    unique() %>%
    arrange(KOD_VYKON_JZS) %>%
    fwrite(file = paste0(paths$vystupy, "neznamy_jzs_kod.csv"),
           sep = "|", row.names = F)
}
#   Nahrad JZS kody DRG kodmi
uzs <- uzs %>%
  mutate(KOD_VYKON_JZS = ifelse(!is.na(kod_drg), kod_drg, KOD_VYKON_JZS)) %>%
  select(-kod_drg)

# Spoj stlpce operacneho a jednodnoveho vykonu do jedneho stlpca, pricom
# prednost ma operacny vykon.
uzs <- uzs %>%
  mutate(KOD_VYKON = ifelse(KOD_VYKON_OPER == "", KOD_VYKON_JZS, KOD_VYKON_OPER))

# Chceme pocitat pocet spravenych vykonov, tak vytvor kombinaciu vykon-obdobie,
# aby sa vykon spravne zapocital viackrat, ak bol pocas jednej hospitalizacie
# robeny viackrat.
uzs <- uzs %>%
  mutate(vykon_lab = ifelse(KOD_VYKON == "", "",
                            paste0(KOD_VYKON, "_", ROK_MESIAC)))

# Ak v aspon jednom riadku hospitalizacie je priznak novorodenca, tak cela
# hospitalizacia bude mat priznak novorodenca. Stava, ze priznak novorodenca
# je len pri id matky, ale pri id dietata uz nie.
uzs <- uzs %>%
  mutate(NOVORODENEC = gsub("[^NO]", "", NOVORODENEC)) %>%
  group_by(ID_HP_ZP) %>%
  mutate(NOVORODENEC = ifelse("NO" %in% unique(NOVORODENEC), "NO", "")) %>%
  ungroup()

# Vyber potrebne stlpce a vyhod duplikaty
uzs <- uzs %>%
  select(BIC_POI, ID_HP_ZP, NOVORODENEC, DATUM_OD, DATUM_DO, KOD_VYKON,
         nemP01, diag_uzs, vykon_lab, STAROST_TYP) %>%
  unique()

# Vycisti pamat
invisible(gc())


### --- Priprav data zo suboru 09_POISTENCI

# Najdi relevantne tabulky za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "POISTENCI")
poi <- main_df[tmp_names]
poi <- rbindlist(poi, use.names = T)

# Zmen typ pre datumy z textu na datumy
poi <- poi %>%
  mutate(DATUM_NAROD = as.IDate(DATUM_NAROD))

# Vyber potrebne stlpce a vyhod duplicity
poi <- poi %>%
  select(BIC_POI, DATUM_NAROD) %>%
  unique()

# Pripoj datum narodenia zo suboru 09_POISTENCI k UZS datam
uzs <- uzs %>%
  left_join(poi, by = "BIC_POI")
