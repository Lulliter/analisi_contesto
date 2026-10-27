# istat_cens_diplomi_profess

**Ente/fonte:** ISTAT — Censimento permanente della popolazione, categoria "Istruzione, lavoro e spostamenti per studio o lavoro" (struttura `DCSS_ISTR_LAV_PEN_2`); tre tavole: `DF_DCSS_ISTR_LAV_PEN_2_TV_1` "Popolazione residente di 9 anni e più per grado di istruzione ed età - comuni"; `DF_DCSS_ISTR_LAV_PEN_2_TV_2` "... per grado di istruzione e cittadinanza - comuni"; `DF_DCSS_LCAS_FRISC_3` "Popolazione residente di 14 anni e più per frequenza di un corso di formazione/aggiornamento professionale e sesso - province e grandi comuni"
**Di cosa si tratta**: residenti di 9 anni e più per titolo di studio più alto conseguito, per comune, sesso e classe d'età o cittadinanza, ogni anno dal 2018; in più, per provincia, chi frequenta un corso di formazione o aggiornamento professionale. Valori assoluti (le % si calcolano). Serve per una tabella dei titoli di studio per comune (modello: Atlante statistico della Città metropolitana di Bologna)
**URL / API:** databrowser https://esploradati.istat.it/databrowser/#/it/censpop/categories/IT1,Z1200CPA,1.0/CPA_POP/DCSS_ISTR_LAV_PEN_2_TV — API SDMX `https://esploradati.istat.it/SDMXWS/rest/data/IT1,DF_DCSS_ISTR_LAV_PEN_2_TV_1,1.0/...`
**Come riscaricare:** eseguire `ingestione/11_get_istat_cens_istr.R` (aggiornare `ANNO_FINE`, cancellare gli rds)
**Data ultimo download:** 2026-10-27 (script `11_get`; json a mano dal databrowser, di controllo)
**Data di ultima pubblicazione:** da verificare (anno censuario 2024)
**Periodo coperto:** 2018-2024 (formazione professionale: solo 2024)
**Unità territoriale:** comuni della provincia di Parma (44 attuali + Mezzani e Sorbolo, soppressi nel 2019); Italia, Emilia-Romagna, 9 province ER (la tavola sulla formazione professionale solo questi ultimi)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Popolazione residente di 9 anni e più per grado di istruzione ed età - comuni (IT1,DF_DCSS_ISTR_LAV_PEN_2_TV_1,1.0).json` — download a mano dal databrowser (2026-10-27), SDMX-JSON con dati e struttura; tenuto come riscontro, la fonte per il codice è lo script
- `Popolazione residente di 9 anni e più per grado di istruzione e cittadinanza - comuni (IT1,DF_DCSS_ISTR_LAV_PEN_2_TV_2,1.0).json` — idem, di controllo
- `Popolazione residente di 14 anni e più per frequenza di un corso di formazione_aggiornamento professionale e sesso - province e grandi comuni (IT1,DF_DCSS_LCAS_FRISC_3,1.0).json` — idem, di controllo
- `sdmx_struttura_istr_eta.json`, `sdmx_struttura_istr_citt.json`, `sdmx_struttura_formaz.json` — "Query struttura" di ciascuna tavola: dimensioni e codelist (da `11_get`)
- `sdmx_istr_eta.rds`, `sdmx_istr_citt.rds`, `sdmx_formaz.rds` — grezzo API, solo codici (da `11_get`)

**Note (come leggere i dati):**

- età solo in 5 classi: 9-24, 25-49, 50-64, 65 e più, 9 e più. Non c'è 25-34: per i giovani adulti la classe più vicina è 25-49
- 6 gradi di istruzione che sommano al totale (il totale non c'è nella tavola): nessun titolo (NED, compresi gli analfabeti), licenza elementare (PSE), licenza media (LSE), diploma di II grado o qualifica professionale compresi IFP e IFTS (USE_IF), ITS o terziario di primo livello (BL), terziario di secondo livello e dottorato (ML_RDD). ML e RDD separati solo per 9 anni e più
- "laurea" alla Bologna = BL + ML_RDD (ma BL comprende anche gli ITS)
- tavola per cittadinanza: solo 9 anni e più (niente classi d'età), niente dettaglio ML/RDD; ITL italiani, FRGAPO stranieri e apolidi
- tavola formazione professionale: 14 anni e più, sì/no/totale per sesso; struttura diversa (`DCSS_LCAS_FRISC`), comuni solo grandi

**Insidie (rotture di serie ed errori):**

- sono stime arrotondate (nota ISTAT): la somma delle modalità può non coincidere con totali pubblicati altrove; nei comuni piccoli e nelle categorie rare i valori sono fragili
- zeri: nel 2018-19 ISTAT pubblica gli zeri con `OBS_STATUS` = `JTEST` ("valore errato usato per test caricamento": 261 celle in `istr_eta`); dal 2020 omette le celle a zero (523 celle assenti 2020-24). Sono categorie rare nei comuni piccoli (Valmozzola, Bore, Monchio, Tornolo…), non legate alla fusione dei comuni. In `11b_clean` entrambi diventano 0, segnalati in `nota_valore`: ipotesi ragionata, non confermata da ISTAT
- Mezzani e Sorbolo hanno dati solo per il 2018; dal 2019 Sorbolo Mezzani (034051). In `11b_clean` il 2018 di Sorbolo Mezzani è la somma dei due, che poi si tolgono
- confronto con il censimento 2011: da verificare sulle note metodologiche ISTAT (metodo diverso: registri + campione)

**Storico aggiornamenti:**

- 2026-10-27 prima acquisizione (anno censuario 2024)
