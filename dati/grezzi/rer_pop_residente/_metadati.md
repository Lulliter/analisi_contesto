# rer_pop_residente

**Ente/fonte:** Regione Emilia-Romagna — Popolazione residente al 1° gennaio
**URL / API:** portale Statistica RER (https://statistica.regione.emilia-romagna.it/) — <precisare pagina esatta>
**Come riscaricare:** <precisare: estrazione self-service dal portale?>
**Data ultimo download:** 2026-07-04
**Periodo coperto:** popolazione al 01/01/2026
**Unità territoriale:** distretti sanitari / ambiti scolastici / comuni / ASL
**Licenza:** <verificare (dati aperti RER)>

**File:**

- `01_resident_Dist_ClasEts_Sesso_2026.csv` — per distretto sanitario, classi d'età, sesso
- `02_resident_AmbScol_ClasEts_Sesso_2026.csv` — per ambito scolastico
- `03a/03b_resident_Comune*_ClasEts_Sesso_2026.csv` — per comune (con/senza codice ISTAT)
- `04_resident_newASLClasEts_Sesso_2026.csv` — per ASL (nuova zonizzazione)
- `05a/05b_resident_Comune*ClasScuola_Sesso.csv` — per comune, classi d'età scolastica
- `06_resident_DistClasScuola_Sesso.csv` — per distretto, classi d'età scolastica

**Note/insidie:** csv con separatore `;`, header multipli (prima riga = titolo lungo con
elenco distretti, poi intestazioni su più righe con celle vuote); encoding non UTF-8
(caratteri accentati corrotti → leggere con latin1/Windows-1252); classi d'età diverse
tra file "ClasEts" (0-14, 15-39, 40-64, 65+) e "ClasScuola".

**Storico aggiornamenti:**

- 2026-07-04 prima acquisizione (popolazione al 01/01/2026)
