# Agent Burn

Native macOS app and local CLI for coding-agent usage, limits, and subscription value.

## Ce que ce fork ajoute

Fork de [Melvynx/agent-burn](https://github.com/Melvynx/agent-burn) adapté à un usage sous Linux / WSL, où
plusieurs agents de code (Claude Code, Codex, modèles locaux auto-hébergés, GLM) travaillent en parallèle. Le
reste de ce README est celui d'amont ; l'application macOS n'est pas modifiée.

- **agent-view intégré** ([`apps/agent-view`](apps/agent-view)) : vue terminal et web de l'atelier d'agents —
  manager, superviseurs, développeurs ; états *en action* / *en veille* / *fini* ; salles par moteur avec leurs
  créneaux ; messagerie `agent-msg`, fils et liens entre agents. Modes : `agent-view` (tableau), `agent-view live`
  (tableau rafraîchi), `agent-view serve` (pages web sur `127.0.0.1:8765`), `agent-view conso`.
- **Conso & quotas** (page `/conso`, commande `agent-view conso`) alimentée par agent-burn : coût équivalent API
  par jour par classe *gratuit* / *abonnement* / *payant*, part gratuite des tokens et coût évité, top modèles,
  valeur des abonnements, limites 5 h / 7 j avec l'heure de remise à zéro. agent-burn tourne en arrière-plan avec
  un cache : la page n'attend jamais.
- **Débit et contexte par modèle** (même page, commande `agent-view debit`) : tokens/s effectifs (moyenne et
  médiane), durée moyenne d'un appel, contexte moyen et pic moyen par session, sur les 7 derniers jours de journaux
  Claude Code et Codex (`AV_DEBIT_JOURS`).
- **Modèles locaux comptés à 0** : `pricingOverrides` de [`config/agent-burn.json`](config/agent-burn.json).
- **`summary --json --breakdown`** ajoute `dailyModels`, la matrice jour × modèle déjà calculée pour le rapport
  HTML, pour empiler un jour par modèle sans relancer une commande par jour.
- **Historiques Claude volumineux** : avec `--since` (ou une plage `today` / `week` / `month`…), les transcripts
  dont la dernière écriture précède la période (marge de deux jours) ne sont plus relus. Sur un historique de
  ~4 000 fichiers / 10 Go, `summary week` passe de 88 s à 32 s. `harness claude` scanne toujours l'historique
  complet (tendance sur 8 semaines) ; pour les seules limites, `AGENT_BURN_QUOTA_ONLY=1 agent-burn harness claude
  --json` répond en 1 à 2 s.
- **Build et installation Linux** : [`scripts/install.sh`](scripts/install.sh) construit le binaire Rust et
  installe `agent-burn` et `agent-view` dans `~/.local/bin` (remplacement atomique, idempotent) ; `--service`
  installe l'unité systemd utilisateur d'agent-view.
- **Configuration locale non versionnée** : noms de machines, URL des moteurs, modèles maison et dossiers vivent
  dans `~/.config/agent-view/config.json` (exemple neutre :
  [`apps/agent-view/config.example.json`](apps/agent-view/config.example.json)). Le dépôt ne contient aucune
  donnée d'infrastructure.

Prérequis : Linux ou WSL, `python3` (agent-view, sans dépendance), Rust stable via [rustup](https://rustup.rs)
pour construire agent-burn, `systemd --user` facultatif.

```bash
scripts/install.sh            # construit et installe agent-burn + agent-view
scripts/install.sh --service  # idem, et active agent-view.service (http://127.0.0.1:8765)
agent-view conso              # consommation et quotas dans le terminal
```

Documentation d'agent-view : [`apps/agent-view/README.md`](apps/agent-view/README.md).

Site: [agent-burn.melvynx.dev](https://agent-burn.melvynx.dev)

`summary` is the all-up local spend view. `harness <claude|codex>` is the weekly subscription-limit view. The npm package also installs `burn` as a short alias.

## Install

**Mac app:** [Download](https://agent-burn.melvynx.dev/download), unzip, move to Applications. macOS 14+, Apple Silicon and Intel. The app bundles the CLI.

**CLI:**

```bash
npx agent-burn@latest summary --value
pnpm dlx agent-burn@latest harness claude --value
bunx agent-burn@latest harness codex --value
```

## Commands

```bash
agent-burn
agent-burn summary
agent-burn summary today
agent-burn summary week --value
agent-burn harness claude --value
agent-burn harness codex --value
agent-burn summary --json
```

macOS app: menu-bar quota for Codex, Claude, and Cursor, plus a dashboard across detected harnesses. Build locally with `just macos::run`. Details: [apps/macos](https://github.com/Melvynx/agent-burn/tree/main/apps/macos).

## Subscription Value

`--value` compares local API-equivalent usage with known or supplied monthly plan prices.

```bash
agent-burn summary --value
agent-burn summary --value --claude-plan max-20x --codex-plan pro
agent-burn harness claude --value --claude-plan 200
agent-burn harness codex --value --codex-plan plus
```

Plan overrides:

- Claude: `pro`, `max-5x`, `max-20x`, or a monthly price
- Codex: `plus`, `pro`, or a monthly price
- Cursor: `pro`, `pro+`, `ultra`, or a monthly price

## Shared Options

```bash
--since <YYYYMMDD>       Start date
--until <YYYYMMDD>       End date
--json                   JSON output
--jq <filter>            Apply a jq filter to JSON output
--mode <auto|calculate|display>
--breakdown              Include model breakdowns
--offline                Use embedded pricing and skip live requests
--no-cost                Hide cost fields
--timezone <tz>          Date grouping timezone
--compact                Force compact table layout
--config <path>          Load a config file
```

## Data Sources

Reads local logs. Nothing is uploaded.

| Source | Default location |
| --- | --- |
| Claude Code | `~/.claude`, `~/.config/claude/projects` |
| Codex | `${CODEX_HOME:-~/.codex}` |
| Cursor | Cursor `state.vscdb` plus the signed-in dashboard usage API |

## Acknowledgments

Agent Burn started from [ccusage](https://github.com/ccusage/ccusage) by [ryoppippi](https://github.com/ryoppippi). The original local log readers, cost aggregation, and CLI report patterns are the prior work this project builds on.

## License

MIT. Copyright (c) 2025 ryoppippi and 2026 Melvynx.
