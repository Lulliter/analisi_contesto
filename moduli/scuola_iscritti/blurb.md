# Iscritti e scuole nella provincia di Parma (statali e paritarie)

**Fonte:** MIM — Portale unico dei dati della scuola, open data: iscritti per
plesso (a.s. 2015/16→2024/25, SENZA scuola dell'infanzia) + anagrafi scuole
(2015/16→2026/27, infanzia inclusa); comuni transcodificati a codici ISTAT via
Elenco comuni (codice catastale)
**Anno dati:** a.s. 2015/16 → 2024/25 (iscritti); → 2026/27 (plessi)
**Ultimo aggiornamento:** 2026-07-19 (modulo collaudato)
**Output principali:** trend `plot_iscritti_ordine_pr` + `plot_iscritti_ordine_gestione_pr`
+ `plot_plessi_ordine_gestione_pr`; stranieri `plot_stranieri_prov_er` +
`plot_stranieri_comuni_pr` (+ `_min`); mappe `mappa_<var>_comuni_pr` (plessi,
alunni, % stranieri) + `mappa_paritarie_plessi_pr` + `mappa_paritarie_iscritti_pr`
(+ tabelle csv omonime)

# Messaggio

- **Il calo demografico è entrato in classe dal basso**: primaria e secondaria
  di I grado perdono iscritti negli ultimi 5 anni, mentre la secondaria di II
  grado cresce ancora (l'onda dei nati fino al 2010 che risale i cicli).
  Totale provincia 2024/25: ~52 mila iscritti (no infanzia).
- **La scuola è il luogo dove si vede la Parma che cambia**: nelle statali gli
  alunni con cittadinanza non italiana sono il 22,7% (2024/25), con punte
  comunali molto più alte — Langhirano ~49%, Busseto ~39%, Colorno ~32% — e
  code basse nei comuni dell'Appennino. <!-- TODO: % complessiva con paritarie
  e confronto con la media ER, da leggere sul grafico province -->
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
convitti. Nei grafici comunali soglia di 300 iscritti per evitare percentuali
instabili; classi delle mappe a quintili provinciali o fisse (dichiarato nei
sottotitoli).
