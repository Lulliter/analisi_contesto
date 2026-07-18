# Mappe tematiche della popolazione (comuni ER)

**Fonte:** ISTAT — Censimento permanente della popolazione, edizione 2024
(via API SDMX, vedi `dati/grezzi/istat_cens/_metadati.md`); confini ISTAT al
01/01/2026, versione generalizzata
**Anno dati:** 2024 (popolazione); 2026 (confini — nessuna variazione di comuni ER dal 2019)
**Ultimo aggiornamento:** 2026-07-17
**Output principali:** `output/mappa_<quota_stranieri|dens_km2|quota_65p|quota_0_14|quota_minorenni>_<er|pr>.png/.rds` (versione ER e versione solo provincia di Parma, stesse classi)

<!-- 2-3 frasi di lettura da scrivere guardando le mappe, es.:
- dove si concentrano stranieri / anziani / bambini nella provincia di Parma
  rispetto al resto dell'ER
- il gradiente pianura-montagna (densità e invecchiamento)
-->

**Note di metodo:** classi = quintili della distribuzione comunale ER; densità
calcolata sulla superficie dei poligoni generalizzati (adeguata per mappe, non
per statistiche ufficiali di superficie — TODO: sostituire con superfici ISTAT);
"stranieri" = cittadinanza straniera + apolidi (codice FRGAPO); "minorenni" =
0-17 anni dall'indicatore dedicato del censimento (`RESPOP_MIN_AV`), non
derivabile dalle classi decennali.
