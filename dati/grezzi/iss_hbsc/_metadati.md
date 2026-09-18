# iss_hbsc

**Ente/fonte:** ISS, sorveglianza HBSC Italia (Health Behaviour in School-aged Children), rilevazione 2022; report regionale Emilia-Romagna e scheda tematica nazionale "Social media"
**Di cosa si tratta**: indagine campionaria quadriennale su studenti di 11, 13, 15 (e in ER anche 17) anni, questionario in classe. Qui SOLO tre indicatori, trascritti a mano dai pdf (2026-09-18): uso problematico dei social media (6+ criteri della Social Media Disorder Scale), videogiochi per almeno 4 ore in un giorno in cui giocano, uso problematico dei videogiochi (Internet Gaming Disorder Scale, punteggio >= 21). Per età e sesso, Emilia-Romagna 2022 (social anche 2018) e Italia 2022 (social). Serve come integrazione, a livello regionale, del modulo `giovani_ict_social` (pagina `educ_ia`): dati del 2022, campione regionale, ER nella media nazionale → sforzo misurato
**URL / API:** pagina ER https://www.epicentro.iss.it/hbsc/indagine-2022-emilia-romagna ; report ER https://www.epicentro.iss.it/hbsc/pdf/indagine-2022/emilia-romagna-2022.pdf ; scheda nazionale https://www.epicentro.iss.it/hbsc/pdf/temi2022/social-media-2022.pdf
**Come riscaricare:** a mano dal browser (il proxy non lascia scaricare da epicentro.iss.it in automatico); i pdf vanno rinominati come sotto. Prossima onda: 2026 (controllare se include domande sull'IA)
**Data ultimo download:** 2026-09-18
**Data di ultima pubblicazione:** pagina regionale del 2023-12-07 (dati 2022)
**Periodo coperto:** 2022 (social anche 2018)
**Unità territoriale:** Emilia-Romagna (nessun dato provinciale); Italia per confronto
**Licenza:** <verificare sul sito ISS (di norma CC BY-NC-ND per i contenuti EpiCentro)>

**File:**

- `hbsc_emilia_romagna_2022.pdf` — report regionale completo (122 pp.); i tre indicatori stanno nel cap. 8 "Social media e gaming" (pp. 95-99, figure 1-3)
- `hbsc_italia_social_media_2022.pdf` — scheda tematica nazionale (3 pp.): uso problematico dei social per età, sesso e regione
- `hbsc_italia_webinar_2024_vieno.pdf` — slide del webinar nazionale (materiale di lettura, non usato)
- `hbsc_2022.csv` — i tre indicatori in formato lungo: `indicatore`, `territorio`, `anno`, `eta` (11/13/15/17/Totale), `sesso` (M/F/MF), `valore` (%), `fonte_tabella`, `nota`

**Note/insidie:** stima campionaria (ER 2022: 4.204 studenti, 970/1.056/1.061/1.117 per età, 232 classi, risposta 99,1%; precisione dichiarata ±3,5%): leggere ordini di grandezza e differenze grandi (età, sesso), non i decimali. I valori delle figure sono stati letti dal testo estratto con pdftotext: due ambiguità segnalate nella colonna `nota` (totale maschi 2022 / femmine 2018 dei social; maschi 15 e 17 anni dei videogiochi). Il "60,8% degli adolescenti passa più di 3 ore davanti a uno schermo" del report regionale è la SOMMA delle quote per attività (video 16,6 + social 25,4 + videogiochi 18,8) e non una quota di adolescenti: NON usarlo. Il totale ER dei social nel report regionale include i 17enni; nella classifica nazionale la base è 11-15 (ER 12,2 vs Italia 13,5). Nel pdf restano, non trascritte, le tabelle sulle ore al giorno per attività (cap. 4, tab. 3-5), i contatti online con gli amici (cap. 8, tab. 1) e la stratificazione per FAS.

**Storico aggiornamenti:**

- 2026-09-18 prima acquisizione: pdf + csv dei tre indicatori
