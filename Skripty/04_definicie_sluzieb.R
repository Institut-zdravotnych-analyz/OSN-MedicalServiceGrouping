##### --------------------------------------------------------------------------
# Skript na spracovanie definicii medicinskych sluzieb podla vyhlasok.
##### --------------------------------------------------------------------------

# Nacitaj subor s pravidlami na priradenie medicinskych sluzieb (agregovany
# zo vsetkych vyhlasok spolu)
#   Hlavne kriteria
defs_hlavne <- read_xlsx(paste0(paths$prevody, files$ms),
                         sheet = 1, col_types = "text")
#   Vedlajsie kriteria
defs_vedla <- read_xlsx(paste0(paths$prevody, files$ms),
                        sheet = 2, col_types = "text")


### --- Priprav hlavne a vedlajsie kriteria na spojenie sa

# Na urcenie niektorych sluzieb dnes nemame data, treba ich vynechat.
defs_hlavne <- defs_hlavne %>%
  filter(Include == T)

# Premenuj stlpec urcujuci coho sa tyka hlavne kriterium.
defs_hlavne <- defs_hlavne %>%
  rename(drg = drg_cat)

# Sluzby maju hierarchiu, podla ktorej sluzba vo skorsom riadku je prednejsia.
# Pridaj premennu s cislom riadka.
defs_hlavne <- defs_hlavne %>%
  mutate(prior = row_number())

# Vyhlaska 12 mala pri medicinskej sluzbe v jednom riadku viacero diagnoz,
# podla ktorych sa urcuje. Treba to rozdelit.
tmp_12 <- separate_rows(defs_hlavne[defs_hlavne$subor == 12, ],
                        drg, sep = ", | ")
tmp_12 <- separate_rows(tmp_12, join, sep = ", ")
# Nahrad povodne definicie sluzieb z vyhlasky 12 (s viacerymi diagnozami v
# jednom riadku) upravenymi
defs_hlavne <- defs_hlavne %>%
  filter(subor != 12) %>%
  rbind(., tmp_12)

# Stlpec podla ktoreho sa spajaju hlavne a vedlajsie kriteria uprav na
# standardnu strukturu (male pismena bez diakritiky)
defs_hlavne <- defs_hlavne %>%
  mutate(join = tolower(gsub("[^0-9a-zA-Z]", "", join)))
defs_vedla <- defs_vedla %>%
  mutate(join = tolower(gsub("[^0-9a-zA-Z]", "", join)))

# Rozdel stlpec, v ktorom je urcene podla coho sa priraduje medicinska sluzba,
# na viacero stlpcov podla toho, ci ide o diagnozu, vykon, alebo drg
defs_hlavne <- defs_hlavne %>%
  data.table() %>%
  mutate(id = row_number()) %>%
  dcast(join + odbornost + vek + `Kod MS` + `Medicinska sluzba` + subor + id
        + prior ~ join_type_ms, value.var = "drg")

# Nahrad chybajuce hodnoty (NA) znakmi pre "akakolvek" pri vedlajsich kriteriach
defs_vedla <- defs_vedla %>%
  mutate(icd = ifelse(join_type_vk == "icd", diag_code, ".*"),
         icd_vedlajsia = ifelse(join_type_vk == "icd_vedlajsia", diag_code, ".*"),
         icd_any = ifelse(join_type_vk == "icd_any", diag_code, ".*")) %>%
  data.table() %>%
  select(-diag_code, -`typ diagnozy`)

# Pripoj vedlajsie kriteria k hlavnym kriteriam.
# Tam kde chyba diagnoza alebo vykon v hlavnych kriteriach, pouzi hodnotu
# z vedljsich kriterii.
defs_hlavne <- defs_hlavne %>%
  left_join(defs_vedla, by = c("join", "subor")) %>%
  mutate(icd = ifelse(is.na(icd.x), icd.y, icd.x),
         icd_vedlajsia = ifelse(is.na(icd_vedlajsia.x), icd_vedlajsia.y,
                                icd_vedlajsia.x),
         vykon = ifelse(is.na(vykon), vykon_code, vykon))

# Nahrad chybajuce diagnozy, vykony, alebo drg znakmi pre "akakolvek" a
# transformuj ich na stadardny tvar (male pismena bez diakritiky a inych znakov)
defs_hlavne <- defs_hlavne %>%
  mutate(drg = fifelse(is.na(drg), ".*", tolower(drg)),
         icd = fifelse(is.na(icd), ".*", tolower(icd)),
         icd_any = fifelse(is.na(icd_any), ".*", tolower(icd_any)),
         icd_vedlajsia = fifelse(is.na(icd_vedlajsia), ".*",
                                 tolower(icd_vedlajsia)),
         vykon = fifelse(is.na(vykon), ".*", tolower(vykon))) %>%
  mutate(drg = fifelse(drg != ".*", gsub("[^0-9a-zA-Z]", "", drg), drg),
         icd = fifelse(icd != ".*", gsub("[^0-9a-zA-Z]", "", icd), icd),
         icd_any = fifelse(icd_any != ".*", gsub("[^0-9a-zA-Z]", "", icd_any),
                           icd_any),
         icd_vedlajsia = fifelse(icd_vedlajsia != ".*",
                                 gsub("[^0-9a-zA-Z]", "", icd_vedlajsia),
                                 icd_vedlajsia),
         vykon = fifelse(vykon != ".*", gsub("[^0-9a-zA-Z]", "", vykon), vykon)) %>%
  filter(!(drg == ".*" & icd == ".*" & vykon == ".*"  & icd_vedlajsia == ".*"
           & icd_any == ".*"))

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
invisible(gc())
