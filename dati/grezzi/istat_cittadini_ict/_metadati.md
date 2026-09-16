# istat_cittadini_ict

**Ente/fonte:** ISTAT — Cittadini e ICT (indagine "Aspetti della vita quotidiana", modulo ICT armonizzato Eurostat)
**Di cosa si tratta**: indagine campionaria annuale sull'uso di internet, dei dispositivi e dei servizi digitali da parte delle persone (6 anni e più; competenze digitali 16-74), con dettaglio per età, sesso, titolo di studio, tipo di famiglia, regione. Dall'edizione 2025 rileva per la PRIMA volta l'uso di strumenti di IA generativa (14 anni e più). Serve per la sezione di inquadramento "L'adozione delle tecnologie negli ultimi quindici anni" (tutti vs giovani) e per l'indicatore "uso dell'IA per età" del modulo `giovani_digitale`.
**URL / API:** comunicato 2025: https://www.istat.it/comunicato-stampa/cittadini-e-ict-anno-2025/ ; serie storiche: IstatData, categoria Cultura, comunicazione, viaggi > "Internet e pc - tipo di utilizzatori" (https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0830COM,1.0/COM_INT_PC_USERS): dataflow SDMX `IT1,83_63_DF_DCCV_AVQ_PERSONE_237,1.0` (Internet - dettaglio età), `..._241` (PC - dettaglio età), `..._239` (Internet - regione e tipo di comune); struttura `DCCV_AVQ_PERSONE`, chiave FREQ.REF_AREA.DATA_TYPE.MEASURE.SEX.AGE.EDU.LAB
**Come riscaricare:**
  1. dal comunicato, allegato `Tavole.zip` (https://www.istat.it/wp-content/uploads/2026/04/Tavole.zip) + `Testo-integrale-e-nota-metodologica.pdf` (754 KB) → tavole 2025 per età, sesso, regione, titolo di studio, tipo di famiglia
  2. per le SERIE LUNGHE per età (uso di internet e del pc, 2001→): `ingestione/06a_get_istat_avq_ict.R` (scritto il 2026-09-15, NON ancora lanciato) → `sdmx_internet_eta.rds`, `sdmx_pc_eta.rds`, `sdmx_internet_reg.rds`
  3. uso di IA generativa 2025 per età e sesso: NON è nelle tavole né su IstatData → trascrivere a mano dal pdf del comunicato in `ict_ia_2025_eta_sesso.csv` (da fare)
  4. social network per età: dataflow `DCCV_ICT` (tipo di dato `PARTSOCIA`), id API da recuperare dal browser (la richiesta diretta dà 404) → da fare
**Data ultimo download:** 2026-09-15 (tavole 2025 + pdf); serie SDMX ancora da scaricare
**Data di ultima pubblicazione:** 2026-04-22 (Cittadini e ICT – Anno 2025)
**Periodo coperto:** 2025 (tavole del comunicato); 2001→2025 (serie IstatData per età, verificato via API: es. 15-17enni internet tutti i giorni 9,7% nel 2001, 52,9% nel 2010, 94,0% nel 2025; totale 6+ 72,4% nel 2025)
**Unità territoriale:** Italia per età × sesso (classi 6-10, 11-14, 15-17, 18-19, 20-24, 25-34, ... 75+); regioni (ITD5 = Emilia-Romagna, ITD = Nord-est) solo sul totale 6+; NESSUN dettaglio provinciale
**Licenza:** CC BY 4.0 (ISTAT) — <verificare in calce alle tavole>

**File:**

- `tav1.1 2025.xlsx` … `tav4.2 2025.xlsx` (11 tavole, da `Tavole.zip`) + `Indice delle tavole allegate 2025.docx` — 1.x accesso e uso di internet (1.2 per sesso ed età; 1.3 per regione), 2.x competenze digitali 16-74, 3.x SPID/CIE, 4.x e-commerce. NIENTE IA generativa nelle tavole
- `Testo-integrale-e-nota-metodologica.pdf` — comunicato + nota metodologica (definizioni, campione)

**Note/insidie:** stima campionaria (circa 20.000 famiglie): per le classi d'età giovani l'errore è più ampio, leggere i trend. La popolazione di riferimento cambia per indicatore (6+ uso internet; 14+ IA generativa; 16-74 competenze digitali, definizione Eurostat DigComp): non confrontare quote con basi diverse. Dati IA 2025 dal comunicato: Italia 17,8% (14+); 14-19 anni 51,2% (F 53,3, M 49,1); 20-24 anni 43,1%; Nord 19,7%, Centro 18,8%, Mezzogiorno 14,6%. Le classi d'età giovani nelle tavole ISTAT sono di solito 6-10, 11-14, 15-17, 18-19, 20-24 (<verificare>).

**Storico aggiornamenti:**

- 2026-09-15 prima acquisizione: tavole 2025 + pdf (serie SDMX: script pronto, da lanciare)
