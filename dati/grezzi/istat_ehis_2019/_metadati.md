# istat_ehis_2019

**Ente/fonte:** ISTAT — Indagine europea sulla salute (EHIS) 2019. Due prodotti distinti: (1) tavole di dati "Condizioni di salute e ricorso ai servizi sanitari in Italia e nell'Unione europea" (ed. 2022), capitolo 3 "Limitazioni", con la loro documentazione; (2) report di sintesi "Le condizioni di salute della popolazione anziana in Italia, anno 2019" (luglio 2021)
**Di cosa si tratta**: limitazioni funzionali delle persone di 65 anni e più: difficoltà nelle attività di cura della persona (ADL: lavarsi, vestirsi, mangiare, alzarsi dal letto, usare il bagno) e nelle attività domestiche (IADL: preparare i pasti, fare la spesa, gestire farmaci e soldi, faccende), per gravità, sesso, classe d'età (65-74 / 75+), regione e ripartizione. È la base delle stime di "anziani non autosufficienti" (modulo `anziani_non_autosuff`, pagina Anziani) e della definizione usata dall'Osservatorio Long Term Care CERGAS Bocconi
**URL / API:** https://www.istat.it/tavole-di-dati/condizioni-di-salute-e-ricorso-ai-servizi-sanitari-in-italia-e-nellunione-europea-indagine-ehis-2019/ (tavole xlsx per capitolo); report di sintesi "Le condizioni di salute della popolazione anziana in Italia, anno 2019" (bib: `IstatAnziani2019`) https://www.istat.it/it/files/2021/07/Report-anziani-2019.pdf
**Come riscaricare:** a mano dalla pagina delle tavole; qui solo il capitolo 3 (gli altri capitoli e le tavole regionali ridondanti del vecchio repo restano in `temp/analisi_contesto_old/`)
**Data ultimo download:** 2025 (vecchio repo); spostati qui il 2026-10-19
**Data di ultima pubblicazione:** 2022 (tavole), 2021 (report); edizione EHIS successiva (2025) non ancora pubblicata al 2026-10
**Periodo coperto:** anno 2019 (stima campionaria)
**Unità territoriale:** Italia per sesso × classe d'età; regioni e ripartizioni solo per il totale 65+ (grezzo e standardizzato)
**Licenza:** CC BY 4.0 (ISTAT)

**File:**

(1) Tavole di dati EHIS 2019, ed. 2022 — https://www.istat.it/tavole-di-dati/condizioni-di-salute-e-ricorso-ai-servizi-sanitari-in-italia-e-nellunione-europea-indagine-ehis-2019/ :

- `ehis2019_3_limitazioni.xlsx` — LETTO DA SCRIPT dal 2026-10-20 (`moduli/anziani_non_autosuff/00_prep_prevalenze.R`: fogli 3.2.1, 3.3.1, 3.4.1). Capitolo 3, 175 fogli: 3.1 limitazioni sensoriali e motorie (15+), 3.2 ADL (65+), 3.3 IADL (65+), 3.4 gravi difficoltà ADL o IADL (65+), 3.5 mobilità. Fogli utili: 3.2.1 (ADL × sesso × età, Italia), 3.2.3/3.2.4 (ADL × regione, grezzo/standardizzato), 3.3.1/3.3.3/3.3.4 (IADL idem), 3.4.1/3.4.3/3.4.4 (ADL o IADL idem)
- `glossario_tavole_ehis2019.pdf`, `nota_metodologica_tavole_ehis2019.pdf`, `indice_tavole_cap_1_8.pdf` — documentazione delle tavole, scaricata dalla stessa pagina (nomi file dati nel vecchio repo, 2025)

(2) Report di sintesi, 14 luglio 2021 — https://www.istat.it/it/files/2021/07/Report-anziani-2019.pdf (bib `IstatAnziani2019`):

- `istat_report_anziani_2019.pdf` — scaricato 2026-10-19 (nome originale `Report-anziani-2019.pdf`, rinominato per coerenza con la cartella). LETTO DA SCRIPT (`moduli/anziani_non_autosuff/00_prep_prevalenze.R`, blocco [B]): p. 2 "I numeri chiave" → gravi difficoltà ADL per classe d'età (65-74, 75-84, 75+, 85+, 65+) e per sesso; la colonna "gravi limitazioni motorie, sensoriali e cognitive" della stessa tabella è la fonte della Tab. 1.2 CERGAS e lo script la usa come controllo incrociato. P. 7 (Nord-est, tassi standardizzati) resta solo nel csv di riscontro

Non grezzo, quindi NON qui: la trascrizione a mano delle prevalenze (CERGAS + ISTAT) sta in `moduli/anziani_non_autosuff/riscontro_prevalenze_a_mano.csv` e serve solo come riscontro dell'estrazione automatica (confronto in coda a `00_prep_prevalenze.R`, atteso nessuna differenza)

**Note (come leggere i dati):**

- Definizioni (glossario ISTAT): "gravi difficoltà" = la persona dichiara di avere molta difficoltà o di non riuscire affatto a svolgere l'attività; ADL = attività di cura della persona; IADL = attività domestiche. "Gravi limitazioni funzionali" (tav. 3.4) = gravi difficoltà in almeno una ADL o IADL
- Il CERGAS (Osservatorio LTC, bib `OLTC_8rapp_2026`, pdf in `dati/grezzi/cergas_oltc/`, cap. 1) chiama "anziani non autosufficienti" gli over 65 con gravi limitazioni funzionali: 28,4% in Italia, applicato alla popolazione 65+ di ogni anno (4,03 milioni nel 2023); per età 14,6% / 32,5% / 63,8%
- ATTENZIONE (verificato 2026-10-20): i valori per età del CERGAS (14,6 / 32,5 / 63,8; 28,4 in totale) nel report ISTAT p. 2 stanno nella colonna "gravi limitazioni motorie, sensoriali e cognitive", non in ADL o IADL. Le gravi difficoltà ADL o IADL (tav. 3.4.1) sono 12,2 (65-74) / 43,6 (75+) / 28,2 (totale): sul totale quasi coincidono, per età no. Il testo del report (p. 6) usa 28,4% anche per ADL o IADL ("circa 3 milioni 800mila"). Nel modulo: "non autosufficienti" = ADL gravi (10,6%); ADL o IADL dalla tav. 3.4.1
- IADL comprende "svolgere occasionalmente lavori domestici pesanti": è la difficoltà grave più frequente (25,7% degli over 65, report p. 6) e da sola porta la quota ADL o IADL vicino al 30%
- Standardizzate per età, Emilia-Romagna e Italia hanno la stessa prevalenza di gravi difficoltà ADL (9,3 vs 9,4); il grezzo ER (11,4 vs 10,6) riflette solo la struttura più vecchia. Il Nord-est standardizzato sta poco sotto l'Italia (8,0 ADL; 21,9 IADL): applicare le prevalenze nazionali a Parma è prudente, semmai leggermente per eccesso
- Totale 65+ ADL per sesso: uomini 7,1% (tav. 3.2.1; il report a p. 2 dice 7,5), donne 13,3% (le donne vivono più a lungo e con più anni di limitazione)

**Insidie:**

- Stima campionaria: nelle tavole il CV non è riportato; usare ordini di grandezza, non decimali
- EHIS intervista solo chi vive in famiglia: esclude chi vive in struttura (RSA, CRA), dove la non autosufficienza è la norma → le stime per prevalenza × popolazione residente sono per difetto, soprattutto tra gli 85+
- Le classi d'età delle tavole xlsx sono due (65-74 / 75+): per il 2036, quando crescono soprattutto gli 85+, servono le tre classi del report (lette dallo script)
- I "non indicato" (1-2%) sono esclusi dalle prevalenze: le % sono su 100 persone comprese le non risposte
- Le tavole regionali del vecchio repo (`temp/analisi_contesto_old/non_autosufficienza/`) replicavano queste con molti grafici: non portate qui

**Storico aggiornamenti:**

- 2026-10-20 tav. 3.2.1, 3.3.1, 3.4.1 lette da script; corretta la nota sulle prevalenze CERGAS (colonna "limitazioni motorie, sensoriali e cognitive"); aggiunta l'insidia sulle persone in struttura

- 2026-10-19 cartella creata spostando dal vecchio repo (`temp/analisi_contesto_old/data_in/istat_ehis_2019/`) solo il capitolo 3 e la documentazione; csv delle prevalenze a tre classi trascritto da OLTC 2026 e report ISTAT (spostato lo stesso giorno in `moduli/anziani_non_autosuff/riscontro_prevalenze_a_mano.csv`)
