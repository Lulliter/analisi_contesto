# Immobili ACER nei quartieri di Parma

**Fonte:** Comune di Parma, open data — "Immobili ACER di Parma 2022" (Politiche abitative, CC BY 4.0) e "Quartieri del Comune di Parma vigenti" (Uffici SIT e Toponomastica, CC BY 4.0)
**Anno dati:** 2022 (pubblicazione 2023-06-08); quartieri vigenti aggiornati al 2023-07-24
**Ultimo aggiornamento:** 2026-10-07 (prima versione del modulo, da collaudare)
**Output principali:** `output/mappa_acer_quartieri` (sunto per quartiere con riquadro della provincia), `output/plot_acer_quartieri`, `output/mappa_acer_<quartiere>` (13 mappe, una per quartiere) (+ `acer_immobili.csv`, `acer_quartieri.csv`)

<Lettura del dato da scrivere dopo il primo giro di 01_dati.R / 02_output.R.>

Avvertenze:

- 1 punto = 1 edificio (indirizzo + civico), non 1 alloggio: la fonte non riporta quanti alloggi ha ogni immobile, quindi i conteggi per quartiere non misurano quante famiglie vi abitano.
- Gli immobili ACER descrivono dove si trova l'offerta di edilizia pubblica gestita da ACER, non dove si concentra il bisogno abitativo: per il bisogno servirebbero altri dati (domande e graduatorie ERP, sfratti, contributi affitto). Da verificare se l'elenco comprenda solo alloggi ERP o anche altre tipologie gestite da ACER.
- Il conteggio per quartiere non tiene conto né della superficie né degli abitanti dei quartieri.
- 21 indirizzi compaiono due volte nella fonte con dati identici (11 a Montanara, tra via Po e largo Otto Marzo): si mantengono come li conta la fonte, perché possono essere più unità allo stesso civico (scale, corpi di fabbrica).
