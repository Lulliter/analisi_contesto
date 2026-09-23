# Iscritti e scuole nella provincia di Parma (statali e paritarie)

**Fonte:** MIM — Portale unico dei dati della scuola, open data: iscritti per
plesso (a.s. 2015/16→2024/25, SENZA scuola dell'infanzia) + anagrafi scuole
(2015/16→2026/27, infanzia inclusa); comuni transcodificati a codici ISTAT via
Elenco comuni (codice catastale)
**Anno dati:** a.s. 2015/16 → 2024/25 (iscritti); → 2026/27 (plessi)
**Ultimo aggiornamento:** 2026-09-23 (solo scuola in età scolare: fuori serali, CPIA, carcere, ospedale — v. note di metodo; prima: 2026-07-19, modulo collaudato)
**Output principali:** trend `plot_iscritti_ordine_pr` + `plot_iscritti_ordine_gestione_pr`
+ `plot_plessi_ordine_gestione_pr`; stranieri `plot_stranieri_prov_er` +
`plot_stranieri_comuni_pr` (+ `_min`); mappe `mappa_<var>_comuni_pr` (plessi,
alunni, % stranieri) + `mappa_paritarie_plessi_pr` + `mappa_paritarie_iscritti_pr`
(+ tabelle csv omonime)

# Messaggio

- **Il calo demografico è entrato in classe dal basso**: primaria e secondaria
  di I grado perdono iscritti negli ultimi 5 anni, mentre la secondaria di II
  grado cresce ancora (l'onda dei nati fino al 2010 che risale i cicli).
  Totale provincia 2024/25: ~51,7 mila iscritti (no infanzia, no corsi per adulti).
- **La scuola è il luogo dove si vede la Parma che cambia**: nelle statali gli
  alunni con cittadinanza non italiana sono il 22,6% (2024/25); contando anche
  le paritarie sono il 21,6% (11.175 su 51.747), contro il 18,7% della media
  regionale: Parma è seconda in Emilia-Romagna dopo Piacenza (25,2%). Punte
  comunali molto più alte — Langhirano ~49%, Busseto ~39%, Colorno ~32% — e
  code basse nei comuni dell'Appennino. (Verificato 2026-09-11 su `stranieri_trend_prov_er`, statali + paritarie; cifre riallineate 2026-09-23 al solo percorso ordinario, da riverificare al prossimo `build.R`.)
- **La paritaria è quasi solo infanzia**: 80 dei 104 plessi paritari sono
  scuole dell'infanzia, presenti in 21 comuni; negli altri ordini è un fenomeno
  concentrato (24 plessi in 5 comuni, ~2.700 iscritti, ~5% del totale). In
  diversi comuni le paritarie restano però un presidio importante — soprattutto
  per l'infanzia, dove in alcuni casi sono l'unica o la principale offerta locale.
- **La rete dei plessi è stabile**: nel decennio 2015-2026 nessuna ondata di
  chiusure — statali quasi immobili (lieve calo di primarie e superiori dal
  2022), le ~80 materne paritarie costanti. Bore e Valmozzola sono gli unici
  comuni senza scuole primarie o secondarie.

**Note di metodo:** gli iscritti MIM non rilevano la scuola dell'infanzia
(l'Anagrafe Studenti parte dalla primaria): i conteggi di PLESSI dall'anagrafe
scuole invece la includono. "Plessi" = sedi registrate in anagrafe (comprese
eventuali sedi senza iscritti); esclusi comprensivi (sedi direttive), CPIA e
convitti. Iscritti e plessi contano SOLO la scuola in età scolare: i corsi
serali (percorsi di II livello), il CPIA, le sezioni carcerarie e ospedaliere
(a Parma ~530 iscritti, 1% del totale) sono fuori, come nel ritardo scolastico
di `scuola_abband_neet`, e vengono trattati a parte nel modulo `formaz_e_rientro`
(classificazione `percorso` fatta in `ingestione/02`). Nei grafici comunali soglia di 300 iscritti per evitare percentuali
instabili; classi delle mappe a quintili provinciali o fisse (dichiarato nei
sottotitoli).
