# Indicatori demografici provinciali, serie storiche 2002-2024

**Fonte:** ISTAT — Indicatori demografici ("Demografia in cifre", demo.istat.it), livello provinciale; download 2026-07-18 (`dati/grezzi/istat_trend_demog/Indicatori_demografici.xls`)
**Anno dati:** 2002-2025 (ultimo anno provvisorio/stimato; indici di struttura fino al 1° gen 2026*)
**Ultimo aggiornamento:** 2026-07-18 — ATTENZIONE: i plot in `output/` sono ancora quelli del vecchio repo (serie 2002-2024, recuperati via git); rilanciare `01_dati.R` + `02_output.R` per rigenerarli col file nuovo
**Output principali:** `output/p01_e_m.rds` … `output/p18_tasso_di_fecondità_totale.rds` (18 ggplot interattivi ggiraph: età media, classi di età, natalità/mortalità, indici strutturali, nuzialità/fecondità, speranza di vita, saldi migratori)

Le serie 2002-2024 confrontano la provincia di Parma con le altre province
dell'Emilia-Romagna, la media regionale e quella nazionale. Messaggio chiave:
Parma invecchia più lentamente di regione e Italia (età media +1 anno vs +2.2 ER
e +4.9 IT nel periodo), con crescita naturale negativa compensata dal saldo
migratorio, in particolare con l'estero. Avvertenza: i valori dell'ultimo anno
possono essere stime provvisorie ISTAT.
