# Rails AI Rules

Règles de sécurité pour agents de code sur les projets Rails DINUM.

## Développement

Toute modification doit être appliquée aux deux agents supportés :
- **Claude Code** : `settings.json`
- **Codex** : `codex.codexpolicy`

Quand tu ajoutes/modifies une règle, mets à jour les deux fichiers et les tests systématiquement.

## Tests

Lancer les tests après chaque modification :

```bash
./tests/run_tests.sh
```

Ne jamais considérer une tâche terminée sans que les tests passent.
Si un test échoue, corriger et relancer jusqu'à ce que tout passe.
