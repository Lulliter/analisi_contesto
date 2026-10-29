# Giovani e lavoro: occupazione e disoccupazione

**Fonte:** Regione Emilia-Romagna, Report giovani 2026 (elaborazioni su ISTAT, rilevazione sulle forze di lavoro: stime campionarie), Tab. 14-19; estrazione dal pdf con `00_prep_condizione_pdf.R`. Iscritti AIRE (dati del Ministero dell'Interno): Tab. 2-3, con `00_prep_aire_pdf.R`
**Anno dati:** 2025 (confronti con 2024 e 2019; per provincia solo 2025 e solo 25-34 anni)
**Ultimo aggiornamento:** 2026-10-29 (modulo nato)
**Output principali:** `condizione_rev`; tabella `aire_confronto_ft`; grafici `plot_occupazione_prov_er`, `plot_disoccupazione_prov_er`, `plot_occupazione_territori`, `plot_disoccupazione_territori`, `plot_variazioni_su_2024_er`, `plot_variazioni_su_2019_er`

# Messaggio

- A Parma lavora il 77% dei giovani di 25-34 anni: meno della media regionale (circa 80%), dove solo Reggio Emilia sta più in basso, ma molto più che in Italia (meno del 70%).
- Tra i 25-34enni di Parma cerca lavoro circa 1 giovane attivo su 20 (circa 5%), come in regione e molto meno che in Italia (9%).
- Il divario tra uomini e donne è ampio: a Parma il tasso di occupazione è circa 85% per gli uomini e 68% per le donne, uno scarto di circa 16 punti come in regione; il tasso di disoccupazione delle donne è circa il doppio di quello degli uomini.
- In regione le due fasce d'età vanno in direzioni opposte: rispetto al 2019 tra i 15-24enni calano gli occupati e crescono gli inattivi (+16%); tra i 25-34enni crescono gli occupati (+10%) e quelli in cerca di lavoro calano di circa il 40%.
- Rispetto all'Europa, a 25-34 anni la regione è in linea con la media UE (circa 80%); a 15-24 anni lavora un giovane su cinque, contro uno su tre nella UE.
- Per ogni 1.000 giovani di 19-34 anni residenti in provincia di Parma, 92 vivono all'estero iscritti all'AIRE di un comune parmense (circa 7.200 nel 2025), un po' più della media regionale (87); dal 2023 il rapporto è salito di circa 11 ogni 1.000, come in regione.

**Note di metodo:** stime campionarie; per provincia e sesso i valori poggiano su campioni piccoli e vanno letti come ordini di grandezza. Il tasso di disoccupazione si calcola su chi lavora o cerca lavoro, non su tutti i giovani. Il Report legge la crescita degli inattivi 15-24 come maggiore permanenza negli studi: con queste tabelle non si può verificare. Per sesso, i valori 2024 e 2019 sono ricostruiti dalle variazioni % stampate (`01_dati.R` § 2). AIRE: conta anche i nati all'estero con cittadinanza italiana e non misura le partenze dell'anno; nella Tab. 3 del Report i valori assoluti di Parma e Piacenza sono scambiati (corretti in `01_dati.R` § 3b).
