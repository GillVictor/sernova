# Architecture

## Vue d'ensemble
Monolithe modulaire déployé en un seul service API, une base PostgreSQL (un schéma par module). Clients : application mobile Flutter, administration Next.js. Temps réel : SignalR (messagerie, notifications). Paiement : abstraction `IPaymentProvider` avec implémentation simulée en V1.

## Modules (alignés sur le chapitre 3 du mémoire)
| Module | Contenu | Schéma |
|---|---|---|
| Accounts | Pays, localités, utilisateurs, permissions, profils prestataires, vérifications, fichiers, paramètres | accounts |
| Catalog | Catégories, attributs, offres, articles, créneaux, recherche et carte | catalog |
| Matching | Demandes, propositions, diffusion, conversations, messages | matching |
| Transactions | Transactions, lignes, conditions figées, historique, justificatifs, livraison, machine à états | transactions |
| Payments | Paiements, reversements, webhooks, évaluations, litiges | payments |
| Notifications | Notifications, appareils, journal d'actions | notifications |

## Règles de dépendance
- `SharedKernel` : types communs (Money, erreurs, pagination, base d'entité). Aucune dépendance vers les modules.
- Chaque module expose un projet de contrats (interfaces et événements) et garde son domaine privé.
- `ServNova.Api` assemble les modules (routes, authentification, middlewares).
- Dépendances autorisées : Transactions utilise Catalog et Accounts via contrats ; Matching utilise Catalog et Accounts ; Payments utilise Transactions ; Notifications est appelé par tous via événements.

## Arborescence cible
```
backend/
  src/
    ServNova.Api/            (composition, middlewares, routes)
    ServNova.SharedKernel/
    Modules/<Module>/
      Domain/                (entités, objets valeur, règles)
      Features/              (un dossier par cas d'utilisation)
      Infrastructure/        (persistance, services externes)
      Contracts/             (interfaces et événements publics)
  tests/
    Unit/  Integration/  Api/
apps/
  mobile/                    (Flutter)
  admin-web/                 (Next.js)
docs/
```

## Principes transverses
Idempotence (en-tête `Idempotency-Key`), concurrence optimiste (`version` sur Transaction, Demande, Paiement), événements internes pour notifications et journal, tâches d'arrière-plan pour les délais (voir feuille « Tâches planifiées » du contrat), « offre valable » calculée à un seul endroit et réutilisée par la recherche, la carte et la livraison.
