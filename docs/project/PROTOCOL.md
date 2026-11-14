# Protocole de collaboration

## Rôles
| Rôle | Responsabilité | Zone de fichiers |
|---|---|---|
| Responsable produit (humain, PDG Gilles) | Décide, tranche les points ouverts, valide les fusions | Tout |
| Architecte et documentation | Contrat d'API, dictionnaire, décisions, plans de tranche, mémoire | `docs/` |
| Développeur backend | Tâches des tranches S* | `backend/` |
| Développeur mobile | Application Flutter | `apps/mobile/` |
| Développeur administration | Console Next.js | `apps/admin-web/` |
| Qualité et sécurité | Revue croisée, tests, durcissement | Tests et revues |
Une instance peut tenir plusieurs rôles, mais une seule tâche à la fois.

## Règles
1. **Le dépôt est la mémoire commune.** Toute décision, tout état d'avancement et toute ambiguïté s'écrivent dans `docs/`.
2. **Une tâche, un propriétaire.** On prend une tâche en la marquant « En cours » dans `BOARD.md` (commit poussé avant de coder). Si deux instances entrent en conflit sur `BOARD.md`, la seconde choisit une autre tâche.
3. **Une zone, un rôle.** On ne modifie pas les fichiers d'un autre rôle sans le dire dans le `WORKLOG.md`. `docs/reference/` (contrat et dictionnaire) ne change que par une PR « docs » séparée, avant le code qui en dépend.
4. **Branches** : `feat/<tâche>-<mot>`, `fix/...`, `docs/...`. **Commits** : `type(module): résumé`. PR petites, une tâche chacune.
5. **Revue croisée** : l'auteur ne fusionne pas sa propre PR ; une autre instance ou l'humain relit avec la liste de la PR.
6. **Nouvelle décision** : ligne dans `decisions.md` (statut Proposée), puis validation par l'humain. **Ambiguïté** : ligne dans `open-points.md`, tâche « Bloqué », question à l'humain.
7. **Sécurité, argent, données personnelles** : jamais de devinette. Aucun secret ni donnée réelle dans le code, les commits ou les messages.
8. **Mémoire** : toute modification de conception qui touche un diagramme ou un tableau du mémoire s'ajoute à `MEMOIRE-TRACKER.md`.
9. **Sessions courtes** : une tâche par session, ne pas réécrire de gros fichiers, citer les identifiants EP et les tables du dictionnaire.

## Début de session
Lire `AGENTS.md`, `BOARD.md`, les dix dernières entrées de `WORKLOG.md`, la fiche de la tâche (et son plan de tranche), puis annoncer la tâche choisie.

## Fin de session
1. Tests verts ou état exact des échecs noté.
2. `BOARD.md` mis à jour (statut, branche).
3. Entrée ajoutée à `WORKLOG.md`.
4. Passage de relais (`templates/handoff.md`) si la tâche est inachevée.

## Définition de « prêt » et de « terminé »
Prêt : contrat, dictionnaire et critères d'acceptation existent pour la tâche ; pas de dépendance bloquante.
Terminé : voir `AGENTS.md` (conformité au contrat, tests verts, migrations, sécurité, documentation, tableau et journal à jour).
