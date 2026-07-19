# Piramidi dell'età (provincia di Parma, ER, Italia)

**Fonte:** ISTAT — Censimento permanente della popolazione, edizione 2024
(singole età aggregate in classi quinquennali; via API SDMX, vedi
`dati/grezzi/istat_cens/_metadati.md`)
**Anno dati:** 2024
**Ultimo aggiornamento:** 2026-07-19 (collaudato: palette bilancio di missione
per maschi/femmine, caption standard)
**Output principali:** `output/piramide_pr_vs_er|pr_vs_it|er_vs_it.png/.rds`
(confronti territoriali) + `output/piramide_pr|er_cittadinanza.png/.rds`
(tre pannelli: Totale | Italiani | Stranieri)

# Messaggio

- **La piramide è una trottola, non una piramide**: la massa sta nelle classi
  50-59 (oltre il 4% della popolazione per sesso in ciascuna classe), la base
  0-4 è sotto il 2% — il ricambio generazionale non c'è. Nelle età oltre gli
  85 anni le donne sono nettamente più numerose degli uomini.
- **Parma è appena più giovane del profilo regionale**: rispetto al contorno
  ER la piramide parmense "sborda" leggermente nelle classi giovani e
  giovani-adulte (25-44) ed è un filo più snella in quelle anziane — una
  differenza piccola ma coerente con l'età media sotto la media ER.
- **Due popolazioni con forme opposte**: la piramide degli italiani è una
  trottola invecchiata (massa a 50-64), quella degli stranieri è concentrata
  nelle età da lavoro e da famiglia (massa a 30-49, con il picco a 35-39 oltre
  il 5% per sesso) e con una base larga: tra gli stranieri gli over 65 sono il
  6% contro il 27% degli italiani, i minori di 15 anni il 18% contro l'11%.
  È l'immigrazione a puntellare le classi giovani della piramide totale.

**Note di metodo:** quote calcolate sulla popolazione totale (M+F) di ciascun
territorio, così territori di taglia diversa sono confrontabili; barre =
territorio target, profilo scuro = territorio di confronto; nei pannelli per
cittadinanza le quote sono sul PROPRIO gruppo (si confrontano le forme, non le
taglie); territori NUTS: `ITD52` = provincia di Parma, `ITD5` = Emilia-Romagna,
`IT` = Italia.
