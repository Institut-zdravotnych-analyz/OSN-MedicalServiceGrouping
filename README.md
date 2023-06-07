<h1>Zaraďovanie hospitalizačných prípadov do medicínskych služieb</h1>
<b>[ENG]</b> Algorithm to assign hospital stays to specific medical services within the <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2021/540>hospital network optimization reform</a>. <br>
<b>[SK]</b> Algoritmus na zaradovanie hospitalizačných prípadov k medicínskym službám. Jedná sa o technickú implementáciu <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2022/316/20220930#prilohy>Príloh 2 - 12 vyhlášky 316/2022 Z. z.</a> v rámci zákona <a href=https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2021/540> 540/2021 Z. z.</a> o kategorizácii ústavnej zdravotnej starostlivosti a o zmene a doplnení niektorých zákonov.<br>

<h2>Change log</h2>
V prípade, že identifikujete chyby v rámci kódu, prosím zaznamenajte ich na GitHub cez Issues, navrhnite priamo cez submit zmenu, alebo nám napíšte email na iza@health.gov.sk<br>
<br>
Change log:
<ul>
<li><b>5.12.2022</b>: Prvá verzia technickej implementácie vyhlášok publikovaná</li>
</ul>

<h2>Technické readme</h2>
Potrebná priečinková štruktúra pre správne fungovanie kódu:<br>
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
  
<h3><a href=https://github.com/Institut-Zdravotnych-Analyz/OSN-MedicalServiceGrouping/tree/main/Data_ZP>Data_ZP</a></h3>
<ul>
<li>Obsahuje hospitalizačné DRG dáta od zdravotných posiťovní po rokoch</li>
<li>Každý rok musí byť pomenovaný ako RRRR a obsahovať priečinky pre všetky 3 ZP</li>
<li>Priečinky ZP musia byť pomenované kódom ZP</li>
</ul>

<h3><a href=https://github.com/Institut-Zdravotnych-Analyz/OSN-MedicalServiceGrouping/tree/main/Kroky_zaloha>Kroky_zaloha</a></h3>
<ul>
<li>Obsahuje parciálne výsledky jednotlivých krokov alogoritmu, ak to uživateľ povolil</li>
</ul>
  
<h3><a href=https://github.com/Institut-Zdravotnych-Analyz/OSN-MedicalServiceGrouping/tree/main/Prevodovniky>Prevodovniky</a></h3>
<ul>
<li>Obsahuje zoznamy / číselníky definujúce medicínske služby na základe DRG kódov, kódov diagnóz, kódy výkonu.</li>
<ul>
<li>Excel <code>definicie_med_sluzieb.xlsx</code> obsahuje definície medicínskych služieb podľa príloh 2 - 11 vyhlášky 316/2022 Z. z. pričom v rámci Excel je možné filtrovať vyhlášky podľa stĺpcu súbor, kde 10 = Príloha 2 až po 19 = Príloha 11</li>
</ul>
<li>Obsahuje číselníky na prevod kódov oddelení na nemocničné kódy.</li>
</ul>
  
<h3><a href=https://github.com/Institut-Zdravotnych-Analyz/OSN-MedicalServiceGrouping/tree/main/Skripty>Skripty</a></h3>
<ul>
<li>Obsahuje skripty na beh algoritmu v prostredí <code>R</code></li>
</ul>
  
<h3>Skripty/00_hlavny_skript.R</h3>
<ul>
<li>Hlavný skript, ktorý volá ďalšie skripty</li>
<li>V prípade veľkých dát, alebo malej RAM, odporúčame otvoriť tento skript a spúšťať ho manuálne po častiach. Taktiež odporúčame povoliť ukladanie parciálnych výsledkov po 5tom kroku, po ktorom odporúčame reštartovať <code>R</code> na prečistenie RAM. Po reštarte spustite segmenty od riadkov 50-56 po koniec.</li>
</ul> 
  
<h3>Skripty/01_konfiguracia.R</h3>
<ul>
<li>Skript definujúci cesty k priečinkom a súborom a iné parametre pre algoritmus</li>
<li>V riadku 7 užívateľ definuje rok pre ktorý sa určujú medicínske služby</li>
<li>V riadku 9 užívateľ definuje ukladanie parciálnych výsledkov po každom kroku</li>
<li>V riadku 10 užívateľ definuje ukladanie parciálnych výsledkov po 5. kroku (odporúčame pre veľké dáta, malú RAM)</li>
<li>Ostatné parametre sa môžu upravovať podľa potrieb (jeden toto robí, ak ten vie čo robí)</li>
</ul>  
  
<h3>Skripty/02-07</h3>
<ul>
<li>Skripty vykonávajúce algoritmus</li>
<li>Obsahuje poznámky na zoznámenie s krokmi algoritmu</li>
<li>Úprava na vlastné nebezpečie</li>
</ul> 

<h3><a href=https://github.com/Institut-Zdravotnych-Analyz/OSN-MedicalServiceGrouping/tree/main/Vystupy>Vystupy</a></h3>
<ul>
<li>Obsahuje výstupy z algoritmu obsahujúce počty hospitalizácií per nemocnica a medicínska služba</li>
</ul>  
