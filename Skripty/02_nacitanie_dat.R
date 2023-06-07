##### --------------------------------------------------------------------------
# Skript na nacitanie dat od poistovni.
##### --------------------------------------------------------------------------

# Vytvor list do ktoreho sa budu nacitavat data
main_df <- list()

# Nacitaj data
for (c in ins$comp) {
  print(paste("Nacitavam data od poistovne", c))

  # Definuj cestu k datam od poistovne
  tmp_path <- paste0(paths$data, c, "/")

  # Ziskaj zoznam suborov v priecinku
  tmp_files <- list.files(tmp_path)
  tmp_files <- tmp_files[grepl(paste(tolower(ins$data), collapse = "|"),
                               tolower(tmp_files))]

  # Iteruj cez subory
  for (f in tmp_files) {
    print(paste("File", f))

    # Nacitaj data
    tmp_df <- fread(file = paste0(tmp_path, f), colClasses = "character")

    # Vloz nacitane data do hlavneho zoznamu
    main_df[[f]] <- tmp_df %>% unique()
  }
}

# Vymaz docasne premenne a uvolni pamat
rm(list = ls(pattern = "^tmp"))
rm(c, f)
invisible(gc())