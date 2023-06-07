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


# V datach o hospitalizaciach mozu mat drg kody a kody diagnoz rozne dlzky,
# pricom su to podretazce dlhsich kodov. Treba preto vytvorit kopie dat v
# ktorych budu mat drg a diagnozy potrebne dlzky.
# Pre DRG su to dlzky: taka aka je vyplnena, 1.
# Pre diagnozy su to dlzky: taka aka je vyplnena, 1, 3, 4, 5.
# Aby sme usetrili trochu pamate, tak po kazdom kroku vyhodime duplicity a
# novo-vytvorene riadky, ktore neobsahuju hodnotu drg/dianoz, ktore su pouzite
# na urcenie medicinskych sluzieb.
#   Pridaj DRG o dlzke 1
tmp_uzs <- uzs_final %>%
  mutate(drg = substring(drg, 0, 1)) %>%
  filter(drg %in% ms_drg)
uzs_final <- rbind(uzs_final, tmp_uzs) %>%
  unique()
invisible(gc())
#   Pridaj hlavne diagnozy o dlzke 1, 3-5
tmp_uzs <- uzs_final %>%
  mutate(icd_1 = substring(icd, 0, 1),
         icd_3 = substring(icd, 0, 3),
         icd_4 = substring(icd, 0, 4),
         icd_5 = substring(icd, 0, 5)) %>%
  select(-icd) %>%
  data.table() %>%
  melt(measure.vars = c("icd_1", "icd_3", "icd_4", "icd_5")) %>%
  mutate(icd = value) %>%
  select(-variable, -value) %>%
  filter(icd %in% ms_diag)
uzs_final <- rbind(uzs_final, tmp_uzs) %>%
  unique()
invisible(gc())
#   Pridaj vedlajsie diagnozy o dlzke 1, 3-5
tmp_uzs <- uzs_final %>%
  mutate(icdv_1 = substring(icd_vedlajsia, 0, 1),
         icdv_3 = substring(icd_vedlajsia, 0, 3),
         icdv_4 = substring(icd_vedlajsia, 0, 4),
         icdv_5 = substring(icd_vedlajsia, 0, 5)) %>%
  select(-icd_vedlajsia) %>%
  data.table() %>%
  melt(measure.vars = c("icdv_1", "icdv_3", "icdv_4", "icdv_5")) %>%
  mutate(icd_vedlajsia = value) %>%
  select(-variable, -value) %>%
  filter(icd_vedlajsia %in% ms_diag)
uzs_final <- rbind(uzs_final, tmp_uzs) %>%
  unique()
invisible(gc())

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
invisible(gc())
