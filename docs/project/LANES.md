# Voies de travail en parallèle

Principe : plusieurs instances travaillent en même temps sans se marcher dessus. Chaque voie a ses fichiers, ses dépendances et son ordre de fusion. Les voies avancent sur le contrat (`docs/reference/`), pas sur le travail non fusionné des autres.

| Voie | Contenu | Zone de fichiers | Peut démarrer | Dépend de |
|---|---|---|---|---|
| A Backend séquentiel | S1-T0 à S1-T10 | `backend/src/ServNova.Api`, `SharedKernel`, `Modules/Accounts`, catégories dans `Modules/Catalog` | Tout de suite | PM-04 |
| B Domaine pur : transactions | Machine à états (neuf états, gardes, transitions) en logique pure, tests par table | `Modules/Transactions/Domain` | Après S1-T1 | S1-T1 |
| C Domaine pur : correspondance | Fonction de couverture, éligibilité, règle « offre valable » en logique pure | `Modules/Matching/Domain` | Après S1-T1 | S1-T1 |
| D Domaine pur : paiement | `IPaymentProvider`, fournisseur simulé, états du paiement | `Modules/Payments/Domain`, `Infrastructure` | Après S1-T1 | S1-T1 |
| E Application mobile | Squelette Flutter, thème, i18n, infobulles d'aide, client d'API, écrans d'authentification sur un serveur factice | `apps/mobile` | Tout de suite (écrans réels après S1-T3) | contrat |
| F Administration | Squelette Next.js, client d'API, écrans de catégories sur un serveur factice | `apps/admin-web` | Tout de suite | contrat |
| G Qualité | Collection de requêtes, liste de contrôle de sécurité, tests d'API de bout en bout | `backend/tests/Api`, `docs/` | Dès S1-T3 | voie A |
| H Architecte | Plans S2 à S6, génération du schéma OpenAPI à partir du contrat, suivi du mémoire | `docs/` | Tout de suite | |

## Règles d'intégration
1. Les voies B, C, D n'écrivent que de la logique pure (sans base de données, sans HTTP) tant que S1 n'est pas fusionnée ; le branchement à la persistance et aux routes se fait dans la tranche concernée (S2, S3, S4).
2. Une voie ne modifie jamais les fichiers d'une autre ; un besoin transverse passe par une PR « docs » sur le contrat ou par un point ouvert.
3. Fusion vers `main` : petites PR, une tâche chacune, revue par une autre instance ; rebaser sur `main` au début de chaque session.
4. Les voies E et F n'appellent que les routes du contrat ; avant que le backend soit prêt, elles utilisent un serveur factice généré à partir du contrat.
5. Les conflits sur `BOARD.md` se résolvent en faveur de la première instance qui a poussé.
