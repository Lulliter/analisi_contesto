# Piano di ristrutturazione del repo

> Creato: 2026-07-17 — Questo file è l'indice della migrazione: spuntare le caselle man mano.
> NB 2026-07-17: pulizia già fatta — rimossi `_targets/`, `presentazione/`, `ZZZ_old/`,
> `source/`, `analysis/`, `data/`, `_data_GDrive/` (tutto nel backup e/o in git history).
> Della vecchia struttura resta solo `dashboard/` (5 temi) come materiale da migrare.

# Obiettivo

Passare da una struttura organizzata per macro-temi (con confini poco netti tra dati,
analisi e presentazione) a una struttura modulare a due strati:

1. **`moduli/`** — unità di analisi autonome: `input` → `output` (grafico / tabella) + `blurb` (commenti x divulgazione)
2. **`sito/`** — spazio di composizione: combina gli output dei moduli secondo le esigenze
   del momento (i temi vivono qui e possono essere ridefiniti senza toccare i moduli)

Rispetto a prima, il flusso dei dati diventa a senso unico:

```
dati/grezzi/ ──▶ ingestione/ ──▶ dati/puliti/ ──▶ moduli/*/output ──▶ sito/
     │        (se multi-modulo)                    ▲
     └─────────────────────────────────────────────┘
              (se mono-modulo salto ingestione/)
```

# Struttura repo

```
analisi_contesto/
├── R/                      # funzioni condivise (resta com'è)
├── dati/
│   ├── grezzi/             # input come arrivano, organizzati per fonte. MAI scritti dal codice
│   └── puliti/             # rds puliti riutilizzabili da più moduli (da ingestione/)
├── ingestione/             # script numerati: grezzi → puliti (solo fonti multi-modulo)
├── moduli/
│   ├── _template_modulo/   # modello da copiare per ogni nuovo modulo
│   └── <nome_modulo>/      # 1 cartella = 1 unità di analisi (nome per FONTE/indicatore)
│       ├── 01_dati.R       # grezzi/puliti → rds pronto, salvato in output/
│       ├── 02_output.R     # → grafico / tabella, salvati in output/
│       ├── blurb.md        # 2-3 frasi di lettura + fonte + anno dati
│       └── output/         # tutto ciò che il modulo produce
└── sito/                   # Quarto website: SOLO legge da moduli/*/output/
    └── temi/               # una pagina per tema, ricombinabile a piacere
```

# Regole (il "contratto" tra strati)

+ Flusso di **elaborazione dati** a senso unico: `dati/grezzi → (ingestione/) → dati/puliti → moduli/*/output → sito`
    + Ogni modulo scrive **solo** nel proprio `output/`
    + Il `sito/` legge e basta, non calcola
    + Un modulo non legge l'`output/` di un altro modulo. 
    + Se un dataset pulito serve a più moduli (e.g. mappe tematiche censimento), si "promuove": il codice che lo genera passa dal `01_dati.R` del modulo a uno script di `ingestione/`, e l'rds risultante va in `dati/puliti/` (in futuro, idealmente sotto targets). È l'unica eccezione ammessa
+ I **moduli si nominano** per ambito+indicatore in `moduli/` in modo che il nome "dica qualcosa" (es. `scuola_iscritti`, `pop_piramide_eta`) — deciso 2026-07-18. 
  Scioglie l'ambiguità "fonte/indicatore". La FONTE sta nel blurb e negli header degli script; l'aggiornamento per fonte si rintraccia via ingestione/ e blurb
  + In ogni `moduli/*/blurb.md`: fonte, anno dei dati, data ultimo aggiornamento — così l'aggiornamento annuale si riduce a "quali moduli hanno dati nuovi?" (qui ci sarà da capire un modo migliore, ma TBD)
+ I **temi** (instabili per costruzione) esistono solo in `sito/` 
+ Le **funzioni** sono organizzate secondo logica della promozione dei dati: una funzione nasce LOCALE nello script che la usa; si promuove a generale (`R/`) alla seconda chiamata da uno script diverso (o se palesemente generica). Nel trasloco si ripulisce: tutto via argomenti, `R/` non conosce i moduli.
    + Mai `source()` orizzontali tra moduli: se serve a due, si promuove. In `R/`: 1 file = 1 funzione, nome file = nome funzione (prefissi: `istat_*` fonti, `f_*` helper viz/formato, `utilities.R` briciole) 
    + Così `R/` contiene solo funzioni con ≥2 utilizzatori, tutte vive

# Indice di migrazione (per tema)

Ordine consigliato: prima le fondamenta, poi un tema alla volta. Per ogni tema:
copiare `_template_modulo/`, portare dentro codice da `dashboard/<tema>/`,
recuperare gli input dal backup mettendoli in `dati/grezzi/` (per fonte).
I vecchi qmd di `analysis/` si recuperano dal backup o da git history.

## 0. Fondamenta organizzative

- [ ] Esisteva una parziale `_targets.R` (nel repo vecchio) ma sarà da ripensare — targets o semplici script di ingestione — almeno per scarico di dati da aggiornare periodicamente (IStat, SITUAS, ecc.)


> **TEMI RIDEFINITI da Luisa il 2026-07-17** (sostituiscono i 5 temi della vecchia
> dashboard), in ordine di priorità. Principio: **l'aggiornamento avviene per FONTE**
> (ingestione/ e moduli/), i temi sono composizione in `sito/`. Il vecchio tema "BES"
> smette di essere un tema a sé: i suoi indicatori si spalmano sui temi come fonte.
> Per ogni tema: fonti già in casa vs da cercare.

## 1. Aggiornamento delle fonti sui temi rilevanti

- [ ] [ONGOING] Da fare man mano che consulto le fonti -> organizzate in `moduli/`, con blurb e output pronti per il sito.  
  + Dettagli di come vengono organizzati i dati e ripensati i contenuti alla sezione "Temi" più in basso. 


## 2. Riorganizzazione dei Temi e preparazione pagine sito

- [ ] [ONGOING] Costruire `sito/` (index + una pagina per tema che include output e blurb dei moduli)
  + Dettagli di come vengono organizzati i dati e ripensati i contenuti alla sezione "Temi" più in basso. 
- [x] Sistema di download tabelle: FATTO e collaudato su `trend_demogr.qmd` e `scuola.qmd` (2026-07-21). Ogni grafico ha 2 bottoni CSV+Excel sotto-destra, via `R/f_bottoni_dati.R` + `R/f_scarica_dati.R` (dipendenza: `downloadthis`). Decisioni fissate: csv INTERNAZIONALE (virgola+punto, BOM) con titolo/fonte come righe `#` in testa; Excel = formato "sicuro" per gli italiani (tipi preservati) con foglio "Metadati"; nome file `<pagina>_<progressivo>`. NB patchwork: titolo/fonte stanno in `plot_annotation` (gestito da f_bottoni_dati).
  - [ ] Applicare ai moduli/pagine FUTURI (retrofit): ogni modulo salva un `.csv` per grafico accanto al `.rds` (v. Convenzioni)
 
# Convenzioni di codifica

- Nomi file e cartelle: minuscoli, parole separate da `_`
- Lingua: italiano coerente (loanword ormai standard tipo "output" ok)
- Codice: R base + tidyverse (purrr sì, lambda `\()` no), pipe nativa `|>`, commenti sugli step principali
- Stile codice: OK che sia sintetico, ma deve essere insieme leggibile da umano che vuole comunque ripercorrerlo e sta facendo analisi interattivamente (troppa astrazioen o una if function che compatta troppi passaggi mi rende difficile capire cosa succede). D'altra parte non vogliamo un codice verboso e ridondante, quindi: commenti sintetici, nomi oggetti chiari, funzioni brevi e con un solo compito.
- Ogni script: intestazione con `Input:`/`Output:` + sezione `# Parametri ---` in testa (anni, path, soglie: tutto ciò che si cambia all'aggiornamento annuale)
- TUTTE le funzioni si chiamano `f_...` (anche quelle locali negli script); script di pipeline con verbi inglesi brevi: `get_` / `clean_` / `prep_`
- Output datati nel contenuto (fonte e anno nel blurb), non nel nome file
- Nome file `.rds`/`.csv` salvato = nome dell'oggetto R che contiene (niente passaggi di riconoscimento in più)
- Grafici di trend: SEMPRE linea + pallino (deciso 2026-07-18); nei confronti multi-territorio i pallini vanno solo sulle linee evidenziate
- Negli script di output: preparazione dati del grafico SEPARATA dal grafico, con oggetto `<nome>_prep` prima di `plot_<nome>`/`mappa_<nome>` (2026-07-18)
- Serie di grafici omogenei (es. mappe tematiche): guidate da una tabella `tribble` "1 riga = 1 grafico", con classi/disegno/salvataggio automatici
- Ogni modulo salva un `.csv` per grafico accanto al `.rds` (stesso nome, o tabella condivisa da più grafici): serve ai bottoni di scarico dati nelle pagine di `sito/` (2026-07-21)
- Ogni pagina del sito avrà un chunk in testa come in `trend_demog.qmd` (`#| label: anteprima`) per consentirmi di visualizzare interattivamente 

---

# Temi 

I macro temi corrispondono + o - alle pagine del `sito/`. GLi item elencati corrispondono + o - ai `moduli/` di info cercate

## 1. Trend demografici (quasi fatto: si aggiorna/salva dal vecchio repo)

**Ricognizione/Aggiornamento FONTI**: fatto

**Ripensamento MODULI (connessi a fonti)**:

- [x] `ingestione/00_*.R` usate per preparare confini, shp per mappe ecc
- [x] `ingestione/01a_*.R` - `ingestione/01d_*.R` usate per preparare i dati censimento (decennali e singole età)  
- [x] `ingestione/02*.R` usate per preparare i dati del ministero istruzione 
- [x] `ingestione/00b_prep_pr_dettaglio.R` per Confini dettagliati per gli zoom PR: Com01012026 non generalizzato in
      grezzi ✓; 
- [x] Modulo `moduli/pop_mappe_tematiche`: % stranieri, densità (superficie SITUAS), % 65+, % 0-14 per comune
- [x] Modulo `moduli/pop_piramide_eta`: COLLAUDATO 2026-07-19 (PR vs ER/IT, ER vs IT con profilo in overlay + pannelli per cittadinanza; colori M/F originali)
- [x] Modulo `moduli/demo_trend_indicatori` (serie storiche): ricostruiti grafici con trend popolazione e indicatori totale, stranieri, 65+, 0-14, densità (superficie SITUAS) per PR vs ER/IT; blurb scritto coi findings
- [x] Creare modulo con Dati IStat su popolazione forecast (ci sono gia in `dati/grezzi/istat_trend_demog/PREVISIONI_*` — ATTENZIONE: solo scenario MEDIANO, niente scenari alternativi; comuni solo >= 5.000 ab.)  
  - [x] prima ingestione: `ingestione/03_prep_istat_previsioni.R` → `dati/puliti/istat_previsioni/` (5 rds)
  - [x] poi modulo: `moduli/demo_trend_previs/` (p01 indice 2024=100, p02 assoluti province ER, p03 piramide PR 2050 vs 2024, p04 quota 65+/80+) + blurb
  - [x] pagina dedicata `sito/temi/_trend_demogr_previs.qmd` (invece che dentro trend_demogr.qmd) — DECISO 2026-07-21: pagina separata, con box di rimando reciproco da/verso trend_demogr
    - [x] PROMOSSA 2026-07-22: rinominata `trend_demogr_previs.qmd`, voce navbar "Previsioni 2050" in `_quarto.yml`
    - [x] box di rimando reciproco (trend_demogr ⇄ previsioni)
    - [x] aggiunti indicatori assistenza/filantropia: p05a/b/c 65+/80+ assoluti (grafici separati per PR/ER/IT), p06 dipendenza anziani, p07 nati/morti previsti
  - [ ] 80+ STORICO per confronto con previsioni: nell'xls indicatori c'è solo 0-14/15-64/65+ → scaricare da demo.istat.it la popolazione per singole età (serie storica; provare pochi anni per volta se il sito non regge il download unico)
  - [ ] SPERANZA DI VITA PREVISTA al 2050: non è nei file scaricati; esiste tra le ipotesi delle previsioni ISTAT ma a livello REGIONALE → nuovo download da demo.istat.it (la storica è già nei trend, p15/p16)


**Pagine `sito/temi/`**: 

- [ ] (DA ARRICCHIRE) `sito/temi/trend_demogr.qmd`
- [ ] (DA ARRICCHIRE) `sito/temi/trend_demogr_previs.qmd`
 
## 2.a Scuola e formazione (c'è un inizio; arricchire con fonti LOCALI)
> Non affrontato nello strategico PS 2024-2027, ma da presentare come "Driver di crescita e realizzazione delle persone" 

**Ricognizione/Aggiornamento FONTI**: 
Fonti in casa: `istat_alunni_disab` (a.s. 2024-25, dettaglio max REGIONE) ✓.

**Ripensamento MODULI (connessi a fonti)**: (bisogni Fondazione: trend generali + fragilità:
abbandoni, NEET, formazione continua, % stranieri per comune, studenti disabili;
mismatch domanda-formazione rimandato → fonte Excelsior, ponte col tema Lavoro):

- [x] Open data MIM (dati.istruzione.it, IODL, CSV per SINGOLA SCUOLA):
      SCARICATO in `dati/grezzi/mim_open_data/` (64 csv: iscritti + cittadinanza
      2015/16→2024/25, anagrafi 2015/16→2026/27) e ingerito; URL e percorso
      leggibile in `_metadati.md`
- [ ] ISTAT BES dei territori (ed. 2025): tavole PROVINCIALI con NEET, uscita
      precoce e formazione continua (stime campionarie, ok come ordine di
      grandezza) → DA SCARICARE per `istruz_formaz_neet`:
      https://www.istat.it/statistiche-per-temi/focus/benessere-e-sostenibilita/bes-dei-territori/
- [ ] USR-ER: report annuali alunni con disabilità con dettaglio provinciale →
      DA SCARICARE per `scuola_disab`: https://www.istruzioneer.gov.it/dati/open-data/
      (nel catalogo MIM un dataset disabilità per scuola NON è stato trovato
      con certezza — verificare col motore interno)
- [ ] Regione ER anagrafe studenti: successo/regolarità per provincia + iscritti
      INFANZIA (validazione e completamento) → DA ACQUISIRE:
      https://scuola.regione.emilia-romagna.it/anagrafi-regionali
- [ ] ISTAT nidi/prima infanzia (posti autorizzati per comune, report feb 2026)
      → DA SCARICARE:
      https://www.istat.it/comunicato-stampa/offerta-di-nidi-e-servizi-integrativi-per-la-prima-infanzia-anno-educativo-2023-2024/

**Ripensamento MODULI (connessi a fonti)**: `scuola_iscritti` (trend PR per ordine
scuola, italiani E stranieri incl. % per comune; fonte MIM), `istruz_formaz_neet`
(NEET/abbandoni/formazione continua PR vs province ER; fonte BES dei territori),
`scuola_disab` (regionale, dati in casa + USR-ER prov.)

- [x] `ingestione/02_prep_mim_studenti.R` ESEGUITO e collaudato (2026-07-19):
      produce `dati/puliti/mim_iscritti/` (scuole_anagrafe_er, scuole_anagrafe_storico_er,
      scuole_iscritti_er, scuole_iscritti_cittadinanza_er); transcodifica comuni
      sul codice catastale (327/327), nome comune ufficiale ISTAT
- [x] Modulo `scuola_iscritti` COLLAUDATO 2026-07-19: trend iscritti (totale +
      pannelli statale/paritaria), trend PLESSI con infanzia fino al 2026/27,
      % stranieri (province con media ER, comuni top+min con soglia 20%),
      3 mappe comunali + 2 mappe paritarie faceted (plessi con infanzia /
      iscritti senza); blurb scritto coi findings
- [ ] _Fonte da acquisire_: iscritti scuola dell'INFANZIA (il MIM non li rileva; l'anagrafe studenti Regione ER sì) — servono per completare trend e quote paritarie, che nell'infanzia sono il segmento capillare
- [ ] _Fonte da acquisire_:  Risultati test invalsi e grado di scolarizzazione  
- [ ] _Fonte da acquisire_:  Studenti disabili (dettaglio provinciale, USR-ER)  

**Pagine `sito/temi/`**: 

- [ ] (DA ARRICCHIRE) Pagina `sito/temi/scuola.qmd` ma 
  - [ ] da arricchire con dati sopra
  - [ ] riscrivere blurb con i dati aggiornati  


## 2.a ...formazione e innovazione 

> Ponte con tema lavoro e se il territorio sta perdendo terreno sull'innovazione (es. startup, brevetti, ecc.)
> PS 2024:2027 imprescindibile saper fare rete tra istruzione superiore / università / aziende e comunità 
  > - Focus sui giovani (Parma capitale dei giovani 2026) e sul mismatch domanda-formazione 

**Ricognizione/Aggiornamento FONTI**: 

- [ ] startup, brevetti, cervelli in fuga e attrattività, ecc. (REgione e bandi?) 
- [ ] mismatch domanda-formazione, nuove forme con cui si cerca il lavoro (es. Excelsior, Osservatori INPS, ecc.)
+ [ ] PMI che introducono innovazione ( Fonte: dati European Commission, 2023)
+ [ ] Investimenti in R&D OECD? 

**Ripensamento MODULI (connessi a fonti)**:
- [ ] Modulo `istruz_formaz_neet` (scaricare tavole BesT provinciali) → avrà una PAGINA separata (neet/abbandoni/formazione continua)

**Pagine `sito/temi/`**: 
- [ ] (DA FARE) `sito/temi/istruz_formaz_neet.qmd`

## 3. Lavoro e redditi da lavoro (tutto da fare)
> Non affrontato nello strategico PS 2024-2027, ma da presentare come "Driver di riscatto economico-sociale" 

Fonti candidate: ISTAT RCFL (occupati/disoccupati, livello prov), Osservatori INPS
(dipendenti, precariato, retribuzioni), MEF dichiarazioni IRPEF per comune,
ISTAT ASIA (imprese/addetti), CCIAA/Excelsior (domanda di lavoro).

**Ricognizione/Aggiornamento FONTI**: 

- [ ] RE-R Statistica 2026 (gia premasticati) `Emilia-Romagna terza regione italiana per reddito medio complessivo nell'anno di imposta 2024` [qui](https://statistica.regione.emilia-romagna.it/studi-analisi/2026/redditi-irpef-emilia-romagna-anno-imposta-2024)
- [ ] RE-R Statistica 2026 (gia premasticati) `Povertà ed esclusione sociale in Emilia-Romagna nel 2025`
[qui](https://statistica.regione.emilia-romagna.it/studi-analisi/2026/rischio-poverta-esclusione-sociale-2025)


**Ripensamento MODULI (connessi a fonti)**:

- [ ] xxxx

**Pagine `sito/temi/`**: 

- [ ] (DA ARRICCHIRE)  
- [ ] (DA FARE)  



## 4. Fragilità economica 

> Da PS 2024-2027 si citano le nuove forme (oltre a povertà materiale) di 
  - povertà lavorativa
  - povertà sanitaria
  - povertà educativa * (link a educazione)
  - povertà abitativa
  - [nuove forme di povertà (es. digitale, relazionale, ecc.) indotte da AI?]

Fonti candidate: INPS (AUU, ADI/sostegni), MEF IRPEF (distribuzione, redditi bassi), ISTAT EU-SILC (povertà, livello reg), Caritas, Regione ER (fondo affitto, ERS), OMI (canoni). Salvare gli appunti tematici del README (povertà abitativa, AUU/OIS).

**Ricognizione/Aggiornamento FONTI**: 

- [ ] xxxx

**Ripensamento MODULI (connessi a fonti)**:

- [ ] xxxx
- [ ] Modulo `mappe_territori` (aree interne, comunità montane, distretti) - da arricchire/rivedere, e confrontare con mappe indici fragilià RE-R


**Pagine `sito/temi/`**: 

- [ ] (DA ARRICCHIRE)  
- [ ] (DA FARE)  


## 5. La fragilità e i bisogni sul territorio 

> PS 2024-2027: Un settore che fornisce un punto di osservazione provilegiato è l'abitare / i bisogni e le risorse si mconcentrano in alcune aree del territorio
> QUI VOGLIO METTERE TANTE MAPPE E ANALISI GEOLOCALIZZATE... 
 
Fonti in casa: `istat_sae_glf_2019` ✓ (stime GLF provinciali), aree interne/zone altimetriche/DEGURBA (già in anagrafica SITUAS ✓), singole età censimento (anziani); nel backup: EHIS 2019 (ADL/IADL), GALI 2023, ISTAT_DISAB_CIFRE. Da cercare: ReportER (ADI, SMAC), INPS AUU figli disabili.
 
**Ricognizione/Aggiornamento FONTI**: 

- [ ] RECUPERARE/CERCARE: spopolamento dei comnuni e aree interne 
- [ ] RECUPERARE/CERCARE: assenza/economicità dei servizi in certi comuni 
- [ ] RECUPERARE/CERCARE: trasporto pubblico sociale
- [ ] RECUPERARE/CERCARE: PRESIDI TERRITORIALIedi prossimità e ricomposizione sociale
- [ ] verde urbano e spazi pubblici, comportamenti sostenibili




**Ripensamento MODULI (connessi a fonti)**:

- [ ] Moduli: `disab_gali`, `disab_ehis_adl`, `anziani_soli`?, `territori_remoti`
      (da definire in ricognizione)

**Pagine `sito/temi/`**: 

- [ ] (DA ARRICCHIRE)  
- [ ] (DA FARE)  


## 6. Capitale istituzionale e sociale (istituzioni pubbliche, terzo settore, capitale relazionale)
> PS 2024-2027: La formazione, la crescita e la valorizzazione del capitale umano sono strettamente collegate alla rete di istituzioni di un dato territorio 

Fonti candidate: ISTAT spesa servizi sociali comuni (grezzi nel backup, ISTAT_SERVSOC),
BDAP/OpenCivitas (bilanci comuni), RUNTS + ISTAT censimento nonprofit (terzo settore),
BES (partecipazione civica, relazioni). Salvabile: `analysis/03_carica_bes.qmd` dal backup.

**Ricognizione/Aggiornamento FONTI**: 

- [ ] Settore sociosanitario (insofferenza e mancanza di personale)
- [ ] Ricognizione terzo settore (RUNTS) e bilanci
- [ ] Legge anziani ... come procede attuazione? 
- [ ] Servizi per l'infanzia (nidi, materne, centri estivi) e per la famiglia (centri famiglie, sostegno genitorialità)
- [ ]  Terzo settore e capitale relazionale (RUNTS, censimento nonprofit, BES indicatori partecipazione civica)
- 

**Ripensamento MODULI (connessi a fonti)**:

- [ ] Modulo `servsoc_spesa_istat` (cubo 2002-2022, dal backup)
- [ ] Modulo `bes_indicatori` (selezione domini pertinenti)


# Guardare esempi di altri 

Perimetro: parto da queste, per patrimonio decrescente, Nord-Centro:

1. Cariplo (Milano)
2.Compagnia di San Paolo (Torino)
3. Cassa di Risparmio di Torino
4. Cassa di Risparmio di Padova e Rovigo
5. Cassa di Risparmio di Verona Vicenza Belluno e Ancona (Cariverona)
6. Cassa di Risparmio in Bologna
7. Cassa di Risparmio di Cuneo
8. Cassa di Risparmio di Lucca
9. Cassa di Risparmio di Modena
10. Monte dei Paschi di Siena
11. Cassa di Risparmio di Firenze
12. Cassa di Risparmio di Trento e Rovereto (Caritro)
13. Cassa di Risparmio di Parma (Cariparma)
14. Cassa di Risparmio di Perugia
15. Cassa di Risparmio di Pisa / Livorno / Pistoia (le toscane minori, se il budget di ricerca lo consente)



---- 


