# ----- [PRIMA VERIFICARE DI AVERE INSTALLATO npm e decktape] -----
# # Disinstalla Node x64 se presente
# brew uninstall node
# # Reinstalla versione arm64
# arch -arm64 brew install node
# # Installa decktape
# npm install -g decktape

# ----- Converti file HTML revealjs in PDF usando decktape -----
#!/bin/bash
# --- Funzione per convertire slide HTML in PDF ---
# NON renderizza: l'HTML deve già esistere (da quarto render o build.R)
# Cerca l'HTML prima in docs/ (output website), poi nella cartella sorgente
qmd2pdf() {
  local file="${1%.qmd}"  # Rimuove .qmd se presente
  local inputdir="${2:-.}"  # Default: cartella corrente
  local outputdir="${3:-.}"  # Default: cartella corrente

  # Cerca l'HTML: prima in docs/ (output del website), poi nella cartella sorgente
  if [ -f "docs/${inputdir}/${file}.html" ]; then
    local html_path="docs/${inputdir}/${file}.html"
  elif [ -f "${inputdir}/${file}.html" ]; then
    local html_path="${inputdir}/${file}.html"
  else
    echo "ERRORE: ${file}.html non trovato né in docs/${inputdir}/ né in ${inputdir}/"
    echo "Renderizza prima con: quarto render ${inputdir}/${file}.qmd"
    return 1
  fi

  echo "Fonte HTML: ${html_path}"
  decktape reveal "${html_path}" "${outputdir}/${file}.pdf" && open "${outputdir}/${file}.pdf"
}


# --- Esempio [GENERALE] di utilizzo della funzione ---
# qmd2pdf "nomefile" "cartella_input" "cartella_output"
# --- Utilizzo per questo progetto (lanciare dalla ROOT del progetto) ---
# Presentazione: trend demografici
qmd2pdf slides presentazione/demographic_trends presentazione/demographic_trends
