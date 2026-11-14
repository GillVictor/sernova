# ServNova

Marketplace de mise en relation entre clients et prestataires de services (marché d'ancrage : Congo, zone CEMAC ; extension prévue).

## Pour démarrer
1. Copier `.env.example` en `.env` et ajuster les valeurs.
2. `docker compose up -d` (PostgreSQL 17 et Mailpit pour les e-mails de test).
3. Suivre `docs/plan-S1.md`, tâche T0, pour créer la solution .NET.
4. Lancer les tests : `dotnet test backend`.

## Documents de référence (ordre de priorité)
1. `docs/reference/data-dictionary.xlsx` : schéma des données.
2. `docs/reference/api-contract.xlsx` : points d'accès (EP-001 à EP-114).
3. `docs/transaction-state-machine.md` : transitions de la transaction et du paiement.
4. `docs/decisions.md` et `docs/open-points.md` : décisions prises et points ouverts.
5. `docs/architecture.md` : structure du code. `AGENTS.md` : consignes aux agents IA.

Les fichiers `docs/reference/*.mermaid` sont des diagrammes de classes de travail (source en texte).

## Pilotage du projet
Tout le pilotage est dans `docs/project/` : `ROADMAP.md` (phases et critères de sortie), `BOARD.md` (tâches et statuts), `PROTOCOL.md` (règles de collaboration entre instances), `WORKLOG.md` (journal), `MEMOIRE-TRACKER.md` (modifications à reporter dans le mémoire), `PROMPTS.md` (consignes de démarrage par rôle).
