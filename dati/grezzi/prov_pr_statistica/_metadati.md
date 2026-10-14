# prov_pr_statistica

**Ente/fonte:** Provincia di Parma — Servizio Statistico, open data sulla popolazione residente
**Di cosa si tratta**: serie storiche per comune (44 comuni attuali, fusioni ricostruite all'indietro) di popolazione residente totale e numero di famiglie, da anagrafi comunali. È la fonte che l'AUSL di Parma dichiara di usare come denominatore dei tassi nei report DAISMDP (vedi `dati/grezzi/ausl_npia/`). Online solo totali: niente età né sesso
**URL / API:** http://www.statistica.parma.it (dominio non leggibile da Claude: scarico a mano) — <precisare la pagina esatta dei due file>
**Come riscaricare:** scarico manuale dei csv dal sito; aggiornare il nome file con l'ultimo anno
**Data ultimo download:** 2026-10-14
**Data di ultima pubblicazione:** 2025 (edizione "2025-Open data")
**Periodo coperto:** popolazione 1990-2025; famiglie 2008-2025
**Unità territoriale:** comuni della provincia di Parma (44)
**Licenza:** <verificare sul sito (open data della Provincia)>

**File:**

- `pop_totale_comune_serie_1990_2025.csv` — `Codcomune;Comune;Anno;Residenti` (originale: "2025-Open data pop totale per comune serie.csv"); 1.584 righe = 44 comuni × 36 anni
- `famiglie_totale_comune_serie_2008_2025.csv` — `Codcomune;Comune;Anno;Famiglie` (originale: "2025-Open data n famiglie totale per comune serie.csv"); 792 righe

**Note (come leggere i dati):**

- `Codcomune` a 5 cifre senza lo zero iniziale (34001 = ISTAT 034001): aggiungerlo per i join con shapefile e SITUAS
- Data di riferimento dell'anno NON dichiarata nei file: i totali provinciali non coincidono con l'ISTAT al 31/12 (Provincia 2019 = 452.015; ISTAT 31/12/2018 = 452.505) e sembrano sfasati di circa un anno (1° gennaio?) e non riallineati al censimento permanente (il 2020 ISTAT cala, la Provincia no). Da verificare sulla pagina di scarico prima di confrontarli con l'ISTAT
- Comuni fusi (Polesine Zibello 34050 dal 2016, Sorbolo Mezzani 34051 dal 2019): la serie è già ricostruita sui confini attuali anche per gli anni precedenti

**Insidie (formato):**

- separatore `;`, CRLF, encoding ASCII
- file famiglie: separatore delle migliaia incoerente, "1.060" in alcune righe e "5518" in altre → leggere come testo, togliere il punto, poi convertire
- file popolazione: numeri puliti, senza separatore

**Storico aggiornamenti:**

- 2026-10-14 prima acquisizione (Luisa scarica a mano; i file erano in `ausl_npia/provincia_statistica/` e sono stati spostati qui perché la fonte è la Provincia, non l'AUSL)
