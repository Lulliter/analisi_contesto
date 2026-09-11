# istat_bes_territori

**Ente/fonte:** ISTAT — Il benessere equo e sostenibile dei territori (Bes dei territori), edizione 2025
**Di cosa si tratta**: Il sistema di indicatori Bes dei Territori (BesT) estende a livello sub-regionale un ampio set delle misure del Benessere equo e sostenibile (Bes), e le integra con ulteriori indicatori di benessere rilevanti per il livello locale
**URL / API:** https://www.istat.it/statistiche-per-temi/focus/benessere-e-sostenibilita/la-misurazione-del-benessere-bes/il-bes-dei-territori/
**Come riscaricare:** dalla pagina, si va all'edizione corrente (e.g. "Diffusioni 2025" e si scaricano `file xlsx` e `file metadati` e `report regionali`; nessuna API
**Data ultimo download:** 2026-09-10
**Data di ultima pubblicazione:** 2025-07-01 (edizione 2025)
**Periodo coperto:** 2004 → 2024 (anni in colonne `V2004`…`V2024`; molti indicatori partono più tardi; il 2024 è provvisorio per alcuni)
**Unità territoriale:** province (107) + regioni, ripartizioni e Italia, tutte nella stessa tavola (139 territori); livello ricavabile dal codice `W_GEO` (vedi `ingestione/04_prep_istat_bes.R`)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**
- `Bes_dei_territori_indic_per_prov_sesso_ed2025.xlsx` — foglio unico `Indicatori_per_provincia_sesso`, 14.253 righe: 1 riga = indicatore × sesso (Maschi/Femmine/Totale) × territorio, anni in colonna; 11 domini, 67 indicatori; valori come testo con virgola decimale; colonna `NOTA` con avvertenze per indicatore
- `Bes_dei_territori_indic_per_prov_sesso_ed2025_METADATI.xlsx` — definizioni dei 67 indicatori (dominio, tipo, codice, definizione, unità di misura, fonte) e segni convenzionali
- `BesT2025_Emilia-Romagna_app_Stat.xlsx` — appendice statistica del report regionale: stessi indicatori della tavola nazionale per le 9 province ER (+ regione, Nord-est, Italia), solo 2019 e ultimo anno con variazione standardizzata; in più il foglio `Indicatori soggettivi - CP` (reti di aiuto, sicurezza percepita, soddisfazione per la vita) per provincia e Grande Comune di Parma
- `BesT2025_Emilia-Romagna.pdf` — report regionale Emilia-Romagna, edizione 2025


**Note/insidie:** fonte MULTI-modulo (istruzione, salute, lavoro, redditi, servizi): i moduli filtrano da `dati/puliti/istat_bes/bes_territori.rds`, non rileggono l'xlsx. Tre tipi di indicatore: "Bes" (40, confrontabili con il Bes nazionale), "Proxy" (16) e "Locale" (11). L'uscita precoce dal sistema di istruzione NON è provinciale (regionale). Indicatori da indagine campionaria (es. NEET, da Forze di lavoro) vanno letti come stime; quelli da fonte amministrativa/censuaria (es. competenze INVALSI in III media) no. Le note segnalano confini provinciali pre-2006 per Sardegna e altre province fino al 2021. Edizione annuale: la prossima porta un file con nuovo suffisso `_ed2026` → aggiornare `file_bes` ed `EDIZIONE` nello script.

**Storico aggiornamenti:**

- 2026-09-10 prima acquisizione (edizione 2025, dati fino al 2024)
