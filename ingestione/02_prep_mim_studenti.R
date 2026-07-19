# ------------------------------------------------------------------------
# Ingestione: MIM open data (studenti + anagrafi scuole) → dati/puliti/mim_iscritti/
# Fonte:  dati/grezzi/mim_open_data/ + dati/grezzi/istat_codici_comuni/
#         (vedi i rispettivi _metadati.md)
# Input:  SCUANAGRAFESTAT|PAR (a.s. 2024/25, per il join scuola → comune/provincia
#         + TUTTI gli a.s. presenti per lo storico dei plessi, 2015/16 → 2026/27)
#         ALUCORSOETASTA|PAR e ALUITASTRACITSTA|PAR, a.s. 2015/16 → 2024/25
#         Elenco-comuni-italiani.csv (ISTAT, per la transcodifica catastale→ISTAT)
# Output: dati/puliti/mim_iscritti/scuole_anagrafe_er.rds (plessi ER, a.s. 2024/25)
#         dati/puliti/mim_iscritti/scuole_anagrafe_storico_er.rds (plessi ER,
#             tutti gli a.s. scaricati — per il trend aperture/chiusure)
#         dati/puliti/mim_iscritti/scuole_iscritti_er.rds
#         dati/puliti/mim_iscritti/scuole_iscritti_cittadinanza_er.rds
#         (nome file = nome oggetto R; consumati dal modulo scuola_iscritti)
# NB: gli iscritti MIM NON coprono la scuola dell'infanzia; il comune arriva
#     dall'anagrafe e viene transcodificato a PRO_COM_T ISTAT via join sul
#     CODICE CATASTALE con l'Elenco comuni ISTAT (dati/grezzi/istat_codici_comuni/)
# ------------------------------------------------------------------------

library(here)
library(readr)
library(dplyr)
library(stringr)
library(purrr)
library(janitor)

# Parametri ---------------------------------------------------------------
dir_in <- here("dati", "grezzi", "mim_open_data")
dir_out <- here("dati", "puliti", "mim_iscritti")
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# Pezzo della stringa per decidere quale dei 12 csv di Anagrage usare 
        # read_csv(file.path(dir_in, paste0("SCUANAGRAFESTAT", ANAGRAFE_AS, ".csv")))
        # [Sarà da aggiornare se  esce l'anagrafe con gli iscritti 2025/26]
ANAGRAFE_AS <- "20242520250831"
# NB: A.S. dell'anagrafe usata per il join scuola → comune/provincia: quello
# dell'ULTIMO file iscritti. Verificato il 2026-07-19 contro le anagrafi
# storiche: nessun alunno ER 2015/16-2024/25 resta fuori (i codici dei plessi
# cessati restano in anagrafe), quindi il join con l'anagrafe unica è esatto


# Funzioni locali ----------------------------------------------------------

# [DEPRECATA 2026-07-19: il join comuni ora usa il codice catastale — tenuta
#  come riferimento se servisse altrove un match per nome]
# Normalizza un nome comune per il join MIM ↔ ISTAT (maiuscole, niente
# accenti/apostrofi/punteggiatura, spazi singoli)
# NB: accenti sostituiti in modo esplicito — iconv(//TRANSLIT) su macOS
#     non è affidabile (la Ì di FORLÌ non veniva convertita)
f_norm_nome <- function(x) {
  x |>
    toupper() |>
    str_replace_all(c(
      "À" = "A", "Á" = "A", "Â" = "A",
      "È" = "E", "É" = "E", "Ê" = "E",
      "Ì" = "I", "Í" = "I", "Î" = "I",
      "Ò" = "O", "Ó" = "O", "Ô" = "O",
      "Ù" = "U", "Ú" = "U", "Û" = "U"
    )) |>
    str_replace_all("[^A-Z ]", " ") |>
    str_squish()
}

# Legge e impila i csv MIM di un tipo (STA + PAR), aggiungendo `gestione`
f_read_mim <- function(prefisso_sta, prefisso_par) {
  files <- list.files(dir_in, pattern = paste0("^(", prefisso_sta, "|", prefisso_par, ")\\d"),
                      full.names = TRUE)
  files |>
    set_names() |>
    map(function(f) read_csv(f, col_types = cols(.default = col_character()))) |>
    list_rbind(names_to = "file") |>
    mutate(gestione = if_else(str_detect(file, prefisso_par), "paritaria", "statale")) |>
    select(-file) |>
    clean_names()
}

# 1. Anagrafi scuole → plessi ER con comune/provincia ----------------------
scuole_anagrafe_er <- bind_rows(
  read_csv(file.path(dir_in, paste0("SCUANAGRAFESTAT", ANAGRAFE_AS, ".csv")),
           col_types = cols(.default = col_character())) |>
    mutate(gestione = "statale"),
  read_csv(file.path(dir_in, paste0("SCUANAGRAFEPAR", ANAGRAFE_AS, ".csv")),
           col_types = cols(.default = col_character())) |>
    mutate(gestione = "paritaria")
) |>
  clean_names() |>
  filter(regione == "EMILIA ROMAGNA") |>
  select(codice_scuola = codicescuola,
         provincia,
         comune = descrizionecomune,
         codice_catastale = codicecomunescuola,
         grado = descrizionetipologiagradoistruzionescuola,
         gestione)

# checks
tabyl(scuole_anagrafe_er, gestione) |> adorn_totals("row")  # 2026-07-19: 2.091 statali + 1.042 paritarie = 3.133 plessi ER)
tabyl(scuole_anagrafe_er, provincia) |> adorn_totals("row")
tabyl(scuole_anagrafe_er, codice_catastale) |> adorn_totals("row")
n_distinct(scuole_anagrafe_er$codice_catastale)
n_distinct(scuole_anagrafe_er$comune)


# 2. Transcodifica comune → PRO_COM_T ISTAT (join sul CODICE CATASTALE) ----
# PROBLEMA: il MIM identifica il comune con il nome (troncato a ~30 caratteri)
# e con il codice CATASTALE (es. E438); al repo serve il codice ISTAT
# (PRO_COM_T, es. "034027") per geometrie sf, mappe e censimento.
# SOLUZIONE (2026-07-19, sostituisce il vecchio join per nome normalizzato +
# ripiego per prefisso): join ESATTO sul codice catastale con l'"Elenco dei
# comuni italiani" ISTAT (dati/grezzi/istat_codici_comuni/), che contiene
# entrambi i codici e il nome ufficiale. Niente nomi, niente ambiguità.
file_elenco_comuni <- here("dati", "grezzi", "istat_codici_comuni",
                    "Elenco-comuni-italiani.csv")
if (!file.exists(file_elenco_comuni)) {
  stop("Manca l'Elenco comuni ISTAT: scaricarlo seguendo ",
       "dati/grezzi/istat_codici_comuni/_metadati.md e rilanciare")
}

# csv ISTAT: separatore ";", encoding latin1
# NB: se una futura edizione cambia i nomi colonna, la select fallisce →
#     aggiornare i nomi qui (e nel _metadati.md della fonte)
comuni_lookup <- read_csv2(file_elenco_comuni,
                           locale = locale(encoding = "latin1"),
                           col_types = cols(.default = col_character())) |>
  clean_names() |>
  select(codice_catastale = codice_catastale_del_comune,
         pro_com_t = codice_comune_formato_alfanumerico,
         comune_istat = denominazione_in_italiano)

# Join sul codice catastale (non sul nome, che può essere troncato o ambiguo)
scuole_anagrafe_er <- scuole_anagrafe_er |>
  left_join(comuni_lookup, by = "codice_catastale") |>
  # nome ufficiale ISTAT come `comune`; quello MIM (troncato) resta in comune_mim
  mutate(comune_mim = comune,
         comune = coalesce(comune_istat, comune)) |>
  select(-comune_istat)

# controllo: plessi senza aggancio (catastale assente o non in elenco)
non_matchati <- scuole_anagrafe_er |>
  filter(is.na(pro_com_t)) |>
  distinct(comune, codice_catastale)
non_matchati
if (nrow(non_matchati) > 0) {
  message("ATTENZIONE - comuni senza PRO_COM_T: ",
          paste(non_matchati$comune, collapse = ", "))
}

# 2c. Anagrafi STORICHE: tutti gli a.s. presenti in grezzi ------------------
# Per il trend dei PLESSI (aperture/chiusure, infanzia inclusa). Usa tutti i
# file SCUANAGRAFESTAT/PAR trovati (v. _metadati.md per la lista completa da
# scaricare) e segnala quanti a.s. ha in mano.
files_anagrafe <- list.files(dir_in, pattern = "^SCUANAGRAFE(STAT|PAR)\\d",
                             full.names = TRUE)

scuole_anagrafe_storico_er <- files_anagrafe |>
  set_names() |>
  map(function(f) read_csv(f, col_types = cols(.default = col_character()))) |>
  list_rbind(names_to = "file") |>
  mutate(gestione = if_else(str_detect(file, "SCUANAGRAFEPAR"), "paritaria", "statale")) |>
  select(-file) |>
  clean_names() |>
  filter(regione == "EMILIA ROMAGNA") |>
  mutate(anno_inizio = as.integer(annoscolastico) %/% 100) |>
  select(anno_inizio, codice_scuola = codicescuola, gestione, provincia,
         comune = descrizionecomune,
         grado = descrizionetipologiagradoistruzionescuola)

message("Anagrafi storiche: ",
        dplyr::n_distinct(scuole_anagrafe_storico_er$anno_inizio),
        " a.s. trovati (", length(files_anagrafe), " file)")

# 3. Iscritti (anno di corso e fascia d'età), tutti gli a.s. ---------------
scuole_iscritti_er <- f_read_mim("ALUCORSOETASTA", "ALUCORSOETAPAR") |>
  mutate(across(c(annoscolastico, annocorso, alunni), as.integer)) |>
  # solo scuole ER (il join porta comune/provincia; inner = scarta fuori regione)
  inner_join(scuole_anagrafe_er |> select(codice_scuola, provincia, comune, pro_com_t),
             by = c("codicescuola" = "codice_scuola")) |>
  # 202425 → 2024 (anno di inizio a.s.), comodo per l'asse x dei trend
  mutate(anno_inizio = annoscolastico %/% 100) |>
  select(anno_scolastico = annoscolastico, anno_inizio,
         codice_scuola = codicescuola, gestione,
         ordine_scuola = ordinescuola, anno_corso = annocorso,
         fascia_eta = fasciaeta, alunni, provincia, comune, pro_com_t)

# 4. Cittadinanza, tutti gli a.s. ------------------------------------------
scuole_iscritti_cittadinanza_er <- f_read_mim("ALUITASTRACITSTA", "ALUITASTRACITPAR") |>
  mutate(across(starts_with("alunni"), as.integer),
         annoscolastico = as.integer(annoscolastico),
         annocorso = as.integer(annocorso)) |>
  inner_join(scuole_anagrafe_er |> select(codice_scuola, provincia, comune, pro_com_t),
             by = c("codicescuola" = "codice_scuola")) |>
  mutate(anno_inizio = annoscolastico %/% 100) |>
  select(anno_scolastico = annoscolastico, anno_inizio,
         codice_scuola = codicescuola, gestione,
         ordine_scuola = ordinescuola, anno_corso = annocorso,
         alunni, alunni_ita = alunnicittadinanzaitaliana,
         alunni_stranieri = alunnicittadinanzanonitaliana,
         alunni_stranieri_ue = alunnicittadinanzanonitalianapaesiue,
         alunni_stranieri_extra_ue = alunnicittadinanzanonitalianapaesinonue,
         provincia, comune, pro_com_t)

# 5. Salva in dati/puliti/mim_iscritti/ ---------------------------------------------
saveRDS(scuole_anagrafe_er, file.path(dir_out, "scuole_anagrafe_er.rds"))
saveRDS(scuole_anagrafe_storico_er, file.path(dir_out, "scuole_anagrafe_storico_er.rds"))
saveRDS(scuole_iscritti_er, file.path(dir_out, "scuole_iscritti_er.rds"))
saveRDS(scuole_iscritti_cittadinanza_er, file.path(dir_out, "scuole_iscritti_cittadinanza_er.rds"))

message("Salvati in dati/puliti/mim_iscritti/: scuole_anagrafe_er (", nrow(scuole_anagrafe_er),
        " plessi), scuole_iscritti_er (", nrow(scuole_iscritti_er),
        " righe), scuole_iscritti_cittadinanza_er (", nrow(scuole_iscritti_cittadinanza_er), " righe)")

# Verifiche rapide (da eseguire a mano) ------------------------------------
scuole_iscritti_er |> filter(provincia == "PARMA", anno_inizio == 2024) |>
  summarise(alunni = sum(alunni))                       # atteso ~49.570 statali+paritarie

scuole_iscritti_er |> count(anno_inizio)                        # 10 a.s.
scuole_iscritti_cittadinanza_er |> filter(provincia == "PARMA") |>
  summarise(pct = sum(alunni_stranieri) / sum(alunni))   # ~19% (solo statali era 22,7%)

