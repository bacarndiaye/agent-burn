# agent-view

Vue terminal et web d'un atelier d'agents de code : un manager, des superviseurs, des développeurs, répartis
dans des « salles » par moteur (modèle local, second poste, GLM, Claude, Codex). Un seul fichier Python 3, sans
dépendance. La page « Conso & quotas » est alimentée par `agent-burn` (ce dépôt).

## Modes

| Commande | Rôle |
| --- | --- |
| `agent-view` | tableau terminal, une fois : agents en action / en veille / finis, flux des messages |
| `agent-view live [s]` | même tableau rafraîchi toutes les `s` secondes (2 par défaut) |
| `agent-view serve [port]` | vue web sur `127.0.0.1:<port>` (8765 par défaut) : bureaux en 3D ou 2D, communications, fils |
| `agent-view debit` | tokens/s et contexte moyen par session, par modèle (voir ci-dessous) |
| `agent-view conso` | consommation et quotas d'après agent-burn (voir ci-dessous) |
| `agent-view couts` | tokens produits par les moteurs locaux / GLM, valorisés au tarif Opus |
| `agent-view liens` | qui dirige qui, qui attend qui, messages perdus |
| `agent-view worktrees [--tout]` | worktrees jamais poussés, en retard ou modifiés |

Pages web : `/` (bureaux), `/conso`, `/liens`, `/worktrees`.

## États d'un agent

- **en action** : transcript écrit depuis moins de 90 s, arbre de processus actif (CPU), ou écriture récente dans le worktree ;
- **en veille** : processus vivant sans activité ;
- **fini** : processus mort (vérifié par pid et heure de démarrage).

Les agents s'inscrivent dans un bus de messages par fichiers (`agent-msg`, `~/.cache/agent-bus` ou `$AGENT_BUS`).
Le manager a une salle fixe ; les salles des moteurs locaux et GLM affichent leurs créneaux (pris / libres).

## Conso & quotas

agent-view lance `agent-burn` en arrière-plan (consommation toutes les 10 min, limites toutes les 2 min) ; la
page affiche toujours la dernière donnée et son âge, jamais une attente :

- coût équivalent API par jour, empilé par classe **gratuit** / **abonnement** / **payant** ;
- tokens par jour par classe, **part gratuite** (période, 7 j, aujourd'hui) et coût évité (tokens gratuits
  valorisés au prix moyen du token payant de la période — une estimation, pas une facture) ;
- top modèles, valeur des abonnements (formule détectée, valeur mensuelle estimée) ;
- limites 5 h et 7 j (Claude) et fenêtre Codex, avec l'heure de remise à zéro. Le quota GLM n'est pas exposé.
- **débit et contexte par modèle** (lus directement dans les journaux, sans agent-burn, 7 derniers jours ;
  `AV_DEBIT_JOURS` pour changer) : appels, **tokens/s effectifs** = tokens générés ÷ durée de l'appel, du dernier
  message ou résultat d'outil reçu à la fin du dernier bloc de la réponse — préremplissage du prompt et attente d'un
  créneau compris, donc la vitesse vécue par l'agent et non le décodage pur du serveur ; médiane ; durée moyenne d'un
  appel ; **contexte moyen** (moyenne, par session, des tokens d'entrée de chaque appel, cache compris) et **pic
  moyen** (contexte maximal atteint par session). Session = un transcript Claude Code (sous-agents compris) ou un
  rollout Codex ; un appel de plus de 15 min est écarté du débit. Premier calcul ~20 s, puis seuls les fichiers
  modifiés sont relus.

Classes : un modèle est **gratuit** s'il est rattaché à un moteur local (`local` ou `strata`) dans la table
`modeles` de la configuration ; sinon il est classé par préfixe (`classes`). Les modèles locaux sont comptés à 0 $
grâce aux `pricingOverrides` d'agent-burn (`config/agent-burn.json`).

Binaire : `$AV_AGENT_BURN`, sinon `agent_burn.binaire` de la configuration (`~/.local/bin/agent-burn` par défaut).
Sans binaire, la page le dit et le panneau « Part gratuite » de la page principale garde son ancien calcul.

## Configuration locale

Rien de propre à une infrastructure n'est versionné. Les noms de salles, URL des moteurs, modèles maison, dossier
des clés et racines des dépôts se règlent dans un fichier local : `$AV_CONFIG`, sinon
`~/.config/agent-view/config.json`. Point de départ : [`config.example.json`](config.example.json). Une clé
absente garde sa valeur par défaut.

| Clé | Contenu |
| --- | --- |
| `titre` | titre des pages |
| `pieces` | salles : `[moteur, nom, capacité affichée, couleur]` |
| `moteurs_url` | sous-chaînes d'`ANTHROPIC_BASE_URL` qui désignent un moteur |
| `moteurs_cmd` | sous-chaînes de ligne de commande (fournisseur Codex d'un modèle local) |
| `modeles` | modèle journalisé → moteur (`local`, `strata`, `glm`) |
| `noms_moteurs` | libellés des moteurs dans les coûts |
| `dossier_cles`, `fichiers_cles` | un moteur sans fichier de clé n'affiche pas de créneaux |
| `racines_depots` | dossiers dont chaque sous-dossier est un dépôt suivi par `/worktrees` |
| `agent_burn` | `binaire`, `config` (fichier passé à `--config`), `periode` (`month`, `week`…) |
| `classes` | préfixes de modèles `abonnement` et `payant` |

Variables utiles : `AV_CONFIG`, `AV_AGENT_BURN`, `AGENT_BUS`, `AV_JUNIOR`, `AV_CPU_ACTIF`, `AV_EUR_PAR_USD`.

## Sécurité

Le serveur n'écoute que `127.0.0.1`, refuse tout en-tête `Host` qui n'est pas local ou privé (DNS rebinding),
sert ses pages avec une CSP à nonce et échappe tout contenu issu du bus. Lecture seule, sauf la page `/liens`
(« réacheminer » / « classer » un message : requêtes POST gardées, journalisées).

## Installation

Depuis la racine du dépôt : `scripts/install.sh` (voir le README principal). Unité systemd utilisateur
d'exemple : [`agent-view.service`](agent-view.service).
