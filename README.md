# Rails AI Rules - DINUM Pôle Data/API

Règles de sécurité pour les agents de codes centralisées pour les applications Rails du pôle Data/API de la DINUM.

## Risques adressés

- **Exfiltration de secrets** : credentials, master.key, .env, clés SSH
- **Prompt injection** : commandes dangereuses (merge PR, édition credentials)

Il n'existe actuellement aucun moyen efficace de se protéger contre les prompts
injections, ces règles permettent de bloquer les commandes les plus à risque et
d'empêcher l'accès aux secrets.

## Prérequis

- [jq](https://jqlang.github.io/jq/) pour le merge JSON

## Installation

```bash
# Dans le projet Rails cible
git submodule add <url-du-repo> rails_ai_rules
./rails_ai_rules/install.sh
```

## Ce que ça protège

### Claude Code (`.claude/settings.json`)

Deny rules qui bloquent :
- Lecture/écriture des secrets : dotfiles (`.env*`), Rails credentials (`master.key`, `*.key`, `credentials*`)
- Commandes dangereuses : `rails credentials:*`, `gh pr merge*`

### Codex (`.codexpolicy`)

Exec policy qui interdit :
- Lecture des secrets via `cat`, `head`, `tail`, `less` sur `.env`, `master.key`, `credentials`
- `rails credentials:edit`, `rails credentials:show`
- `gh pr merge`, `gh merge`

## Mise à jour

```bash
git submodule update --remote rails_ai_rules
./rails_ai_rules/install.sh
```

L'installation est idempotente : les deny rules sont mergées sans doublons.

## Tests

```bash
./tests/run_tests.sh
```

Utilise un dummy app Rails minimal (`tests/dummy_app/`) pour vérifier :
- Installation et merge des deny rules
- Idempotence (pas de doublons)
- Préservation des règles custom existantes

## Contribuer

1. Fork + branche
2. Modifier les fichiers (`settings.json`, `codex.codexpolicy`, `install.sh`)
3. Tester dans un projet Rails
4. PR
