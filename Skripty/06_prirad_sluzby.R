##### --------------------------------------------------------------------------
# Skript na priradenie medicinskych sluzieb k hospitalizaciam
##### --------------------------------------------------------------------------

# Inicializuj premennu do ktorej sa budu ukladat hospitalizacie s priradenou
# medicinskou sluzbou.
uzs_ms_list <- list()

# Prirad sluzby podla toho co zohladnuju
tmp_names <- names(ms_list)
tmp_names <- tmp_names[tmp_names != "icd_vedlajsia"]
for (n in tmp_names) {
  print(paste("Priradujem sluzby podla: ", n))

  # Ak sa zohladnuje viac ako jeden faktor, rozhod ich na vektor nazvov
  if (n %like% ",") {
    tmp_join_col <- unlist(strsplit(n, split = ", "))
  } else {
    tmp_join_col <- n
  }

  # Sprav predvyber podla
  #   premennych ktore nas zaujimaju
  if ("icd_any" %in% tmp_join_col) {
    tmp_data <- uzs_final %>%
      select(id_hosp_nem, vek, HMOTNOST, UPV, typ_zs, vykon_lab,
             any_of(tmp_join_col), icd, icd_vedlajsia) %>%
      unique()
  } else {
    tmp_data <- uzs_final %>%
      select(id_hosp_nem, vek, HMOTNOST, UPV, typ_zs, vykon_lab,
             all_of(tmp_join_col)) %>%
      unique()
  }
  #   DRG
  if ("drg" %in% tmp_join_col) {
    tmp_data <- tmp_data %>%
      filter(drg %in% ms_drg)
  }
  #   vykonu
  if ("vykon" %in% tmp_join_col) {
    tmp_data <- tmp_data %>%
      filter(vykon != "")
  }
  #   diagnozy
  if ("icd" %in% tmp_join_col) {
    tmp_data <- tmp_data %>%
      filter(icd %in% ms_diag)
  }
  if ("icd_vedlajsia" %in% tmp_join_col) {
    tmp_data <- tmp_data %>%
      filter(icd_vedlajsia %in% ms_diag)
  }
  if ("icd_any" %in% tmp_join_col) {
    tmp_data <- tmp_data %>%
      filter((icd_vedlajsia %in% ms_diag) | (icd %in% ms_diag))
  }

  # Prirad sluzby. Ak je tam "icd_any", tak treba priradenie spravit dvakrat,
  # raz pre "icd" a raz pre "icd_vedlajsia"
  if ("icd_any" %in% tmp_join_col) {
    uzs_ms_list[[n]] <- rbind(
      tmp_data %>%
        inner_join(data.frame(ms_list[[n]]) %>%
                     select(-icd, -icd_vedlajsia),
                   by = c(t(tmp_join_col[which(tmp_join_col != "icd_any")]),
                          "icd_vedlajsia" = "icd_any")),
      tmp_data %>%
        inner_join(data.frame(ms_list[[n]]) %>%
                     select(-icd, -icd_vedlajsia),
                   by = c(t(tmp_join_col[which(tmp_join_col != "icd_any")]),
                          "icd" = "icd_any"))
    ) %>%
      unique()
  } else {
    uzs_ms_list[[n]] <- tmp_data %>%
      inner_join(data.frame(ms_list[[n]]), by = t(tmp_join_col)) %>%
      unique()
  }

  invisible(gc())
}

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
invisible(gc())
