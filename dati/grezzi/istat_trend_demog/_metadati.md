# istat_trend_demog

**Ente/fonte:** Istat - demo - demografia in cifre 
**URL / API:** https://demo.istat.it/?l=it#sezione1
**Come riscaricare:** file vari `.xls`/`.csv.zip` scaricabili a mano dal sito
**Data ultimo download:** 2026-07-18
**Periodo coperto:** Indicatori demografici provinciali, serie storiche 2002-2025* + previsioni 2024-2050
**Unità territoriale:** comuni (solo >= 5.000 ab. per le previsioni) / province / regioni / ripartizioni
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Indicatori_demografici.xls` — serie storiche 2002-2025*; salti di riga e totali x regione 
- Previsioni 2024-2050 (base 1.1.2024, pubblicate lug 2025, SOLO scenario mediano), csv zippati:
  - `PREVISIONI_Componenti_del_bilancio_demografico-Comuni_Emilia-Romagna.csv.zip` — nati, morti, iscritti/cancellati, pop inizio/fine anno
  - `PREVISIONI_Principali_indicatori_strutturali-Comuni_Emilia-Romagna.csv.zip` — età media, % 0-14 / 15-64 / 65+
  - `PREVISIONI_Tassi_generici_del_movimento_demografico-Comuni_Emilia-Romagna.csv.zip` — natalità, mortalità, migratorio, crescita
  - `Previsioni_comunali_popolazione_per_eta-Comuni_Emilia-Romagna.csv.zip` — pop per sesso × classi quinquennali (00-04 … 95+ + "Tutte le età")
  - `Previsioni_comunali_popolazione_per_eta-Province.csv.zip` — idem, TUTTE le 107 province italiane

**Note/insidie:**

- Previsioni: SOLO scenario mediano (nessuna colonna scenario nei csv, malgrado il sito parli di scenari); incertezza crescente allontanandosi dal 2024
- File comunali previsioni: solo comuni >= 5.000 ab. al 1.1.2024 → 195 comuni ER, 22 su 44 in provincia di Parma
- File province: nessun aggregato (no ER, no Italia) → totali da calcolare sommando le province
- Formato csv previsioni: separatore ";", virgola decimale, 1a riga = titolo (skip), codici comune/provincia con zero iniziale (tenerli character)
- Nomi territorio nei csv previsioni ("Forlì-Cesena", "Reggio nell'Emilia") diversi dall'xls storico ("Forli'") → attenzione ai join per nome
- Ingestione: `ingestione/03_prep_istat_previsioni.R` → `dati/puliti/istat_previsioni/` (consumati da `moduli/demo_trend_previs`)

**Storico aggiornamenti:**

- 2025-11-12 prima acquisizione trend storici 2002-2024
- 2026-07-18 aggiornamento trend storici 2022-2025 + scenari futuri (previsioni 2024-2050)
- 2026-07-21 ingestione previsioni + note su formato e coperture
