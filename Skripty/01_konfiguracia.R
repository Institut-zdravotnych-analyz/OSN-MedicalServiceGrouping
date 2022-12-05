##### --------------------------------------------------------------------------
# Skript na konfiguraciu parametrov algoritmu na priradenie medicinskych sluzieb.
##### --------------------------------------------------------------------------

# Nastav volitene parametre
#   Rok za ktory sa priraduju medicinske sluzby
rok <- 2019
#   Ci robit zalohy pocas procesu
sprav_zalohy <- TRUE

# Nacitaj potrebne kniznice.
# UPOZORNENIE: Tieto kniznice je potrebne mat nainstalovane pred tym, ako bude
#               spusteny skript "00_hlavny_skript.R"
library(dplyr)  #*
library(data.table)  #*
library(tidyr)  #*
library(zoo)
library(readxl)
library(janitor)
library(stringr)  #*
library(fuzzyjoin)
library(lubridate)  #*
library(rstudioapi)  #*

# Definicia ciest k vstupnym udajom
#   Nazvy priecinkov
folders <- list()
folders$hlavny <- "OSN-MedicalServiceGrouping"
folders$data <- "Data_ZP"
folders$prevody <- "Prevodovniky"
folders$vystupy <- "Vystupy"
folders$zalohy <- "Kroky_zaloha"
#   Pospajaj priecinky do ciest
paths <- list()
paths$base <- getSourceEditorContext()$path %>% str_split("/")
paths$base <- paste0(paths$base[[1]][1:which(paths$base[[1]] == folders$hlavny)],
                    collapse = "/")
paths$data <- paste0(paths$base, "/", folders$data, "/", rok, "/")
paths$prevody <- paste0(paths$base, "/", folders$prevody, "/")
paths$vystupy <- paste0(paths$base, "/", folders$vystupy, "/")
paths$zalohy <- paste0(paths$base, "/", folders$zalohy, "/")

# Definicia nazvov podprieinkov a suborov
#   Priecinky pre poistovne
ins <- list()
ins$comp <- c("24", "25", "27")
#   Subory s datami
ins$data <- c("UZS_JZS_UDAJE.csv", "HP_UDAJE.csv", "HP_PREKLADY.csv",
              "HP_VDG.csv", "HP_ZV.csv", "UZS_POISTENCI.csv", "UZS_UDAJE.csv",
              "[0-9]_JZS_UDAJE.csv")
#   Prevodove subory
files <- list()
files$ms <- "definicie_med_sluzieb.xlsx"
files$taz <- "FSchweres_Problem_Ngb.txt"
files$sig_all <- "GENOR.txt"
files$sig_rem <- "P-01.txt"
files$hosp <- "pzs_na_nemocnicu.xlsx"