# comune_pr_open

**Ente/fonte:** Comune di Parma — portale Open Data
**Di cosa si tratta**: portale dei dati aperti del Comune di Parma (piattaforma DKAN, non CKAN): cartografia, toponomastica, demografia, servizi comunali del solo territorio comunale. In questa cartella: il catalogo del portale e i dataset usati dai moduli.
**URL / API:** https://opendata.comune.parma.it (API in stile CKAN: `/api/3/action/package_list`, `package_show?id=...`)
**Come riscaricare:** catalogo con `ingestione/08_get_catalogo_opendata_parma.R`; i singoli dataset con `ingestione/09_get_comune_pr_cartografia.R` (tabella "1 riga = 1 file" nei Parametri; per un aggiornamento si cambia la riga con l'indirizzo preso dal catalogo)
**Data ultimo download:** 2026-10-07 (catalogo, ACER, quartieri); strade, torrenti, ferrovie, parchi: <AAAA-MM-GG>
**Data di ultima pubblicazione:** variabile per dataset (v. colonna `modificato` del catalogo)
**Periodo coperto:** variabile per dataset
**Unità territoriale:** Comune di Parma (punti, linee, quartieri)
**Licenza:** CC BY 4.0 (indicata dal portale per i dataset usati qui)

**File:**

- `catalogo_opendata_parma.rds` / `.xlsx` — catalogo del portale (fogli dataset, risorse, metadati), prodotto da `ingestione/08`
- `ACER_immobili.geojson` — "Immobili ACER di Parma 2022" (Politiche abitative): 1 riga = 1 immobile (indirizzo + civico, anno di costruzione), circa 640 righe, WGS84 (EPSG 4326). Scheda: https://opendata.comune.parma.it/dataset/immobili-acer-di-parma-2022 — file: https://opendata.comune.parma.it/sites/default/files/ACER_immobili.geojson
- `quartieri_vigenti.geojson` — "Quartieri del Comune di Parma vigenti" (Uffici SIT e Toponomastica): 13 quartieri, campi `ID_QUART`, `Circoscrizione`, `QUARTIERE`, WGS84. Scheda: https://opendata.comune.parma.it/dataset/quartieri-del-comune-di-parma-vigenti — file: https://opendata.comune.parma.it/sites/default/files/quartieri_vigenti.geojson
- `torrenti.geojson` — "Livello cartografico dei torrenti" (SIT), WGS84. Scheda: https://opendata.comune.parma.it/dataset/livello-cartografico-dei-torrenti
- `ferrovie.geojson` — "Livello cartografico delle linee ferroviarie di Parma" (SIT), WGS84. Scheda: https://opendata.comune.parma.it/dataset/livello-cartografico-delle-linee-ferroviarie-di-parma
- `parchi_intitolati.geojson` — "Parchi intitolati" (poligoni con nome del parco), WGS84. Scheda: https://opendata.comune.parma.it/dataset/parchi-intitolati
- `Grafo_stradale_PARMA_2025_RDN2008 (SHP).zip` + cartella `grafo_stradale_2025/` — "Livello cartografico del reticolo stradale di Parma 2025" (assi stradali, SIT), shapefile RDN2008 UTM32N (EPSG 7791). Scheda: https://opendata.comune.parma.it/dataset/livello-cartografico-del-reticolo-stradale-di-parma-2025
- `Popolazione_residente_2026.csv` + `Popolazione_residente_codifica_campi_2025.csv` — "Popolazione residente al 1 gennaio 2026" (anagrafe comunale, pubblicato 2026-02-20): 1 riga = 1 residente, 202.742 righe; campi `Tipores`, `Sesso`, `ETA`, `Cittad`, `Ncomp`, `Relpar`, `Quartiere` (nome per esteso, 13 quartieri), `SEZ21` (sezione di censimento 2021); csv `;`, codifica in latin1. In pulizia: anni compiuti = `ETA - 1` (`ETA` è 2026 meno l'anno di nascita; verificato sulle classi di età della Regione al 1/1/2026 in `rer_pop_residente/`, che coincidono). Scheda: https://opendata.comune.parma.it/dataset/popolazione-residente-al-1-gennaio-2026

**Note (come leggere i dati):**

- il portale è DKAN: `package_search` non esiste e `package_show` restituisce il dataset dentro un elenco; il server MCP per CKAN non lo legge
- campo "autore" compilato in circa metà dei dataset (spesso è l'email dell'ufficio); "gestore" sempre "Open Data Comune di Parma", quindi non informativo
- immobili ACER: nessun numero di alloggi né quartiere nel dato (il quartiere si ricava con un join spaziale); aggiornamento del 2023-06-08 con dati 2022
- gli stessi dati sono pubblicati anche come shapefile in RDN2008 UTM32N (EPSG 7791) e in UTMRER (EPSG 5659)
- popolazione 2026: totale coerente con la Regione al 1/1/2026 (202.729)

**Insidie (rotture di serie ed errori):**

- immobili ACER: 21 indirizzi compaiono due volte con dati identici (cambia solo `IDE`, che è un progressivo di riga; anche nel csv `INDIR2` è vuoto): si tengono come nella fonte (639 righe), perché possono essere più unità allo stesso civico
- quartieri: nella fonte due nomi abbreviati ("S.Leonardo", "C.S. Martino"); esiste anche la versione storica dei quartieri (dataset `quartieri-del-comune-di-parma-storico`), da non confondere
- popolazione 2026: `Relpar` nel dato ha solo i codici 1-11, mentre la codifica allegata (la stessa del 2022) va da 1 a 99: oltre a 1 = intestatario (affidabile, la somma di `Ncomp` torna) i codici non sono interpretabili
- popolazione 2026: nelle convivenze anagrafiche (`Tipores == 2`, circa 3.100 residenti) `Ncomp` è la dimensione della convivenza (fino a 369): escluderle dagli indicatori sulle famiglie
- popolazione 2026: `SEZ21` vuota per 166 residenti (il quartiere c'è sempre); `Cittad` 224, 998, 999 assenti dalla codifica (24 persone)

**Storico aggiornamenti:**

- 2026-10-07 prima acquisizione: catalogo (77 dataset, 279 risorse); immobili ACER e quartieri vigenti (geojson)
- <AAAA-MM-GG> strade 2025, torrenti, ferrovie, parchi intitolati (con `ingestione/09`) — sfondo delle mappe per quartiere
- 2026-10-08 popolazione residente al 1/1/2026 (con `ingestione/09`)
