##### --------------------------------------------------------------------------
# Skript na spracovanie dat o hospitalizaciach od poistovni.
# Data sa vycistia, co najlepsie sa urcia veky a pospajaju do jednej premennej.
#
# CAST C: Spoj UZS_JZS a DRG dat a zjednot ich
##### --------------------------------------------------------------------------

# Spoj tabulky uzs a drg
uzs_final <- drg %>%
  full_join(uzs, by = "ID_HP_ZP", suffix = c(".02", ".01"))


### --- Zjednot udaje, ktore sa nachadzaju v oboch tabulkach

# Datumy hospitalizacie
# Zaujimaju nas kvoli urceniu veku, vyberame najskorsi z datumov prijatia
# a prepustenia cez datumy zo suborov 01, 02 a 03.
# Tento krok trva trochu dlhsie
uzs_final <- uzs_final %>%
  mutate(datum_start = pmin(DATUM_OD.02, DATUM_DO.02, DATUM_OD.03, DATUM_DO.03,
                            DATUM_OD.01, DATUM_DO.01, na.rm = T),
         datum_end = pmax(DATUM_DO.02, DATUM_DO.03, DATUM_DO.01, na.rm = T)) %>%
  group_by(ID_HP_ZP) %>%
  mutate(datum_start = min(datum_start, na.rm = T),
         datum_end = max(datum_end, na.rm = T)) %>%
  select(-DATUM_OD.02, -DATUM_DO.02, -DATUM_OD.03, -DATUM_DO.03, -DATUM_OD.01,
         -DATUM_DO.01, -BIC_POI.02, -BIC_POI.01) %>%
  ungroup()
# Ak nahodou vsetkych 6 datumov chyba = je tam hodnota NA, tak vysledna hodnota
# bude NA. Zmen ju na koniec roka, za ktory sa vyhodnocuju data.
uzs_final <- uzs_final %>%
  mutate(datum_start = as.character(datum_start),
         datum_start = ifelse(is.na(datum_start), paste0(rok, "-12-31"), datum_start),
         datum_start = as.IDate(datum_start))

# Datumy narodenia
# Zaujimaju nas kvoli urceniu veku, vyberame najskorsi z datumov narodenia,
# ktore boli priradene na zaklade identifikatorov poistencov zo suborov 01 a 02
# a datumu narodenia, ktory bol vyplneny v subore 02.
# Tento krok trva trochu dlhsie
uzs_final <- uzs_final %>%
  group_by(ID_HP_ZP) %>%
  mutate(datum_nar = min(c(DATUM_NAROD.02, DATUM_NAROD.0209, DATUM_NAROD.01),
                         na.rm = T)) %>%
  ungroup() %>%
  select(-DATUM_NAROD.02, -DATUM_NAROD.0209, -DATUM_NAROD.01)
# Ak sa neda priradit datum narodenia identifikatorom poistencov a nie je ani
# vyplneny v subore 02, tak vysledna hodnota je NA.

# Hlavna diagnoza
uzs_final <- uzs_final %>%
  mutate(icd = ifelse(!is.na(HDG), HDG, diag_uzs)) %>%
  select(-HDG, -diag_uzs)

# Typ zdravotnej starostlivosti
uzs_final <- uzs_final %>%
  mutate(typ_zs = ifelse(!is.na(STAROST_TYP.02), STAROST_TYP.02,
                         STAROST_TYP.01)) %>%
  select(-STAROST_TYP.02, -STAROST_TYP.01)
#   Pre chybajuci typ starostlivosti pouzi XX
uzs_final <- uzs_final %>%
  mutate(typ_zs = ifelse(is.na(typ_zs) | (typ_zs == ""), "XX", typ_zs))

# Kod nemocnice
# Najprv sa doplnia do stlpcov z oboch suborov hodnoty podla druheho subor a
# nasledne sa vylucia riadky, kde nie su rovnake.
uzs_final <- uzs_final %>%
  mutate(nemP01.02 = ifelse(!is.na(nemP01.02), nemP01.02, nemP01.01),
         nemP01.01 = ifelse(!is.na(nemP01.01), nemP01.01, nemP01.02))
#   Exportuj zaznamy kde su kody nemocnic rozdielne
if (sprav_export_chyb) {
  uzs_final %>%
    filter(nemP01.02 != nemP01.01) %>%
    fwrite(file = paste0(paths$vystupy, "rozdielne_nemP01_", rok, "_drguzs.csv"),
           sep = "|", row.names = F)
}
#   Zjednot kody
uzs_final <- uzs_final %>%
  filter(nemP01.02 == nemP01.01) %>%
  mutate(kod_nem = nemP01.02) %>%
  select(-nemP01.02, -nemP01.01)
#   Exportuj zaznamy ktorym nebola priradena nemocnica
if (sprav_export_chyb) {
  uzs_final %>%
    filter(is.na(kod_nem)) %>%
    fwrite(file = paste0(paths$vystupy, "chybajuce_nemP01_", rok, "_uzsdrg.csv"),
           sep = "|", row.names = F)
}

# Vytvor identifikator hospitalizacia-nemocnica
uzs_final <- uzs_final %>%
  mutate(id_hosp_nem = paste0(ID_HP_ZP, "_", kod_nem))

# Vykon
uzs_final <- uzs_final %>%
  mutate(vykon = ifelse(!(is.na(KOD_VYKON.02) | (KOD_VYKON.02 == "")),
                          KOD_VYKON.02, KOD_VYKON.01),
         vykon_lab = ifelse(!(is.na(vykon_lab.02) | (vykon_lab.02 == "")),
                            vykon_lab.02, vykon_lab.01)) %>%
  select(-KOD_VYKON.02, -KOD_VYKON.01, -vykon_lab.02, -vykon_lab.01)

# Nahrad chybajuce hodnoty, ktore vznikli spojenim tabulliek
uzs_final <- uzs_final %>%
  replace_na(list(VEK_DNI = "-2", VEK_ROKY = "-2", HMOTNOST = "-2",
                  UPV_DLZKA = "-2",
                  DRG_SKUP = "", VDG = "", NOVORODENEC = "", icd = "",
                  vykon = "", vykon_lab = ""))

# Zmen typ ciselnych premennych na cislo
uzs_final <- uzs_final %>%
  mutate(VEK_DNI = as.numeric(VEK_DNI),
         VEK_ROKY = as.numeric(VEK_ROKY),
         HMOTNOST = as.numeric(HMOTNOST),
         UPV_DLZKA = as.numeric(UPV_DLZKA))

# Prirad vek podla pravidiel:
#   01 - vypocitaj vek podla datumu hospitalizacie a datumu narodenia
uzs_final$vek_nar <- trunc(time_length(difftime(uzs_final$datum_start,
                                                uzs_final$datum_nar), "years"))
#   Chybajuce hodnoty vekov nastav na -2
uzs_final <- uzs_final %>%
  mutate(vek_nar = ifelse(is.na(vek_nar), -2, vek_nar))
#   Inicializuj vek
uzs_final$vek = -3
#   02 - ak vek_nar vypocitany v bode 01 je 0, tak nastav vek = 0
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3) & (vek_nar == 0), 0, vek))
#   03 - ak 0 < vek_dni < 367, tak vek = 0
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3) & ((VEK_DNI > 0) & (VEK_DNI < 367)), 0, vek))
#   04 - ak 0 < hmotnost < 6000 a vek_roky = {0-, 13+}, tak vek = 0
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3)
                      & ((HMOTNOST > 0) & (HMOTNOST < 6000)
                         & ((VEK_ROKY < 1) | (VEK_ROKY > 12))), 0, vek))
#   05 - ak novorodenec = NO, tak vek = 0
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3) & (NOVORODENEC == "NO"), 0, vek))
#   06 - ak 0 < vek_nar, tak vek = vek_nar
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3) & (vek_nar > 0), vek_nar, vek))
#   07 - ak 0 < vek_roky, tak vek = vek_roky
uzs_final <- uzs_final %>%
  mutate(vek = ifelse((vek == -3) & (VEK_ROKY > 0), VEK_ROKY, vek))
#   Odstran nepotrebne stlpce
uzs_final <- uzs_final %>%
  select(-VEK_DNI, -VEK_ROKY, -NOVORODENEC, -datum_start, -datum_nar, -vek_nar)
#   Exportuj zaznamy, ktore maju nestandardne hodnoty
if (sprav_export_chyb) {
  #   Vysoky vek
  uzs_final %>%
    filter(vek > 109) %>%
    fwrite(file = paste0(paths$vystupy, "data_vysoky_vek_", rok, ".csv"),
           sep = "|", row.names = F)
  #   Novorodenci bez hmotnosti
  uzs_final %>%
    filter(vek == 0 & HMOTNOST < 1) %>%
    fwrite(file = paste0(paths$vystupy, "data_vek0_hmotnost0_", rok, ".csv"),
           sep = "|", row.names = F)
  #   Chybajuci vek (aj napriek carovaniu so vsetkym moznym)
  uzs_final %>%
    filter(vek < 0) %>%
    fwrite(file = paste0(paths$vystupy, "data_chybajuci_vek_", rok, ".csv"),
           sep = "|", row.names = F)
}
#   08 - inak vek = 42
uzs_final <- uzs_final %>%
  mutate(vek = ifelse(vek == -3, 42, vek))


# Vyrad hospitalizacie ktore nekoncia vo vybranom roku
uzs_final <- uzs_final %>%
  filter(year(datum_end) == rok)


# Premen kody DRG, diagnoz a vykonov na standardny tvar
# - len male pismena a cisla.
uzs_final <- uzs_final %>%
  mutate(DRG_SKUP = gsub("[^0-9a-zA-Z]", "", tolower(DRG_SKUP)),
         icd = gsub("[^0-9a-zA-Z]", "", tolower(icd)),
         VDG = gsub("[^0-9a-zA-Z]", "", tolower(VDG)),
         vykon = gsub("[^0-9a-zA-Z]", "", tolower(vykon)))


# Vyber a premenuj stlpce, ktore budu pouzite dalej
uzs_final <- uzs_final %>%
  select(ID_HP_ZP, kod_nem, id_hosp_nem, drg = DRG_SKUP, icd,
         icd_vedlajsia = VDG, vykon, vykon_lab, vek, HMOTNOST, UPV = UPV_DLZKA,
         typ_zs)
