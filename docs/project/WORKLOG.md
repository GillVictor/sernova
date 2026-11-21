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

## 2026-11-14 : P-04 partie 1, ressources de texte du mobile
Instance : Claude (conversation, rôle développeur mobile), branche `feat/p04-mobile-l10n` (issue de `main`, indépendante de `feat/p05-admin-skeleton`).
Fait : `apps/mobile/lib/l10n/app_fr.arb` (textes d'aide, libellés, exemples et erreurs des écrans EP-001 à EP-008), `l10n.yaml`, contrôleur `tool/check_l10n.mjs` (vert, y compris un cas d'échec vérifié), README d'intégration, passage de relais.
Suit : une instance avec le SDK Flutter termine P-04 (projet, `HelpTextField`, thème, client d'API, tests).
À signaler : aucun code Dart écrit ; le SDK Flutter est inutilisable dans l'environnement (domaine du moteur Dart bloqué). Fichiers hors zone modifiés : `docs/` (BOARD, WORKLOG, handoff) et `.github/workflows/ci.yml` (job `mobile-l10n`) ; les deux branches modifient `ci.yml` et `WORKLOG.md` : prévoir un petit conflit à la fusion.
