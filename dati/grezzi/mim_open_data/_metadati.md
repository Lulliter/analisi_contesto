# mim_open_data

**Ente/fonte:** MIM — Portale Unico dei Dati della Scuola, open data  \
**URL / API:** https://dati.istruzione.it/opendata/opendata/catalogo/  \
**Come riscaricare:** CSV a link diretto (liste per dataset qui sotto); un file per anno scolastico. Salvare in questa cartella coi nomi originali.  \
**Data ultimo download:** 2026-07-18 (42 file csv, ~270 Mb)  \
**Periodo coperto:** a.s. 2015/16 → 2024/25 (anagrafi scuole già a.s. 2025/26 e 2026/27)  \
**Unità territoriale:** SINGOLA SCUOLA (plesso, `CodiceScuola`); i file studenti NON hanno provincia/comune → si ricavano dal join con l'anagrafe scuole (`Provincia`, `CodiceComuneScuola` = codice catastale)  \
**Licenza:** IODL 2.0

---

## 1. Anagrafe scuole STATALI

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area SCUOLE → "Informazioni anagrafiche scuole statali"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0400SCUANAGRAFESTAT

File (basta il 2024/25 per il join con gli studenti; 13 Mb):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20242520250831.csv
- (futuri aggiornamenti: https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20252620250901.csv )

## 2. Anagrafe scuole PARITARIE

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area SCUOLE → "Informazioni anagrafiche scuole paritarie"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0410SCUANAGRAFEPAR

File (2 Mb):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20242520250831.csv
- (futuri aggiornamenti: https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20252620250901.csv )


### Anagrafi STORICHE (per il trend dei plessi, infanzia inclusa)

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset → Ambito Scuola → area SCUOLE → "Informazioni anagrafiche scuole statali" (oppure "... scuole paritarie") → tabella "formato CSV", una riga per anno scolastico  
**Link dataset:** statali https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0400SCUANAGRAFESTAT
| paritarie https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0410SCUANAGRAFEPAR

Servono per `plessi_trend_pr` (modulo `scuola_iscritti`): un file per a.s., statali (~13 Mb) e paritarie (~2-3 Mb). NB: 2017/18, 2025/26 e 2026/27 hanno il suffisso-data anomalo (0901 invece di 0831), gia' corretto qui sotto.

Statali (SCUANAGRAFESTAT):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20262720260901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20252620250901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20171820170901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFESTAT20151620160831.csv

Paritarie (SCUANAGRAFEPAR):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20262720260901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20252620250901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20171820170901.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/SCUANAGRAFEPAR20151620160831.csv

## 3. Iscritti (anno di corso e fascia d'età) — scuola STATALE

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area STUDENTI → "Studenti per anno di corso e fascia di età. Scuola statale"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0010ALUCORSOETASTA

File (~16-18 Mb/anno):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20171820180831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETASTA20151620160831.csv

## 4. Iscritti (anno di corso e fascia d'età) — scuola PARITARIA

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area STUDENTI → "Studenti per anno di corso e fascia di età. Scuola paritaria"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0020ALUCORSOETAPAR

File (~2 Mb/anno):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20171820180831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUCORSOETAPAR20151620160831.csv

## 5. Studenti per cittadinanza (italiana/straniera) — scuola STATALE

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area STUDENTI → "Studenti della scuola primaria e secondaria per cittadinanza. Scuola statale"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0050ALUITASTRACITSTA

File (~6-7 Mb/anno):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20171820180831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITSTA20151620160831.csv

## 6. Studenti per cittadinanza (italiana/straniera) — scuola PARITARIA

**Percorso leggibile:** dati.istruzione.it → Open Data → Catalogo Dataset →
Ambito Scuola → area STUDENTI → "Studenti della scuola primaria e secondaria per cittadinanza. Scuola paritaria"
**Link dataset:** https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/?datasetId=DS0060ALUITASTRACITPAR

File (~800 kb/anno; nomi verificati fino al 2022/23, gli altri seguono lo stesso
pattern — se un link desse 404, prendere il file dalla scheda dataset):

- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20242520250831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20232420240831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20222320230831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20212220220831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20202120210831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20192020200831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20181920190831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20171820180831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20161720170831.csv
- https://dati.istruzione.it/opendata/opendata/catalogo/elements1/leaf/ALUITASTRACITPAR20151620160831.csv

---

**Note/insidie:**

- i file studenti hanno SOLO `CodiceScuola`: provincia e comune si ricavano dal
  join con le anagrafi (per questo vanno scaricate)
- il dataset iscritti NON rileva la scuola dell'INFANZIA (dal tracciato:
  "Non sono rilevati dati relativi alla scuola dell'infanzia") → i trend
  coprono primaria + secondarie; per l'infanzia servirà altra fonte (o anagrafe
  regionale ER)
- il comune in anagrafe è il codice CATASTALE, non ISTAT → serve transcodifica
  (verificare se l'anagrafica comuni in dati/puliti ha il catastale, altrimenti
  aggiungerlo da SITUAS)
- copertura nazionale ESCLUSE province autonome TN/BZ (e AO per le anagrafi) —
  per PR irrilevante
- l'anagrafe paritarie ha tracciato più snello ma stessi campi chiave
  (`CodiceScuola`, `Provincia`, `CodiceComuneScuola`) → il join funziona uguale

**Storico aggiornamenti:**

- 2026-07-18 ricognizione e lista URL
- 2026-07-18 download completo (42 csv); sanity check ok: PR 2024/25 statali =
  308 plessi, 44 comuni, 49.570 alunni (no infanzia), 22,7% stranieri
