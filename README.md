# Parma: analisi di dati di contesto

# Obiettivo

Studiare e mettere a disposizione dati socio-economici rilevanti per la missione di Fondazione Cariparma, con focus su Parma e provincia.

<!-- 
A supporto della preparazione di Documenti Strategici di Fondazione Cariparma a:

  + Piano Strategico 2024-27 (in corso, ma da riscrivere x il 2028-...)
  + Input per il Bilancio di Missione 2026 e seguenti
  
  > D.A.: Quali sono delle criticità che emergono oggi che il PS 2024-27 non aveva? (Tenendo sotto controllo i 10 assi tematici dello strategico)
-->


# Organizzazione del lavoro 
Obiettivo: avere un progetto che facilita la riproducibilità e l'aggiornamento/aggiunta periodici di dati. La struttura è stata organizzata con approccio modulare a due strati:

1. **`moduli/*`** — unità di analisi autonome: `input` → `output` (grafico / tabella) + `blurb` (commenti x divulgazione)
    + Dentro **`ingestione/*`** ci sono alcuni script dedicati a certi dati che sono un po' più complessi da scaricare e che danno output che possono essere riutilizzati da più moduli
2. **`sito/*`** — spazio di composizione che combina gli output dei moduli secondo le scelte del momento (i temi vivono qui e possono essere ridefiniti senza toccare i moduli)

Il flusso dei dati diventa a senso unico, previene dipendenze incrociate tra strati:

```
dati/grezzi/ ──▶ ingestione/ ──▶ dati/puliti/ ──▶ moduli/*/output ──▶ sito/
     │        (se multi-modulo)                    ▲
     └─────────────────────────────────────────────┘
              (se mono-modulo salto ingestione/)
```

> Regole del flusso tra strati: sezione [Regole](#regole) qui sotto. Stato del lavoro e _pending tasks_: [`_TODO.qmd`](_TODO.qmd).



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
└── _TODO.qmd               # diario di lavoro: stato tema per tema, fonti da acquisire
```

# Regole

+ Flusso di **elaborazione dati** a senso unico: `dati/grezzi → (ingestione/) → dati/puliti → moduli/*/output → sito`
    + Ogni modulo scrive **solo** nel proprio `output/`
    + Il `sito/` legge e basta, non calcola
    + Un modulo non legge l'`output/` di un altro modulo. 
    + Se un dataset pulito serve a più moduli (e.g. mappe tematiche censimento), si "promuove": il codice che lo genera passa dal `01_dati.R` del modulo a uno script di `ingestione/`, e l'rds risultante va in `dati/puliti/` (in futuro, idealmente sotto targets). È l'unica eccezione ammessa
+ I **moduli** si nominano per ambito+indicatore in `moduli/` in modo che il nome "dica qualcosa" (es. `scuola_iscritti`, `pop_piramide_eta`) — deciso 2026-07-18. 
  Scioglie l'ambiguità "fonte/indicatore". La FONTE sta nel blurb e negli header degli script; l'aggiornamento per fonte si rintraccia via ingestione/ e blurb
  + In ogni `moduli/*/blurb.md`: fonte, anno dei dati, data ultimo aggiornamento — così l'aggiornamento annuale si riduce a "quali moduli hanno dati nuovi?" (qui ci sarà da capire un modo migliore, ma TBD)
+ I **temi** (instabili per costruzione) esistono solo in `sito/` 
+ Le **funzioni** sono organizzate secondo logica della promozione dei dati: una funzione nasce LOCALE nello script che la usa; si promuove a generale (`R/`) alla seconda chiamata da uno script diverso (o se palesemente generica). Nel trasloco si ripulisce: tutto via argomenti, `R/` non conosce i moduli.
    + Mai `source()` orizzontali tra moduli: se serve a due, si promuove. In `R/`, script per RUOLO, non per funzione  -- e.g. `grafici.R` (temi, caption, mappe, salvataggio, girafe), `sito.R` (bottoni di scarico dati, solo pagine), `istat.R` (ingestione fonti ISTAT), ecc.
    + **Grafici del sito, tre regole** (controllate da `build.R`): 1) tema solo da `R/grafici.R` (`f_theme_sito()` e varianti `_trend`, `_mappa`, `_piramide`; mai `theme_minimal()`/`base_size` nei moduli); 2) larghezza unica `fig-width: 9` dal default di `_quarto.yml` (con 9 pollici 1 pt del tema = 1 pt a schermo; nei chunk solo `fig-height`, se serve più altezza); 3) sottotitolo "Indicatore: …" con la base esplicita e numeri italiani (`big.mark = "."` sempre con `decimal.mark = ","`). Le scelte del singolo grafico (assi inclinati, limiti, colori) stanno nel grafico
    + Così `R/` contiene solo funzioni con ≥ 2 utilizzatori, tutte vive
+ **Aspetto del sito**: il tema è quello di default di Quarto/Bootstrap; le personalizzazioni (TOC, callout, colori navbar) stanno in `assets/styles/custom.css`. Il file `assets/styles/parma-theme.scss` contiene la palette Cariparma ma **non è collegato** in `_quarto.yml` (tema spento, ereditato da un altro progetto): serve solo come riferimento per i codici colore.

<!-- 
+ **Convenzioni di codifica**
  + Spostate in [`CLAUDE.md`](CLAUDE.md) il 2026-09-02 (sono istruzioni permanenti, non voci da spuntare). Stile di tabelle e grafici: skill `formatting-r` + `R/formatting.R`.
-->

# Note riproducibilità

I dati **non sono sul repo remoto**: `dati/grezzi/` e `dati/puliti/` contengono file pesanti esclusi via `.gitignore`. Versionati solo i `_metadati.md` (uno per fonte in `dati/grezzi/`: URL, come riscaricare, periodo, insidie) e i `.gitkeep`.

Per ricostruire i dati: segui i `_metadati.md` per riscaricare i grezzi, poi rigenera `puliti/` e gli `output/` dei moduli con i rispettivi script.

Scorciatoia: `source("build.R")` rigenera gli `output/` di tutti i moduli e invalida `_freeze/sito` (necessario perché `freeze:auto` guarda solo i `.qmd`), poi si lancia `quarto::quarto_render()`.


> Convenzioni e aggiornamento fonti: [`dati/README.md`](dati/README.md).

# TODO

🔨 Lavoro per tema in corso. Il diario — stato tema per tema, fonti da acquisire — sta in [`_TODO.qmd`](_TODO.qmd) 

# Licenza

Testi, grafici, tabelle e dati derivati: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (la dicitura è inclusa nei CSV/Excel scaricabili, via `R/f_scarica_dati.R`). Codice: MIT (file `LICENSE`). Dati grezzi: restano soggetti alla licenza della fonte, indicata nel `_metadati.md` di ciascuna cartella di `dati/grezzi/`.


# Utilizzo IA

Nello sviluppo del codice R e nella predisposizione di alcuni testi descrittivi è stato usato un assistente di IA (Claude, Anthropic). Scelta delle fonti, elaborazioni, verifica dei risultati e commenti sono dell'autrice, che ne ha la responsabilità.

Contesto usato dall'assistente:

- `CLAUDE.md` (nella radice del progetto, non pubblicato): istruzioni su progetto, regole e modo di lavorare; lo scrive l'autrice, Claude propone modifiche
- Memoria: preferenze dell'autrice ricordate tra una sessione e l'altra; sta nell'account claude.ai (progetto analisi_contesto), si aggiorna in automatico, l'autrice la rivede ogni 2-3 mesi
- Skill: procedure ripetibili (`avanzamento` per il diario `_TODO.qmd`, `formatting-r` per tabelle e grafici); stanno nell'account claude.ai, Claude propone modifiche e l'autrice le salva



----------
