# istat_bes

**Ente/fonte:** ISTAT — La misurazione del benessere equo e sostenibile (BES) - dal 2013... 
**Di cosa si tratta**: approccio multidimensionale per misurare il "Benessere equo e sostenibile" (Bes) con l'obiettivo di integrare le informazioni fornite dagli indicatori sulle attività economiche con le fondamentali dimensioni del benessere, corredate da misure relative alle diseguaglianze e alla sostenibilità. Sono stati individuati 12 domini fondamentali per la misura del benessere in Italia.
**URL / API:** https://www.istat.it/statistiche-per-temi/focus/benessere-e-sostenibilita/la-misurazione-del-benessere-bes/gli-indicatori-del-bes/
**Come riscaricare:** dalla pagina, sezione `Gli indicatori del Bes`, si può scaricare il `"Rapporto Bes YYYY"` e l'`"Aggiornamento intermedio YYYY"`
**Data ultimo download:** 2026-09-11
**Data di ultima pubblicazione:** 2026-04 (Aggiornamento intermedio 2026)
**Periodo coperto:** 2004 → 2025 (anni in colonna; nell'aggiornamento 2026 la colonna 2026 è vuota, il 2025 è provvisorio per alcuni indicatori; molti indicatori partono più tardi, es. quelli da Forze di lavoro dal 2018)
**Unità territoriale:** regioni e province autonome (22) + ripartizioni (7) + Italia nel file per regione e sesso; solo Italia negli altri file (per età/sesso, per titolo di studio) o ripartizioni; NESSUN dettaglio provinciale → per Parma vedi `istat_bes_territori`
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Bes_2024_dati/` — Rapporto Bes 2024: `Indicatori_per_regione_sesso_REV.xlsx` (8.480 righe, 1 riga = indicatore × sesso × territorio, anni 2004→2025 in colonna, colonna `NOTA`), `Indicatori_per_eta_sesso.xlsx`, `Indicatori_per_titolo_studio.xlsx` (2 fogli), `Indicatori_per_titolo_studio_ripartizione.xlsx`, `Metadati.xlsx` (152 indicatori: dominio, codice, definizione, fonte)
- `Bes_2024_dati_agg2026/` — Aggiornamento intermedio 2026, stessi 5 file (nomi in minuscolo) con un anno in più e 153 indicatori
- `Bes_2024_report.pdf` — il rapporto

**Note/insidie:** 12 domini, ~150 indicatori: molto più ricco del Bes dei territori (11 domini, 67 indicatori) ma solo regionale. Valori come testo con virgola decimale. Codici con suffisso (`-N22`, `-N23`, `-N25`) = serie ricostruite dopo revisioni della fonte (es. Forze di lavoro), che partono più tardi. Indicatori di interesse per il tema giovani e lavoro: `02IST005-N22` Uscita precoce dal sistema di istruzione e formazione (18-24 anni, dal 2018; NON c'è nel Bes dei territori) e `03LAV002-N22` Tasso di mancata partecipazione al lavoro (15-74 anni, dal 2018; questo c'è anche per provincia in `istat_bes_territori`, insieme alla versione giovanile 15-29). Entrambi da Forze di lavoro → stime campionarie. Due edizioni l'anno (Rapporto in primavera + aggiornamento intermedio): usare l'aggiornamento più recente, il Rapporto serve per il pdf.

**Storico aggiornamenti:**

- 2026-09-11 prima acquisizione (Rapporto Bes 2024 + Aggiornamento intermedio 2026, dati fino al 2025)
