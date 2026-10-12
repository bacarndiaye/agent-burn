#!/usr/bin/env bash
# install.sh [--sans-build] [--service] : construit agent-burn (Rust) et installe agent-burn + agent-view dans
# ~/.local/bin ($PREFIX_BIN pour un autre dossier). Remplacement ATOMIQUE (install vers .new puis mv) : un processus qui
# exécute l'ancienne version n'est jamais coupé en pleine lecture. Idempotent : relançable à volonté.
#   --sans-build  réutilise rust/target/release/agent-burn déjà construit
#   --service     installe aussi l'unité systemd utilisateur d'agent-view si elle n'existe pas encore
# Configurations (jamais écrasées) : ~/.config/agent-burn/agent-burn.json (modèles locaux à 0), créée depuis
# config/agent-burn.json si absente ; ~/.config/agent-view/config.json, à créer depuis apps/agent-view/config.example.json.
set -euo pipefail
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${PREFIX_BIN:-$HOME/.local/bin}"
BUILD=1 SERVICE=0
for a in "$@"; do
  case "$a" in
    --sans-build) BUILD=0 ;;
    --service) SERVICE=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "install.sh : option inconnue : $a" >&2; exit 2 ;;
  esac
done
export PATH="$HOME/.cargo/bin:$PATH"

if [ "$BUILD" = 1 ]; then
  command -v cargo >/dev/null || { echo "install.sh : cargo absent — installer Rust (https://rustup.rs) puis relancer" >&2; exit 2; }
  (cd "$RACINE/rust" && cargo build --release --locked -p agent-burn)
fi
[ -x "$RACINE/rust/target/release/agent-burn" ] || { echo "install.sh : binaire absent, relancer sans --sans-build" >&2; exit 2; }
command -v python3 >/dev/null || { echo "install.sh : python3 absent (requis par agent-view)" >&2; exit 2; }
python3 -m py_compile "$RACINE/apps/agent-view/agent-view"

mkdir -p "$BIN"
pose() {   # pose <source> <destination> : rien à faire si identique
  if cmp -s "$1" "$2" 2>/dev/null; then echo "à jour    : $2"; return; fi
  install -m 755 "$1" "$2.new" && mv -f "$2.new" "$2"
  echo "installé  : $2"
}
pose "$RACINE/rust/target/release/agent-burn" "$BIN/agent-burn"
pose "$RACINE/apps/agent-view/agent-view" "$BIN/agent-view"

CFG="$HOME/.config/agent-burn/agent-burn.json"
if [ ! -e "$CFG" ]; then
  mkdir -p "$(dirname "$CFG")" && cp "$RACINE/config/agent-burn.json" "$CFG" && echo "config    : $CFG (modèles locaux comptés à 0)"
fi
AVC="${AV_CONFIG:-$HOME/.config/agent-view/config.json}"
[ -e "$AVC" ] || echo "astuce    : copier apps/agent-view/config.example.json vers $AVC puis l'adapter (salles, moteurs, modèles locaux)"

UNITE="$HOME/.config/systemd/user/agent-view.service"
if [ "$SERVICE" = 1 ] && [ ! -e "$UNITE" ]; then
  mkdir -p "$(dirname "$UNITE")" && cp "$RACINE/apps/agent-view/agent-view.service" "$UNITE"
  systemctl --user daemon-reload && systemctl --user enable --now agent-view.service && echo "service   : agent-view.service activé"
elif command -v systemctl >/dev/null && systemctl --user cat agent-view.service >/dev/null 2>&1; then
  systemctl --user restart agent-view.service && echo "service   : agent-view.service redémarré"
fi
