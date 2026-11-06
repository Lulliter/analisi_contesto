# istat_cens_famiglie

**Ente/fonte:** ISTAT — Censimento permanente della popolazione, categorie "Famiglie" e "Convivenze anagrafiche"; tre tavole: `DF_DCSS_FAMIGLIE_TV_1` "Famiglie per numero di componenti - comuni"; `DF_DCSS_FAM_POP_TV_1` "Numero di famiglie e popolazione residente in famiglia - comuni"; `DF_DCSS_CONVIVENZE_TV_2` "Popolazione residente in convivenza per tipo di convivenza e sesso - comuni"
**Di cosa si tratta**: per comune, famiglie al 31 dicembre per numero di componenti (1, 2, 3, 4, 5, 6 e più, totale); residenti, residenti in famiglia e in convivenza (da cui i componenti medi per famiglia); residenti in convivenza per tipo (es. case di riposo) e sesso. Serve per le famiglie di una sola persona e le famiglie numerose per comune, e per le convivenze nel tema Anziani; NON c'è l'età dei componenti, quindi non dà gli anziani soli
**URL / API:** databrowser https://esploradati.istat.it/databrowser/#/it/censpop (Categorie › Famiglie; Categorie › Convivenze anagrafiche) — API SDMX: vedi "Come riscaricare"
**Come riscaricare:** a mano dal databrowser (comuni della provincia di Parma + Italia, Emilia-Romagna, province ER; anno), esportando in "SDMX-CSV" con i soli codici; oppure le query API usate il 2026-11-06 (aggiornare l'anno):

- `DF_DCSS_FAM_POP_TV_1`: `https://esploradati.istat.it/SDMXWS/rest/data/IT1,DF_DCSS_FAM_POP_TV_1,1.0/A.<codici comuni separati da +>+IT+ITD5+ITD51+ITD52+ITD53+ITD54+ITD55+ITD56+ITD57+ITD58+ITD59.INST_RESPOP_AV+NPHH_AV+POPHH_AV+RESPOP_AV/ALL/?detail=full&startPeriod=2024-01-01&endPeriod=2024-12-31&dimensionAtObservation=TIME_PERIOD` (struttura: `https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/DF_DCSS_FAM_POP_TV_1/1.0/?detail=Full&references=Descendants`)
- `DF_DCSS_CONVIVENZE_TV_2`: `https://esploradati.istat.it/SDMXWS/rest/data/IT1,DF_DCSS_CONVIVENZE_TV_2,1.0/A.<codici comuni separati da +>+IT+ITD5+ITD51+ITD52+ITD53+ITD54+ITD55+ITD56+ITD57+ITD58+ITD59.INST_RESPOP_AV.F+M+T...ALL+ALL_OTHER_INST_HOU+RELIG_INST+WELFARE_INST+WINST_ADULT+WINST_IMMIGR./ALL/?detail=full&startPeriod=2024-01-01&endPeriod=2024-12-31&dimensionAtObservation=TIME_PERIOD` (struttura: `https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/DF_DCSS_CONVIVENZE_TV_2/1.0/?detail=Full&references=Descendants`)

**Data ultimo download:** 2026-11-06 (a mano, Luisa)
**Data di ultima pubblicazione:** da verificare (anno censuario 2024)
**Periodo coperto:** 2024 (scaricato solo l'ultimo anno)
**Unità territoriale:** 44 comuni della provincia di Parma; Italia, Emilia-Romagna, 9 province ER
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Famiglie per numero di componenti - comuni (IT1,DF_DCSS_FAMIGLIE_TV_1,1.0)(1).csv` — SDMX-CSV, solo codici, 383 righe: è il file da usare nel codice
- `Famiglie per numero di componenti - comuni (IT1,DF_DCSS_FAMIGLIE_TV_1,1.0).csv` — CSV con codici ed etichette: le note ISTAT sono tra apici singoli e contengono virgole, quindi un lettore csv standard sfasa le colonne (es. righe di Bologna). Non usare
- `... .json` (SDMX-JSON), `... .xml` (SDMX-ML con le strutture, 9,8 MB), `...(1).xml` (SDMX-ML solo dati) — stessi dati, tenuti come riscontro
- `Numero di famiglie e popolazione residente in famiglia - comuni (IT1,DF_DCSS_FAM_POP_TV_1,1.0).csv` — SDMX-CSV, solo codici, 216 righe (55 territori × 4 indicatori, meno 4 celle assenti)
- `Popolazione residente in convivenza per tipo di convivenza e sesso - comuni (IT1,DF_DCSS_CONVIVENZE_TV_2,1.0).csv` — SDMX-CSV, solo codici, 673 righe; solo i comuni che hanno convivenze e solo i tipi scelti nella query

**Note (come leggere i dati):**

- `DF_DCSS_FAMIGLIE_TV_1`: indicatore unico `NPHH_AV` = famiglie al 31 dicembre; `NUM_MEMB`: `N1`…`N5`, `N6_GE` (6 e più), `TOT`
- `DF_DCSS_FAM_POP_TV_1`: `RESPOP_AV` residenti, `POPHH_AV` residenti in famiglia, `INST_RESPOP_AV` residenti in convivenza, `NPHH_AV` famiglie (identiche alla tavola per numero di componenti); residenti = in famiglia + in convivenza; componenti medi = `POPHH_AV` / `NPHH_AV`
- `DF_DCSS_CONVIVENZE_TV_2`: `TYPE_INST_HOUSEHOLD` scaricati: `ALL` tutte le convivenze; `WELFARE_INST` istituti assistenziali, di cui `WINST_ADULT` ospizi e case di riposo per adulti inabili e anziani e `WINST_IMMIGR` strutture di accoglienza per immigrati (non scaricati: presidi residenziali per minori, altri istituti assistenziali); `RELIG_INST` istituti religiosi; `ALL_OTHER_INST_HOU` altre convivenze. Non scaricati neanche istituti di istruzione, di cura, penitenziari. `GENDER` F, M, T; età e cittadinanza solo totali (per comune la tavola non ha l'età: l'età c'è solo per province e grandi comuni, `..._TV_1`)
- famiglie = famiglie censite, escluse le convivenze anagrafiche
- famiglie di 1 componente = persone che vivono sole, di qualsiasi età
- riscontri: Comune di Parma, famiglie di 1 componente 44% nel censimento 2024, 45% dall'anagrafe comunale 2026 (`comune_pr_open`); residenti in convivenza 3.086 nel censimento, circa 3.100 in anagrafe
- ordini di grandezza 2024: provincia 4.436 residenti in convivenza, di cui 1.184 in case di riposo per anziani e adulti inabili (Parma città 460)

**Insidie (rotture di serie ed errori):**

- stime arrotondate (nota ISTAT); controllato il 2026-11-06: per tutti i 55 territori la somma delle modalità coincide con `TOT`, e residenti = in famiglia + in convivenza
- `N6_GE` assente per Albareto (034001) e Monchio delle Corti (034022): con ogni probabilità cella a zero omessa, come in `istat_cens_diplomi_profess` (ipotesi, non confermata da ISTAT)
- `INST_RESPOP_AV` assente per 4 comuni (034019, 034026, 034038, 034040): lì residenti in famiglia = residenti, quindi zero omesso
- residenti in case di riposo: il dato conta chi vi ha la RESIDENZA; l'ipotesi (da verificare con i posti autorizzati delle strutture) è che molti ospiti mantengano la residenza nella casa di famiglia, quindi sarebbe un conteggio per difetto degli ospiti
- note ISTAT solo come codici (`STRUTTURE__ALL_OTHER_INST_HOU_N1`, `034051_N1` Sorbolo Mezzani): il testo è nella struttura del dataflow
- codici comune a 6 cifre come testo (`034001`): leggerli come carattere per non perdere lo zero iniziale

**Storico aggiornamenti:**

- 2026-11-06 prima acquisizione (anno censuario 2024): famiglie per numero di componenti; poi famiglie e popolazione in famiglia; residenti in convivenza per tipo
