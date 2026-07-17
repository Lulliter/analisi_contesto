# Piramidi dell'età (provincia di Parma, ER, Italia)

**Fonte:** ISTAT — Censimento permanente della popolazione, edizione 2024
(singole età aggregate in classi quinquennali; via API SDMX, vedi
`dati/grezzi/istat_cens/_meta.md`)
**Anno dati:** 2024
**Ultimo aggiornamento:** 2026-07-17
**Output principali:** `output/piramide_pr_vs_er|pr_vs_it|er_vs_it.png/.rds`
(confronti territoriali) + `output/piramide_pr|er_cittadinanza.png/.rds`
(tre pannelli: Totale | Italiani | Stranieri)

# Messaggio
<!-- 2-3 frasi di lettura da scrivere guardando i grafici, es.: -->

- La piramide di Parma "sborda" dal profilo ER/Italia negli strati più giovani (seppur di poco) 
- Tra i residenti stranieri della provincia gli over 65 sono il 6% contro il 27% degli italiani; i minori di 15 anni il 18% contro l'11%
 



**Note di metodo:** quote calcolate sulla popolazione totale (M+F) di ciascun
territorio, così territori di taglia diversa sono confrontabili; barre =
territorio target, profilo scuro = territorio di confronto; territori NUTS:
`ITD52` = provincia di Parma, `ITD5` = Emilia-Romagna, `IT` = Italia.
