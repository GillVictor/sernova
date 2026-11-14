# Journal de bord

Une entrée par session, la plus récente en bas. Format : date, instance et rôle, ce qui a été fait, ce qui suit, points à signaler.

## 2026-11-14 : mise en place de la structure du projet
Instance : Claude (conversation, rôle architecte).
Fait : classes finales (28), matrice des transitions, dictionnaire de données (224 attributs), contrat d'API (113 points d'accès), dépôt de démarrage, structure de pilotage.
Suit : PM-01 (calendrier), PM-02 (points ouverts), puis S1-T0.
À signaler : le calendrier n'est pas connu ; les heures de la feuille de route sont des propositions.

## 2026-11-14 : arbitrage des points ouverts et calendrier
Instance : Claude (conversation, rôle architecte).
Fait : OP-01 à OP-14 validés (D17 à D27) ; CodeSms ajouté au dictionnaire ; route EP-114 ajoutée au contrat (114 points d'accès) ; créneaux rattachés au profil (dictionnaire, contrat, diagramme 1/3) ; jalons en heures reçus : 720, 840, 960 ; feuille de route réordonnée autour de ces jalons ; dépôt GitHub créé.
Suit : décision sur la visibilité du dépôt (PM-04), liste des villes (OP-09), puis S1-T0.

## 2026-11-14 : localités et voies parallèles
Instance : Claude (conversation, rôle architecte).
Fait : dix villes du Congo fournies par l'humain, converties en jeu de départ ; deux niveaux de localité (ville, quartier facultatif) ; `villeCle` ajoutée au dictionnaire ; squelette détaillé des modules ; voies de travail parallèles définies (`LANES.md`) avec les tâches P-01 à P-08.
Suit : pousser la structure dans le dépôt GitHub, lancer S1-T0 (voie A) et les voies E, F, H.

## 2026-11-14 : P-05 squelette de l'administration Next.js
Instance : Claude (conversation, rôle développeur administration), branche `feat/p05-admin-skeleton`.
Fait : `apps/admin-web` (Next 16, React 19, TypeScript) : écran de connexion (EP-004), client d'API avec renouvellement des jetons (EP-005) et déconnexion (EP-006), page d'accueil (EP-009), serveur factice sans dépendance, textes français dans `src/i18n/fr.json`, composants `TextField` + `FieldHelp` (infobulle d'aide obligatoire sur chaque champ). 13 tests, typecheck et build verts ; `npm audit` sans alerte.
Suit : revue croisée, puis FR-02 (catégories) une fois OP-15 et OP-16 tranchés ; P-04 (Flutter) reprend les mêmes clés de texte.
À signaler : j'ai écrit hors de ma zone dans `docs/` (D29 proposée, OP-15, OP-16, BOARD, WORKLOG) et `.github/workflows/ci.yml` (job `admin-web`). Aucun changement de contrat. Flutter n'était pas installable dans l'environnement : P-04 non commencée.
