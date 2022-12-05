<h1>Medical services grouping / Zaraďovanie hospitalizačných prípadov do medicínskych služieb</h1>
<b>[ENG]</b> Algorithm to assign hospital stays to specific medical services within the <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2021/540>hospital network optimization reform</a>. <br>
<b>[SK]</b> Algoritmus na zaradovanie hospitalizačných prípadov k medicínskym službám. Jedná sa o technickú implementáciu <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2022/316/20220930#prilohy>Príloh 2 - 12 vyhlášky 316/2022 Z. z.</a> v rámci zákona <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2021/540> 540/2021 Z. z.</a> o kategorizácii ústavnej zdravotnej starostlivosti a o zmene a doplnení niektorých zákonov.<br>

<h2>Change log</h2>
<b>[ENG]</b> Please provide any identified issues via GitHub issue tracking or submit your proposed changes with sufficient comments.<br>
<b>[SK]</b> V prípade, že identifikujete chyby v rámci kódu, prosím zaznamenajte ich na GitHub cez Issues, navrhnite priamo cez submit zmenu, alebo nám napíšte email na iza@health.gov.sk<br>
<br>
Change log:
<ul>
<li><b>5.12.2022</b>: First technical implementation of grouping published (Prvá verzia technickej implementácie vyhlášok publikovaná)</li>
</ul>

<h2>Technical readme</h2>
Folder structure for correct function of the algorithm:<br>
OSN-MedicalServiceGrouping
<ul>
<li>Data_ZP</li>
	<ul>
<li>2021</li>
		<ul>
<li>24</li>
<li>25</li>
<li>27</li>
			</ul></ul>
<li>Kroky_zaloha</li>
<li>Prevodovniky</li>
<li>Skripty</li>
<li>Vystupy</li>
</ul>
  
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
