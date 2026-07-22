# Previsioni demografiche al 2050 (scenario mediano)

**Fonte:** ISTAT — Previsioni della popolazione 2024-2050, SOLO scenario
mediano, base 1.1.2024 (demo.istat.it); download 2026-07-18
(`dati/grezzi/istat_trend_demog/PREVISIONI_*` e `Previsioni_comunali_*`)  
**Anno dati:** proiezioni 2024-2050, popolazione al 1° gennaio  
**Ultimo aggiornamento:** 2026-07-22 (aggiunti p05a/b/c, p06, p07)  
**Output principali:** `p01_pop_indice` (pop totale 2024=100, province ER + ER + Italia), `p02_pop_totale` (valori assoluti, solo province ER), `p03_piramide_pr` (piramide PR 2050 vs 2024), `p04_quota_anziani` (% 65+ e 80+), `p05a/b/c_anziani_*` (65+/80+ in valore assoluto, un grafico per Parma/ER/Italia), `p06_dipendenza_anziani` (65+ ogni 100 in età 15-64), `p07_nati_morti` (bilancio naturale previsto PR/ER, solo comuni >= 5.000 ab.) + csv omonimi  

# Messaggio

- **Parma è prevista in crescita, controtendenza rispetto all'Italia**: al 2050 la provincia arriverebbe a ~486mila abitanti (**+6,9%** sul 2024), la crescita più alta tra le province ER (seconda: Bologna, +4,6%); l'Emilia-Romagna nel complesso +2,7%, mentre l'Italia perderebbe il **-7,3%**.
- **L'invecchiamento però accelera ovunque**: a Parma i 65+ passerebbero dal 23,4% al **31,8%** della popolazione (quasi 1 abitante su 3), e gli 80+ dall'8,0% al **12,2%** — in valore assoluto gli 80+ crescono di oltre il 60%. Parma resterebbe comunque un po' "più giovane" di ER (32,9%) e Italia (34,6%).
- **La piramide si sbilancia verso l'alto**: le coorti dei baby boomer si spostano nelle classi 75-85+, mentre le classi 0-29 si assottigliano ulteriormente — implicazioni dirette per non autosufficienza e servizi socio-sanitari.
- **In valore assoluto la platea cresce più che in quota**: a Parma gli 80+ da ~36mila a ~59mila (+64%), i 65+ da ~106mila a ~154mila; l'indice di dipendenza anziani sale da 36,6 a **56,1** (ER 59,0; Italia 63,6).
- **Il saldo naturale peggiora**: nei comuni PR >= 5.000 ab. il deficit nati-morti quasi raddoppia (da ~-1.400 a ~-2.550 l'anno): la crescita prevista poggia interamente sui flussi migratori.

**Note di metodo:** previsioni ISTAT base 1.1.2024, SOLO scenario mediano (i file pubblicati per comuni/province non riportano gli scenari alternativi); i file comunali coprono solo i comuni ≥ 5.000 abitanti (195 in ER, 22 su 44 in provincia di Parma). Gli aggregati Emilia-Romagna e Italia sono somme delle province (i file ISTAT non contengono totali). Come tutte le proiezioni, l'incertezza cresce allontanandosi dall'anno base.
