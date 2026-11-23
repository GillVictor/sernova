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

## 2026-11-14 : FR-02 écrans de gestion des catégories (admin web)
Instance : Claude (conversation, rôle développeur administration), branche `feat/fr02-admin-categories` (issue de `feat/p05-admin-skeleton` : à fusionner après P-05).
Fait : page `/categories` (arbre, création, modification et désactivation, caractéristiques) sur les routes EP-021, EP-022, EP-089, EP-090, EP-091 (vérifiées contre le contrat) ; composants `SelectField` et `CheckboxField` en plus de `TextField`, tous avec infobulle d'aide (textes français dans `fr.json`, 10 champs ajoutés) ; serveur factice étendu (409 `DUPLICATE_NAME`, 422 avec `errors[]`, 403 via `MOCK_NO_PERMISSION=1`) ; 25 tests, typecheck et build verts.
Suit : revue croisée ; branchement au vrai backend à S1-T6 en confrontant OP-17 ; OP-15 et OP-16 toujours ouverts.
À signaler : aucun changement de contrat. L'interface ne cache rien selon les permissions (OP-16) ; le serveur reste l'autorité (403). Hors zone : `docs/` uniquement (BOARD, WORKLOG, OP-17). Pas de désactivation d'une catégorie « utilisée » côté interface : elle dépend de la réponse 409 du serveur.

## 2026-11-14 : revue de sécurité du front (auto-revue)
Instance : Claude, sur `feat/fr02-admin-categories`. Rapport : `docs/project/reviews/2026-11-14-front-securite.md` (10 constats, 7 corrigés avec tests, 3 ouverts : OP-16, OP-18). 34 tests, typecheck et build verts. Revue croisée par une autre instance toujours nécessaire.

## 2026-11-23 : FW-01 corrections de la revue de l'admin web
Instance : Claude (rôle développeur administration), branche `fix/fw01-admin-review` (issue de `main` après la fusion de la PR n°3).
Fait (tests écrits d'abord, vérifiés en échec puis en succès) : l'infobulle se ferme avec Échap même quand le focus reste sur le bouton, et reste accessible à la souris (WCAG 1.4.13) ; chargement des caractéristiques sans course entre catégories ni affichage de la liste de la catégorie précédente (hook `useCategoryAttributes`) ; le message de succès disparaît quand on change d'action ; `next-env.d.ts` n'est plus suivi (`typecheck` le régénère avec `next typegen`) ; `engines` et `.nvmrc` (Node 22.13 ou plus), `jsdom` 29 compatible avec Node 24.13 ; serveur factice sur les deux adresses locales (correctif `0f5b034`). 46 tests, typecheck, build et `npm audit` verts.
Suit : revue croisée ; OP-21 (catégories désactivées) à trancher avant S1-T6 ; les statuts de P-05 et FR-02, fusionnées, restent « En revue » dans `BOARD.md` : à passer à « Terminé » par l'humain.
À signaler : aucun changement de contrat ; OP-21 propose un ajout. Le mobile n'est pas touché. Hors zone : `docs/` seulement.
