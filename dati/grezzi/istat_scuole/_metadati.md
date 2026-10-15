# istat_scuole

**Ente/fonte:** ISTAT — IstatData, sezione "Scuole" (tavola DCIS_SCUOLE1_4)
**Di cosa si tratta**: scuole, iscritti e caratteristiche degli alunni per ordine di scuola; qui la scuola dell'infanzia (iscritti, femmine, stranieri, alunni con disabilità, per gestione), per provincia. Indicata dalla Regione ER in risposta alla richiesta n. 3 (anagrafe regionale degli studenti). Serve a `scuola_iscritti` (infanzia) e forse a `scuola_disabilita` (validazione)
**URL / API:** databrowser https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0820EDU,1.0/DCIS_SCUOLE/ ; API SDMX tavola `52_1045_DF_DCIS_SCUOLE1_4`
**Come riscaricare:** `ingestione/10_prep_istat_scuole.R` (cancellare `sdmx_scuole_infanzia.rds` e rilanciare)
**Data ultimo download:** 2026-10-15
**Data di ultima pubblicazione:** <da compilare>
**Periodo coperto:** a.s. 2014/15-2024/25 (TIME_PERIOD = anno T dell'a.s. T-1/T: 2015-2025)
**Unità territoriale:** Italia, Emilia-Romagna, province dell'Emilia-Romagna (niente comuni)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `sdmx_struttura_scuole1_2.json`, `sdmx_infanzia_conteggi.rds` — 2a tavola "Infanzia - scuole, classi, bambini" (`52_1045_DF_DCIS_SCUOLE1_2`): CONTEGGI di scuole (SCHO), classi (CLAS), iscritti (ENR), per sesso e cittadinanza (solo iscritti) e gestione: `STA` statale, `PUB_NSTA` non statale pubblica (comunali e altri enti pubblici), `PUB` pubblica (= le due), `PRI` privata, `ALL` totale. Pulito in `dati/puliti/istat_scuole/infanzia_conteggi.rds`

- `sdmx_struttura_scuole1_4.json` — struttura della tavola e codelist (codice → etichetta), grezzo API
- `sdmx_scuole_infanzia.rds` — dati grezzi dell'API, solo codici

**Note/insidie:**

- Sono **indicatori, non conteggi**: nella tavola non c'è il numero di iscritti. `DATA_TYPE`: `ENROL` = iscritti per classe (media), `DISAB` = iscritti disabili per 1.000 iscritti, `FOR` = iscritti stranieri per 100 iscritti, `FEM` = iscritte femmine per 100 iscritti, `PUB` = iscritti in scuole pubbliche per 100 iscritti (solo con gestione `ALL`)
- `TYPE_SCHOOL_MANAGEMENT` (codelist CL_NATGIUR1): `ALL` = totale, `PUB` = pubblica, `PRI` = privata; non distingue statale e comunale
- Altre dimensioni fisse: `SCHOOL_LEVEL` = `PRE` (infanzia), `SEX` = `T`, `CITIZENSHIP` = `TOTAL`, `SCHOOL_YEAR` e `TYPE_SCHOOL` = `ALL`
- 13 serie per territorio (4 indicatori × 3 gestioni + `PUB` sul totale) × 11 anni = 143 righe; 11 territori
- `OBS_VALUE` arriva come testo; la tavola non ha la colonna `OBS_STATUS`
- Gli stessi codici (`PUB`, `FOR`, `ALL`, `PRI`) compaiono in codelist diverse con significati diversi: le etichette vanno prese dalla codelist della dimensione giusta (vedi `dimensioni` nello script)

- Gestione ISTAT vs categorie del Ministero (verificato su Parma, infanzia 2024/25): `STA` statali (61 scuole; anagrafe MIM 64 plessi statali); `PUB_NSTA` non statali pubbliche = paritarie gestite da enti pubblici, in pratica le comunali (15); `PRI` private = paritarie private (64). `PUB_NSTA` + `PRI` = 79 ≈ 80 plessi paritari dell'anagrafe MIM. Quindi "pubblica" ISTAT (`PUB` = statali + comunali, indicatore `pubbliche_pct` 59% a Parma) NON è il complemento delle paritarie MIM (comunali + private, 57% degli iscritti a Parma): nel sito usare statale / paritaria come negli altri grafici, con le comunali come dettaglio delle paritarie

**Storico aggiornamenti:**

- 2026-10-15 prima acquisizione (anni 2015-2025)
- 2026-10-15 aggiunta la 2a tavola con i conteggi (DCIS_SCUOLE1_2), trovata da Luisa nel databrowser
