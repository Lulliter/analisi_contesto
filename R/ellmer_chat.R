# Chat interattiva con Claude da RStudio via ellmer ----
# Prerequisiti (una tantum):
#   1. Creare chiave API su https://platform.claude.com/settings/keys
#   2. Salvarla in /Users/luisamimmi/.Renviron
#      [usethis::edit_r_environ() → aggiungere: ANTHROPIC_API_KEY=sk-ant-...]
#   3. Riavviare R
#   4. install.packages("ellmer")

library(ellmer)

claude <- chat_anthropic(
  model  = "claude-sonnet-4-5",
  system_prompt = "Sei un assistente per analisi di dati in R. Risposte brevi e dirette, senza preamboli."
)

live_console(claude)

## 🚪 Per uscire
#  `Ctrl + c`
