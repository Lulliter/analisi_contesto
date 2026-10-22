# Anziani non autosufficienti: stima per Parma oggi, 2036 e 2050

**Fonte:** popolazione: ISTAT, censimento 2024 per singola età e previsioni 2024-2050 (scenario mediano); prevalenze per classe di età e sesso: ISTAT EHIS 2019 (ADL/IADL), ISTAT Disabilità in cifre 2023 (GALI), CERGAS Osservatorio Long Term Care (gravi limitazioni funzionali), ISS Report demenze 2024 (vedi `00_prep_prevalenze.R` e i `_metadati.md` delle cartelle `istat_ehis_2019`, `istat_disab_cifre_gali_2023`, `cergas_oltc`, `iss_demenze`)
**Anno dati:** popolazione 2024 (previsioni 2036 e 2050); prevalenze 2019-2024 secondo la fonte
**Ultimo aggiornamento:** 2026-10-22
**Output principali:** `output/tab_quadro_pr|er|it_ft.rds` (quadro delle condizioni per territorio), `output/plot_quota_anziani`, `output/plot_stima_classi_pr`, `output/plot_demenze_classi_pr`, `output/plot_demenze_sesso_pr` (+ csv)

# Messaggio

- In provincia di Parma gli over 65 sono 108 mila, 36 mila dei quali hanno 80 anni o più. L'onda dei grandi anziani arriva dopo il 2036, quando le generazioni numerose nate tra il 1960 e il 1970 superano gli 80 anni: gli over 80 passano da 41 a 59 mila tra il 2036 e il 2050.
- Applicando alla popolazione di Parma le prevalenze per età, oggi circa 12.500 anziani non sono autosufficienti nella cura della persona (ADL, ~12% degli over 65); potrebbero diventare 14.600 nel 2036 e 19.300 nel 2050. Circa 7 su 10 sono donne. Le persone con demenza sono circa 9 mila, 14 mila nel 2050.
- Sono stime di ordine di grandezza, non conteggi: dicono quante persone ci si deve aspettare con quelle caratteristiche, non quante ne seguono i servizi.

**Note di metodo:** prevalenza per classe di età, presunta costante nel tempo e uguale tra territori, moltiplicata per la popolazione residente e prevista; le indagini intervistano solo chi vive in famiglia, quindi le stime sono per difetto; le condizioni del quadro (GALI grave, ADL o IADL, ADL, demenze) si sovrappongono e non vanno sommate.
