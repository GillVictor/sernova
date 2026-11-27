# ServNova : backend (.NET 10)

Monolithe modulaire : `src/ServNova.Api` (API), `src/ServNova.SharedKernel`, un projet par module dans
`src/Modules/` (Accounts, Catalog, Matching, Notifications, Payments, Transactions), tests dans `tests/`.
Le contrat est dans `docs/reference/api-contract.xlsx` ; le plan de la tranche dans `docs/plan-S1.md`.

## Démarrer en local

Prérequis : SDK .NET 10 et Docker.

```
cd backend
copy .env.example .env          # puis choisir POSTGRES_PASSWORD (Windows ; cp sous Linux/macOS)
docker compose up -d            # base PostgreSQL locale (pas encore utilisée par l'API avant S1-T1)
dotnet run --project src/ServNova.Api
```

Vérifier : `GET /api/v1/health` répond `200 {"status":"ok"}` (l'adresse affichée au démarrage).

## Tests

```
dotnet test
```

Les tests d'intégration avec base de données (à partir de S1-T1) utilisent Testcontainers et demandent Docker.

## Configuration (variables d'environnement)

| Variable | Rôle | Défaut |
|---|---|---|
| `Cors__AllowedOrigins__0`, `__1`… | Origines navigateur autorisées (https, ou http sur localhost) ; une valeur invalide arrête le démarrage | aucune |
| `RateLimiting__Global__PermitLimit` / `WindowSeconds` | Limite globale par adresse client | 100 / 60 s |
| `RateLimiting__Strict__PermitLimit` / `WindowSeconds` | Limite des routes sensibles | 5 / 60 s |
| `Serilog__MinimumLevel__Default` | Niveau des journaux | Information |
| `OpenApi__Enabled` | Publier `/openapi/v1.json` hors Development | false |

Les erreurs sont en `application/problem+json` avec `code` et `traceId` ; le `traceId` est aussi dans chaque
ligne de journal de la requête. Aucun secret n'est dans le dépôt.
