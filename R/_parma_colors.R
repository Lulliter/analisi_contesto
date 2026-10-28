# Parma Colours ----
#
# CONVENZIONE SEMANTICA (decisa 2026-07-17, usare coerentemente nei grafici):
#   verde   = giovani / minori
#   fasce d'età / ordini di scuola (giovani): verde_eta3 / verde_eta4, chiaro = piccoli → scuro = grandi
#     (deciso 2026-09-26: luminosità distanziata e capo chiaro giallo-verde, i grn_* erano troppo vicini)
#   rosso   = anziani / invecchiamento
#   viola   = stranieri / migrazioni
#   blu     = densità, popolazione totale, temi neutri
#   pesca (seq_factor_peach) = abitare pubblico / immobili ACER (deciso 2026-10-09 in comune_pr_quartieri; brnyl scartata: i toni scuri vanno nel bordeaux di Parma)
#   arancio = seconda chance / istruzione degli adulti (serali, CPIA, carcere: seq_factor_orange[6/8/4], deciso 2026-09-23 in formaz_e_rientro)
#   bordeaux (burg_*) = evidenziazione Parma (mappe) + hover interattivo (R/f_girafe.R usa burg_md)
#   serie territoriali (trend): Parma = ylw_lg, ER = grn_md, Italia = blu_md
#   piramidi: maschi = azzurro, femmine = rosa antico
#   distretti sanitari AUSL PR (entità nuova, palette CATEGORICA a 4): cat_distretti (deciso 2026-10-14 in npia_utenti)
#
# NB 2026-07-18: hex allineati alla palette del repo BILANCIO DI MISSIONE
# (gialli e grigi aggiornati; maschi/femmine sono gli hex originali che
# la nota pre-2026 chiedeva di ritrovare)

maschi <- "#6B8FAD"        # azzurro (Maschi)
femmine <- "#C47A87"       # rosa antico (Femmine)
sesso_m_pal <- maschi      # alias usati da pop_piramide_eta
sesso_f_pal <- femmine
blu_piramide <- "#6B8FAD"  # azzurro per eventuali piramidi monocrome

blu_sc <- "#033c55"
blu_md <- "#005d82"        # territorio = "Italia"
blu_lg <- "#5582a7"

grn_sc <- "#246864"
grn_md <- "#539d90"        # territorio = "Emilia-Romagna"
grn_lg <- "#8eb9b1"

# verdi per fasce d'età / ordini di scuola: chiaro = piccoli → scuro = grandi
verde_eta3 <- c("#a6c48a", "#3d8f80", "#0f4a44")
verde_eta4 <- c("#b5cf8f", "#6fb3a4", "#2f7f72", "#12463f")

pur_sc <- "#553c64"
pur_md <- "#805f95"
pur_lg <- "#9a8da3"

ylw_sc <- "#b27d2c"
ylw_md <- "#d9a44a"
ylw_lg <- "#f0c166"        # territorio = "Parma"

grey_extra_sc <- "#4F4F4F"
grey_sc <- "#808080"
grey_md1 <- "#A9A9A9"
grey_md2 <- "#D3D3D3"
grey_m <- "#d3d3d3"        # alias storico di grey_md2 (usato nelle mappe)
grey_extrlight <- "#FDFBF7"

burg_sc <- "#5C2129"
burg_md <- "#873C4A"
burg_lg <- "#B85E6A"

# Ggplot ready -----

seq_dummy_blue <- c('#deebf7', '#9ecae1', '#3182bd')
seq_factor_blue <- c(
  '#f7fbff',
  '#deebf7',
  '#c6dbef',
  '#9ecae1',
  '#6baed6',
  '#4292c6',
  '#2171b5',
  '#084594'
)

seq_dummy_red <- c('#fee0d2', '#fc9272', '#de2d26')
seq_factor_red <- c(
  '#fff5f0',
  '#fee0d2',
  '#fcbba1',
  '#fc9272',
  '#fb6a4a',
  '#ef3b2c',
  '#cb181d',
  '#99000d'
)

seq_dummy_green <- c('#e5f5e0', '#a1d99b', '#31a354')
seq_factor_green <- c(
  '#f7fcf5',
  '#e5f5e0',
  '#c7e9c0',
  '#a1d99b',
  '#74c476',
  '#41ab5d',
  '#238b45',
  '#005a32'
)

seq_dummy_purple <- c('#efedf5', '#bcbddc', '#756bb1')
seq_factor_purple <- c(
  '#fcfbfd',
  '#efedf5',
  '#dadaeb',
  '#bcbddc',
  '#9e9ac8',
  '#807dba',
  '#6a51a3',
  '#4a1486'
)

seq_dummy_orange <- c('#fee6ce', '#fdae6b', '#e6550d')
seq_factor_orange <- c(
  '#fff5eb',
  '#fee6ce',
  '#fdd0a2',
  '#fdae6b',
  '#fd8d3c',
  '#f16913',
  '#d94801',
  '#8c2d04'
)

seq_dummy_grey <- c('#f0f0f0', '#bdbdbd', '#636363')
seq_factor_grey <- c(
  '#ffffff',
  '#f0f0f0',
  '#d9d9d9',
  '#bdbdbd',
  '#969696',
  '#737373',
  '#525252',
  '#252525'
)

# abitare pubblico (ACER): da Carto Colors Peach (7 toni, giallo-pesca -> arancio-rosso),
# portata a 8 toni per lo schema seq8[2:8] delle mappe
seq_factor_peach <- grDevices::colorRampPalette(c('#fde0c5', '#facba6', '#f8b58b', '#f59e72', '#f2855d', '#ef6a4c', '#eb4a40'))(8)
# Carto BrnYl (sabbia -> prugna): disponibile, non assegnata (provata per ACER il 2026-10-09)
seq_factor_brnyl <- grDevices::colorRampPalette(c('#ede5cf', '#e0c2a2', '#d39c83', '#c1766f', '#a65461', '#813753', '#541f3f'))(8)


div_dummy_ter <- c('#d8b365', '#f5f5f5', '#5ab4ac')
div_factor_ter <- c(
  '#8c510a',
  '#bf812d',
  '#dfc27d',
  '#f6e8c3',
  '#c7eae5',
  '#80cdc1',
  '#35978f',
  '#01665e'
)

div_dummy_red_blu <- c('#d73027', '#f7f7f7', '#4575b4')
div_factor_red_blu <- c(
  '#d53e4f',
  '#f46d43',
  '#fdae61',
  '#fee08b',
  '#e6f598',
  '#abdda4',
  '#66c2a5',
  '#3288bd'
)


# distretti sanitari dell'AUSL di Parma: palette CATEGORICA (nessun ordine tra i distretti),
# tinte fuori da quelle riservate (verde minori, rosso anziani, viola stranieri, giallo Parma, ...)
cat_distretti <- c("Parma" = "#8C6D31",
                   "Fidenza" = "#1B7F8C",
                   "Sud Est" = "#C2559A",
                   "Valli Taro e Ceno" = "#6699CC")

# Color QUALITATIVE
#install.packages("rcartocolor")
#https://carto.com/carto-colors/
rcartocolor::carto_pal(9, name = "Prism")
#[1] "#5F4690" "#1D6996" "#38A6A5" "#0F8554" "#73AF48" "#EDAD08" "#E17C05" "#CC503E" "#666666"
rcartocolor::carto_pal(9, name = "Safe")
#[1] "#88CCEE" "#CC6677" "#DDCC77" "#117733" "#332288" "#AA4499" "#44AA99" "#999933" "#888888"
rcartocolor::carto_pal(9, name = "Antique")
#[1] "#855C75" "#D9AF6B" "#AF6458" "#736F4C" "#526A83" "#625377" "#68855C" "#9C9C5E" "#7C7C7C"
rcartocolor::carto_pal(9, name = "TealRose")
#"#D1EEEA" "#B2DFDD" "#96CFD1" "#7DBDC4" "#68ABB8" "#5596AA" "#45819A" "#366B88" "#2A5674"
#ffc6c4,#f4a3a8,#e38191,#cc607d,#ad466c,#8b3058,#672044
#"#009392" "#55A49D" "#91B8AA" "#C1CFB8" "#F1EAC8" "#E8C5B3" "#DFA0A0" "#D67C8E" "#D0587E"

rcartocolor::carto_pal(15, name = "Sunset")
 # "#F3E79B" "#F5D891" "#F9C987" "#F9B982" "#F8AA7F" "#F69B7F" "#F08D82" "#EB7F86" "#DE748B" "#D26991" "#C06296" "#AD5C9C" "#9658A0"
 # "#7955A2" "#5C53A5"
 rcartocolor::carto_pal(15, name = "BluYl")
 # [1] "#F7FEAE" "#DBF3AA" "#C0E9A6" "#A6DEA4" "#8CD2A2" "#74C6A1" "#5DBAA0" "#46AEA0" "#2BA19D" "#10949A" "#058795" "#02798E" "#006C87"
 # [14] "#025F7E" "#045275"
 
 rcartocolor::carto_pal(7, "BluYl")
 # "#F7FEAE" "#B7E6A5" "#7CCBA2" "#46AEA0" "#089099" "#00718B" "#045275"