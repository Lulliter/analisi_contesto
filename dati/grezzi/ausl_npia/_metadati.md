# ausl_npia

**Ente/fonte:** AUSL di Parma — Dipartimento Assistenziale Integrato Salute Mentale e Dipendenze Patologiche (DAISMDP), "Report d'attività" annuale, a cura dell'Ufficio Sistema Informativo e Osservatorio sulle Dipendenze
**Di cosa si tratta**: report annuale del Dipartimento con una sezione sulla neuropsichiatria dell'infanzia e dell'adolescenza (NPIA): minori che accedono ai servizi e pazienti in carico (progetto terapeutico aperto) per distretto, età, sesso, cittadinanza e diagnosi, provincia di Parma. Documenti, non dataset: i numeri utili sono trascritti a mano in `npia_pr_serie.csv`. Unico indicatore con dato su Parma per il benessere mentale dei ragazzi (modulo `npia_utenti`, pagina `benessere_giovani.qmd`)
**URL / API:** sito AUSL Parma, pagina del DAISMDP https://www.ausl.pr.it/azienda/daismdp/default.aspx (il dominio non è leggibile da Claude: scarico a mano). Riferimento regionale (solo totale ER): slide "Riorganizzazione della salute mentale in Emilia-Romagna" (luglio 2024) https://salute.regione.emilia-romagna.it/notizie/regione/2024/luglio/riorganizzazione_della_salute_mentale_emilia-romagna.pdf
**Come riscaricare:** scarico manuale dei pdf dalla pagina del Dipartimento, un report per anno (esce in estate con i dati dell'anno precedente); il csv si aggiorna a mano aggiungendo le righe della nuova edizione
**Data ultimo download:** 2026-10-13
**Data di ultima pubblicazione:** 2025 (Report 2024)
**Periodo coperto:** 2010-2024 (in carico), 2012-2024 (accessi); edizioni 2014-2024, manca il report 2013 e precedenti
**Unità territoriale:** distretti socio-sanitari (Parma, Fidenza, Sud Est, Valli Taro e Ceno) e "Totale Provincia" (la riga AUSL/TOTALE dei report, nel csv come quinto livello della colonna `distretto`)
**Licenza:** documenti pubblici, licenza non dichiarata (citare la fonte)

**File:**

- `npia_pr_serie.csv` — TRASCRIZIONE A MANO (2026-10-13): formato lungo, una riga per anno × distretto × indicatore, con colonna `fonte` = edizione del report da cui viene il numero e `nota` per le incongruenze. Indicatori: `accessi` (utenti con almeno una prestazione, ogni età e residenza, Tab. 2, dal 2017), `accessi_residenti_0_17` e `tasso_accesso_x1000` (residenti 0-17 su popolazione 0-17, Tab. 3, dal 2012), `accessi_stranieri_0_17` e tasso, `pop_residente_0_17`, `in_carico` e `in_carico_nuovi` (progetto terapeutico aperto, dal 2010), `in_carico_eta_*` (6 classi, solo Totale Provincia, fino al 2022), `in_carico_stranieri` / `quota_stranieri_in_carico_pct`, `in_carico_femmine` / `quota_femmine_in_carico_pct`, `in_carico_autismo` (F84)
- `npia_diagnosi_2024.csv` — TRASCRIZIONE A MANO (2026-10-14) della tabella "Tipologia diagnosi principale" del report 2024 (p. 10): una riga = diagnosi, con n, %, età media, % femmine, % stranieri; unica modifica: maiuscole del report normalizzate. Fotografia di un solo anno: fino al 2021 le diagnosi in cartella non erano mutuamente esclusive, quindi un confronto con le edizioni precedenti è da verificare prima di farlo
- `sma_diagnosi_2024.csv` — TRASCRIZIONE A MANO (2026-10-14) della tabella "Diagnosi primaria" della salute mentale ADULTI, report 2024 (p. 13): stessa struttura del csv NPIA; riferimento macro, solo scarico
- `npia_sma_confronto_2024.csv` — sei indicatori 2024 minori (NPIA) vs adulti (SMA) come stampati nel report (p. 7, 9-10, 12-13; pagina e nota per riga): accessi, in carico, % sulla popolazione di riferimento, femmine, stranieri, prima diagnosi
- `report_2014.pdf` … `report_2024.pdf` — le 11 edizioni (nomi uniformati il 2026-10-22; in origine `Report_`, `REPORT_`, `report _2022`) (2015 è una scansione senza testo: i suoi dati vengono dalle edizioni 2016-2017, che li riportano come anni precedenti)
- `CARTA_SERVIZI_DAISMDP_2026.pdf`, `Quaderni_la_casa_primo_luogo_cura.pdf` — descrittivi, nessun dato di serie

**Note (come leggere i dati):**

- Due misure diverse: `accessi` = individui con almeno una prestazione nell'anno (anche una sola consulenza o valutazione medico-legale); `in carico` = persone con progetto terapeutico aperto. Non si sommano; affiancate vanno lette come imbuto (chi arriva → chi è preso in carico), non come lista d'attesa
- Geografia diversa tra tabelle: gli `accessi` per distretto sono attribuiti al distretto del SERVIZIO erogante; `accessi_residenti_0_17` e `tasso_accesso_x1000` sono per distretto di RESIDENZA (verificato sul report 2024; per gli in carico da chiedere all'AUSL)
- Denominatori dei tassi (popolazione residente 0-17): dati del Servizio Statistico della Provincia di Parma (statistica.parma.it), come dichiarato nei report; la Provincia pubblica online solo i totali per comune (vedi `dati/grezzi/prov_pr_statistica/`)
- "Stranieri": le tabelle dicono STRANIERI, ma il testo del report 2024 (p. 10) parla di "origine straniera" e confronta il 28% di pazienti stranieri con "circa il 30%" di minori stranieri residenti; per cittadinanza i minori stranieri della provincia sono il 20% (censimento 2024: 14.004 su 69.597). Base (origine o cittadinanza) da chiarire con l'AUSL; nel frattempo nelle tabelle "stranieri come definiti nel report"
<!-- Nei report, "stranieri" (tabelle accessi, in carico, diagnosi) indica la cittadinanza non italiana o l'origine straniera, compresi i minori nati in Italia da genitori stranieri? Il testo del 2024 (p. 10) confronta con "circa il 30%" di minori stranieri residenti, mentre per cittadinanza (ISTAT 2024) sono il 20%. -->
- Denominatore dei minorenni residenti: 4.655 in carico nel 2024 = 6,1% secondo il report → circa 76.000 minorenni; il censimento ISTAT 2024 ne conta 69.597 (6,7%): la popolazione della Provincia usata dall'AUSL è ~10% più alta dell'ISTAT
- 2020 anno Covid: in carico -22%
- La quota di minori in carico sul totale dei residenti 0-17 (5,3% nel 2023, 6,1% nel 2024) è calcolata dal report; la popolazione 0-17 per distretto c'è solo per 2017-2022
- VTC = Valli Taro e Ceno; Sud Est = Langhirano e dintorni; composizione comunale dei 4 distretti da ricostruire (tabella comune → distretto, voce in `_TODO.qmd`, Demografia)
- Nei grafici del modulo le serie partono dal 2017: primo anno con tutte le misure nella definizione corrente e tre punti pre-Covid (deciso 2026-10-14)

**Insidie (rotture di serie ed errori):**

BTW, le edizioni rivedono gli anni precedenti: nel csv vale l'edizione più recente, le differenze sono nella colonna `nota` del csv. 
- Revisione 2016 degli in carico 2013-14 (3.439/3.851 nell'edizione 2014 → 3.130/3.361 dal 2016, -9/-13%): la nota di metodo (p. 5 di entrambe) è identica, cambia solo la didascalia della tabella da "almeno una prestazione nell'anno" (report_2014 p. 18, Tab. 10) a "almeno una prestazione nel progetto nell'anno" (report_2016 p. 16, Tab. 11); motivo non dichiarato, da chiedere all'AUSL. Accessi 2012-2013 solo nella vecchia definizione, più bassa. In carico 2010-2012 solo nell'edizione 2014
<!-- Criterio di conteggio degli in carico. Tra il report 2014 (p. 18, Tab. 10, “progetti aperti con almeno una prestazione nell’anno”) e il report 2016 (p. 16, Tab. 11, “almeno una prestazione nel progetto nell’anno”) i minori in carico del 2013 e 2014 passano da 3.439 e 3.851 a 3.130 e 3.361. È cambiato il criterio di conteggio, e vale ancora oggi?-->
- Dal 2022 cartella regionale CURE anche in NPIA: possibile rottura di serie (es. Valli Taro e Ceno in carico 2023 = 245, contro 450 nel 2022 e 349 nel 2024); dal 2022 le diagnosi contano la sola principale
<!-- Valli Taro e Ceno 2023. Nel distretto i minori in carico passano da 450 (2022) a 245 (2023) e risalgono a 349 nel 2024 (report 2024, p. 9), con un calo più contenuto degli accessi (da 675 a 507). Il report non commenta il dato: c’è una spiegazione che possiamo riportare (organico del servizio, riorganizzazione, passaggio alla cartella clinica regionale)? E più in generale i dati 2022-2024 sono confrontabili con i precedenti? -->
- Le edizioni 2023 e 2024 sono più corte: Niente nuovi in carico, età e sesso solo come percentuali da grafico: le serie “nuovi” ed “età 0-17 per distretto” si fermano al 2022, quindi i grafici su età e tasso di accesso non arrivano all’ultimo anno. Non è un errore, è un buco: si risolve solo chiedendo le tabelle.
<!-- Tabelle 2023 e 2024. Le ultime due edizioni non riportano più, per la NPIA, alcune tabelle presenti fino al 2022: nuovi in carico per distretto, accessi dei residenti 0-17 con popolazione e tasso per distretto, pazienti in carico per classe d’età e sesso. Sarebbe possibile averle, anche come file Excel, per il 2023 e il 2024? -->
- Errori evidenti nei report, segnalati nella colonna `nota` del csv e CORRETTI SOLO IN CODICE (`moduli/npia_utenti/01_dati.R`, § 2b colonne `_calc`, applicate in § 2c nel dataset `npia_distretti_rev`): accessi Parma 2021 ripete il valore 2020; stranieri 2020 VTC/Sud Est invertiti; totale provincia 2014-2016 non stampato dall'edizione 2016. Il csv resta fedele a quanto stampato
<!--  Due probabili refusi. Report 2021, p. 15: gli accessi dei residenti 0-17 del distretto di Parma (2.396) ripetono il valore 2020 (report 2020, p. 17) pur con una variazione indicata del +17,9%. Report 2021, p. 17: i conteggi degli utenti stranieri 2020 di Valli Taro e Ceno (266) e Sud Est (109) sembrano invertiti, visti i tassi per 1.000 che ne risultano. Potete confermare i valori corretti?-->





**Storico aggiornamenti:**

- 2026-10-13 cartella creata; verificato che la Regione pubblica solo il totale regionale; Luisa scarica le 11 edizioni del report DAISMDP; Claude trascrive `npia_pr_serie.csv` e compila i metadati. Richiesta n. 5 all'AUSL sospesa: da riscrivere, se serve, dopo aver guardato i dati (tabelle in Excel, nuovi in carico ed età 2023-24)
