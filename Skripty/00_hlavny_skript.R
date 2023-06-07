##### --------------------------------------------------------------------------
# Hlavny skript algoritmu na priradenie medicinskych sluzieb hospitalizaciam.
# Staci spustit tento skript, ostatne sa volaju podla potreby z neho.
# Volitelne parametre je potrebne nastavit v skripte "01_konfiguracia.R", napr.
# otvorenim v programe Notepad++ a prepisanim hodnot parameterov.
# V skripte "01_konfiguracia.R" je tiez zoznam kniznic, ktore su potrebne pre
# spravne fungovanie algoritmu. Tieto kniznice je potrebne mat nainstalovane
# pred tym ako sa spusti hlavny (tento) skript.
##### --------------------------------------------------------------------------

# Spusti konfiguracny skript, ktory nacita potrebne kniznice, zadefinovanu
# strukturu a mena priecinkov a suborov a hodnoty parametrov.
source("01_konfiguracia.R", echo = F)

# Spusti skript na nacitanie dat
source("02_nacitanie_dat.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "02_nacitane_data_", rok, ".RData"))
}

# Priprav data na urcovanie medicinskych sluzieb
source("03_prirrav_data.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky | sprav_zalohu_po_5) {
  save.image(file = paste0(paths$zalohy, "03_pripravene_data_", rok, ".RData"))
}

# Priprav definicie medicinskych sluzieb
source("04_definicie_sluzieb.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "04_definicie_sluzieb_", rok, ".RData"))
}

# Priprav priradenie sluzieb
source("05_prirpav_priradenie.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "05_pripravene_na_priradenie_", rok,
                           ".RData"))
}

# Ak je urobenie zalohy po 5tej casti povolena, odporuca sa vypnut a zapnut R,
# aby sa uvolnila RAM, a pokracovat odtialto.
if (!exists("uzs_final") & !exists("ms_list")) {
  # Treba znova spravit konfiguraciu
  source("01_konfiguracia.R", echo = F)

  # A nacitat premenne potrebne na pokracovanie
  load(paste0(paths$zalohy, "05_pripravene_na_priradenie_", rok, ".RData"))
}

# Prirad medicinske sluzby hospitalizaciam. V tomto kroku su hospitalizacii
# priradene vsetky sluzby, ktore by mohli byt. V dalsom kroku sa aplikuju
# dodatocne specialne kriteria a priorita medzi medicinskymi sluzbami.
source("06_prirad_sluzby.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "06_priradene_sluzby_", rok, ".RData"))
}

# Aplikuj dodatocne specialne kriteria a prioritu medzi medicinskymi sluzbami.
# Tiez exportuj vystup s poctami medicinskych sluzieb.
source("07_dolad_sluzby.R", echo = T)

# Sprav zalohu aktualneho stavu, ak to pouzivatel chce
if (sprav_zalohy_vsetky) {
  save.image(file = paste0(paths$zalohy, "07_konecny_stav_", rok, ".RData"))
}
