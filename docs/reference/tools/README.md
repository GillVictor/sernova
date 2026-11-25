# Outils du contrat

`generate_openapi.py` produit `../openapi.yaml` (OpenAPI 3.1, 114 opérations) à partir de `api-contract.xlsx` et `data-dictionary.xlsx`. Il sert à :
- générer un client ou un serveur factice commun aux deux fronts (tâche P-07, étape 2) ;
- tester côté backend que les routes exposées sont celles du contrat (S1-T10).

```bash
pip install pyyaml openpyxl
python docs/reference/tools/generate_openapi.py          # régénère openapi.yaml
python docs/reference/tools/generate_openapi.py --check  # échoue si le fichier n'est pas à jour (utilisable en CI)
```

Règles : ne jamais modifier `openapi.yaml` à la main ; corriger le contrat puis régénérer. Au 2026-11-24, 20 routes ont un schéma de réponse fixé par la feuille Schémas ; les autres gardent un schéma `x-schema-status: indicative`, précisé tranche par tranche. Les codes d'erreur sont dans `components.x-error-codes`.
