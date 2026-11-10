# Famiglie per numero di componenti (comuni della provincia di Parma)

**Fonte:** ISTAT — Censimento permanente della popolazione, edizione 2024, tavola "Famiglie per numero di componenti - comuni" (`DF_DCSS_FAMIGLIE_TV_1`, scaricata a mano, vedi `dati/grezzi/istat_cens_famiglie/_metadati.md`); confini ISTAT al 01/01/2026
**Anno dati:** 2024 (famiglie al 31 dicembre)
**Ultimo aggiornamento:** 2026-11-09 (mappe di conteggio delle famiglie di 1 persona e numerose; tooltip delle % in forma "% di N famiglie"); prima versione 2026-11-06
**Output principali:** `output/mappa_<famiglie|pct_famiglie_1|pct_famiglie_numerose|famiglie_1|famiglie_numerose>_pr.png/.rds`; `output/famiglie_comuni.csv` (comuni + Italia, Emilia-Romagna, provincia di Parma)

# Messaggio

In provincia quattro famiglie su dieci sono di una sola persona, come in regione e poco più che in Italia (38%). Le persone sole pesano di più in montagna, dove in 13 comuni sono più della metà delle famiglie (fino al 64% a Monchio delle Corti), e a Parma (44%). Le famiglie numerose (5 o più componenti) sono poche ovunque (4%), un po' più frequenti nella Bassa e in pedecollina (Langhirano 8%, Sissa Trecasali 7%).

**Note di metodo:** famiglie censite, escluse le convivenze (case di riposo, istituti); famiglia di 1 persona = chi vive solo, a qualsiasi età (la tavola non ha l'età dei componenti); famiglie numerose = 5 o più componenti. Per Albareto e Monchio delle Corti la fonte non riporta le famiglie di 6+ componenti: poste a 0. Stessi indicatori delle mappe per quartiere (`comune_pr_quartieri`), ma fonte (censimento, non anagrafe comunale) e anno diversi, e gradini diversi.
