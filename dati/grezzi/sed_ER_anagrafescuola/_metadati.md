# sed_ER_anagrafescuola

**Ente/fonte:** Regione Emilia-Romagna — SED, anagrafe regionale delle scuole
**Di cosa si tratta**: elenco degli istituti scolastici (sedi) della provincia di Parma per anno scolastico: codice meccanografico, tipo (infanzia, primaria, …), statale/paritaria, indirizzo, comune, ambito, ente gestore, dirigente. È l'anagrafe delle SCUOLE, non degli studenti (per quella vedi `rer_anagrafe_studenti/`)
**URL / API:** <da inserire: pagina SED di scarico>
**Come riscaricare:** scarico manuale dal portale SED, filtro provincia = PR, un file per anno scolastico
**Data ultimo download:** <da inserire>
**Data di ultima pubblicazione:** aggiornamento continuo (anagrafe amministrativa)
**Periodo coperto:** a.s. 2024/25, 2025/26, 2026/27
**Unità territoriale:** singola scuola (provincia di Parma)
**Licenza:** <da verificare sul portale>

**File:**

- `AnagrafeScuole_PR_2024_2025.txt` — ~160 sedi, tab-delimited, UTF-8 con BOM, header su 1 riga
- `AnagrafeScuole_PR_2025_2026.txt` — idem
- `AnagrafeScuole_PR_2026_2027.txt` — idem (~158 sedi)

**Note/insidie:** separatore tab e BOM iniziale (`readr::read_tsv()` lo gestisce); campo `Nome` con virgolette doppie interne; include paritarie (assenti o parziali nei file studenti MIM); non ancora usato da nessun modulo

**Storico aggiornamenti:**

- <AAAA-MM-GG> prima acquisizione (Luisa)
- 2026-10-13 metadati compilati a posteriori
