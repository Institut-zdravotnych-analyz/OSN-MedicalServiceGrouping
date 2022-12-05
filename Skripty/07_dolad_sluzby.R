##### --------------------------------------------------------------------------
# Skript na aplikovanie dodatocnych specialnych kriterii na medicinske sluzby a
# vylucenie priradenia, ak je uz priradena meedicinska sluzba, ktora ma prioritu.
##### --------------------------------------------------------------------------

# Spoj priradenia medicinskych sluzieb pre rozne podmienky
uzs_list <- rbindlist(uzs_list, fill = T)
uzs_list <- uzs_list %>%
  select(nemP01, ID_HOSP_ZP, drg, vykon, icd, icd_vedlajsia,
         icd_any, `Kod.MS`, `Medicinska.sluzba`, UPV, subor, vek,
         HMOTNOST, vek_crit) %>%
  unique()

# Nacitaj dodatocne kriteria pre novorodenecke sluzby
taz <- fread(file = paste0(paths$prevody, files$taz), skip = 20, sep = "=",
             header = F)[,1]
sig <- fread(file = paste0(paths$prevody, files$sig_all), skip = 14, sep = "=",
             header = F) %>%
  anti_join(fread(file = paste0(paths$prevody, files$sig_rem), skip = 3,
                  sep = "=", header = F), by = "V1")

# Aplikuj dodatocne kriteria pre novorodenecke sluzby
#   Zisti ci hospitalizacie vykazuju tazkosti a signifikantne vykony
uzs_list <- uzs_list %>% group_by(ID_HOSP_ZP) %>%
  mutate(tazkosti = length(intersect(unique(c(icd, icd_vedlajsia)), taz$V1)),
         sig_op = length(intersect(unique(vykon), sig$V1))) %>%
  ungroup()
#   Aplikuj kriteria na tazkosti a signifikantne vykony
uzs_list <- uzs_list %>% mutate(UPV = as.numeric(UPV)) %>%
  filter(!(`Kod.MS` == "43-08" & !(sig_op == 0 & UPV > 95 & tazkosti < 2) |
             `Kod.MS` == "43-02" & !(sig_op == 0 & UPV > 95 & tazkosti >= 2) |
             `Kod.MS` == "43-01" & !(sig_op > 0)))
#   Aplikuj hmotnostne kriterium pre sluzbu 43-07
uzs_list <- uzs_list %>%
  filter(!(`Kod.MS` == "43-07" & !(vek == 0 & (HMOTNOST > 0 & HMOTNOST < 500))))

# Z priradenych medicinskych sluzieb pre kazdu hospitalizaciu ponechaj len tu
# s najvyssou prioritou.
uzs_list <- uzs_list %>% left_join(ms_riadky %>% group_by(`Kod MS`) %>%
                                     filter(prior == min(prior)) %>%
                                     ungroup(),
                                   by = c("Kod.MS" = "Kod MS"))

# Vyrad priradenia, ktore nesplnaju vekove kriterium
#   Deti maju subory 16 a 18, dospeli maju subory 17 a 19
uzs_list <- uzs_list %>% filter(!(subor == 19 & vek <= 18))
uzs_list <- uzs_list %>% filter(!(subor == 17 & vek <= 18))
uzs_list <- uzs_list %>% filter(!(subor == 16 & vek > 18))
uzs_list <- uzs_list %>% filter(!(subor == 18 & vek > 18))
#   Niektore sluzby maju byt len pre dospelych, aj ked su urcene v inych suboroch
uzs_list <- uzs_list %>%
  mutate(vek_crit = ifelse(is.na(vek_crit), "vsetci", vek_crit),
         vek_pass = ifelse(vek_crit == "18+" & vek < 19, "n", "y")) %>%
  filter(vek_pass == "y") %>%
  select(-vek_crit, -vek_pass)

# Vytvor vysledny data frame
uzs_list_final <- uzs_list %>%
  select(nemP01, ID_HOSP_ZP, drg, vykon, icd, icd_vedlajsia, icd_any,
         ms_kod = `Kod.MS`, ms_name = `Medicinska.sluzba`, subor, prior, vek) %>%
  mutate(vek_skupina = case_when(vek == 0 ~ 0,
                                 vek %in% 1:6 ~ 1,
                                 vek %in% 7:15 ~ 7,
                                 vek %in% 16:18 ~ 16,
                                 vek > 18 ~ 18)) %>%
  group_by(ID_HOSP_ZP) %>%
  mutate(prior_check = ifelse(subor == min(subor), T, F)) %>%
  ungroup() %>%
  filter(prior_check == T) %>%
  select(-prior_check) %>%
  group_by(ID_HOSP_ZP) %>%
  filter(prior == min(prior)) %>%
  ungroup() %>%
  unique()

# Exportuj pocty medicinskych sluzieb po nemocniciach, sluzbach a vekoch.
# Kazda hospitalizacia je zapocitavana raz.
uzs_list_final %>%
  mutate(ms_kod = paste0("'", ms_kod)) %>%
  group_by(nemP01, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet_hosp = n_distinct(ID_HOSP_ZP)) %>%
  write.csv2(paste0(paths$vystupy, "vystup_", rok, ".csv"),
             fileEncoding = "UTF-8")
