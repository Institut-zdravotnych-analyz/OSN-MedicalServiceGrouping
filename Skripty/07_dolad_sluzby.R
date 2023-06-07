##### --------------------------------------------------------------------------
# Skript na aplikovanie dodatocnych specialnych kriterii na medicinske sluzby a
# vylucenie sluzby, ak je uz priradena sluzba s vyssou prioritou.
##### --------------------------------------------------------------------------

# Spoj priradenia medicinskych sluzieb pre rozne podmienky
uzs_ms_list <- rbindlist(uzs_ms_list, fill = T)

# Nacitaj dodatocne kriteria pre novorodenecke sluzby
taz <- fread(file = paste0(paths$prevody, files$taz), header = F)
sig <- fread(file = paste0(paths$prevody, files$sig), header = F)

# Aplikuj dodatocne kriteria pre novorodenecke sluzby
#   Zisti ci hospitalizacie vykazuju tazkosti a signifikantne vykony
uzs_ms_list <- uzs_ms_list %>%
  group_by(id_hosp_nem) %>%
  mutate(tazkosti = length(intersect(unique(c(icd, icd_vedlajsia)), taz$V1)),
         sig_op = length(intersect(unique(vykon), sig$V1))) %>%
  ungroup()
#   Aplikuj kriteria na tazkosti a signifikantne vykony
uzs_ms_list <- uzs_ms_list %>% mutate(UPV = as.numeric(UPV)) %>%
  filter(!(`Kod.MS` == "43-08" & !(sig_op == 0 & UPV > 95 & tazkosti < 2) |
             `Kod.MS` == "43-02" & !(sig_op == 0 & UPV > 95 & tazkosti >= 2) |
             `Kod.MS` == "43-01" & !(sig_op > 0)))
#   Aplikuj hmotnostne kriterium pre sluzbu 43-07
uzs_ms_list <- uzs_ms_list %>%
  filter(!(`Kod.MS` == "43-07" & !(vek == 0 & (HMOTNOST > 0 & HMOTNOST < 500))))

# Vyrad priradenia, ktore nesplnaju vekove kriterium
#   Deti maju subory 16 a 18, dospeli maju subory 17 a 19
uzs_ms_list <- uzs_ms_list %>% filter(!(subor == 19 & vek <= 18))
uzs_ms_list <- uzs_ms_list %>% filter(!(subor == 17 & vek <= 18))
uzs_ms_list <- uzs_ms_list %>% filter(!(subor == 16 & vek > 18))
uzs_ms_list <- uzs_ms_list %>% filter(!(subor == 18 & vek > 18))
#   Niektore obmedzenia su definovane v prilohach
uzs_ms_list <- uzs_ms_list %>%
  mutate(vek_crit = ifelse(is.na(vek_crit), "vsetci", vek_crit),
         vek_pass = "y",
         vek_pass = ifelse((vek_crit == "18+") & (vek < 19), "n", vek_pass),
         vek_pass = ifelse((vek_crit %like% "nad 18") & (vek < 19), "n",
                           vek_pass),
         vek_pass = ifelse((vek_crit %like% "do 18") & (vek > 18), "n",
                           vek_pass)) %>%
  filter(vek_pass == "y") %>%
  select(-vek_crit, -vek_pass)

# Vytvor vekove skupiny pouzivane pre OSN
uzs_ms_list <- uzs_ms_list %>%
  mutate(vek_skupina = case_when(vek == 0 ~ "age0",
                                 vek %in% 1:6 ~ "age1",
                                 vek %in% 7:15 ~ "age7",
                                 vek %in% 16:18 ~ "age16",
                                 vek > 18 ~ "age19"))

# Napocitaj pocet hospitalizacii pre medicinsku sluzbu pred aplikovanim priorit
# medicinskych sluzieb.
pocty_hosp <- uzs_ms_list %>%
  select(id_hosp_nem, vek_skupina, ms_kod = Kod.MS, ms_name = Medicinska.sluzba,
         typ_zs)
pocty_hosp <- pocty_hosp %>%
  mutate(kod_nem = gsub(".*_", "", id_hosp_nem),
         kod_hp = gsub("_[^_]+$", "", id_hosp_nem),
         ms_kod = paste0("'", ms_kod))
#   s JZS
tmp_pocty <- pocty_hosp %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = n_distinct(kod_hp)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_hosp_pred_prior_s_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)
#   bez JZS
tmp_pocty <- pocty_hosp %>%
  filter(typ_zs != "JZS") %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = n_distinct(kod_hp)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_hosp_pred_prior_bez_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)

# Napocitaj pocet vykonov pre medicinske sluzby, ktore su urcene vykonom pred
# aplikovanim priorit medicinskych sluzieb.
pocty_vyk <- uzs_ms_list %>%
  filter(joiner %like% "vykon") %>%
  select(id_hosp_nem, vek_skupina, ms_kod = Kod.MS, ms_name = Medicinska.sluzba,
         vykon_lab, typ_zs)
pocty_vyk <- pocty_vyk %>%
  mutate(kod_nem = gsub(".*_", "", id_hosp_nem),
         kod_hp = gsub("_[^_]+$", "", id_hosp_nem),
         ms_kod = paste0("'", ms_kod))
#   s JZS
tmp_pocty <- pocty_vyk %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina, kod_hp) %>%
  summarise(pocet = n_distinct(vykon_lab)) %>%
  ungroup() %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = sum(pocet, na.rm = T)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_vykon_pred_prior_s_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)
#   bez JZS
tmp_pocty <- pocty_vyk %>%
  filter(typ_zs != "JZS") %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina, kod_hp) %>%
  summarise(pocet = n_distinct(vykon_lab)) %>%
  ungroup() %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = sum(pocet, na.rm = T)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_vykon_pred_prior_bez_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)

### Aplikuj priority na urcenie dvojic hosp-sluzba
# Ako prva priorita sa aplikuje cislo suboru v ktorom je sluzba definovana,
# mensie cislo ma prioritu.
uzs_ms_priorita <- uzs_ms_list %>%
  select(id_hosp_nem, ms_kod = Kod.MS, ms_name = Medicinska.sluzba, subor,
         vek_skupina, typ_zs) %>%
  group_by(id_hosp_nem) %>%
  filter(subor == min(subor)) %>%
  ungroup() %>%
  unique()
# Niektore subory s definiciami nie su zoradene podla priority sluzieb. Treba
# spravit krok v ktorom ma prioritu sluzba na vyssej urovni.
#   Vyber subory, ktore nie su zoradene podla priority
tmp_subory <- c(13, 15, 16, 17, 18, 19)
tmp_prior <- uzs_ms_priorita %>%
  filter(subor %in% tmp_subory)
#   Prirad uroven k medicinskym sluzbam pri zohladneni veku
tmp_uroven <- fread(file = paste0(paths$prevody, files$uroven))
tmp_prior <- tmp_prior %>%
  left_join(tmp_uroven, by = c("ms_kod" = "code_ms", "vek_skupina"))
#   Pre kazdu hospitalizaciu ponechaj len tie sluzby, ktore su na najvyssej
#   urovni
tmp_prior <- tmp_prior %>%
  group_by(id_hosp_nem) %>%
  filter(uroven == max(uroven)) %>%
  ungroup() %>%
  select(-uroven) %>%
  unique()
#   Nahrad povodne hospitalizacie novymi po aplikovani urovnovej priority
uzs_ms_priorita <- uzs_ms_priorita %>%
  filter(!(subor %in% tmp_subory)) %>%
  rbind(tmp_prior)
# Ako posledny krok sa z kazdeho suboru zoberie sluzba, ktora je na najvyssom
# riadku (je skor).
#   Pripoj cislo riadku pre sluzbu
uzs_ms_priorita <- uzs_ms_priorita %>%
  left_join(ms_riadky %>%
              group_by(`Kod MS`) %>%
              filter(prior == min(prior)) %>%
              ungroup(),
            by = c("ms_kod" = "Kod MS"))
#   Ponechaj len sluzby s najnizsim cislom riadku
uzs_ms_priorita <- uzs_ms_priorita %>%
  group_by(id_hosp_nem) %>%
  filter(prior == min(prior)) %>%
  ungroup() %>%
  select(-prior) %>%
  unique()

# Napocitaj pocty hospitalizacii pre medicinske sluzby po aplikovanim priorit
# medicinskych sluzieb.
pocty_prior <- uzs_ms_priorita %>%
  select(id_hosp_nem, vek_skupina, ms_kod, ms_name, typ_zs)
pocty_prior <- pocty_prior %>%
  mutate(kod_nem = gsub(".*_", "", id_hosp_nem),
         kod_hp = gsub("_[^_]+$", "", id_hosp_nem),
         ms_kod = paste0("'", ms_kod))
#   s JZS
tmp_pocty <- pocty_prior %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = n_distinct(kod_hp)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_hosp_po_prior_s_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)
#   bez JZS
tmp_pocty <- pocty_prior %>%
  filter(typ_zs != "JZS") %>%
  group_by(kod_nem, ms_kod, ms_name, vek_skupina) %>%
  summarise(pocet = n_distinct(kod_hp)) %>%
  ungroup()
tmp_pocty$ms_name <- enc2utf8(tmp_pocty$ms_name)
Encoding(tmp_pocty$ms_name) <- "unknown"
fwrite(tmp_pocty, file = paste0(paths$vystupy, "pocet_hosp_po_prior_bez_JZS_",
                                rok, ".csv"), sep = "|", row.names = F, bom = T)
