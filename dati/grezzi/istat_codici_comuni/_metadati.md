# istat_codici_comuni

**Ente/fonte:** ISTAT — Codici statistici delle unità amministrative territoriali
**Percorso leggibile:** istat.it → Metodi e classificazioni → "Codici statistici
delle unità amministrative territoriali: comuni, città metropolitane, province e
regioni" → "Elenco dei comuni italiani" (csv)
**Link pagina:** https://www.istat.it/it/archivio/6789
**Link diretto csv:** https://www.istat.it/storage/codici-unita-amministrative/Elenco-comuni-italiani.csv
**Come riscaricare:** click sul link diretto; ISTAT lo aggiorna a ogni variazione
amministrativa (l'URL resta stabile)
**Data ultimo download:** <da compilare al download>
**Periodo coperto:** fotografia corrente dei comuni italiani
**Unità territoriale:** comune
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

- `Elenco-comuni-italiani.csv` — separatore `;`, encoding latin1; colonne chiave:
  "Codice Comune formato alfanumerico" (= PRO_COM_T, 6 cifre), "Codice Catastale
  del comune" (es. E438), "Denominazione in italiano"

**Uso nel repo:** transcodifica codice catastale MIM → codice ISTAT in
`ingestione/02_prep_mim_studenti.R` (sezione 2)

**Note/insidie:** i nomi colonna possono variare leggermente tra edizioni →
se l'ingestione dà errore sulla `select`, verificare qui i nomi correnti

**Storico aggiornamenti:**

- 2026-07-19 fonte individuata (nessun download ancora)
