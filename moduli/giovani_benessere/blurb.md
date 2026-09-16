# Come stanno i giovani: salute mentale e soddisfazione (14-19 e 20-24 anni)

**Fonte:** ISTAT, Bes nazionale (aggiornamento 2026), indicatori per età e sesso dall'indagine "Aspetti della vita quotidiana" (stima campionaria): indice di salute mentale (MH), soddisfazione per le relazioni amicali, soddisfazione per la propria vita, giudizio positivo sulle prospettive future. Per età × sesso solo Italia; Emilia-Romagna, Nord-est e Italia solo come totale della popolazione (`bes_giovani_reg`)
**Anno dati:** 2016→2025 (salute mentale); 2005→2025 (amici); 2010→2025 (vita); 2012→2025 (prospettive)
**Ultimo aggiornamento:** 2026-09-15 (modulo scritto: 01_dati.R + 02_output.R; grafici da collaudare nella pagina `_educ_ia`)
**Output principali:** `plot_salute_mentale_14_19`, `plot_amici_14_19` (+ tabelle dati `bes_giovani_eta_sesso`, `bes_giovani_reg`)

# Messaggio

- **La pandemia ha colpito i giovani, non la popolazione nel suo insieme**: l'indice di salute mentale dei 14-19enni crolla nel 2021 (da 73,9 a 70,3) mentre quello dell'intera popolazione non si muove (68,1 nel 2019, 68,2 nel 2021, 68,5 nel 2025). Nel 2025 i 14-19enni (72,0) non sono ancora tornati al livello del 2019 (72,9).
- **Le ragazze stanno peggio e recuperano più lentamente**: 14-19enni femmine 70,6 nel 2019, 66,6 nel 2021, 69,3 nel 2025; i maschi 74,9 → 74,1 → 74,6, cioè quasi tornati. Il divario di genere è stabile, 5-6 punti a sfavore delle ragazze, in tutta la serie.
- **La coorte del lockdown si porta dietro il segno**: i 20-24enni (che nel 2020-21 avevano 15-19 anni) nel 2025 stanno peggio che nel 2019 (68,9 contro 70,4) e non mostrano recupero; per le 20-24enni femmine 67,1 contro 69,3.
- **Le amicizie: il lockdown è il minimo, ma per le ragazze la discesa parte dal 2012-13**: quota di 14-19enni "molto soddisfatti" delle relazioni con gli amici al 34,5% nel 2021 (era ~41% prima), poi risale al 40% nel 2025. Le ragazze però erano al 47% nel 2012 e sono al 37% dal 2018 (discesa graduale 2012-17, gradino 2017→2018), senza risalita; i ragazzi restano tra il 43% e il 49% per tutta la serie tranne il 2021 (34,6%) e recuperano (43,8% nel 2025). La discesa delle ragazze precede la pandemia ed è compatibile con quanto osservato in altri paesi sul benessere delle adolescenti (Twenge, Haidt; critici Orben & Przybylski, Odgers — riferimenti commentati in `_educ_ia.qmd`), ma con questi dati non si può attribuire a una causa: negli stessi anni c'è anche la seconda recessione (2012-14) e un possibile cambio di metodo dell'indagine.
- **Il quadro non è a senso unico**: soddisfazione per la propria vita (14-19: 56,9% nel 2019, 52,3% nel 2021, 56,4% nel 2025) e giudizio positivo sulle prospettive future (60,7 → 62,2 → 61,6) hanno la buca del 2021 ma un trend di fondo stabile o in crescita. Umore e relazioni peggiorano, la fiducia nel futuro no.
- **Emilia-Romagna**: disponibile solo il totale della popolazione (standardizzato per età), allineato all'Italia (68,5 contro 68,7 nel 2025): nessuna specificità regionale leggibile; per i giovani della regione, e a maggior ragione di Parma, il dato non esiste.

# Note

- Indice di salute mentale (MH): misura di disagio psicologico (psychological distress) ottenuta dai punteggi di ciascun individuo di 14 anni e più a 5 quesiti del questionario SF36, sulle quattro dimensioni ansia, depressione, perdita di controllo comportamentale o emozionale, benessere psicologico; scala 0-100, più alto = meglio. È benessere autoriferito, non una diagnosi.
- I valori per età e sesso sono tassi GREZZI (codice `01SAL003B`); quelli territoriali in `bes_giovani_reg` sono STANDARDIZZATI per età (codice `01SAL003`): stesso indicatore, i totali non coincidono (nota ISTAT). Non confrontare i due numeri tra loro.
- Stime campionarie: commentare trend e ordini di grandezza, non i decimali anno per anno.
- Il salto della soddisfazione per la propria vita tra 2011 e 2012 (14-19: 57 → 47) è da verificare, possibile cambio di metodo dell'indagine: per questo la serie non è in grafico.
