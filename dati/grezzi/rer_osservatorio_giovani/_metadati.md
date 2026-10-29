# rer_osservatorio_giovani

**Ente/fonte:** Regione Emilia-Romagna — Report annuale sulla condizione giovanile in Emilia-Romagna (edizioni 2025 e 2026)
**Di cosa si tratta**: rapporto regionale sui giovani 15-34 anni (demografia, istruzione, lavoro, NEET, salute, partecipazione). Per il lavoro riporta elaborazioni regionali sulla rilevazione ISTAT delle forze di lavoro (stime campionarie): condizione professionale in migliaia, tassi di attività, occupazione e disoccupazione per età e sesso, e per provincia (solo 25-34 anni)
**URL / API:** <!-- link alla pagina del Report da completare -->
**Come riscaricare:** scarico manuale del pdf; i numeri si estraggono con `moduli/giovani_ingresso_lavoro/00_prep_condizione_pdf.R`
**Data ultimo download:** 2026-10-29
**Data di ultima pubblicazione:** 2026-08 (edizione 2026, versione del 05/08/2026)
**Periodo coperto:** edizione 2026: dati 2025, con confronti 2019 e 2024; edizione 2025: dati 2024
**Unità territoriale:** Emilia-Romagna (con confronti Nord-est, Italia, UE 27); province ER solo per i tassi 25-34 anni (Tab. 19 dell'edizione 2026)
**Licenza:** documento pubblico, licenza non dichiarata (citare la fonte)

**File:**

- `Report_giovani_2026.pdf` — edizione 2026 (68 pagine, testo selezionabile). Cap. 3 "Giovani e lavoro": Tab. 14 condizione professionale 15-24 / 25-34 / 15-34 / 15+ (migliaia 2019, 2024, 2025 e var. %, p. 41); Tab. 15 idem per sesso (2025 e var. %, p. 43); Tab. 16-18 tassi di attività, occupazione e disoccupazione 15-24 e 25-34 per sesso, ER / Nord-est / Italia / UE 27 (p. 44-45); Tab. 19 tassi di occupazione e disoccupazione 25-34 per provincia e sesso (p. 46); Fig. 24-25 classifica delle regioni (solo grafico)
- `Report_giovani_2025.pdf` — edizione 2025 (dati 2024): Tab. 12-15 come le Tab. 14-18 dell'edizione 2026, senza tabella per provincia. Non usato per ora
- `giovani_occupati_xprov_2025.png`, `giovani_disoccoccupati_xprov_2025.png`, `variaz_x_condiz_2025.png` — schermate della versione web del Report (grafici Flourish), solo come riferimento per i grafici; i dati sono quelli delle Tab. 14 e 19

**Note (come leggere i dati):** tasso di attività = forze di lavoro / popolazione; tasso di occupazione = occupati / popolazione; tasso di disoccupazione = persone in cerca di occupazione / forze di lavoro, nella classe d'età. Le var. % e i tassi sono calcolati dalla Regione su dati non arrotondati: ricalcolati dalle migliaia stampate differiscono di 0,1-0,2 punti. I tassi per provincia e sesso poggiano su campioni piccoli: valori indicativi.

**Insidie (rotture di serie ed errori):** le stime delle forze di lavoro non coincidono con la popolazione residente usata nel cap. 1 del Report (note 13-14): sono due stime diverse. Nella Tab. 19 Forlì-Cesena ha due valori stampati senza decimale ("90", "8"). Il testo della versione web dice "dal 6,1% (2024) al 4,9% (2024)": il secondo anno è un refuso per 2025.

**Storico aggiornamenti:**

- 2026-10-29 prima acquisizione (edizioni 2025 e 2026; Luisa: pdf e schermate; Claude: script di estrazione e metadati)
