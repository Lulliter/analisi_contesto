# Osservatorio Dati Sociali — modelli di riferimento e scelte iniziali

Nota di lavoro. Punto di partenza per il README del progetto.
Contesto: osservatorio dati socio-economici interno a una fondazione, territorio di Parma / Emilia-Romagna, gestito da una persona sola, in un ambiente con data governance poco matura.

---

## 1. Il vincolo che decide tutto

Il collo di bottiglia non sono le idee di prodotto (quelle ci sono già, la filosofia è quella di Openpolis / Urban / Candid). Il vincolo reale è duplice:

1. **Una persona sola.** Qualsiasi modello che presuppone un team va riletto, non copiato.
2. **Governance dei dati ferma.** Pubblicare dati aperti richiede un sì istituzionale che oggi non è scontato.

Ogni scelta qui sotto è filtrata da questi due vincoli. Il criterio non è "cosa è bello", ma "cosa è sostenibile da sola e difendibile internamente".

---

## 2. Principio guida: il portale è un output generato, non un sito da aggiornare

È la lezione dell'**Urban Institute**, che ha risolto esattamente questo problema con lo stack che uso già io (R, Quarto, Git): documentano dataset e variabili con libri Quarto e generano migliaia di pagine di metriche territoriali come siti Quarto. Il punto non è la scala, è il paradigma: le pagine non si curano a mano, si **rigenerano da codice**.

Tradotto sul mio caso:

- L'Osservatorio è un **progetto Quarto** versionato in Git.
- I dati di contesto (ISTAT, BES, dati provinciali ER) vengono presi, puliti e trasformati con **script R**.
- Il sito statico si **rigenera** con un `build.R` (o make), come già faccio per gli altri progetti.
- Deploy sul VPS via rsync, workflow che ho già in piedi.

Conseguenza pratica: **niente piattaforma dinamica con database**. Un database live richiede manutenzione, backup, sicurezza, uptime — cose che una persona sola non regge. Un sito statico rigenerato è manutenzione quasi zero tra un aggiornamento e l'altro.

---

## 3. La rosa dei modelli — cosa rubare da ciascuno

Ordinata secondo la mia priorità reale (reggere da sola > governance > stack > prodotto).

### Urban Institute — priorità 1 (reggere da sola)
- **Cosa rubare:** il paradigma "dati come artefatti generati". Documentazione dei dataset come parte del build, non come lavoro separato.
- **Perché per me:** stesso stack, sostenibilità da persona sola.
- **Cosa NON copiare:** la scala (migliaia di pagine) e il fatto che dietro c'è un team.

### Fondazione Agnelli / Eduscopio — priorità 1 + 2 (sostenibilità + metodo)
- **Cosa rubare:** due cose. (a) *Un prodotto-cardine annuale fatto benissimo*, non un osservatorio che promette tutto. Eduscopio è online dal 2014, gratuito, e fa una cosa sola ripetuta ogni anno. (b) *Pochi indicatori rigorosi ma comprensibili*, ciascuno con un **documento metodologico pubblico** accanto.
- **Perché per me:** il prodotto-cardine annuale è il modello di sostenibilità per chi è solo. Il documento metodologico è anche una difesa: rende il dato contestabile e quindi credibile.
- **Cosa NON copiare:** il team dedicato dietro il portale.

### Candid — priorità 2 (governance) + prodotto
- **Cosa rubare:** la **tassonomia**. Il loro Philanthropy Classification System (soggetto, popolazione, strategia di supporto, area geografica) permette di taggare e interrogare in modo coerente organizzazioni, grant e dati. Nato dalla fusione Foundation Center + GuideStar, il loro mestiere è rendere i dati *interoperabili*, non solo pubblicarli.
- **Perché per me:** se classifico da subito i miei grant e i dati di contesto con una tassonomia pensata bene, poi posso incrociarli. È il lavoro noioso che decide se tra tre anni l'Osservatorio è interrogabile o è un cimitero di PDF. Nessun consulente lo farà al posto mio.
- **Cosa NON copiare:** l'infrastruttura ad API (fuori scala). Ma la *logica di classificazione* sì, da subito.

### Openpolis — priorità 4 (prodotto), già padroneggiata
- **Cosa rubare:** l'architettura a due livelli — *dato di contesto* (raccolto ampio, aggiornato, pulito) separato da *approfondimento tematico* (i focus). È esattamente la mia struttura: base di contesto larga + focus sui temi dei grant.
- **Perché per me:** è la mia filosofia di prodotto. Ci metto poco perché è quello che già so fare.
- **Cosa NON copiare:** il volume e le 17 persone.

### Benchmark territoriali italiani (da guardare, non ancora aperti a fondo)
- **IRPET (Toscana), IRES (Piemonte), PoliS-Lombardia:** osservatori socio-economici territoriali regionali. Non sono fondazioni, ma il mestiere è il mio. Utili come riferimento su *quali indicatori di contesto* tenere e come strutturarli.
- **Osservatorio povertà educativa (Con i Bambini / Openpolis):** il gemello istituzionale più stretto — osservatorio tematico legato a erogazioni filantropiche. Da studiare come caso quasi identico al mio. *Da verificare a fondo.*

---

## 4. Il nodo consulenti — cosa chiedere e cosa rifiutare

Problema osservato: i consulenti presentano pacchetti chiusi (slide, dashboard Power BI a scatola nera). Sono inutili per me, perché mi consegnano un *output* invece di un *asset che possiedo e combino*. Non ho accesso ai dati grezzi sottostanti, quindi non posso incrociarli con i miei o con le mie idee.

**Regola per selezionare i consulenti:**

- **NO** a chi produce l'analisi (slide, report, dashboard chiuse). Quello è il lavoro che tengo in casa.
- **SÌ** a chi produce **pipeline**: un data loader, lo scraping di una fonte ostica, una funzione R riusabile, un pezzo di infrastruttura di deploy.
- **Criterio di accettazione di una consulenza:** *"Cosa mi resta in mano quando il consulente se ne va?"* Se la risposta è un file, è la scelta sbagliata. Se è **codice versionato che io posso rieseguire e modificare**, è quella giusta.

Il consulente giusto non guarda i dati al posto mio: mi mette in condizione di guardarli meglio da sola.

---

## 5. Governance dei dati aperti — scelte da fare all'inizio

Meglio nascere "aperti" che rincorrere l'apertura dopo. Da decidere subito:

- **Formati:** CSV (o TSV) + metadati, formati testuali versionabili in Git. Niente formati proprietari come output pubblico.
- **Licenza:** una licenza aperta standard (es. CC-BY) da associare a ogni dataset pubblicato.
- **Metadati:** ogni dataset accompagnato da descrizione di fonte, data di aggiornamento, definizione delle variabili. Il modello Agnelli (documento metodologico pubblico) applicato a ogni dato.
- **Tassonomia:** adottare da subito uno schema di classificazione (ispirato a Candid) per taggare dati di contesto e grant in modo che siano incrociabili.
- **Nodo politico:** la pubblicazione richiede un via libera istituzionale. Da affrontare presto e in modo esplicito — è il rischio più serio, più del lato tecnico.

---

## 6. Architettura del progetto (bozza)

Coerente con lo stack che uso già (R, Quarto, Git, VPS + rsync).

Due livelli di contenuto, come da modello Openpolis:

1. **Base di contesto** — dati socio-economici del territorio (Parma / ER), raccolti con scope ampio, aggiornati periodicamente. Ruolo: cornice di riferimento stabile.
2. **Focus tematici** — approfondimenti sui temi verso cui si indirizza la filantropia dei grant. Ruolo: collegare i dati alle scelte erogative.

Struttura tecnica (bozza da dettagliare):

- Progetto Quarto (website) versionato in Git, con `renv` per la riproducibilità.
- Script R di raccolta/pulizia dati, separati per fonte, con `----` sui commenti di sezione.
- `build.R` che orchestra: raccolta dati -> trasformazione -> render Quarto -> deploy rsync.
- Dati grezzi e dati puliti separati; i puliti pubblicati come open data con metadati.
- Sezione "metodologia" pubblica per ogni indicatore.

---

## TO DO

- [ ] Verificare a fondo l'Osservatorio povertà educativa (Con i Bambini / Openpolis) come caso gemello.
- [ ] Guardare IRPET / IRES / PoliS-Lombardia per la lista di indicatori di contesto territoriale.
- [ ] Definire la prima versione della tassonomia (soggetto / popolazione / area geografica / tema di grant).
- [ ] Scegliere licenza aperta e template di metadati per i dataset.
- [ ] Individuare il "prodotto-cardine annuale" — il primo output ripetibile in stile Eduscopio.
- [ ] Affrontare il nodo del via libera istituzionale alla pubblicazione dei dati.
- [ ] Impostare lo scheletro del progetto Quarto + `build.R`.
