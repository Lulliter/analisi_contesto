# Parma Colours ----
#
# CONVENZIONE SEMANTICA (decisa 2026-07-17, usare coerentemente nei grafici):
#   verde   = giovani / minori
#   rosso   = anziani / invecchiamento
#   viola   = stranieri / migrazioni
#   blu     = densità, popolazione totale, temi neutri
#   arancio = disponibile (non ancora assegnato)
#   bordeaux (burg_*) = evidenziazione Parma
#   piramidi: maschi = azzurro pallido, femmine = rosa (stile repo pre-2026;
#             hex approssimati — sostituire qui se si ritrovano gli originali)

sesso_m_pal <- "#a8c6df"   # azzurro pallido (Maschi)
sesso_f_pal <- "#f2b8c6"   # rosa (Femmine)
blu_piramide <- "#a8c6df"  # azzurro per eventuali piramidi monocrome

blu_sc <- "#033c55"
blu_md <- "#005d82"
blu_lg <- "#5582a7"

grn_sc <- "#246864"
grn_md <- "#539d90"
grn_lg <- "#8eb9b1"

pur_sc <- "#553c64"
pur_md <- "#805f95"
pur_lg <- "#9a8da3"

ylw_sc <- "#9f7d35"
ylw_md <- "#d9b942"
ylw_lg <- "#f7da7b"


blu_piramide <- "#6B8FAD"   # blu tenue delle piramidi d'età (da input_bilancio_missione)

grey_extrlight <- "#FDFBF7"
grey_m <- "#d3d3d3"
grey_sc <- "#a9a9a9"


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


# Color QUALITATIVE
#install.packages("rcartocolor")
#https://carto.com/carto-colors/
rcartocolor::carto_pal(9, name = "Prism")
#[1] "#5F4690" "#1D6996" "#38A6A5" "#0F8554" "#73AF48" "#EDAD08" "#E17C05" "#CC503E" "#666666"
rcartocolor::carto_pal(9, name = "Safe")
#[1] "#88CCEE" "#CC6677" "#DDCC77" "#117733" "#332288" "#AA4499" "#44AA99" "#999933" "#888888"
rcartocolor::carto_pal(9, name = "Antique")
#[1] "#855C75" "#D9AF6B" "#AF6458" "#736F4C" "#526A83" "#625377" "#68855C" "#9C9C5E" "#7C7C7C"
