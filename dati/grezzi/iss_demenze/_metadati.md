# iss_demenze

**Ente/fonte:** Istituto Superiore di Sanità — Osservatorio Demenze, Fondo per l'Alzheimer e le demenze (www.demenze.it)
**Di cosa si tratta**: materiali dell'Osservatorio nazionale: il Report Nazionale 2024 del Fondo (stime dei casi di demenza in Italia per sesso e classe d'età, indagini sui servizi), la mappa dei servizi per le demenze dell'Emilia-Romagna (CDCD, CRA, centri diurni: elenco, non attività) e i risultati della survey nazionale su RSA e centri diurni. Qui serve la Tabella 1.1 del Report (tassi di prevalenza per sesso × classi quinquennali 65+) per stimare le persone con demenza a Parma (modulo `anziani_non_autosuff`); la mappa dei servizi e la survey riguardano l'offerta → tema Assistenza
**URL / API:** https://www.demenze.it (sezioni "Fondo demenze", "Survey mappa"); Report Nazionale: pubblicato con 21 profili regionali (quello dell'Emilia-Romagna da cercare: potrebbe avere gli utenti dei CDCD)
**Come riscaricare:** scarico manuale dal sito; il Report è annuale (progetto Fondo 2021-2024)
**Data ultimo download:** 2026-10-19
**Data di ultima pubblicazione:** 2024 (Report Nazionale), 2023 (survey RSA e CD)
**Periodo coperto:** stime sui residenti ISTAT al 1.1.2023; tassi di prevalenza dalla meta-analisi europea Bacigalupo et al. 2018
**Unità territoriale:** Italia (Report); Emilia-Romagna per comune (mappa servizi)
**Licenza:** documenti pubblici ISS, citare la fonte

**File:**

- `ReportNazionale_2024.pdf` — 305 pp. Tabella 1.1 (p. 1 del cap. 1 "Epidemiologia"; lo script riporta anche la pagina del pdf): casi prevalenti di demenza ≥ 65 anni per sesso e classe d'età (65-69 … ≥90): popolazione, tassi × 100, casi; totale Italia 1.126.961 (uomini 5,5%, donne 9,9% dei 65+). Tab. 1.2 demenza giovanile 35-64 (23.730 casi); Tab. 1.3 MCI (952.101). DA LEGGERE CON SCRIPT (`moduli/anziani_non_autosuff/00_prep_prevalenze_pdf.R`, come per il CERGAS)
- `MappaServiziER.pdf` — 73 pp., schede dei servizi per le demenze in Emilia-Romagna dal portale ISS (CDCD, CRA, centri diurni, associazioni), con quelli di Parma; elenco, senza dati di attività
- `risultati_survey_rsa_e_cd1.pdf` — slide ISS (dic. 2023), survey nazionale su RSA e centri diurni 2022-23, progetto Fondo Alzheimer

**Note (come leggere i dati):**

- I tassi della Tab. 1.1 sono quelli di Bacigalupo et al. 2018 (meta-analisi europea), applicati alla popolazione italiana: vanno da 0,9% (uomini 65-69) a 38,9% (donne ≥ 90); raddoppiano circa ogni 5 anni d'età
- Stessa logica del CERGAS per la non autosufficienza: prevalenza per età × popolazione, costante nel tempo; i casi "stimati" non sono le diagnosi dei servizi (quelle stanno nei CDCD)
- Confronto con Alzheimer Europe 2025 (`dati/grezzi/alzheimer_europe/`): tassi diversi (più recenti) e base di popolazione diversa: Italia 65+ 1,38 milioni nel 2025 contro 1,13 nel 2023 qui; usare una sola fonte per le stime e citare l'altra come intervallo

**Insidie:**

- Il pdf del Report è lungo (305 pp.): lo script cerca la pagina dalla stringa "Tabella 1.1 Italia. Casi prevalenti"; se una nuova edizione cambia titolo o impaginazione le regex vanno riviste
- Nella Tab. 1.1 i numeri hanno il punto delle migliaia e la virgola decimale; "≥90" con il simbolo ≥ (nel testo estratto può diventare "!90")

**Storico aggiornamenti:**

- 2026-10-19 cartella creata (Luisa scarica dal portale ISS); i csv di Alzheimer Europe scaricati insieme sono stati spostati in `alzheimer_europe/`
