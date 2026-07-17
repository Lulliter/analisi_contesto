# Parma: analisi di dati di contesto

## Purpose of the project

Studying mission-relevant socio-economic data on Fondazione Cariparma's area of reach: Parma and its province.

+ Obiettivo di fondo per Piano Strategico del 2028? (da fare nel 2027):

  > D.A.: Quali sono delle criticità che emergono oggi che il PS 2024-27 non aveva? (Tenendo sotto controllo i 10 assi tematici dello strategico)

## Organizzazione del progetto

🔨 **Repo in ricostruzione** (dal 2026-07-17): struttura modulare a due strati, piano e indice di migrazione in [`CLAUDE_TODO.md`](./CLAUDE_TODO.md).

```
analisi_contesto/
├── R/                     # funzioni condivise (1 file = 1 funzione)
├── dati/
│   ├── grezzi/            # input per fonte, MAI scritti dal codice
│   └── puliti/            # rds puliti riutilizzabili da più moduli
├── moduli/                # 1 cartella = 1 unità di analisi: input → output + blurb
│   └── _template_modulo/  # modello da copiare per ogni nuovo modulo
├── sito/                  # Quarto website: compone gli output dei moduli per tema
│   └── temi/
├── dashboard/             # VECCHIA struttura (5 temi): materiale da migrare,
│                          #   esclusa dal render del sito
├── assets/                # stili, brand (loghi, tema revealjs), visual identity
├── bib/                   # bibliografia (Zotero: CRP_analisi_contesto.bib)
└── _extensions/           # estensioni Quarto (fontawesome)
```

Regole del flusso (a senso unico): `dati/grezzi → dati/puliti → moduli/*/output → sito`.
Ogni modulo scrive solo nel proprio `output/`; il sito legge e basta; i moduli si
nominano per fonte/indicatore, i temi vivono solo in `sito/`.

# TODO

+ 🔨 Migrazione per tema → checklist in [`CLAUDE_TODO.md`](./CLAUDE_TODO.md)
  + primo modulo pilota: `pop_piramide_eta` (da `dashboard/demographic_trends/`)
  + ricostruire lo strato "fondamenta" (shp + anagrafiche comuni) in `dati/puliti/`

+ Ridefinizione di TEMI / DIMENSIONI / INDICATORI
(Inspo vedi [`CRP_analisi_contesto.bib`](./bib/CRP_analisi_contesto.bib):
  1. Eurispes (Rapporto italia 2026)
  2. Intesa per il Sociale (MONITOR PER LA GEOGRAFIA DELLE FRAGILITÀ E DELLE DISUGUAGLIANZE)
  3. Welforum
  4. Bocconi ecc )

+ OIS sintesi posizionamento Prov PR su assi tematici (as of Dicembre 2025)
  [Legenda: Criticità bassa 🟢 | Criticità media 🟡 | Criticità alta 🔴]

  + 🟢 demografia
  + 🟢 economia
  + 🟡 servizi sociali-disabilità
  + 🟡 servizi sociali-anziani
  + 🟡 condizione abitativa
  + 🟡 cultura e patrimonio
  + 🟡 biblioteche
  + 🟢 ambiente
  + 🟢 istruzione
  + 🟢 prima infanzia
  + 🔴 ricerca innovazione
  + 🟢 terzo settore

# Temi `interni`

+ **la valutazione d'impatto**
  1. in generale nel terzo settore
  2. FCRPR
  3. i nostri Enti

+ **AI e privacy**
  1. in generale nel terzo settore
  2. FCRPR
  3. i nostri Enti


## Temi `esterni`

#### TREND DEMOGRAFICI
+ **piramide età** (FACETED x comune di ER) [https://rfortherestofus.com/2024/07/population-pyramid-part-1](https://rfortherestofus.com/2024/07/population-pyramid-part-1)

+ Territori marginalizzati // Mappe di ....
  + 🟦 aggiungo layer `aree interne`
  + 🟦 aggiungo layer `comunità montane`
  + aggiungo layer `Distretti`

> Andrea: però OKKIO perchè se vuoi mostrare la corrispondenza tra bisogni e territori, devi tener presente che molto di quelli che diamo a Parma (e.g. Ospedale, Università) poi serve in realtà tutta la prov. quindi non ci sarà una corrispondenza...


#### DISABILITA'
> OIS: L'Assegno Unico Universale (AUU) è un sostegno economico per le famiglie con figli a carico, garantito a tutti i nuclei indipendentemente dalla condizione: (...) **per i figli con disabilità, il beneficio è senza limiti di età**
▪ L'importo dell'assegno associato alla presenza di figli con disabilità risulta più contenuto rispetto al dato nazionale**i nuclei con figli con disabilità, percepiscono un importo medio mensile inferiore a quello nazionale e regionale**


+ è vero che qui non c'è la presa in carico? (Elena Saccenti)
  + [ReportER] ADI (x distretto)
  + [ReportER] SMAC Disabili ≠ SMAC Anziani
  + [Inps] AUU - spaccato per "figli disabili"
  + [Istat Esplora Dati] https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0800SSW,1.0/SSW_SOCSE/DCIS_SPESESERSOC1

#### SANITA'
+ mobilità sanitaria
  + fetta di stranieri
  + in realta prima venivano di più di adesso...
+ qualità
+ liste d'attesa?
+ medici e infermieri?
+ badanti che mancano dopo questa generazione non si troverannno più neanche quelle

#### POVERTÀ ABITATIVA
- case dlel'ospedale adesso vuote?
- è un problema sia di quantità che di qualità

#### LAVORO POVERO


#### Imprenditorialità

- startup innovative
- imprese sociali
- AI e automazione

### Revision ex Intesa SanPaolo


CAPITALE UMANO

  + 🟢 **Popolazione e trend demografici**
    + Andamento demografico
    + Mortalità non per vecchiaia
  + 🟢 **istruzione (e formazione)**
    + Livello d'istruzione
    + Processi formativi

CAPITALE SOCIALE

  + ➡️ **Mercato del lavoro** ( _"uno dei cardini x la sfida delle disuguaglianze"_ )
    + uomini
    + donne
    + giovani
    + [immigrati/badanti]
  + **Redditi, ricchezza e consumi**
    + Consumi
    + reddito ( _"working poor"_ )
    + patrimonio
  + ➡️ **Inclusione sociale e vulnerabilità** ( _"incrociare dimensioni di esclusione e povertà"_)
    + disabilità
    + migranti
    + povertà abitativa (🟡 condizione abitativa)
    + povertà educativa
    + povertà materiale
    + sostegni economici alla fragilità
  + ➡️ **Legalità e sicurezza** ( _"Parma messa male?/ Atlante di Genere?"_ )
    + Istituti di pena
    + Reati
    + Sicurezza
    + Microcriminalità
  + **Presenza dell'economia sociale e capitale relazionale**
    + Capitale relazionale
    + civismo e (partecipazione alla vita) politica
    + 🟢 (organizzazioni del) terzo settore


CAPITALE ECONOMICO-ISTITUZIONALE

  + **Qualità e accesso ai servizi**
    + Servizi sanitari
    + Servizi non sanitari
      + 🟡 cultura e patrimonio
      + 🟡 biblioteche
    + servizi scolastici
      + 🟢 prima infanzia
    + Trasporti pubblici e mobilità sostenibile
  + **Risorse pubbliche, assistenza e servizi alle categorie fragili**
    + Risorse delle amministrazioni locali ( _capacità di spesa e dotazioni_  )
    + 🟡 servizi sociali-disabilità
    + 🟡 servizi sociali-anziani

  + 🟢 **Economia (Tessuto economico e aziende)**
    + Tessuto economico
    + 🔴 Ricerca innovazione
    - Internazionalizzazione
    - Competitività turismo
    - [startup innovative]
    - [AI e automazione]


CAPITALE NATURALE

  + 🟢 **ambiente e nuove fonti energetiche**
    + Caratteristiche ambientali e cambiamenti climatici
    + Qualità dell'ambiente e dei servizi ambientali
    + Sicurezza ambientale
    + Utilizzo di fonti rinnovabili
