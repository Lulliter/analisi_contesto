# istat_cittadini_ict

**Ente/fonte:** ISTAT — Cittadini e ICT (indagine "Aspetti della vita quotidiana", modulo ICT armonizzato Eurostat)
**Di cosa si tratta**: indagine campionaria annuale sull'uso di internet, dei dispositivi e dei servizi digitali da parte delle persone (6 anni e più; competenze digitali 16-74), con dettaglio per età, sesso, titolo di studio, tipo di famiglia, regione. Dall'edizione 2025 rileva per la PRIMA volta l'uso di strumenti di IA generativa (14 anni e più). Serve per la sezione di inquadramento "L'adozione delle tecnologie negli ultimi quindici anni" (tutti vs giovani) e per l'indicatore "uso dell'IA per età" del modulo `giovani_digitale`.
**URL / API:** 

  1. comunicato 2025: https://www.istat.it/comunicato-stampa/cittadini-e-ict-anno-2025/ ;
  2. serie storiche: https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0830COM,1.0/COM_INT_PC_USERS ---  OPPURE `IstatData` > (`Categorie`) `Cultura, comunicazione, viaggi` > `"Internet e pc - tipo di utilizzatori"`
    - Query SDMX `IT1,83_63_DF_DCCV_AVQ_PERSONE_237,1.0` (Internet - dettaglio età), 
      - Query struttura: https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/83_63_DF_DCCV_AVQ_PERSONE_237/1.0/?detail=Full&references=Descendants
    - Query SDMX `IT1,83_63_DF_DCCV_AVQ_PERSONE_241,1.0` (PC - dettaglio età), 
      - Query struttura: https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/83_63_DF_DCCV_AVQ_PERSONE_241/1.0/?detail=Full&references=Descendants
    - Query SDMX `IT1,83_63_DF_DCCV_AVQ_PERSONE_239,1.0` (Internet - regione e tipo di comune); 
      - Query struttura: https://esploradati.istat.it/SDMXWS/rest/dataflow/IT1/83_63_DF_DCCV_AVQ_PERSONE_239/1.0/?detail=Full&references=Descendants
    - struttura `DCCV_AVQ_PERSONE` (la stessa per le tre tavole: verificato il 2026-09-17 interrogando ciascuna tavola, v. `f_struttura_di()` in `06a`; il json salvato viene dalla sola 237): la "Query struttura" restituisce in una sola risposta la tavola, le sue dimensioni in ordine e le codelist (codice → etichetta). NB: senza indicare un formato ISTAT risponde in JSON, non in xml → salvata come `sdmx_struttura_avq_persone.json` e letta con `jsonlite`
    - chiave = il filtro della query dati: un valore per ogni dimensione, nell'ordine della struttura, separati da `.`; posizione vuota = tutte le modalità; `+` = oppure. Es. `A.IT..HSC.1+2+9..99.99`. Dimensioni e diciture ISTAT (lette dalle codelist il 2026-09-17):
      - 1 `FREQ` (`CL_FREQ`): `A` = annuale
      - 2 `REF_AREA` (`CL_ITTER107`, Territorio): `IT` = Italia, `ITD` = Nord-est, `ITD5` = Emilia-Romagna
      - 3 `DATA_TYPE` (`CL_TIPO_DATO_AVQ`, Tipo dato): lasciato vuoto = i 6 della tavola. Internet, "persone di 6 anni e più per utilizzo di Internet e frequenza di utilizzo": `6_INTSI` usano Internet, `6_INTTUTTI` tutti i giorni, `6_INT_1P_SETT` una o più volte alla settimana, `6_INT_QV_MESE` qualche volta al mese, `6_INT_QV_ANNO` qualche volta all'anno, `6_INTNO` non usano Internet. Pc: gli analoghi `3_PCSI`, `3_PCTUTTI`, `3_PC_1P_SETT`, `3_PC_QV_MESE`, `3_PC_QV_ANNO`, `3_PCNO` ("persone di 3 anni e più per utilizzo del personal computer…")
      - 4 `MEASURE` (`CL_MISURA_AVQ`): `HSC` = per 100 persone con le stesse caratteristiche
      - 5 `SEX` (`CL_SEXISTAT1`): `1` = maschi, `2` = femmine, `9` = totale
      - 6 `AGE` (`CL_ETA1`, Classe di età): lasciato vuoto = tutte le classi (`Y6-10`, `Y11-14`, `Y15-17`, `Y18-19`, `Y20-24`, `Y25-34`, … `Y_GE75` = 75 anni e più); totale = `Y_GE6` (6 anni e più) per internet, `Y_GE3` (3 anni e più, con in più la classe `Y3-5`) per il pc
      - 7 `EDU_LEV_HIGHEST` (`CL_TITOLO_STUDIO`, Titolo di studio): `99` = totale
      - 8 `LABOUR_PROFESS_STATUS_B` (`CL_CONDIZIONE_DICH`, Condizione dichiarata = condizione professionale, NON tipologia di famiglia): `99` = totale
      - 9 `TIME_PERIOD`: l'anno; è sempre l'ultima dimensione e non sta nella chiave
    - nel risultato: `OBS_VALUE` = valore (arriva come testo), `OBS_STATUS` = eventuale segnalazione sul singolo valore (`CL_FLAG`): quasi sempre vuota; vale `0` = "il dato non raggiunge la metà della cifra minima considerata" (i `..` delle tavole: quota < 0,05%) e lì `OBS_VALUE` manca — edizione 2025: 30 celle piccole su 11.664 (frequenze rare, over 75). In `sdmx_internet_reg.rds` la colonna non c'è proprio


**Come riscaricare:**
  1. dal comunicato, allegato `Tavole.zip` (https://www.istat.it/wp-content/uploads/2026/04/Tavole.zip) + `Testo-integrale-e-nota-metodologica.pdf` (754 KB) → tavole 2025 per età, sesso, regione, titolo di studio, tipo di famiglia
  2. per le SERIE LUNGHE per età (uso di internet e del pc, 2001→): `ingestione/06a_get_istat_avq_ict.R` (lanciato e verificato il 2026-09-17): prima la struttura (`sdmx_struttura_avq_persone.json`, una tantum), poi i dati → `sdmx_internet_eta.rds`, `sdmx_pc_eta.rds`, `sdmx_internet_reg.rds`. All'aggiornamento annuale: cancellare i tre rds e rilanciare; la struttura si riscarica solo se ISTAT cambia la tavola. ATTENZIONE al limite ISTAT: 5 richieste al minuto, poi blocco dell'IP per 1-2 giorni
  3. uso di IA generativa 2025 per età e sesso: NON è nelle tavole né su IstatData → trascrivere a mano dal pdf del comunicato in `ict_ia_2025_eta_sesso.csv` (da fare) — AGGIORNAMENTO 2026-09-17: NON si trascrive. Verificato che nel pdf c'è solo un paragrafo (p. 6 circa, con Figura 4) con 8 numeri in tutto, e che l'IA non compare né nelle 11 tavole xlsx né nella codelist dei tipi di dato AVQ: i numeri (v. Note/insidie) si citano nel testo della pagina; per un grafico per età v. Eurostat `isoc_ai_iaiu`
  4. social network per età: dataflow `DCCV_ICT` (tipo di dato `PARTSOCIA`), id API da recuperare dal browser (la richiesta diretta dà 404) → da fare
**Data ultimo download:** 2026-09-15 (tavole 2025 + pdf); 2026-09-17 (serie SDMX + struttura)
**Data di ultima pubblicazione:** 2026-04-22 (Cittadini e ICT – Anno 2025)
**Periodo coperto:** 2025 (tavole del comunicato); 2001→2025 SENZA il 2004 (serie IstatData per età, 24 anni; verificato via API: es. 15-17enni internet tutti i giorni 9,7% nel 2001, 52,9% nel 2010, 94,0% nel 2025; totale 6+ 72,4% nel 2025)
**Unità territoriale:** Italia per età × sesso (classi 6-10, 11-14, 15-17, 18-19, 20-24, 25-34, ... 75+); regioni (ITD5 = Emilia-Romagna, ITD = Nord-est) solo sul totale 6+; NESSUN dettaglio provinciale
**Licenza:** CC BY 4.0 (ISTAT) — <verificare in calce alle tavole>

**File:**

- `tav1.1 2025.xlsx` … `tav4.2 2025.xlsx` (11 tavole, da `Tavole.zip`) + `Indice delle tavole allegate 2025.docx` — 1.x accesso e uso di internet (1.2 per sesso ed età; 1.3 per regione), 2.x competenze digitali 16-74, 3.x SPID/CIE, 4.x e-commerce. NIENTE IA generativa nelle tavole
- `Testo-integrale-e-nota-metodologica.pdf` — comunicato + nota metodologica (definizioni, campione)
- `sdmx_internet_eta.rds`, `sdmx_pc_eta.rds` (da `06a`) — Italia, frequenza d'uso × sesso × classe d'età × anno; solo codici, niente etichette (5.616 e 6.048 righe)
- `sdmx_internet_reg.rds` (da `06a`) — internet, totale 6 anni e più, sesso totale: Italia, Nord-est, Emilia-Romagna
- `sdmx_struttura_avq_persone.json` (da `06a`, 6,7 MB) — struttura `DCCV_AVQ_PERSONE` con tutte le codelist: è qui che si leggono le etichette dei codici

**Note/insidie:** stima campionaria (circa 20.000 famiglie): per le classi d'età giovani l'errore è più ampio, leggere i trend. La popolazione di riferimento cambia per indicatore (6+ uso internet; 14+ IA generativa; 16-74 competenze digitali, definizione Eurostat DigComp): non confrontare quote con basi diverse. Nelle serie SDMX alcune celle piccole non hanno valore (`OBS_STATUS` = `0`, quota sotto lo 0,05%): non sono errori di download, e nel pulito restano `NA` con la segnalazione accanto. Dati IA 2025 dal comunicato: Italia 17,8% (14+); 14-19 anni 51,2% (F 53,3, M 49,1); 20-24 anni 43,1%; Nord 19,7%, Centro 18,8%, Mezzogiorno 14,6%. Le classi d'età giovani nelle tavole ISTAT sono di solito 6-10, 11-14, 15-17, 18-19, 20-24 (<verificare>).

**Storico aggiornamenti:**

- 2026-09-15 prima acquisizione: tavole 2025 + pdf (serie SDMX: script pronto, da lanciare)
- 2026-09-17 scaricate le serie SDMX 2001→2025 (internet e pc per età, internet per territorio) e la struttura con le codelist; chiave e diciture verificate sulle codelist ISTAT
