# Iscritti nelle scuole della provincia di Parma (italiani e stranieri)

**Fonte:** MIM — Portale unico dei dati della scuola, open data (statali + paritarie; la scuola dell'infanzia NON è rilevata); dettaglio per singolo plesso aggregato a comune/provincia
**Anno dati:** a.s. 2015/16 → 2024/25
**Ultimo aggiornamento:** 2026-07-18 (bozza — DA COLLAUDARE dopo l'esecuzione di ingestione/02 + 01 + 02)
**Output principali:** `output/plot_iscritti_ordine_pr` (+ variante facet `plot_iscritti_ordine_gestione_pr`), `output/plot_stranieri_prov_er`, `output/plot_stranieri_comuni_pr`, e 3 mappe comunali `mappa_n_plessi_comuni_pr` / `mappa_alunni_comuni_pr` / `mappa_quota_stranieri_comuni_pr` (+ tabelle csv dei dati; i nomi delle mappe derivano da `mappe_indicatori` in 02_output.R)

# Messaggio
<!-- 2-3 frasi da scrivere guardando i grafici collaudati; attesi dal sanity check: -->

- Il trend degli iscritti (scuole statali + paritarie) mostra un lieve calo costante negli ultimi 5 anni nella primaria e secondaria di I grado, mentre gli ultimi 2/3 anni indicano un aumento degli iscritti alla secondaria di II grado. 
- Si nota che le scuole paritarie sono frequentate da una quota di alunni molto alta nella fascia 6-11 anni (primaria), che poi va a scendere nelle medie e superiori.
- Nel 2024/25 gli alunni stranieri sono ~23% nelle scuole statali della provincia (contro una media di ~18% in ER); a livello comunale l'incidenza è molto eterogenea: Langhirano ~49%, Busseto ~39%, Colorno ~32%

**Note di metodo:** % calcolate sul totale iscritti (no infanzia); i comuni con pochi alunni sono esclusi dal grafico comunale (soglia 300 iscritti) per evitare percentuali instabili.
