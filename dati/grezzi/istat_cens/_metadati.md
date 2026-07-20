# istat_cens

**Ente/fonte:** ISTAT — Censimento `permanente` della popolazione (dataset `DF_DCSS_POP_DEMCITMIG_TV_2`: popolazione per età, sesso, cittadinanza — comuni)
**URL / API:** SDMX: `https://esploradati.istat.it/SDMXWS/rest/data/IT1,DF_DCSS_POP_DEMCITMIG_TV_2,1.0/...` — browser: https://esploradati.istat.it/databrowser/#/it/censpop
**Come riscaricare:** eseguire `ingestione/01a_get_istat_cens.R` (aggiornare `ANNO_CENS`; ~15 min per i limiti di frequenza ISTAT; il file già scaricato non viene riscaricato)
**Data ultimo download:** 2026-07-17 (330 comuni ER, 36.160 righe, nessun blocco fallito)
**Periodo coperto:** anno censuario 2024 (edizione pubblicata a dicembre 2025)
**Unità territoriale:** comuni ER (330)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `istat_cens_pop_com_er_<anno>.rds` — risposta API grezza (dataframe rsdmx, comuni ER; classi decennali + minorenni)
- `istat_cens_pop_com_er_seta_<anno>.rds` — risposta API grezza, SINGOLE ETÀ (flow `SETA_1`, da `01c`; serve per tagli tipo 65+)
- `istat_cens_pop_confronti_<anno>.rds` / `..._confronti_seta_<anno>.rds` — territori di confronto: IT, Nord-Est (ITD), ER (ITD5), province ER (ITD51-59; ITD52 = Parma)

**Note/insidie:**

- "censimento" = censimento PERMANENTE (dal 2018 è annuale: campioni + registri);
  ogni anno è anno censuario, il 2024 è un'edizione regolare, non un'anomalia
- il flow contiene DUE indicatori: `RESPOP_AV` (popolazione per classi d'età
  decennali) e `RESPOP_MIN_AV` (popolazione minorenne 0-17, solo totale —
  NON ricavabile dalle classi decennali, quindi tenuto come oggetto separato)
- età in CLASSI DECENNALI; le SINGOLE ETÀ sono nel flow gemello
  `DF_DCSS_POP_DEMCITMIG_SETA_1` (stessa ricetta a blocchi, ~10x righe)

- la ricetta che FUNZIONA: blocchi da 10 comuni + jolly `"......"` sulle dimensioni
  non territoriali (`f_scarica_istat_blocchi()` in `R/f_istat_scarica_cens.R`).
  Il server tronca le chiavi SDMX oltre ~260 caratteri: MAI elencare le 102 età
- ⚠️ VICOLO CIECO documentato (2026-07-17): il dataflow "popolazione residente"
  `22_289_DF_DCIS_POPRES1_24` accetta le chiavi ma restituisce zero righe per i
  comuni (anche senza alcun filtro); l'export dell'interfaccia Esplora Dati non
  funziona e l'URL "Query del dato" che genera supera i limiti del server.
  Non riprovarci: usare questo censimento via API o demo.istat.it per le serie
- rate limit ISTAT severo (~5 query/min, blocchi IP temporanei): non ridurre le pause
- TODO: territori di confronto (Italia, Nord-Est, ER, prov. PR) e serie 2019-2026
  ancora da risolvere (candidati: stesso flow con codici aggregati, o demo.istat.it)

**Storico aggiornamenti:**

- 2026-07-17 prima acquisizione (anno censuario 2024; 36.160 righe)
