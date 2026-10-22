# mim_ia_a_scuola

**Ente/fonte:** MIM, INDIRE, USR Lombardia — documenti ufficiali e indagini sull'introduzione dell'IA nella scuola
**Di cosa si tratta**: raccolta di documenti (non dataset) a supporto della pagina `educ_ia`: le Linee guida ministeriali per l'IA nelle scuole (versione 1.0, agosto 2025, e versione impaginata di ottobre 2025), un'indagine INDIRE sui docenti (2025, campione di volontari), un monitoraggio regionale (USR Lombardia, luglio 2025) e le Indicazioni nazionali dei licei (usate come riferimento sui contenuti digitali/IA nei curricoli).
**URL / API:** Linee guida: https://www.mim.gov.it/documents/20182/0/MIM_Linee+guida+IA+nella+Scuola_09_08_2025-signed.pdf ; INDIRE: <URL> ; Monitoraggio USR Lombardia: <URL> ; Indicazioni nazionali licei: <URL>
**Come riscaricare:** a mano dalle pagine sopra
**Data ultimo download:** 2025-09-21 (Indicazioni nazionali: 2026-04-22)
**Data di ultima pubblicazione:** 2025-08 (Linee guida v1.0, D.M. 166/2025); 2025-10 (versione impaginata); 2025-03 (INDIRE); 2025-07 (USR Lombardia)
**Periodo coperto:** a.s. 2024/25
**Unità territoriale:** Italia; Lombardia (monitoraggio)
**Licenza:** documenti pubblici MIM/INDIRE; verificare le condizioni di riuso prima di riprodurre tabelle

**File:**

- `MIM_Linee guida IA nella Scuola_09_08_2025-signed.pdf` — Linee guida v1.0 adottate con D.M. 166 del 9 agosto 2025 (chiavi bib `MIM_LineeGuidaIA`, `MIM2025dmIA`)
- `Linee guida IA scuole_IT 1.pdf` — stesso testo, edizione impaginata (ottobre 2025, 58 pp.)
- `INDIRE_Dati-indagine_IA_scuola.pdf` — INDIRE e La Tecnica della Scuola, "Utilizzo dell'intelligenza artificiale nella didattica", 12 slide di risultati (chiave bib `indireUtiizzoDellIntelligenzaArtificiale2025`); citato in `educ_ia.qmd` (83% dei docenti: usare l'IA con molta attenzione)
- `Monitoraggio regionale IA.pdf` — USR Lombardia, "Monitoraggio sull'introduzione dell'IA nelle istituzioni scolastiche della Lombardia", luglio 2025, 13 pp.; non ancora citato
- `INDICAZIONI NAZIONALI LICEI/` — pdf per indirizzo (premessa + 10 licei), aprile 2026; non ancora usati

**Note (come leggere i dati):** I pdf non sono dati: se servono numeri, estrarli con uno script `00_prep_<cosa>_pdf.R` del modulo (regola Fonti in pdf, `dati/README.md`).

**Insidie (rotture di serie ed errori):** l'indagine INDIRE è su un campione di volontari (docenti che hanno risposto), non rappresentativo: i numeri vanno presentati come percentuali tra i rispondenti.

**Storico aggiornamenti:**

- 2025-09-21 prima acquisizione (Linee guida, INDIRE, USR Lombardia)
- 2026-04-22 Indicazioni nazionali licei
