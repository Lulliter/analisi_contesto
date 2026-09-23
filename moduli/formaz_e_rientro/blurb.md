# Seconda chance: chi rientra in formazione da adulto nella provincia di Parma

**Fonte:** MIM — Portale unico dei dati della scuola, open data: iscritti per plesso dei corsi serali (percorsi di II livello) e delle sezioni carcerarie, a.s. 2015/16→2024/25 (`percorso == "seconda_chance"` da `ingestione/02`); CPIA di Parma, Bilancio di sostenibilità e sito (trascrizione a mano in `dati/grezzi/iefp_cpia_ER_PR/`)
**Anno dati:** a.s. 2015/16 → 2024/25 (serali e carcere); 2024/25 (CPIA, un solo anno)
**Ultimo aggiornamento:** 2026-09-23 (modulo nato, 01_dati.R da collaudare)
**Output principali:** `plot_rientro_porte_pr` (le tre porte, ultimo a.s.), `rientro_trend_pr`, `rientro_incidenza_prov_er`, `rientro_profilo_pr`, `rientro_sedi_pr`

# Messaggio

- **Circa 500 adulti l'anno tornano a scuola nei corsi serali** della provincia (8 sedi: 6 a Parma, Fidenza, Salsomaggiore), quasi tutti in istituti tecnici e professionali; erano 700 nel 2015/16, un calo di circa il 30% in dieci anni. È una controtendenza: in Italia i serali crescono da dieci anni (dal 2,3% al 3,2% della secondaria di II grado statale), mentre Parma passa dal 4,2% al 2,5%, sopra la media regionale (1,9%) ma ormai sotto quella nazionale. A questi si aggiungono 10-30 studenti l'anno nelle sezioni carcerarie (rilevate dal 2017/18).
- **Nove su dieci sono maggiorenni e più di un terzo è straniero** (2024/25: 179 su 502), una quota ben superiore a quella della scuola ordinaria (22%): il serale è anche una porta d'ingresso per chi arriva da fuori.
- **Il CPIA è la parte più grande e meno visibile**: oltre 3.000 iscritti in 162 gruppi (alfabetizzazione in italiano, licenza media, competenze di base), sei volte i serali, ma assenti dai dati aperti del Ministero; il numero viene dal bilancio di sostenibilità del Centro e va confermato.

**Note di metodo:** l'incidenza per provincia rapporta i serali alla secondaria di II grado ordinaria delle sole scuole statali (stessi dati MIM da entrambi i lati), così il confronto tra province è omogeneo. Le paritarie non hanno corsi serali rilevati (in Emilia-Romagna nessun plesso paritario di II grado ha più del 30% di iscritti sopra i 18 anni, a.s. 2024/25); le scuole private non paritarie ("recupero anni") non rilasciano titoli e non stanno nella fonte: è la seconda chance a pagamento, qui non misurabile. Restano fuori anche gli allievi IeFP negli enti di formazione (dati solo regionali, INAPP: 15.817 in Emilia-Romagna nel 2023/24) e quelli IeFP dentro gli istituti professionali (già nei conteggi ordinari, non distinguibili). Il CPIA non ha trend né dettaglio per età e cittadinanza: da richiedere al Centro.
