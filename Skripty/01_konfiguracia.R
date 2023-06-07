##### --------------------------------------------------------------------------
# Skript na konfiguraciu parametrov algoritmu na priradenie medicinskych sluzieb.
##### --------------------------------------------------------------------------

# Nastav volitene parametre
#   Rok za ktory sa priraduju medicinske sluzby
rok <- 2022
#   Ci robit zalohy pocas procesu
sprav_zalohy_vsetky <- TRUE
sprav_zalohu_po_5 <- TRUE
#   Ci exportovat zaznamy s chybajucimi/chybnymi udajmi
sprav_export_chyb <- TRUE
#   Ci sa maju hospitalizacie, ktore boli v ramci DRG zlucene do inej vymazat
sprav_vylucenie_zlucenych <- TRUE

# Nacitaj potrebne kniznice.
# UPOZORNENIE: Tieto kniznice je potrebne mat nainstalovane pred tym, ako bude
#               spusteny skript "00_hlavny_skript.R"
library(dplyr)
library(data.table)
library(tidyr)
library(readxl)
library(stringr)
library(lubridate)

# Definicia ciest k vstupnym udajom
#   Nazvy priecinkov
folders <- list()
folders$hlavny <- "OSN_MedicalServiceGrouping"
folders$data <- "Data_ZP"
folders$prevody <- "Prevodovniky"
folders$vystupy <- "Vystupy"
folders$zalohy <- "Kroky_zaloha"
#   Pospajaj priecinky do ciest
paths <- list()
paths$base <- gsub(paste0("(", folders$hlavny, ").*"), "\\1", getwd())
paths$data <- paste0(paths$base, "/", folders$data, "/", rok, "/")
paths$prevody <- paste0(paths$base, "/", folders$prevody, "/")
paths$vystupy <- paste0(paths$base, "/", folders$vystupy, "/")
paths$zalohy <- paste0(paths$base, "/", folders$zalohy, "/")

# Definicia nazvov podpriecinkov a suborov
#   Priecinky pre poistovne
ins <- list()
ins$comp <- c("24", "25", "27")
#   Subory s datami
ins$data <- c("01_UZS_JZS.csv", "02_HP.csv", "03_PREKLAD.csv",
              "04_VDG.csv", "05_VYKON.csv", "09_POISTENCI.csv")
#   Prevodove subory
files <- list()
files$ms <- "definicie_med_sluzieb.xlsx"
files$taz <- "tazke_problemy.csv"
files$sig <- "signif_vykony.csv"
files$hosp <- "pzs_na_nemocnicu.xlsx"
files$uroven <- "uroven_sluzby.csv"
files$jzs_drg <- "JZS_na_DRG_2022.xlsx"
