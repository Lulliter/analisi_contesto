# ___________________________________________________________________________
# Modulo: giovani_ict_social
# Scopo:  social e relazioni con gli amici dei ragazzi di 11-19 anni (Italia, 2023), per età
#         (11-13, 14-19) e sesso: profilo sui social, amici sentiti online, amici visti di
#         persona, nuove amicizie fatte online. Quattro grafici con lo STESSO disegno
#         (barre impilate al 100%), guidati dalla tabella GRAFICI (1 riga = 1 grafico)
#         + due grafici di TREND 2001-2025 (linea + pallino): internet tutti i giorni per età; internet e pc per età
#         + due grafici sull'IA generativa (Eurostat 2025): adozione per età e scopi d'uso dei giovani, Italia e UE
# Input:  output/ragazzi_ict_social.rds, output/ict_giovani_eta.rds, output/ia_eta_it_ue.rds (da 01_dati.R)
# Output: output/plot_*.rds (ggplot; girafe() nella pagina di sito) + .png (nome file = oggetto)
#         dati per i bottoni di scarico: output/ragazzi_ict_social.csv (tabella condivisa dai 4 grafici a barre),
#         output/ict_giovani_eta.csv (condivisa dai 2 grafici di trend), output/ia_eta_it_ue.csv (dai 2 sull'IA)
# NB: profilo social e nuove amicizie hanno come base i ragazzi che USANO INTERNET
# ___________________________________________________________________________

# Setup -------------------------------------------------------------------
library(here)
library(dplyr)
library(stringr)
library(purrr)
library(glue)
library(ggplot2)
library(ggiraph)
library(scales)
library(ggtext)

source(here("R", "_parma_colors.R"))
source(here("R", "f_caption_fonte.R"))
source(here("R", "f_theme_scuola.R"))

# Parametri ---------------------------------------------------------------
dir_mod <- here("moduli", "giovani_ict_social", "output")
ANNO <- 2023
CAP <- f_caption_fonte("ISTAT, indagine Bambini e ragazzi (rilevazione 2023, dati pubblicati nel 2025); stima campionaria")
# un colore per sesso (da _parma_colors); la risposta si legge dall'INTENSITÀ del colore (trasparenza)
# maschi/femmine = i colori delle piramidi di popolazione; "Tutti" (maschi e femmine) in grigio neutro
COL_SESSO <- c("Maschi" = maschi, "Femmine" = femmine, "Tutti" = grey_sc)
SOGLIA_ETICHETTA <- 4   # sotto questa % l'etichetta dentro la barra non ci sta: va sopra la barra (v. etichette_sopra)

# --- parametri dei grafici di trend (internet e pc per età)
CAP_ICT <- f_caption_fonte("ISTAT, Aspetti della vita quotidiana (2001-2025; nel 2004 l'indagine non è stata svolta); stima campionaria")
ANNO_PRIMO_ICT  <- 2001
ANNO_ULTIMO_ICT <- 2025
# anni sull'asse x nei grafici a pannelli (poco spazio): ogni 5 anni, con il 2020 in vista
BREAKS_ANNI_PANNELLI <- c(2001, 2005, 2010, 2015, 2020, 2025)
LOCKDOWN <- c(2020, 2021)   # anni evidenziati con una fascia grigia (come in giovani_benessere)
# classi d'età nei grafici, con l'etichetta da mostrare (15-19 = nostra stima da 15-17 e 18-19, v. 01_dati.R)
LAB_ETA <- c("06-10" = "6-10 anni", "11-14" = "11-14 anni", "15-19" = "15-19 anni", "20-24" = "20-24 anni",
             "Totale" = "Popolazione (6 anni e più)")
# verdi (giovani) dal chiaro al scuro con l'età; la popolazione in grigio
COL_ETA <- c(colorRampPalette(c("#b9d8d1", grn_sc))(4), grey_sc)
names(COL_ETA) <- LAB_ETA
# due STRUMENTI, non due gruppi di persone: niente verde (= giovani), niente viola (= stranieri),
# niente grigio (= riferimento neutro). Internet in blu (temi neutri), pc in ocra: freddo contro caldo
COL_STRUMENTO <- c("Usano internet" = ylw_sc , "Usano il pc" = blu_md)

# --- parametri dei grafici sull'IA generativa (Eurostat)
ANNO_IA <- 2025
CAP_IA <- f_caption_fonte("Eurostat, indagine sull'uso delle ICT (2025; per l'Italia dati ISTAT); stima campionaria")
# Italia = blu (convenzione delle serie territoriali); UE = grigio, il riferimento neutro
COL_TERRITORIO <- c("Italia" = blu_md, "UE (27 paesi)" = grey_md1)
LIVELLI_ETA_IA <- c("16-19", "20-24", "25-34", "35-44", "45-54", "55-64", "65-74", "Totale 16-74")
ETA_SCOPI <- c("16-19", "20-24")     # classi d'età nel grafico degli scopi
# scopi d'uso: codice dell'indicatore → etichetta nel grafico, nell'ordine in cui compaiono
LAB_SCOPI <- c("scopo_studio" = "Per lo studio", "scopo_privato" = "Per scopi privati", "scopo_lavoro" = "Per lavoro")

# --- parametri dei grafici a barre (social e amici)
# 1 riga = 1 grafico
GRAFICI <- tribble(
  ~nome,                        ~indicatore,             ~titolo,                                                   ~sottotitolo,
  "plot_profilo_social",        "profilo_social",        "Ragazzi con un profilo sui social network",               "Indicatore: % dei ragazzi di 11-19 anni che usano internet, per età e sesso",
  "plot_amici_online",          "amici_online",          "Quanto spesso i ragazzi sentono gli amici online",        "Indicatore: % di tutti i ragazzi di 11-19 anni, per età e sesso (chat, chiamate, videochiamate)",
  "plot_amici_di_persona",      "amici_di_persona",      "Quanto spesso i ragazzi vedono gli amici di persona",     "Indicatore: % di tutti i ragazzi di 11-19 anni, per età e sesso (nel tempo libero)",
  "plot_nuove_amicizie_online", "nuove_amicizie_online", "Ragazzi che usano internet per fare nuove amicizie",      "Indicatore: % dei ragazzi di 11-19 anni che usano internet, per età e sesso"
)

# raggruppamento NOSTRO delle sei risposte ISTAT in tre categorie (solo per i grafici: nel csv restano
# tutte e sei). 1 riga = 1 risposta ISTAT; gli indicatori che non compaiono qui passano invariati
GRUPPI <- tribble(
  ~indicatore,        ~risposta,                            ~gruppo,
  "amici_online",     "Continuamente",                      "Più volte al giorno",
  "amici_online",     "Più volte al giorno",                "Più volte al giorno",
  "amici_online",     "Ogni giorno (o quasi ogni giorno)",  "Ogni giorno o quasi",
  "amici_online",     "Qualche volta a settimana",          "Meno spesso o mai",
  "amici_online",     "Meno spesso",                        "Meno spesso o mai",
  "amici_online",     "Mai",                                "Meno spesso o mai",
  "amici_di_persona", "Tutti i giorni",                     "Tutti i giorni",
  "amici_di_persona", "Qualche volta a settimana",          "Qualche volta a settimana",
  "amici_di_persona", "Una volta a settimana",              "Una volta a settimana o meno",
  "amici_di_persona", "Qualche volta al mese (meno di 4)",  "Una volta a settimana o meno",
  "amici_di_persona", "Qualche volta l'anno",               "Una volta a settimana o meno",
  "amici_di_persona", "Mai",                                "Una volta a settimana o meno"
)

# ordine delle risposte in ogni grafico: dalla più "intensa" (colore pieno, in basso) all'ultima (colore tenue)
LIVELLI <- list(
  profilo_social        = c("Sì, su più social network", "Sì, su un social network", "No"),
  amici_online          = c("Più volte al giorno", "Ogni giorno o quasi", "Meno spesso o mai"),              # v. GRUPPI
  amici_di_persona      = c("Tutti i giorni", "Qualche volta a settimana", "Una volta a settimana o meno"),  # v. GRUPPI
  nuove_amicizie_online = c("Sì", "No")
)

# 1. Carica dati pronti ----------------------------------------------------
ragazzi_ict_social <- readRDS(file.path(dir_mod, "ragazzi_ict_social.rds"))
ict_giovani_eta    <- readRDS(file.path(dir_mod, "ict_giovani_eta.rds"))
ia_eta_it_ue       <- readRDS(file.path(dir_mod, "ia_eta_it_ue.rds"))

# 2. Preparazione (comune ai quattro grafici) --------------------------------
# etichette e tooltip calcolati QUI: negli aes() del plot salvato restano solo colonne
risposte_prep <- ragazzi_ict_social |>
  filter(variabile == "eta", risposta != "Totale") |>
  # raggruppo le risposte dove previsto (GRUPPI) e sommo le percentuali: hanno la stessa base
  left_join(GRUPPI, by = c("indicatore", "risposta")) |>
  mutate(risposta = coalesce(gruppo, risposta)) |>
  summarise(percentuale = sum(percentuale), .by = c(indicatore, sesso, categoria, risposta)) |>
  mutate(
    sesso = factor(sesso, levels = c("Maschi", "Femmine", "Totale"), labels = names(COL_SESSO)),
    # stima campionaria: nelle barre numeri interi, il decimale solo nel tooltip
    etichetta = if_else(percentuale >= SOGLIA_ETICHETTA, scales::number(percentuale, accuracy = 1, suffix = "%"), ""),
    tooltip = glue("{categoria}, {sesso}: {risposta} {scales::number(percentuale, accuracy = 0.1, decimal.mark = ',')}%"),
    id = paste(categoria, sesso, risposta)
  )

risposte_prep
# controllo: dopo il raggruppamento ogni barra somma ancora a 100
risposte_prep |> summarise(totale = sum(percentuale), .by = c(indicatore, sesso, categoria)) |> count(round(totale))

# 3. Grafici di trend: internet e pc per età (2001-2025) ------------------------------

# __ plot_internet_eta ----
# chi usa internet TUTTI I GIORNI: una linea per classe d'età + la popolazione come riferimento
internet_eta_prep <- ict_giovani_eta |>
  filter(strumento == "internet", frequenza == "tutti i giorni", eta %in% names(LAB_ETA)) |>
  mutate(
    eta_lab = factor(eta, levels = names(LAB_ETA), labels = LAB_ETA),
    giovani = eta != "Totale",     # la popolazione è solo un riferimento: tratteggiata e senza pallini
    tooltip = glue("{eta_lab}, {anno}: {scales::number(valore, accuracy = 0.1, decimal.mark = ',')}%")
  )

internet_eta_prep

plot_internet_eta <- internet_eta_prep |>
  ggplot(aes(x = anno, y = valore, color = eta_lab, group = eta_lab)) +
  # fascia grigia sugli anni della pandemia
  annotate("rect", xmin = LOCKDOWN[1] - 0.5, xmax = LOCKDOWN[2] + 0.5,
           ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
  annotate("text", x = mean(LOCKDOWN), y = Inf, label = "pandemia",
           hjust = 0.5, vjust = 1.5, size = 3.5, color = grey_extra_sc) +
  geom_line_interactive(aes(tooltip = eta_lab, data_id = eta_lab, linetype = giovani), linewidth = rel(1.1)) +
  geom_point_interactive(data = function(df) dplyr::filter(df, giovani),
                         aes(tooltip = tooltip, data_id = eta_lab), size = 1.8) +
  scale_x_continuous(breaks = ANNO_PRIMO_ICT:ANNO_ULTIMO_ICT) +        # tutti gli anni, etichette inclinate (come nei moduli scuola)
  scale_y_continuous(limits = c(0, 100), labels = scales::label_number(suffix = "%")) +
  scale_color_manual(values = COL_ETA) +
  scale_linetype_manual(values = c("TRUE" = "solid", "FALSE" = "dashed"), guide = "none") +
  f_theme_scuola() +
  theme(plot.caption = element_text(hjust = 0), plot.caption.position = "plot") +
  labs(title = str_wrap(glue("Chi usa internet tutti i giorni, per età ({ANNO_PRIMO_ICT}-{ANNO_ULTIMO_ICT})"), 55),
       subtitle = "Indicatore: % delle persone della stessa età che usano internet tutti i giorni. Linea tratteggiata = popolazione di 6 anni e più",
       caption = CAP_ICT, x = "", y = "")

plot_internet_eta

# __ plot_pc_internet ----
# chi USA internet e chi USA il pc, un pannello per classe d'età (niente totale: basi diverse, 6+ e 3+)
pc_internet_prep <- ict_giovani_eta |>
  filter(frequenza == "usano", eta %in% setdiff(names(LAB_ETA), "Totale")) |>
  mutate(
    eta_lab = factor(eta, levels = names(LAB_ETA), labels = LAB_ETA),
    strumento_lab = factor(strumento, levels = c("internet", "pc"), labels = names(COL_STRUMENTO)),
    tooltip = glue("{eta_lab}, {anno} - {strumento_lab}: {scales::number(valore, accuracy = 0.1, decimal.mark = ',')}%")
  )

pc_internet_prep

plot_pc_internet <- pc_internet_prep |>
  ggplot(aes(x = anno, y = valore, color = strumento_lab, group = strumento_lab)) +
  annotate("rect", xmin = LOCKDOWN[1] - 0.5, xmax = LOCKDOWN[2] + 0.5,
           ymin = -Inf, ymax = Inf, fill = "grey85", alpha = 0.5) +
  geom_line_interactive(aes(tooltip = strumento_lab, data_id = strumento_lab), linewidth = rel(1.1)) +
  geom_point_interactive(aes(tooltip = tooltip, data_id = strumento_lab), size = 1.5) +
  facet_wrap(~ eta_lab, nrow = 2) +
  scale_x_continuous(breaks = BREAKS_ANNI_PANNELLI) +
  scale_y_continuous(limits = c(0, 100), labels = scales::label_number(suffix = "%")) +
  scale_color_manual(values = COL_STRUMENTO) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        strip.text = element_text(size = rel(1), face = "bold"),
        plot.caption = element_text(hjust = 0), plot.caption.position = "plot") +
  labs(title = str_wrap(glue("Chi usa internet e chi usa il pc, per età ({ANNO_PRIMO_ICT}-{ANNO_ULTIMO_ICT})"), 55),
       subtitle = "Indicatore: % delle persone della stessa età che usano internet (almeno una volta l'anno) e che usano il pc. Fascia grigia = pandemia (2020-2021)",
       caption = CAP_ICT, x = "", y = "")

plot_pc_internet


# 4. Grafici -------------------------------------------------------------------
# un grafico = barre impilate al 100%: una barra per sesso (colore), un pannello per classe d'età;
# la risposta è la trasparenza: stessa scala di intensità nei tre colori
f_plot_risposte <- function(indicatore_sel, titolo, sottotitolo, dati) {
  livelli <- LIVELLI[[indicatore_sel]]
  # intensità: da 1 (colore pieno, prima risposta) a 0.15 (tenue, ultima risposta: "No", "Mai")
  intensita <- seq(1, 0.15, length.out = length(livelli))
  names(intensita) <- livelli

  dati_grafico <- dati |>
    filter(indicatore == indicatore_sel) |>
    mutate(risposta = factor(risposta, levels = livelli),
           # testo bianco sui colori pieni, scuro su quelli tenui
           col_testo = if_else(intensita[as.character(risposta)] >= 0.6, "white", "grey20"))

  # le fette troppo sottili per un'etichetta sono le ultime risposte, in cima alla barra ("Mai", "Qualche
  # volta l'anno"): le scrivo SOPRA la barra, nell'ordine in cui sono impilate (dal basso verso l'alto).
  # La prima risposta sta in fondo alla barra: se fosse sottile non va sopra, resta solo nel tooltip
  etichette_sopra <- dati_grafico |>
    filter(percentuale < SOGLIA_ETICHETTA, risposta != livelli[1]) |>
    arrange(risposta) |>
    summarise(etichetta_sopra = paste(scales::number(percentuale, accuracy = 1, suffix = "%"), collapse = " · "),
              .by = c(categoria, sesso))

  dati_grafico |>
    ggplot(aes(x = sesso, y = percentuale, fill = sesso, alpha = risposta)) +
    geom_col_interactive(aes(tooltip = tooltip, data_id = id, group = risposta),
                         position = position_stack(reverse = TRUE), width = 0.7) +
    geom_text(aes(label = etichetta, color = col_testo, group = risposta),
              position = position_stack(vjust = 0.5, reverse = TRUE), size = 4,
              alpha = 1, show.legend = FALSE) +                  # il testo resta pieno: la trasparenza è solo delle barre
    geom_text(data = etichette_sopra, aes(x = sesso, y = 101, label = etichetta_sopra),
              inherit.aes = FALSE, vjust = 0, size = 3.5, color = "grey30") +
    facet_wrap(~ categoria) +
    scale_fill_manual(values = COL_SESSO, guide = "none") +        # il sesso si legge sull'asse x
    scale_alpha_manual(values = intensita) +
    scale_color_identity() +
    scale_y_continuous(breaks = seq(0, 100, 25), labels = scales::label_number(suffix = "%"),
                       expand = expansion(mult = c(0, 0.08))) +       # spazio in alto per le etichette sopra la barra
    # legenda delle risposte in grigio neutro (vale per i tre colori), al massimo 3 voci per riga
    guides(alpha = guide_legend(nrow = ceiling(length(livelli) / 3), byrow = TRUE,
                                override.aes = list(fill = grey_extra_sc))) +
    f_theme_scuola() +
    theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
          strip.text = element_text(size = rel(1), face = "bold"),
          plot.caption = element_text(hjust = 0),          # caption allineata a sinistra...
          plot.caption.position = "plot") +                # ...rispetto all'intera figura, non al pannello
    labs(title = str_wrap(glue("{titolo} ({ANNO})"), 55), subtitle = sottotitolo, caption = CAP, x = "", y = "")
}

lista_plot_barre <- GRAFICI |>
  select(indicatore_sel = indicatore, titolo, sottotitolo) |>   # i nomi delle colonne = gli argomenti della funzione
  pmap(f_plot_risposte, dati = risposte_prep)

names(lista_plot_barre) <- GRAFICI$nome

# __ plot_profilo_social ----
lista_plot_barre$plot_profilo_social

# __ plot_amici_online ----
lista_plot_barre$plot_amici_online

# __ plot_amici_di_persona ----
lista_plot_barre$plot_amici_di_persona

# __ plot_nuove_amicizie_online ----
lista_plot_barre$plot_nuove_amicizie_online


# 5. Grafici sull'IA generativa: Italia e UE (2025) ------------------------------------

# __ plot_ia_eta ----
# chi ha usato strumenti di IA generativa negli ultimi 3 mesi, per classe d'età (% sul totale delle persone)
ia_eta_prep <- ia_eta_it_ue |>
  filter(indicatore == "uso_ia") |>
  mutate(
    eta = factor(eta, levels = LIVELLI_ETA_IA),
    territorio = factor(territorio, levels = names(COL_TERRITORIO)),
    etichetta = scales::number(valore, accuracy = 1, suffix = "%"),
    tooltip = glue("{territorio}, {eta} anni: {scales::number(valore, accuracy = 0.1, decimal.mark = ',')}%"),
    id = paste(territorio, eta)
  )

ia_eta_prep

plot_ia_eta <- ia_eta_prep |>
  ggplot(aes(x = eta, y = valore, fill = territorio)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = id, group = territorio),
                       position = position_dodge(width = 0.75), width = 0.7) +
  # riga tratteggiata che stacca il "Totale 16-74" (ultima barra) dalle classi d'età.
  # Sta DOPO geom_col: messa prima, una posizione numerica su un asse a categorie dà errore
  geom_vline(xintercept = length(LIVELLI_ETA_IA) - 0.5, linetype = "dashed", color = grey_sc, linewidth = 0.4) +
  # etichetta sopra ogni barra (group = territorio: serve al dodge per allinearla alla colonna)
  geom_text(aes(label = etichetta, group = territorio),
            position = position_dodge(width = 0.75), vjust = -0.4, size = 3.8) +
  scale_y_continuous(labels = scales::label_number(suffix = "%"), expand = expansion(mult = c(0, 0.12))) +
  scale_fill_manual(values = COL_TERRITORIO) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        plot.caption = element_text(hjust = 0), plot.caption.position = "plot") +
  labs(title = str_wrap(glue("Chi usa l'IA generativa, per età ({ANNO_IA})"), 55),
       subtitle = "Indicatore: % delle persone della stessa età che hanno usato l'IA generativa negli ultimi 3 mesi. Italia e Unione europea",
       caption = CAP_IA, x = "Età (anni)", y = "")

plot_ia_eta

# __ plot_ia_scopi ----
# per cosa la usano i giovani: % TRA CHI HA USATO l'IA; gli scopi non si escludono (non sommano a 100)
ia_scopi_prep <- ia_eta_it_ue |>
  filter(indicatore %in% names(LAB_SCOPI), eta %in% ETA_SCOPI) |>
  mutate(
    scopo = factor(indicatore, levels = names(LAB_SCOPI), labels = LAB_SCOPI),
    eta_lab = paste(eta, "anni"),
    territorio = factor(territorio, levels = names(COL_TERRITORIO)),
    etichetta = scales::number(valore, accuracy = 1, suffix = "%"),
    tooltip = glue("{territorio}, {eta_lab} - {scopo}: {scales::number(valore, accuracy = 0.1, decimal.mark = ',')}%"),
    id = paste(territorio, eta, scopo)
  )

ia_scopi_prep

plot_ia_scopi <- ia_scopi_prep |>
  ggplot(aes(x = scopo, y = valore, fill = territorio)) +
  geom_col_interactive(aes(tooltip = tooltip, data_id = id, group = territorio),
                       position = position_dodge(width = 0.75), width = 0.7) +
  geom_text(aes(label = etichetta, group = territorio),
            position = position_dodge(width = 0.75), vjust = -0.4, size = 3.8) +
  facet_wrap(~ eta_lab) +
  scale_y_continuous(limits = c(0, 100), labels = scales::label_number(suffix = "%"),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = COL_TERRITORIO) +
  f_theme_scuola() +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5),
        strip.text = element_text(size = rel(1), face = "bold"),
        plot.caption = element_text(hjust = 0), plot.caption.position = "plot") +
  labs(title = str_wrap(glue("Per cosa i giovani usano l'IA generativa ({ANNO_IA})"), 55),
       subtitle = "Indicatore: % dei giovani della stessa età che hanno usato l'IA negli ultimi 3 mesi; gli scopi non si escludono a vicenda",
       caption = CAP_IA, x = "", y = "")

plot_ia_scopi

# 6. Salva (rds per il sito + png per riuso rapido; nome file = oggetto) ----
# tutti i grafici del modulo in una lista: i 2 di trend + i 2 sull'IA + i 4 a barre (l'ordine delle sezioni sopra non conta)
lista_plot <- c(list(plot_internet_eta = plot_internet_eta, plot_pc_internet = plot_pc_internet,
                     plot_ia_eta = plot_ia_eta, plot_ia_scopi = plot_ia_scopi), lista_plot_barre)
names(lista_plot)   # attesi 8 nomi

purrr::iwalk(lista_plot, function(p, nome) {
  saveRDS(p, file.path(dir_mod, paste0(nome, ".rds")))
  ggsave(file.path(dir_mod, paste0(nome, ".png")), p, width = 9, height = 6, dpi = 300, device = ragg::agg_png)
  message("Salvato: ", nome, " (.rds + .png)")
})
