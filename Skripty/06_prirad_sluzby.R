##### --------------------------------------------------------------------------
# Skript na priradenie medicinskych sluzieb k hospitalizaciam
##### --------------------------------------------------------------------------

# Inicializuj premennu do ktorej sa budu ukladat hospitalizacie s priradenou
# medicinskou sluzbou.
uzs_list <- list()

# Prirad sluzby postupne podla toho, co zohladnuju
tmp_names <- names(ms_list)
tmp_names <- tmp_names[tmp_names != "icd_vedlajsia"]
for (i in tmp_names) {
  name <- names(ms_list[i])
  print(name)
  if (name %like% ",") {
    join_col <- unlist(strsplit(name, split = ", "))
  } else{
    join_col <- name
  }
  if ("icd_any" %in% join_col) {
    uzs_list[[i]] <- rbind(uzs_final %>%
                             inner_join(data.frame(ms_list[[i]]) %>% select(-icd, -icd_vedlajsia),
                                        by = c(t(join_col[which(join_col != "icd_any")]),
                                               "icd_vedlajsia" = "icd_any")),
                           uzs_final %>%
                             inner_join(data.frame(ms_list[[i]]) %>% select(-icd, -icd_vedlajsia),
                                        by = c(t(join_col[which(join_col != "icd_any")]),
                                               "icd" = "icd_any"))) %>%
      unique()
  }else if (c("icd") != join_col) {
    uzs_list[[i]] <- uzs_final %>% inner_join(data.frame(ms_list[[i]]), by = t(join_col)) %>% unique()
  } else{
    temp <- data.table(uzs_final) %>% unique()
    uzs_list[[i]] <- temp %>% inner_join(data.frame(ms_list[[i]]), by = t(join_col)) %>% unique()
    remove(temp)
    gc()
  }
  gc()
}

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
invisible(gc())
