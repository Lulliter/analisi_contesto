# invalsi

**Ente/fonte:** INVALSI — Servizio statistico, open data: "Dati sottostanti le Dashboard di Tableau del Rapporto 2025-2026" (Rilevazioni nazionali degli apprendimenti, dato censuario su tutti gli studenti)
**Di cosa si tratta**: le tavole aggregate che alimentano i cruscotti Tableau del Rapporto nazionale INVALSI: quota di studenti che raggiungono i traguardi nazionali, distribuzione nei livelli di apprendimento, differenze per genere/origine/ESCS, per macroarea e regione. Due pacchetti per edizione: gradi 2-5-10 e gradi 8-13.
**URL / API:** archivio open data https://serviziostatistico.invalsi.it/archivi-dati/?_invalsi_ss_data_collective=open-data ; pagine dei due pacchetti 2025-26: https://serviziostatistico.invalsi.it/invalsi_ss_data/dati-sottostanti-le-dashboard-di-tableau-del-rapporto-2025-2026-grado-2-grado-5-grado-10/ e https://serviziostatistico.invalsi.it/invalsi_ss_data/dati-sottostanti-le-dashboard-di-tableau-del-rapporto-2025-2026-grado-8-grado-13/ ; cruscotti Tableau elencati in https://serviziostatistico.invalsi.it/grafici-interattivi/
**Come riscaricare:** dalla pagina del pacchetto, bottone di download del singolo file (xlsx o csv), senza registrazione; ogni file ha il suo "tracciato" (dizionario delle variabili) scaricabile accanto. Il dominio è bloccato dal proxy di Claude: scaricare a mano
**Data ultimo download:** 2026-09-02
**Data di ultima pubblicazione:** 2026-07-30 (Rapporto 2025-2026, presentato a luglio 2026)
**Periodo coperto:** a.s. 2017/18 → 2025/26 (manca il 2019/20: prove non svolte per il Covid)
**Unità territoriale:** regioni (Trento e Bolzano l. it. separate) + ripartizioni (Nord Ovest, Nord Est, Centro, Sud, Sud e Isole) + Italia; NESSUN dettaglio provinciale in questi file
**Licenza:** CC BY 4.0 IT (INVALSI)

**File:**

- `Traguardi_MS2026.xlsx` — dal pacchetto gradi 2-5-10; foglio unico, 3.020 righe in formato lungo: 1 riga = territorio × grado × materia × a.s.; `VALORI` = % di studenti che raggiungono il traguardo. Gradi: 2, 5 e 10 (primaria e biennio superiori); materie: Italiano, Matematica, Inglese Reading, Inglese Listening (inglese solo dove prevista). Colonne `Significatività_AAvsBB` = differenza statisticamente significativa tra due a.s. consecutivi (testo "Statistically significant" / vuoto); `Ordinatore` = ordinamento delle regioni (`#NULL!` per Trento)

**Da scaricare (ricognizione 2026-09-11, non ancora in casa):**

- `Trend_TRAGUARDI_MS2026` (pacchetto gradi 8-13): "distribuzione percentuale degli studenti che raggiungono o meno i traguardi nazionali dal 2019 al 2026, per macroarea e regione" → gemello del file sopra per terza media e quinta superiore. xlsx: https://serviziostatistico.invalsi.it/download/1251/dati-sottostanti-le-dashboard-di-tableau-del-rapporto-2025-2026-grado-8-grado-13/17643/trend_traguardi_ms2026-dati-pop-g08-e-g13-2.xlsx ; tracciato: https://serviziostatistico.invalsi.it/download/1251/dati-sottostanti-le-dashboard-di-tableau-del-rapporto-2025-2026-grado-8-grado-13/17633/tracciato_trend_traguardi_ms2026-dati-pop-g08-e-g13.xlsx
- `Livelli Completo_G8_G13` (stesso pacchetto): distribuzione nei livelli di apprendimento per macroarea e regione, gradi 8 e 13. xlsx: https://serviziostatistico.invalsi.it/download/1251/dati-sottostanti-le-dashboard-di-tableau-del-rapporto-2025-2026-grado-8-grado-13/17628/livelli-completo_g8_g13-pop-9.xlsx
- Dal pacchetto 2-5-10 anche `Livelli_Fasce_Percentili_Sig_Variabilita_MS2026` e `Differenza_WLE_MS2026` (differenze di punteggio tra anni per regione), se servono

**Note/insidie:** i file open data sono SOLO regionali/macroarea. La dispersione implicita (studenti di grado 13 sotto il livello adeguato in tutte le materie) NON è in questi file: sta nel Rapporto/presentazione 2026 come grafico per regione con serie 2019→2026 (https://www.invalsi.it/wp-content/uploads/2026/07/Presentazione-Risultati-Prove-INVALSI-2026.pdf), da trascrivere a mano o da chiedere al Servizio statistico (uff.statistico@invalsi.it, "richieste dati ad hoc"). Nella stessa presentazione c'è una mappa "Tasso di ELET per provincia, biennio 2024-25" (elaborazioni INVALSI su microdati ISTAT): è l'unico dato PROVINCIALE sull'uscita precoce trovato finora, ma solo come grafico. Il dato provinciale di terza media (quota sotto il livello adeguato) resta quello ripreso dall'ISTAT nel Bes dei territori (`istat_bes_territori`). Il file porta la significatività ma non gli errori standard. Colonna `Anno_new` in formato "2017-2018" (da convertire in "2017/18" per coerenza con gli altri moduli).

**Storico aggiornamenti:**

- 2026-09-02 prima acquisizione (`Traguardi_MS2026.xlsx`, Rapporto 2025-2026, a.s. 2017/18 → 2025/26)
- 2026-09-11 ricognizione fonti: individuati i file gemelli per i gradi 8 e 13 (URL sopra), da scaricare a mano
