# cergas_oltc

**Ente/fonte:** CERGAS SDA Bocconi — Osservatorio Long Term Care (OLTC), Rapporto annuale (a cura di Fosti, Notarnicola e altri)
**Di cosa si tratta**: rapporto nazionale sul settore della non autosufficienza: definizione e stima del bisogno (anziani non autosufficienti = over 65 con gravi limitazioni funzionali, ISTAT EHIS 2019), offerta di servizi (residenziale, domiciliare, trasferimenti), spesa. Qui serve per la DEFINIZIONE e per le prevalenze a tre classi d'età (cap. 1, Tab. 1.1 e 1.2) usate in `moduli/anziani_non_autosuff/`; il resto (offerta) potrà servire al tema Assistenza
**URL / API:** https://cergas.unibocconi.eu/observatories/long-term-care (rapporti scaricabili previa registrazione)
**Come riscaricare:** scarico manuale del pdf dal sito dell'Osservatorio; una edizione l'anno (inverno)
**Data ultimo download:** 2026-10-19 (8° Rapporto, 2026)
**Data di ultima pubblicazione:** 2026 (8° Rapporto)
**Periodo coperto:** stime 2013-2023 (serie storica delle stime del bisogno; dal 2019 metodo attuale)
**Unità territoriale:** Italia (alcune tavole per regione)
**Licenza:** documento pubblico, diritti dell'editore (Egea): citare, non ridistribuire

**File:**

- `oltc_8_rapporto_2026.pdf` — 8° Rapporto (bib `OLTC_8rapp_2026`). LETTO DA SCRIPT: `moduli/anziani_non_autosuff/00_prep_prevalenze.R` (pdftools + regex) legge Tab. 1.1 (28,4%, p. 18-19 stampate) e Tab. 1.2 (65-74 14,6% / 75-84 32,5% / 85+ 63,8%, p. 19 stampata); la pagina del pdf dipende dalla copia e lo script la stampa a schermo. Il 7° Rapporto (bib `OLTC_7rapp_2025`) è solo in Zotero

**Note (come leggere i dati):**

- "Anziani non autosufficienti" per il CERGAS = persone di 65 anni e più con gravi limitazioni funzionali (gravi difficoltà in almeno una ADL o IADL) secondo ISTAT EHIS 2019: 28,4% degli over 65, applicato alla popolazione 65+ di ogni anno (4,03 milioni nel 2023). La prevalenza è tenuta COSTANTE dal 2019 (ISTAT non l'ha aggiornata): la crescita delle stime è solo demografica
- Le stime 2013-2016 usavano un altro metodo (19,8% + ospiti dei presidi residenziali): non confrontabili con le successive (lo dice il Rapporto)
- Le prevalenze per età della Tab. 1.2 vengono dal report ISTAT 2021 (bib `IstatAnziani2019`, in `istat_ehis_2019/`): il Rapporto le cita, non le produce

**Insidie:**

- Se cambia l'impaginazione in una nuova edizione, le regex di `00_prep_prevalenze.R` vanno riviste (i controlli in coda allo script devono tornare TRUE; il riscontro è `moduli/anziani_non_autosuff/riscontro_prevalenze_a_mano.csv`)

**Storico aggiornamenti:**

- 2026-10-19 cartella creata con l'8° Rapporto (pdf allegato da Luisa in chat); prima era in `istat_ehis_2019/`
