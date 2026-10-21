# istat_disab_cifre_gali_2023

**Ente/fonte:** ISTAT — Disabilità in cifre, tavola "a.2 Persone per gravità delle limitazioni nelle attività abitualmente svolte (valori percentuali)", da indagine Multiscopo "Aspetti della vita quotidiana" (parte generale)
**Di cosa si tratta**: indicatore GALI (Global Activity Limitation Indicator): quota di persone che dichiarano limitazioni, per motivi di salute e da almeno 6 mesi, nelle attività che le persone svolgono abitualmente, per gravità (gravi / non gravi / nessuna). ISTAT considera "persone con disabilità" chi dichiara limitazioni gravi. Serve alla tabella quadro della pagina Anziani (modulo `anziani_non_autosuff`), accanto alle misure ADL/IADL di EHIS
**URL / API:** EX https://disabilitaincifre.istat.it/MD/dawinciMD.jsp?p=0 (interrogazione nel foglio `info` del file), ORA ???
**Come riscaricare:** a mano da Disabilità in cifre, tavola a.2, per regione e classe d'età (il sistema incrocia al massimo 2 dimensioni: una query per classe d'età)
**Data ultimo download:** 2025 (vecchio repo, data esatta non annotata); copiato qui da `temp/analisi_contesto_old/data_in/ISTAT_DISAB_CIFRE/` il 2026-10-20
**Data di ultima pubblicazione:** da verificare (dato 2023)
**Periodo coperto:** 2023 (media degli ultimi due anni, 2022-2023)
**Unità territoriale:** regioni e Italia, per classe d'età (0-44, 45-64, 65-74, 75+)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `gali_2023_eta_regione.xls` — nome originale `GALI_2023_eta_regione.xls`. Tre fogli: `info` (definizioni, note, link della query), `2023` (tavola a.2 per regione, tutte le età, come scaricata), `2023_eta_regione` (regione × livello di gravità × classe d'età: sembra assemblato a mano nel vecchio repo da più query, da verificare contro il sito prima di usarlo)

**Note/insidie:**

- Esclude le persone che vivono in residenze (solo famiglie): sottostima tra i più anziani
- Una sola domanda generale, auto-riferita: misura la disabilità percepita, non l'autonomia in attività specifiche (per quella: ADL/IADL in `istat_ehis_2019/`)
- Indagine diversa da EHIS: le quote GALI non si sommano né si sottraggono a quelle ADL/IADL
- Classe 75+ unica: non distingue 75-84 e 85+
- C'è una quota "Non indicato" (5-11% secondo regione ed età): le % sono su 100 persone comprese le non risposte
- Stima campionaria: usare ordini di grandezza

**Storico aggiornamenti:**

- 2026-10-20 copiato dal vecchio repo per la tabella quadro della pagina Anziani (il file in `temp/` resta)
