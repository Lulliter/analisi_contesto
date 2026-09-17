# eurostat_isoc_ai

**Ente/fonte:** Eurostat — dataset `isoc_ai_iaiu` "Individuals - use of generative AI tools" (indagine europea sull'uso delle ICT nelle famiglie e da parte delle persone)
**Di cosa si tratta**: quota di persone che hanno usato strumenti di IA generativa negli ultimi 3 mesi e per quale scopo (privato, lavoro, istruzione formale), per paese e per caratteristiche della persona (età, sesso, istruzione, condizione professionale, ecc.). È un'indagine armonizzata: per l'Italia i dati vengono dall'indagine ISTAT Aspetti della vita quotidiana (la stessa di `istat_cittadini_ict`), quindi i valori italiani coincidono con quelli del comunicato ISTAT (es. 16-74 anni = 19,9%). Serve al modulo `giovani_ict_social` (adozione dell'IA per età, Italia a confronto con l'UE; scopi d'uso dei giovani)
**URL / API:** https://ec.europa.eu/eurostat/databrowser/product/page/ISOC_AI_IAIU ; commento di Eurostat: https://ec.europa.eu/eurostat/statistics-explained/index.php?title=Use_of_artificial_intelligence_by_individuals ; in R: pacchetto `eurostat`, `get_eurostat("isoc_ai_iaiu")`
**Come riscaricare:** `ingestione/07_get_eurostat_ai.R` (solo download, con cache): cancellare i due rds e rilanciare. Scarica la tavola intera (non si filtra alla fonte) e i dizionari dei codici
**Data ultimo download:** 2026-09-17
**Data di ultima pubblicazione:** 2026-06-05 (primi risultati diffusi da Eurostat il 2025-12-16) 
**Periodo coperto:** 2025 (prima rilevazione: un solo anno, nessun trend)
**Unità territoriale:** paesi UE + aggregati (`EU27_2020` = UE a 27) e alcuni paesi extra-UE; Italia = `IT`. NESSUN dato regionale
**Licenza:** riuso libero con citazione della fonte (Eurostat) — `Unless otherwise indicated (e.g. in individual copyright notices), content owned by the EU on this website is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0) licence`

**File:**

- `isoc_ai_iaiu.rds` (da `07`) — tavola come arriva, 39.006 righe, solo codici: `indic_is` (indicatore), `ind_type` (caratteristica della persona), `unit` (base della percentuale), `geo`, `TIME_PERIOD`, `values`
- `isoc_ai_iaiu_etichette.rds` (da `07`) — codice → dicitura Eurostat (in inglese: i dizionari non esistono in italiano) per `indic_is`, `ind_type`, `unit`, `geo`

**Note/insidie:** ATTENZIONE alla base della percentuale (`unit`): `PC_IND` = sul totale delle persone (quella giusta per l'ADOZIONE); `PC_IND_IU3` = su chi ha usato internet negli ultimi 3 mesi; `PC_IND_IUAI` = su chi ha usato l'IA (quella giusta per gli SCOPI: "tra chi la usa, per cosa"). Indicatori: `I_IUAI` uso negli ultimi 3 mesi; `I_IUAIPR` per scopi privati; `I_IUAIWP` per lavoro; `I_IUAIFE` per istruzione formale (gli scopi non si escludono: non sommano a 100). Popolazione di riferimento 16-74 anni (`IND_TOTAL`): diversa dal 14 anni e più del comunicato ISTAT (17,8%). Classi d'età utili: `Y16_19`, `Y20_24`, `Y16_24`, `Y25_34`, … `Y65_74`; per sesso con prefisso `F_` / `M_`. Le classi si SOVRAPPONGONO (16-19, 16-24, 16-29…): scegliere un insieme coerente prima di fare grafici. Stima campionaria: per le classi giovani leggere gli ordini di grandezza. Valori di prova (2026-09-17): Italia 16-19 = 51,9; Italia totale = 19,9; UE totale = 32,7

**Storico aggiornamenti:**

- 2026-09-17 prima acquisizione (dati 2025)
