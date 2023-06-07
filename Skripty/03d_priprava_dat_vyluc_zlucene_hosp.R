##### --------------------------------------------------------------------------
# Skript na spracovanie dat o hospitalizaciach od poistovni.
# Data sa vycistia, co najlepsie sa urcia veky a pospajaju do jednej premennej.
#
# CAST D: Vylucenie hospitalizacii, ktore boli zlucene kvoli DRG
##### --------------------------------------------------------------------------

# Najdi tabulky s drg datami za vsetky poistovne a spoj ich
tmp_names <- main_df %>% names()
tmp_names <- which(tmp_names %like% "HP")
tmp_drg <- main_df[tmp_names]
tmp_drg <- rbindlist(tmp_drg, use.names = T)

# Vytvor jedinecne id hospitalizacie ktory zohladnuje aj z ktorej nemocnice je
tmp_drg <- tmp_drg %>%
  mutate(prevadzka = ifelse(startsWith(ID_HP_PZS, "Z"),
                            substring(ID_HP_PZS, 4, 4),
                            substring(ID_HP_PZS, 3, 3)),
         hosp_uid = paste0(ID_HP_PZS, "_", PZS_6, "_", prevadzka))

# Zo stlpca s ciastkovymi hospitalizaciami odstran medzery (nemali by byt, ale
# radsej pre isototu to treba spravit) a ak je ako oddelovac pouzita bodka
# (mala by byt pouzivana len ciarka, ale radsej to sprav) zmen ju na ciarku
tmp_drg$ZLUCENE_HP <- gsub(" ", "", tmp_drg$ZLUCENE_HP)
tmp_drg$ZLUCENE_HP <- gsub("\\.", ",", tmp_drg$ZLUCENE_HP)

# Vyber riadky, ktore maju nieco v ciastkovej hospitalizacii
tmp_ch <- tmp_drg %>%
  filter(ZLUCENE_HP != "") %>%
  select(PZS_6, prevadzka, ZLUCENE_HP) %>%
  unique()

# Rozdel ciastkove hospitalizacie samostatne do riadkov
tmp_ch <- tmp_ch %>%
  separate_rows(ZLUCENE_HP, sep = ",")

# Vytvor jedinecne id pre ciastkove hospitalizacie
tmp_ch <- tmp_ch %>%
  mutate(hosp_uid = paste0(ZLUCENE_HP, "_", PZS_6, "_", prevadzka))

# Najdi id hospitalizacii prisluchajucich jedinecnym id
tmp_ch <- tmp_drg %>%
  filter(hosp_uid %in% tmp_ch$hosp_uid)
tmp_ch <- tmp_ch$ID_HP_ZP

# Exportuj ciastkove hospitalizacie
uzs_final %>%
  filter(ID_HP_ZP %in% tmp_ch) %>%
  fwrite(file = paste0(paths$vystupy, "ciastkove_hosp_", rok, ".csv"),
         sep = "|", row.names = F)

# Vyhod ciastkove hospitalizacie
uzs_final <- uzs_final %>%
  filter(!(ID_HP_ZP %in% tmp_ch))
