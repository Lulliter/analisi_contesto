# Input:  ggobj — un ggplot (con geoms _interactive di ggiraph)
# Output: widget girafe con lo stile standard del sito:
#         tooltip scuro + hover bordeaux (burg_md, evidenziazione di palette)
f_girafe <- function(ggobj) {
  ggiraph::girafe(
    ggobj = ggobj,
    options = list(
      ggiraph::opts_tooltip(
        css = "background-color:#333; color:white; padding:8px; border-radius:4px; font-size:12px;"
      ),
      # css differenziato per tipo di elemento: alle LINEE niente fill
      # (in SVG riempirebbe l'area sotto la curva), a punti e poligoni si'
      ggiraph::opts_hover(css = ggiraph::girafe_css(
        css   = "fill:#873C4A;stroke:#873C4A;",  # default (es. poligoni mappe)
        line  = "fill:none;stroke:#873C4A;",
        point = "fill:#873C4A;stroke:#873C4A;"
      ))
    )
  )
}
