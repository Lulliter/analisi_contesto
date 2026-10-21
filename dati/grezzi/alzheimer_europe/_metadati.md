# alzheimer_europe

**Ente/fonte:** Alzheimer Europe — "The Prevalence of Dementia in Europe 2025" (Dementia Prevalence Report 2025, progetto cofinanziato UE)
**Di cosa si tratta**: stime del numero di persone con demenza per paese europeo, per sesso e classe d'età, 2025-2050 (ogni 5 anni), ottenute applicando tassi di prevalenza aggiornati alle previsioni di popolazione Eurostat. Per l'Italia e per l'UE27 i dati sono scaricabili in csv: da `Dementia / Population` si ricavano i tassi per sesso × età, costanti negli anni. Qui serve come fonte alternativa (più recente) alle prevalenze ISS per stimare le demenze a Parma (modulo `anziani_non_autosuff`)
**URL / API:** https://www.alzheimer-europe.org/resources/publications/prevalence-dementia-europe-2025?language_content_entity=en (sezione  Home -> Resources -> Reports And Publications -> Dementia Research Participation And Data Sharing In Europe) — <precisare la pagina del download dei csv>
**Come riscaricare:** scarico manuale di pdf e csv dal sito
**Data ultimo download:** 2026-10-19
**Data di ultima pubblicazione:** 2026-10 (rapporto "Prevalence of Dementia in Europe 2025": pubblicato nel 2026, dati riferiti al 2025)
**Periodo coperto:** 2025, 2030, 2035, 2040, 2045, 2050 (popolazione prevista Eurostat; tassi costanti)
**Unità territoriale:** Italia; UE27
**Licenza:** <verificare sul report>

**File:**

- `alzheimer_europe_dementia_prevalence_report_2025.pdf` — report (64 pp.), metodo e tavole per paese
- `alzheimer_europe_dementia_data_Italy.csv` — `Country, Year, Age, Population_F, Population_M, Dementia_F, Dementia_M, Total`; 8 classi d'età (30-59, 60-64, 65-69, …, 85-89, 90+) × 6 anni; popolazione e casi con decimali (medie di previsioni)
- `alzheimer_europe_dementia_data_EU27.csv` — idem per l'UE27

**Note (come leggere i dati):**

- Tassi di prevalenza 2025, Italia, 65+ (donne / uomini): 65-69 1,4 / 1,1; 70-74 3,7 / 3,8; 75-79 8,0 / 7,3; 80-84 13,2 / 11,1; 85-89 24,4 / 16,9; 90+ 44,7 / 30,8 (calcolati dal csv, uguali in tutti gli anni)
- Italia, casi 65+: 1,38 milioni nel 2025, 1,64 nel 2035, 2,18 nel 2050 (dal csv): la crescita è tutta demografica
- Rispetto all'ISS (Bacigalupo 2018, `dati/grezzi/iss_demenze/`): tassi più alti nelle donne molto anziane e più bassi negli uomini 85-89; il totale Italia è circa il 20% sopra l'ISS, in parte per i tassi e in parte per l'anno base. Scegliere UNA fonte per le stime del sito e citare l'altra come confronto

**Insidie:**

- I valori di popolazione e casi sono decimali (medie): arrotondare solo nell'output
- Le classi 30-59 e 60-64 (demenza giovanile) vanno escluse dalle stime sui 65+

**Storico aggiornamenti:**

- 2026-10-19 prima acquisizione (Luisa scarica; file spostati da `iss_demenze/` perché la fonte è diversa)
