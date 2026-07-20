# istat_shp

**Ente/fonte:** ISTAT — Confini delle unità amministrative a fini statistici
**URL / API:** https://www.istat.it/notizia/confini-delle-unita-amministrative-a-fini-statistici-al-1-gennaio-2018-2/
**Come riscaricare:** dalla pagina sopra, zip "Confini al 1° gennaio <anno>" — versione **generalizzata** (suffisso `_g`), WGS84; estrarre le sottocartelle per livello amministrativo
**Data ultimo download:** 2026-07-17 (set completo 01/01/2026 generalizzato)
**Periodo coperto:** confini al 01/01/2026
**Unità territoriale:** comuni / province e città metropolitane / regioni / ripartizioni
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Com01012026_g/` — confini comunali generalizzati (shp+dbf+prj+shx, WGS84)
- `Com01012026/` — confini comunali NON generalizzati (110 MB, gitignorati):
  rimessi dal backup il 2026-07-17, servono SOLO per gli zoom di dettaglio
  sulla provincia PR (vedi `ingestione/00b_prep_pr_dettaglio.R`)
- `ProvCM01012026_g/` — province e città metropolitane
- `Reg01012026_g/` — regioni
- `RipGeo01012026_g/` — ripartizioni geografiche
- `_istat_shp_legenda.pdf` — legenda ISTAT (ereditata dalla vecchia struttura)

**Note/insidie:**

- nomi delle sottocartelle originali ISTAT (non rinominare); WGS84 (vedi .prj)
- versione **generalizzata** (confini semplificati): ok per mappe tematiche, NON per
  calcoli di superficie o spatial join di precisione (in quel caso riscaricare la
  non generalizzata)
- dal 01/01/2026 nuovi codici/assetto delle province della Sardegna (riforma
  territoriale) → non confrontare i layer province con annate precedenti
- comuni al 01/01/2026 = identici al 01/01/2025 (7.896), quindi quest'annata copre
  anche analisi riferite al 2025; MA nel corso del 2026 due variazioni (Lirio →
  Montalto Pavese (PV), gennaio; fusione Castegnero Nanto (VI), febbraio → 7.894):
  compariranno nei confini al 01/01/2027
- i confini cambiano per fusioni di comuni → attenzione ai join con codici ISTAT
  di annate diverse

**Politica scelta (2026-07-17): un solo vintage di confini, l'ultimo.**

- Niente annate storiche "per sicurezza": i dati (anche riferiti al 2023 o serie
  2002-2024) si mappano sui confini correnti, perché le fonti pubblicano serie
  ricostruite sui comuni attuali ("comune attualizzato" RER, ricostruzioni ISTAT)
- Emilia-Romagna: ultima variazione = fusione Sorbolo Mezzani (PR) 01/01/2019;
  da allora 330 comuni invariati → per ER/PR il vintage 2026 copre anche i dati 2023
- Guardia nel codice, non in cartella: a ogni join dati↔shp fare `anti_join()` sui
  codici ISTAT; se emergono orfani (dataset su comuni pre-fusione) si costruisce
  una tabella di raccordo nel modulo. Annata storica da riscaricare SOLO per mappe
  comunali Italia intera con dati d'epoca (caso raro, annotarlo qui)

**Storico aggiornamenti:**

- 2025-11-08 prima acquisizione (confini 01/01/2025, versione non generalizzata)
- 2026 aggiunta Com01012026 (comuni 01/01/2026, non generalizzata)
- 2026-07-17 spostato in dati/grezzi/ (era data/data_in/istat_shp_ITA)
- 2026-07-17 sostituito tutto con set completo 01/01/2026 **generalizzato** (~20 MB
  vs ~250 MB); annate 2025 e versione non generalizzata eliminate (restano nel backup)
