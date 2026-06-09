#!/usr/bin/env bash
# _git_track_AND_rsynch.sh
# Copia la cartella docs/ di QUESTO repo dal Mac alla cartella Windows condivisa.
# Versione per-repo: lo script vive dentro il repo e sincronizza solo il proprio docs/.
#
# Prerequisiti:
#   1. rsync installato sul Mac (verifica con: rsync --version)
#      se manca: brew install rsync
#   2. Il volume Windows deve essere montato su Mac
#      (Finder → Rete → oppure cmd+K → smb://...)
#   3. Il repo deve avere una sottocartella docs/
# ----------------------------------------------------------------------
#
# Rendi script eseguibile (una volta sola):
#   chmod +x _git_track_AND_rsynch.sh
#
# Poi ogni volta, dalla cartella del repo:
#   ./_git_track_AND_rsynch.sh

# ── VARIABILI (modifica qui se cambia la destinazione) ────────────────

# Destinazione: cartella Windows montata come volume sul Mac
DESTINAZIONE="/Volumes/areacomuneatutti/! Mimmi/siti_web"

# ── SCRIPT (non modificare) ───────────────────────────────────────────

# Cartella in cui si trova questo script (= root del repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Nome del repo = nome della cartella che contiene lo script
REPO="$(basename "$SCRIPT_DIR")"

SRC="$SCRIPT_DIR/docs/"
DST="$DESTINAZIONE/$REPO/docs/"

# Sveglia il volume SMB (macOS lo riattiva al primo accesso)
ls "$DESTINAZIONE" &>/dev/null 2>&1
sleep 1

# Controlla che il volume Windows sia REALMENTE montato (non una cartella fantasma)
if ! mount | grep -q "/Volumes/areacomuneatutti"; then
    echo "ERRORE: volume Windows non montato. Connettiti prima alla rete aziendale."
    exit 1
fi

# Controlla che docs/ esista nel repo
if [[ ! -d "$SRC" ]]; then
    echo "ERRORE: cartella docs/ non trovata in $SCRIPT_DIR"
    exit 1
fi

# ── Git: status, commit, push ─────────────────────────────────────────
cd "$SCRIPT_DIR"

echo "── git status ──"
git status --short

# Se ci sono modifiche, chiedi messaggio e committa
if [[ -n "$(git status --porcelain)" ]]; then
    echo ""
    read -p "Messaggio commit: " msg
    if [[ -z "$msg" ]]; then
        echo "Messaggio vuoto, interrotto."
        exit 1
    fi
    git add -A
    git commit -m "$msg" || { echo "ERRORE: git commit fallito"; exit 1; }
fi

# Push (anche se non c'erano modifiche nuove: utile per commit locali non pushati)
git push || { echo "ERRORE: git push fallito"; exit 1; }

# ── Sync docs/ sul volume Windows ─────────────────────────────────────
mkdir -p "$DST"

# Copia la cartella docs/ del repo
# -a = preserva permessi e timestamp, -v = verbose
# --delete = rimuove nella destinazione i file eliminati nell'origine
rsync -av --delete "$SRC" "$DST"

# Rimuove il flag "hidden" che macOS aggiunge sui volumi SMB
chflags -R nohidden "$DST"

echo ""
echo "Sincronizzazione completata: $REPO/docs/ → $DST"

# ── Promemoria finale ─────────────────────────────────────────────────
echo ""
echo "------------------------------------------------------"
echo "PROMEMORIA: avvisa Alberto di sincronizzare"
echo "$REPO"
echo "------------------------------------------------------"
