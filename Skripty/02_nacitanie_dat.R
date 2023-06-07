##### --------------------------------------------------------------------------
# Skript na nacitanie dat od poistovni.
##### --------------------------------------------------------------------------

# Vytvor list do ktoreho sa budu nacitavat data
main_df <- list()

# Nacitaj data
for (c in ins$comp) {
  print(paste("Nacitavam data pre poistovnu", c))

  # Definuj cestu k data od poistovne
  tmp_path <- paste0(paths$data, c, "/")

  # Ziskaj zoznam suborov v priecinku
  tmp_files <- list.files(tmp_path)
  tmp_files <- tmp_files[grepl(paste(ins$data, collapse = "|"), tmp_files)]

  # Iteruj cez subory
  for (f in tmp_files) {
    print(paste("File", f))

    # Nacitaj data
    tmp_df <- fread(file = paste0(tmp_path, f), colClasses = "character")

    # Poistovne si obcas prilepili na zaciatok stlpec s ich cislom, tak to treba
    # zohladnit, inak nebudu rovnake stlpce pod sebou.
    tmp_df <- tmp_df %>%
      mutate(ins_name = c)
    tmp_drop <- vector()
    for (i in 1:(ncol(tmp_df) - 1)) {
      tmp_vec <- unique(tmp_df %>% select(as.numeric(i)))
      if (length(tmp_vec) == 1 & tmp_vec[1] %in% ins$comp) {
        tmp_drop <- c(tmp_drop, -i)
      }
    }

    # Vloz nacitane data do hlavneho zoznamu
    tmp_df <- as.data.frame(tmp_df)
    main_df[[f]] <- tmp_df[, tmp_drop]
    main_df[[f]] <- main_df[[f]] %>% unique()
  }
}

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(c, f, i)
invisible(gc())
