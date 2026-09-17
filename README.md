# Parma: analisi di dati di contesto

# Obiettivo

Studiare e mettere a disposizione dati socio-economici rilevanti per la missione di Fondazione Cariparma, con focus su Parma e provincia, di aiuto per i ci tipo 

  + Piano Strategico 2024-27 (in corso, ma da riscrivere x il 2028-...)
  + Input per il Bilancio di Missione 2026 e seguenti
  
  > D.A.: Quali sono delle criticità che emergono oggi che il PS 2024-27 non aveva? (Tenendo sotto controllo i 10 assi tematici dello strategico)

# Metodo ristrutturazione repo 
Passare da una struttura organizzata per macro-temi (con confini poco netti tra dati,
analisi e presentazione) a una struttura modulare a due strati:

1. **`moduli/`** — unità di analisi autonome: `input` → `output` (grafico / tabella) + `blurb` (commenti x divulgazione)
2. **`sito/`** — spazio di composizione: combina gli output dei moduli secondo le esigenze
   del momento (i temi vivono qui e possono essere ridefiniti senza toccare i moduli)

I temi (ridefiniti il 2026-07-17, in sostituzione dei 5 temi della vecchia dashboard) sono composizione in `sito/`: l'aggiornamento avviene per FONTE (`ingestione/` e `moduli/`) e il vecchio tema "BES" non è più un tema a sé, i suoi indicatori si spalmano sui temi come fonte.

> Regole del "contratto" tra strati: sezione [Regole](#regole) qui sotto. Convenzioni di codifica: [`CLAUDE.md`](CLAUDE.md). Stato del lavoro tema per tema: [`_TODO.qmd`](_TODO.qmd).

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
├── sito/                   # Quarto website: SOLO legge da moduli/*/output/
│   └── temi/               # una pagina per tema, ricombinabile a piacere
├── assets/                 # css/scss, brand e logo Fondazione
├── bib/                    # bibliografia (collegata a Zotero)
├── docs/                   # output del sito (GitHub Pages) — generato, non editare
├── build.R                 # rigenera gli output di tutti i moduli
├── README.md               # questo file
├── _TODO.qmd               # diario di lavoro: stato tema per tema, fonti da acquisire
└── _toDONE.qmd             # voci chiuse di _TODO.qmd
```

# Regole

+ Flusso di **elaborazione dati** a senso unico: `dati/grezzi → (ingestione/) → dati/puliti → moduli/*/output → sito`
    + Ogni modulo scrive **solo** nel proprio `output/`
    + Il `sito/` legge e basta, non calcola
    + Un modulo non legge l'`output/` di un altro modulo. 
    + Se un dataset pulito serve a più moduli (e.g. mappe tematiche censimento), si "promuove": il codice che lo genera passa dal `01_dati.R` del modulo a uno script di `ingestione/`, e l'rds risultante va in `dati/puliti/` (in futuro, idealmente sotto targets). È l'unica eccezione ammessa
+ I **moduli si nominano** per ambito+indicatore in `moduli/` in modo che il nome "dica qualcosa" (es. `scuola_iscritti`, `pop_piramide_eta`) — deciso 2026-07-18. 
  Scioglie l'ambiguità "fonte/indicatore". La FONTE sta nel blurb e negli header degli script; l'aggiornamento per fonte si rintraccia via ingestione/ e blurb
  + In ogni `moduli/*/blurb.md`: fonte, anno dei dati, data ultimo aggiornamento — così l'aggiornamento annuale si riduce a "quali moduli hanno dati nuovi?" (qui ci sarà da capire un modo migliore, ma TBD)
+ I **temi** (instabili per costruzione) esistono solo in `sito/` 
+ **Licenza** (deciso 2026-09-15: contenuti CC BY 4.0, codice MIT, v. README): per ogni nuova fonte/modulo verificare la licenza dei dati grezzi e annotarla nel `_metadati.md`; se non è "solo attribuzione" (CC BY / IODL) va valutato prima se e come ripubblicare i dati derivati (la dicitura nei CSV/Excel scaricabili sta in `R/f_scarica_dati.R`)
+ **Home** (`index.qmd`): quando si aggiunge o promuove una pagina in `sito/temi/` (o si cambia un gruppo della navbar), aggiornare anche l'elenco dei temi e il callout "in preparazione" nella home. Nelle pagine di `sito/temi/` niente `date: last-modified`: il campo `description` del YAML dice fonti, anni dei dati e mese di estrazione, e va aggiornato quando si aggiornano i moduli della pagina
+ Le **funzioni** sono organizzate secondo logica della promozione dei dati: una funzione nasce LOCALE nello script che la usa; si promuove a generale (`R/`) alla seconda chiamata da uno script diverso (o se palesemente generica). Nel trasloco si ripulisce: tutto via argomenti, `R/` non conosce i moduli.
    + Mai `source()` orizzontali tra moduli: se serve a due, si promuove. In `R/`: 1 file = 1 funzione, nome file = nome funzione (prefissi: `istat_*` fonti, `f_*` helper viz/formato, `utilities.R` briciole) 
    + Così `R/` contiene solo funzioni con ≥2 utilizzatori, tutte vive

+ **Convenzioni di codifica**
  + Spostate in [`CLAUDE.md`](CLAUDE.md) il 2026-09-02 (sono istruzioni permanenti, non voci da spuntare). Stile di tabelle e grafici: skill `formatting-r` + `R/formatting.R`.


# Note riproducibilità

I dati **non sono sul repo remoto**: `dati/grezzi/` e `dati/puliti/` contengono file pesanti esclusi via `.gitignore`. Versionati solo i `_metadati.md` (uno per fonte in `dati/grezzi/`: URL, come riscaricare, periodo, insidie) e i `.gitkeep`.

Per ricostruire i dati: segui i `_metadati.md` per riscaricare i grezzi, poi rigenera `puliti/` e gli `output/` dei moduli con i rispettivi script.

Scorciatoia: `source("build.R")` rigenera gli `output/` di tutti i moduli e invalida `_freeze/sito` (necessario perché `freeze:auto` guarda solo i `.qmd`), poi si lancia `quarto::quarto_render()`.

Aspetto del sito: il tema è quello di default di Quarto/Bootstrap; le personalizzazioni (TOC, callout, colori navbar) stanno in `assets/styles/custom.css`. Il file `assets/styles/parma-theme.scss` contiene la palette Cariparma ma **non è collegato** in `_quarto.yml` (tema spento, ereditato da un altro progetto): serve solo come riferimento per i codici colore.

> Convenzioni e aggiornamento fonti: [`dati/README.md`](dati/README.md).

# Licenza

Testi, grafici, tabelle e dati derivati: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (la dicitura è inclusa nei CSV/Excel scaricabili, via `R/f_scarica_dati.R`). Codice: MIT (file `LICENSE`). Dati grezzi: restano soggetti alla licenza della fonte, indicata nel `_metadati.md` di ciascuna cartella di `dati/grezzi/`.

# TODO

🔨 Lavoro per tema in corso. Il diario — stato tema per tema, fonti da acquisire — sta in [`_TODO.qmd`](_TODO.qmd) (voci chiuse in [`_toDONE.qmd`](_toDONE.qmd)); entrambi si renderizzano a mano e restano fuori dal sito.

----------
