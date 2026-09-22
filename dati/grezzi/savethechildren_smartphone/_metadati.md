# savethechildren_smartphone

**Ente/fonte:** Save the Children Italia, su elaborazioni ISTAT dall'indagine "Aspetti della vita quotidiana"
**Di cosa si tratta**: quota di bambini di 6-10 anni che usano lo smartphone tutti i giorni, in tre bienni (2018-19, 2021-22, 2022-23). ISTAT non pubblica questa serie nei dati aperti (IstatData ha solo il possesso del cellulare da parte delle famiglie): i valori sono ripresi a mano da due comunicati stampa. Serve alla sezione "I dispositivi in mano a bambini e ragazzi" di `sito/temi/educ_ia.qmd` (modulo `giovani_ict_social`)
**URL / API:**

  1. comunicato 2023 (2018-19 = 18,4%; 2021-22 = 30,2%): https://www.savethechildren.it/press/infanzia-si-abbassa-sempre-di-piu-leta-cui-si-utilizza-uno-smartphone-e-il-43-dei-bambini-tra
  2. comunicato 10 aprile 2025, "Educare al digitale" (2022-23 = 32,6%; Nord 23,9%, Sud e Isole 44,4%): https://www.savethechildren.it/press/infanzia-e-digitale-circa-un-bambino-su-3-tra-i-6-e-i-10-anni-usa-lo-smartphone-tutti-i

**Come riscaricare:** non si scarica: `smartphone_6_10.csv` è scritto a mano dai due comunicati (una riga per biennio, colonna `fonte`)
**Data ultimo download:** 2026-09-22
**Data di ultima pubblicazione:** 2025-04-10 (comunicato "Educare al digitale")
**Periodo coperto:** 2018-19, 2021-22, 2022-23 (bienni)
**Unità territoriale:** Italia (nel 2022-23 anche Nord e Sud e Isole, non riportati nel csv)
**Licenza:** dati citati da comunicato stampa, con citazione della fonte

**File:**

- `smartphone_6_10.csv` — `periodo` (biennio), `anno_fine` (secondo anno del biennio, per l'asse x), `percentuale`, `fonte` (quale comunicato)

**Note/insidie:** misura l'USO quotidiano, non il possesso di uno smartphone personale. I bienni sono medie di due anni di indagine (per avere campioni sufficienti su una classe d'età piccola). I due comunicati non dicono se le elaborazioni ISTAT sono identiche: il confronto 2021-22 → 2022-23 va letto con cautela. Stima campionaria. Manca un dato per gli 11-14 anni.

**Storico aggiornamenti:**

- 2026-09-22 prima acquisizione (valori da comunicati 2023 e 2025)
