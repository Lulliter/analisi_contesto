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

> Regole complete del "contratto" tra strati, convenzioni di codifica e stato della migrazione: [`_TODO.qmd`](_TODO.qmd).

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

# Note riproducibilità

I dati **non sono sul repo remoto**: `dati/grezzi/` e `dati/puliti/` contengono file pesanti esclusi via `.gitignore`. Versionati solo i `_metadati.md` (uno per fonte in `dati/grezzi/`: URL, come riscaricare, periodo, insidie) e i `.gitkeep`.

Per ricostruire i dati: segui i `_metadati.md` per riscaricare i grezzi, poi rigenera `puliti/` e gli `output/` dei moduli con i rispettivi script.

Scorciatoia: `source("build.R")` rigenera gli `output/` di tutti i moduli e invalida `_freeze/sito` (necessario perché `freeze:auto` guarda solo i `.qmd`), poi si lancia `quarto::quarto_render()`.

Aspetto del sito: il tema è quello di default di Quarto/Bootstrap; le personalizzazioni (TOC, callout, colori navbar) stanno in `assets/styles/custom.css`. Il file `assets/styles/parma-theme.scss` contiene la palette Cariparma ma **non è collegato** in `_quarto.yml` (tema spento, ereditato da un altro progetto): serve solo come riferimento per i codici colore.

> Convenzioni e aggiornamento fonti: [`dati/README.md`](dati/README.md).

# Licenza

Testi, grafici, tabelle e dati derivati: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (la dicitura è inclusa nei CSV/Excel scaricabili, via `R/f_scarica_dati.R`). Codice: MIT (file `LICENSE`). Dati grezzi: restano soggetti alla licenza della fonte, indicata nel `_metadati.md` di ciascuna cartella di `dati/grezzi/`.

# TODO

🔨 Migrazione per tema in corso. Il diario di lavoro — piano, regole, convenzioni di codifica e stato tema per tema — sta in [`_TODO.qmd`](_TODO.qmd), che si renderizza a mano (`_TODO.html`) e resta fuori dal sito.

----------
