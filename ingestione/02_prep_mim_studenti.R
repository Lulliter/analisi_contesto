# ------------------------------------------------------------------------
# Ingestione: MIM open data (studenti + anagrafi scuole) → dati/puliti/mim_iscritti/
# Fonte:  dati/grezzi/mim_open_data/ (vedi _metadati.md; download 2026-07-18)
# Input:  SCUANAGRAFESTAT|PAR (a.s. 2024/25, per il join scuola → comune/provincia)
#         ALUCORSOETASTA|PAR e ALUITASTRACITSTA|PAR, a.s. 2015/16 → 2024/25
# Output: dati/puliti/mim_iscritti/scuole_anagrafe_er.rds (plessi ER, statali+paritarie)
#         dati/puliti/mim_iscritti/scuole_iscritti_er.rds
#         dati/puliti/mim_iscritti/scuole_iscritti_cittadinanza_er.rds
#         (nome file = nome oggetto R; consumati dal modulo scuola_iscritti)
# NB: gli iscritti MIM NON coprono la scuola dell'infanzia; il comune arriva
#     dall'anagrafe (nome + codice catastale) e viene transcodificato a
#     PRO_COM_T ISTAT via join sul nome normalizzato coi comuni ER (sf)
# ------------------------------------------------------------------------

library(readr)
library(dplyr)
library(stringr)
library(purrr)
library(janitor)
library(here)
library(sf) # solo per leggere ER_comuni_sf e buttare la geometria

# Parametri ---------------------------------------------------------------
dir_in <- here("dati", "grezzi", "mim_open_data")
dir_out <- here("dati", "puliti", "mim_iscritti")
ANAGRAFE_AS <- "20242520250831" # a.s. dell'anagrafe usata per il join

if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# Funzioni locali ----------------------------------------------------------

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

# 2. Transcodifica comune → PRO_COM_T ISTAT (join sul nome normalizzato) ---
comuni_er_lookup <- readRDS(here("dati", "puliti", "istat_shp", "ER_comuni_sf.rds")) |>
  st_drop_geometry() |>
  transmute(comune_norm = f_norm_nome(COMUNE), pro_com_t = PRO_COM_T)

# 2a. join esatto sul nome normalizzato
scuole_anagrafe_er <- scuole_anagrafe_er |>
  mutate(comune_norm = f_norm_nome(comune)) |>
  left_join(comuni_er_lookup, by = "comune_norm")

# 2b. ripiego per i nomi MIM TRONCATI (il campo comune taglia a ~30 caratteri,
# es. "CASTROCARO TERME E TERRA DEL S"): aggancio per prefisso, accettato solo
# se il prefisso identifica UN solo comune ISTAT
prefissi_na <- scuole_anagrafe_er |>
  filter(is.na(pro_com_t)) |>
  distinct(comune_norm) |>
  pull(comune_norm)

if (length(prefissi_na) > 0) {
  match_prefisso <- prefissi_na |>
    map(function(p) {
      hit <- comuni_er_lookup |> filter(str_starts(comune_norm, p))
      if (nrow(hit) == 1) {
        tibble(comune_norm = p, pro_com_t_fb = hit$pro_com_t)
      } else {
        NULL # 0 o >1 candidati: resta NA e finisce nel controllo sotto
      }
    }) |>
    list_rbind()

  if (nrow(match_prefisso) > 0) {
    scuole_anagrafe_er <- scuole_anagrafe_er |>
      left_join(match_prefisso, by = "comune_norm") |>
      mutate(pro_com_t = coalesce(pro_com_t, pro_com_t_fb)) |>
      select(-pro_com_t_fb)
  }
}

scuole_anagrafe_er <- scuole_anagrafe_er |> select(-comune_norm)

# controllo: comuni MIM non agganciati ai codici ISTAT (da sistemare a mano
# in comuni_er_lookup se ne compaiono)
non_matchati <- scuole_anagrafe_er |> filter(is.na(pro_com_t)) |> distinct(comune)
if (nrow(non_matchati) > 0) {
  message("ATTENZIONE - comuni senza PRO_COM_T: ",
          paste(non_matchati$comune, collapse = ", "))
}

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
  summarise(pct = sum(alunni_stranieri) / sum(alunni))   # ~22-23% (solo statali era 22,7%)
