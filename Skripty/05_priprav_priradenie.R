##### --------------------------------------------------------------------------
# Skript na pripravenie priradenia medicinskych sluzieb k hospitalizaciam
##### --------------------------------------------------------------------------

# Vytvor indikator, na co sa pri priradovani treba pozerat a pridaj ho k
# definiciam medicinskych sluzieb
tmp_joiner <- defs_hlavne %>%
  select(`Kod MS`, `Medicinska sluzba`, drg, vykon, icd, icd_vedlajsia, icd_any) %>%
  mutate(id = row_number()) %>%
  data.table() %>%
  melt(id.vars = c("Kod MS", "Medicinska sluzba", "id"),
       measure.vars = c("drg", "vykon", "icd", "icd_any", "icd_vedlajsia")) %>%
  filter(value != ".*") %>%
  group_by(`Kod MS`, `Medicinska sluzba`, id) %>%
  summarise(joiner = paste0(unique(variable), collapse = ", ")) %>%
  ungroup()

defs_hlavne <- defs_hlavne %>%
  mutate(id = row_number()) %>%
  left_join(tmp_joiner %>% select(id, joiner), by = "id")

# Vyber stlpce ktore su potrebne na priradenie medicinskych sluzieb
defs_hlavne <- defs_hlavne %>%
  select(`Kod MS`, `Medicinska sluzba`, drg, vykon, icd, icd_vedlajsia, icd_any,
         joiner, subor, prior, vek_crit = vek)

# Rozdel kriteria podla toho, co zohladnuju
ms_list <- split(data.table(defs_hlavne), by = "joiner")

# Vyber zoznam medicinskych sluzieb a cisel ich riadkov
ms_riadky <- defs_hlavne %>%
  select(`Kod MS`, prior) %>%
  unique()

# Vytvor zoznamy drg a diagnoz pouzitych na urcenie medicinskych sluzieb
ms_drg <- defs_hlavne$drg %>% unique()
ms_drg <- ms_drg[ms_drg != ".*"]
ms_diag <- c(defs_hlavne$icd, defs_hlavne$icd_vedlajsia, defs_hlavne$icd_any) %>%
  unique()
ms_diag <- ms_diag[ms_diag != ".*"]

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(defs_hlavne, defs_vedla)
invisible(gc())

# Transformuj drg, diagnozy a vykony v data o hospitalizaciach na standardny
# tvar (male pismena bez diakritiky a inych znakov)
uzs_final <- uzs_final %>%
  mutate(drg = gsub("[^0-9a-zA-Z]", "", tolower(KOD_DRG)),
         diag_code = gsub("[^0-9a-zA-Z]", "", tolower(diag_uzs)),
         vykon = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VYKON)))
uzs_final <- uzs_final %>%
  mutate(icd = ifelse(is.na(KOD_DIAG_HL), diag_code,
                      gsub("[^0-9a-zA-Z]", "", tolower(KOD_DIAG_HL))),
         icd_vedlajsia = gsub("[^0-9a-zA-Z]", "", tolower(KOD_VEDL_DIAG)))

# Zahod stlpce, ktore nie su potrebne
uzs_final <- uzs_final %>%
  select(-KOD_DRG, -diag_uzs, -KOD_VYKON, -KOD_DIAG_HL, -KOD_VEDL_DIAG,
         -diag_code, -KOD_VYK_OPER)
uzs_final <- uzs_final %>% unique()
invisible(gc())

# V datach o hospitalizaciach mozu mat drg kody a kody diagnoz rozne dlzky,
# pricom su to podretazce dlhsich kodov. Treba preto vytvorit kopie dat v
# ktorych budu mat drg a diagnozy potrebne dlzky.
# Pre DRG su to dlzky: taka aka je vyplnena, 1.
# Pre diagnozy su to dlzky: taka aka je vyplnena, 1, 3, 4, 5.
# Aby sme usetrili trochu pamate, tak po kazdom kroku vyhodime duplicity.
#   DR#G o plnej dlzke
tmp_join_ms <- uzs_final %>%
  filter(!is.na(drg)) %>%
  filter(drg %in% ms_drg) %>%
  unique()
invisible(gc())
#   DRG o dlzke 1
tmp <- uzs_final %>%
  filter(!is.na(drg)) %>%
  mutate(drg = substring(drg, 0, 1)) %>%
  filter(drg %in% ms_drg)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   diagnozy o plnej dlzke
tmp <- uzs_final %>%
  filter(!is.na(icd) | !is.na(icd_vedlajsia)) %>%
  filter(icd %in% ms_diag | icd_vedlajsia %in% ms_diag)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   diagnozy o dlzke 1
tmp <- uzs_final %>%
  filter(!is.na(icd) | !is.na(icd_vedlajsia)) %>%
  mutate(icd = substring(icd, 0, 1),
         icd_vedlajsia = substring(icd_vedlajsia, 0, 1)) %>%
  filter(icd %in% ms_diag | icd_vedlajsia %in% ms_diag)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   diagnozy o dzke 3
tmp <- uzs_final %>%
  filter(!is.na(icd) | !is.na(icd_vedlajsia)) %>%
  mutate(icd = substring(icd, 0, 3),
         icd_vedlajsia = substring(icd_vedlajsia, 0, 3)) %>%
  filter(icd %in% ms_diag | icd_vedlajsia %in% ms_diag)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   diagnozy o dlzke 4
tmp <- uzs_final %>%
  filter(!is.na(icd) | !is.na(icd_vedlajsia)) %>%
  mutate(icd = substring(icd, 0, 4),
         icd_vedlajsia = substring(icd_vedlajsia, 0, 4)) %>%
  filter(icd %in% ms_diag | icd_vedlajsia %in% ms_diag)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   diagnozy o dlzke 5
tmp <- uzs_final %>%
  filter(!is.na(icd) | !is.na(icd_vedlajsia)) %>%
  mutate(icd = substring(icd, 0, 5),
         icd_vedlajsia = substring(icd_vedlajsia, 0, 5)) %>%
  filter(icd %in% ms_diag | icd_vedlajsia %in% ms_diag)
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())
#   a este vsetko co ma vykon, ak to nahodou este nebolo pridane
tmp <- uzs_final %>%
  filter(vykon != "")
tmp_join_ms <- rbind(tmp_join_ms, tmp) %>%
  unique()
invisible(gc())

# Prirad data s kodmi roznej dlzky do povodnej premennej
uzs_final <- tmp_join_ms

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(ms_diag, ms_drg)
invisible(gc())
