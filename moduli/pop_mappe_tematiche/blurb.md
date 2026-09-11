# Mappe tematiche della popolazione (comuni ER)

**Fonte:** ISTAT — Censimento permanente della popolazione, edizione 2024
(via API SDMX, vedi `dati/grezzi/istat_cens/_metadati.md`); confini ISTAT al
01/01/2026, versione generalizzata
**Anno dati:** 2024 (popolazione); 2026 (confini — nessuna variazione di comuni ER dal 2019)
**Ultimo aggiornamento:** 2026-09-11 (scritto il Messaggio dai dati di `pop_mappe_sf`)
**Output principali:** `output/mappa_<quota_stranieri|dens_km2|quota_65p|quota_0_14|quota_minorenni>_<er|pr>.png/.rds` (versione ER e versione solo provincia di Parma, stesse classi)

# Messaggio

- **Una provincia a due velocità, città e pianura da una parte, Appennino dall'altra**: 18 dei 44 comuni parmensi stanno nel quinto di comuni ER meno densi (sotto i 39 abitanti per km²) ma raccolgono appena 28 mila residenti su 456 mila (6%); il capoluogo da solo ne ha 199 mila (44%, 764 ab/km²). La densità media provinciale (132 ab/km²) è ben sotto quella regionale (198) proprio per il peso della montagna.
- **Stranieri sopra la media regionale, e non solo in città**: il 14,8% dei residenti ha cittadinanza straniera (ER 12,7%); 12 comuni su 44 stanno nel quinto più alto dell'ER, e in testa non c'è Parma (17,1%) ma la pedecollina della filiera alimentare (Calestano 20,7%, Langhirano 20,6%, Fornovo e Salsomaggiore 16,6%). In fondo l'Appennino interno, con il 3-4% (Albareto, Monchio, Corniglio, Tornolo).
- **Invecchiamento: la provincia è un po' più giovane della regione (65+ al 23,6% contro 24,9%), ma la media nasconde due estremi**: 12 comuni stanno nel quinto più giovane dell'ER (la cintura del capoluogo e la pedecollina: Torrile 18,3%, Colorno, Langhirano, Lesignano, Sala Baganza) e 14 nel quinto più vecchio, tutti in montagna, dove gli anziani sono quasi la metà dei residenti (Bore 47%, Monchio 44%, Tornolo 42%, Palanzano 41%) e i bambini 0-14 il 4-6%. I bambini si concentrano invece nella bassa e nella pedecollina (San Secondo 14,4%, Langhirano 14,0%, Colorno e Fidenza 13,7%); Parma città è nella media (12,3%, ER 11,8%).


**Note di metodo:** classi = quintili della distribuzione comunale ER; densità
calcolata sulla superficie dei poligoni generalizzati (adeguata per mappe, non
per statistiche ufficiali di superficie — TODO: sostituire con superfici ISTAT);
"stranieri" = cittadinanza straniera + apolidi (codice FRGAPO); "minorenni" =
0-17 anni dall'indicatore dedicato del censimento (`RESPOP_MIN_AV`), non
derivabile dalle classi decennali.
