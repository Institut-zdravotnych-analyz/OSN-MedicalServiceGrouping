##### --------------------------------------------------------------------------
# Hlavny skript algoritmu na priradenie medicinskych sluzieb hospitalizaciam.
# Staci spustit tento skript, ostatne sa volaju podla potreby z neho.
# Volitelne parametre je potrebne nastavit v skripte "01_konfiguracia.R", napr.
# otvorenim v programe Notepad++ a prepisanim hodnot parameterov.
#
# V skripte "01_konfiguracia.R" je tiez zoznam kniznic, ktore su potrebne pre
# spravne fungovanie algoritmu. Tieto kniznice je potrebne mat nainstalovane
# pred tym ako sa spusti hlavny (tento) skript.
#
# Pracovny priecinok musi byt rovnaky ako priecinok v ktorom su ulozene skripty!
##### --------------------------------------------------------------------------

# Skontroluj, ze nastaveny pracovny priecinok v R je rovnaky ako priecinok, kde
# su ulozene skripty
if (!endsWith(getwd(), "Skripty")) {
  stop(paste("Nastaveny pracovny priecinok musi byt rovnaky ako priecinok,",
              "kde su ulozene skripty!"))
}

# Spusti konfiguracny skript, ktory nacita potrebne kniznice, zadefinovanu
# strukturu a mena priecinkov a suborov a hodnoty parametrov.
source("01_konfiguracia.R", echo = F)

# Spusti skript na nacitanie dat
source("02_nacitanie_dat.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "02_nacitane_data_", rok, ".RData"))
}

# Priprava dat na urcovanie medicinskych sluzieb
source("03a_priprava_data_UZS_JZS.R", echo = T)
source("03b_priprava_data_DRG.R", echo = T)
source("03c_priprava_spoj_data.R", echo = T)
if (sprav_vylucenie_zlucenych) {
  source("03d_priprava_vyluc_zlucene_hosp.R", echo = T)
}
# Vyber stlpce, ktore u potrebne a vyhod duplikaty
uzs_final <- uzs_final %>%
  select(id_hosp_nem, drg, icd, icd_vedlajsia, vykon, vykon_lab, vek, HMOTNOST,
         UPV, typ_zs) %>%
  unique()
# Poznamka: ako ziskat id_hosp a nemP01 z id_hosp_nem
# uzs_final <- uzs_final %>%
#   mutate(kod_nem = gsub(".*_", "", id_hosp_nem),
#          kod_hp = gsub("_[^_]+$", "", id_hosp_nem))
#   Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(uzs, drg, prek, poi, vdg, vyk)
rm(main_df)
invisible(gc())

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "03_pripravene_data_", rok, ".RData"))
}

# Priprav definicie medicinskych sluzieb
source("04_definicie_sluzieb.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "04_definicie_sluzieb_", rok, ".RData"))
}
invisible(gc())

# Priprav priradenie sluzieb
source("05_priprav_priradenie.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky | sprav_zalohu_po_5) {
  save.image(file = paste0(paths$zalohy, "05_pripravene_na_priradenie_", rok,
                           ".RData"))
}
invisible(gc())

# Ak je urobenie zalohy po 5tej casti povolene, odporuca sa vypnut a zapnut R,
# aby sa uvolnila RAM, a pokracovat odtialto.
# TODO: pridaj aj check na existenciu ulozeneho workspace !
if (!exists("uzs_final") & !exists("ms_list")) {
  # Treba znova vytvorit cesty k suborom
  paths <- list()
  paths$scripts <- dirname(getSourceEditorContext()$path)
  # a spravit konfiguraciu
  source(paste0(paths$scripts, "/01_konfiguracia.R"), echo = F)

  # A nacitat premenne potrebne na pokracovanie
  load(paste0(paths$zalohy, "05_pripravene_na_priradenie_", rok, ".RData"))

  invisible(gc())
}

# Prirad medicinske sluzby hospitalizaciam. V tomto kroku su hospitalizacii
# priradene vsetky sluzby, ktore by mohli byt. V dalsom kroku sa aplikuju
# dodatocne specialne kriteria a priorita medzi medicinskymi sluzbami.
source("06_prirad_sluzby.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "06_priradene_sluzby_", rok, ".RData"))
}
invisible(gc())

# Aplikuj dodatocne podmienky na priradenie do medicinskej sluzby. Napocitaj
# vykony a hospitalizacie pre medicinske sluzby pred tym, ako bude jednej
# hospitalizacii priradene len jedna najdolezitejsia sluzba (kvoli podmienkam
# na pocty vykonov). Nasledne vyber spomedzi moznych medicinskych sluzieb pre
# hospitalizaciu tu najdolezitejsiu a napocitaj pocty hospitalizacii.
source("07_dolad_sluzby.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "07_konecny_stav_", rok, ".RData"))
}
invisible(gc())
