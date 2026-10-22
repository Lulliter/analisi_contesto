# rer_irpef

**Ente/fonte:** Regione Emilia-Romagna, Ufficio di Statistica — "Redditi Irpef in Emilia-Romagna. Anno d'imposta 2024" (elaborazione su dati MEF, Dipartimento delle Finanze)
**Di cosa si tratta**: rapporto annuale (14 pp.) sui contribuenti e i redditi dichiarati ai fini IRPEF in Emilia-Romagna, con confronto tra province e con l'Italia: numero di contribuenti, reddito complessivo medio, distribuzione per classi di reddito e tipologia (lavoro dipendente, pensione, autonomo). Fonte "premasticata": i dati per comune sono sul sito MEF.
**URL / API:** <URL pagina Statistica RER> ; dati di base: https://www1.finanze.gov.it/finanze/analisi_stat/public/index.php?tree=2024 (MEF, dichiarazioni IRPEF per comune)
**Come riscaricare:** a mano dalla pagina Statistica RER (sezione Studi e analisi)
**Data ultimo download:** 2026-10-09
**Data di ultima pubblicazione:** 2026-06 (anno d'imposta 2024)
**Periodo coperto:** anno d'imposta 2024 (con confronti sugli anni precedenti)
**Unità territoriale:** regione, province
**Licenza:** <verificare; Statistica RER di norma CC BY 4.0>

**File:**

- `Rapporto-Redditi-IRPEF-Emilia-Romagna-Italia-2026_su_2024.pdf` — rapporto completo; tabelle non ancora estratte

**Note (come leggere i dati):** Non ancora usato da nessun modulo (tema 7 Lavoro e redditi / 8 Fragilità economica in `_TODO.qmd`); se servono numeri, estrarli con uno script `00_prep_<cosa>_pdf.R` (regola Fonti in pdf, `dati/README.md`) oppure, meglio, scaricare i dati per comune dal MEF.

**Insidie (rotture di serie ed errori):** i redditi IRPEF sono dichiarati, non percepiti: escludono i redditi esenti e i non dichiaranti e sottostimano i redditi bassi.

**Storico aggiornamenti:**

- 2026-10-09 prima acquisizione (edizione 2026, a.i. 2024)
