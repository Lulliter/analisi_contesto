# Parma: analisi di dati di contesto

# Obiettivo

Studiare e mettere a disposizione dati socio-economici rilevanti per la missione di Fondazione Cariparma, con focus su Parma e provincia, di aiuto per i ci tipo 

  + Piano Strategico 2024-27 (in corso, ma da riscrivere x il 2028-...)
  + Input per il Bilancio di Missione 2026 e seguenti
  
  > D.A.: Quali sono delle criticità che emergono oggi che il PS 2024-27 non aveva? (Tenendo sotto controllo i 10 assi tematici dello strategico)

# Metordo ristrutturazione repo 
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

# TODO

+ 🔨 Migrazione per temain corso... `...TODO.md`

----------
