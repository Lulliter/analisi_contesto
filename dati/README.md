# dati/

Due sole categorie, flusso a senso unico (vedi [`CLAUDE_TODO.md`](../CLAUDE_TODO.md)):

- `grezzi/` — input come arrivano (download manuali o script di scarico), organizzati
  per fonte, con note/metadati accanto. **Nessuno script di analisi ci scrive.**
- `puliti/` — rds puliti riutilizzabili da più moduli (anagrafiche comuni, shapefile
  processati, serie storiche pulite). Scritti da targets / script di ingestione.

Il terzo livello ("data_out") non esiste come cartella centrale: ogni modulo in
`moduli/` salva nel proprio `output/`.

## Convenzioni per `grezzi/`

- Una cartella per fonte/dataset, un solo livello: `<ente>_<contenuto>[_<anno>]`
  (minuscolo con `_`; es. `istat_shp/`, `istat_ehis_2019/`, `inps_auu/`).
  L'anno nel nome solo per edizioni chiuse (censimenti, survey), mai per serie correnti.
- File grezzi: **mai rinominati, mai modificati a mano** — tengono il nome originale
  del download; le correzioni le fa il codice del modulo.
- Ogni cartella ha un `_metadati.md` (copiare [`grezzi/_template_metadati.md`](grezzi/_template_metadati.md)):
  fonte, URL, come riscaricare, data download, periodo, note/insidie, storico.
  I file grossi sono gitignorati, gli `.md` no → i metadati sono l'unica memoria
  versionata di cosa c'è (e come riottenerlo).
- Aggiornamento annuale: nuovo rilascio che sostituisce la serie → sovrascrivi il file;
  annata che si aggiunge → il nuovo file convive col vecchio. In entrambi i casi
  aggiornare "Storico aggiornamenti" nel `_metadati.md`.

