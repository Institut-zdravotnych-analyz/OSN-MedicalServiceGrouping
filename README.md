# OSN-MedicalServiceGrouping
Algorithm to assign hospital stays to specific medical services within the hospital network optimization reform.

Folder structure for correct function of the algorithm:
OSN-MedicalServiceGrouping<br>
	├── Data_ZP<br>
			└──── 2021<br>
					├────── 24<br>
					├────── 25<br>
					└────── 27<br>
	├── Kroky_zaloha<br>
	├── Prevodovniky<br>
	├── Skripty<br>
	└── Vystupy<br>
  
Data_ZP
  - Folder containing data about hospitalisations divided by years.
  - Folder for each year must be named after the year and must contain folders for each insurance company.
  - Folders for individual insurance companies must be named after the codes of insurance companies.

Kroky_zaloha
  - Folder where partial results from individual steps of the algorithm are saved, if the user allowed this option.
  
Prevodovniky
  - Folder containing lists defining medical services based on DRG codes, codes of diagnoses, and codes of operations.
  - Also contains list for converting codes of departments to hospital codes.
  
Skripty
  - Folder containing scripts to run algorithm.
  
Vystupy
  - Folder where output from algorithm containing number of hospitalisations per hospital per medical service.
  

Skripty/00_hlavny_skript.R
  - Main script of the algorithm that calls other scripts.
  - If case of small data, algorithm can be run by running this script.
  - If case of large data or small RAM, it is recommended to open this script and manually run segments. Also recommended is to allow algorithm to save partial result after 5th step and once that is run, restart R to clear RAM. After restart manually run segments from segment on rows 50-56 to the end.
  
Skripty/01_konfiguracia.R
  - Script that sets up paths to folders and files and other parameters necessary for the algorithm.
  - In row 7 user specifies year for which to assign medical services.
  - In row 9 user specifies whether to save partial results after each step.
  - In row 10 user specifies whether to save partial results after step 5. (Recommended for large data or small RAM)
  - Other parameters can be changed to reflect conditions on local computer. Do that only if one knows what he is doing.
  
Skripty/02-07
  - Scripts performing steps of the algortihm.
  - Contain comments to take reviewer through algorithm.
  - Modify at your own peril.
