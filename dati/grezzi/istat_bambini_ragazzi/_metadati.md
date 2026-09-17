# istat_bambini_ragazzi

**Ente/fonte:** ISTAT — Indagine "Bambini e ragazzi: comportamenti, atteggiamenti e progetti futuri", anno 2023
**Di cosa si tratta**: indagine campionaria sui ragazzi di 11-19 anni residenti in Italia (italiani e stranieri): relazioni con amici e famiglia, uso dei social, povertà educativa, cittadinanza e appartenenza, progetti futuri. Questionario online, rilevazione 1 ott - 20 dic 2023; circa 108.000 ragazzi contattati, 39.214 rispondenti; campione estratto dal registro della popolazione, stratificato per regione, cittadinanza, classe d'età (11-13, 14-19) e sesso. Serve alla sezione di contesto di `educ_ia` (uso dei social e relazioni online dei ragazzi)
**URL / API:** https://www.istat.it/tavole-di-dati/bambini-e-ragazzi-comportamenti-atteggiamenti-e-progetti-futuri/ (nessuna API: tavole xlsx in uno zip)
**Come riscaricare:** dalla pagina, a mano: `TAVOLE.zip` (https://www.istat.it/wp-content/uploads/2025/06/TAVOLE.zip) scompattato in `TAVOLE/`, più indice delle tavole, nota metodologica e glossario (pdf)
**Data ultimo download:** 2026-09-17
**Data di ultima pubblicazione:** 2025-06-30 (indice delle tavole sostituito il 2025-07-24 per correggere la numerazione)
**Periodo coperto:** 2023 (un solo anno; l'edizione precedente dell'indagine è del 2021, confrontabilità da verificare)
**Unità territoriale:** Italia e 5 ripartizioni (Nord-ovest, Nord-est, Centro, Sud, Isole). NESSUN dato regionale o provinciale nelle tavole
**Licenza:** CC BY 4.0 (ISTAT) — <verificare>

**File:**

- `TAVOLE/Tavole A/Tav.<n>_a.xlsx` (18 tavole) — serie più dettagliata: per sesso, cittadinanza, generazione migratoria, età e ripartizione. In uso: `Tav.8_a` frequenza con cui vedono gli amici nel tempo libero; `Tav.9_a` frequenza di relazioni online o telefoniche con gli amici; `Tav.10_a` profilo sui social network (tra chi usa internet); `Tav.11_a` uso di internet per fare nuove amicizie
- `TAVOLE/Tavole B/` (17 tavole, senza il sesso) e `TAVOLE/Tavole C/` (17 tavole, solo cittadinanza e ripartizione) — non usate. ATTENZIONE: la numerazione cambia tra le serie (il profilo social è 10.a ma 9.b e 9.c)
- `Indice-delle-tavole-statistiche_new.pdf`, `Nota-metodologica-1.pdf`, `Glossario.pdf`

**Note/insidie:** ogni tavola ha un solo foglio con tre blocchi in verticale (MASCHI, FEMMINE, MASCHI E FEMMINE), ciascuno con le stesse 22 righe; colonne = valori assoluti e poi valori percentuali, intestazione su due righe con celle unite. Le variabili di riga sono AFFIANCATE, non incrociate: c'è età × sesso e ripartizione × sesso, ma non età × ripartizione. L'età ha solo due classi (11-13, 14-19). La riga "Stranieri" compare due volte in ogni blocco (totale cittadinanza e totale generazione migratoria). Le tavole 10 e 11 hanno come base i ragazzi che usano internet, non tutti gli 11-19enni. Stima campionaria: leggere gli ordini di grandezza. Microdati a uso pubblico disponibili sul sito ISTAT (https://www.istat.it/microdati/indagine-indagine-su-bambini-e-ragazzi-comportamenti-atteggiamenti-e-progetti-futuri-microstat/; presenza della regione da verificare)

**Storico aggiornamenti:**

- 2026-09-17 prima acquisizione (tavole 2023, pubblicate il 2025-06-30)
