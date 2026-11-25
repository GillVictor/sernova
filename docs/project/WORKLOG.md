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

## 2026-11-21 : FR-03 écran de recherche d'offres (mobile Flutter)

Instance : Claude (conversation, rôle développeur mobile), branche feat/fr03-mobile-search. Fait : apps/mobile créé (aucun code Flutter n'existait) : socle minimal (client d'API HTTPS avec erreurs problem+json, Money, textes fr.json imbriqués comme l'admin, thème, HelpTooltip) et écran de recherche sur EP-035 (texte avec délai de saisie, filtres catégorie, localité, tri, pagination par curseur, états vide et erreur, réponses périmées ignorées), EP-021 (arbre des catégories) et EP-023 (localités). Infobulle d'aide sur chaque champ. 5 fichiers de tests (client d'API, Money, requête, modèles, contrôleur, page). Suit : revue croisée ; exécuter flutter pub get && flutter analyze && flutter test (Flutter n'était pas installable dans l'environnement : AUCUN test n'a été exécuté) ; écran de détail d'offre (EP-037) ; carte (EP-036) ; FR-01 (navigation, authentification) et le reste de P-04 (serveur factice). À signaler : écrit hors de ma zone dans docs/ (BOARD, WORKLOG, OP-19 à OP-22, D30 proposée). Aucun changement de contrat. Le cœur favori de la maquette n'est pas livré (OP-20). Les anciens écrans d'accueil et de publication d'une demande, produits en conversation avant ce dépôt, ne sont pas inclus : ils doivent être alignés sur EP-038 (titre obligatoire, budget en {amount, currency}, catégorie feuille, Idempotency-Key).

## 2026-11-21 : FR-04 écran de détail d'une offre (mobile Flutter)

Instance : Claude (conversation, rôle développeur mobile), branche feat/fr04-mobile-offer-detail (issue de feat/fr03-mobile-search : à fusionner après FR-03). Fait : écran de détail sur EP-037 (galerie avec compteur, titre, note, prix selon ModePrix, pastilles localité, modalité et vérifié, description repliable, articles d'une vente avec disponibilité, bloc prestataire avec taux de prestations achevées), états chargement, introuvable (404) et erreur avec nouvel essai ; ouverture depuis un résultat de la recherche. Les boutons « Commander cette offre » (EP-051, S3) et « Voir le profil » (EP-019) n'apparaissent que si le parent fournit l'action : ils sont donc absents de l'application tant que ces tâches ne sont pas faites. Formatage du prix et de la note factorisé (catalog_format.dart), utilisé aussi par la carte de résultat. 3 fichiers de tests ajoutés (formatage, contrôleur, page) et le test des modèles étendu. Suit : revue croisée ; exécuter flutter pub get && flutter analyze && flutter test (toujours aucun test exécuté, Flutter indisponible) ; profil public du prestataire (EP-019, EP-020) une fois la maquette fournie ; FR-01 ; commande (S3). À signaler : écrit hors de ma zone dans docs/ (BOARD, WORKLOG, OP-23). Aucun changement de contrat. Partage, favori et délai « 2 à 5 jours » de la maquette non livrés (OP-20, OP-23).

## 2026-11-21 : FR-05 tableau de bord et FR-06 profil prestataire (mobile Flutter)

Instance : Claude (conversation, rôle développeur mobile), branches feat/fr05-mobile-provider-dashboard et feat/fr06-mobile-provider-profile (empilées sur feat/fr04-mobile-offer-detail). Correction d'un travail antérieur : completionRate était lu comme une fraction de 0 à 1 ; le dictionnaire dit 0 à 100. Corrigé (code et tests, OP-23), le sens reste ambigu (OP-24). Fait : client d'API étendu (jeton Bearer fourni par l'appelant, POST, PATCH, PUT, 204), ApiFailure et LoadState partagés, sélecteur de localité factorisé (shared/widgets) et réutilisé par la recherche. Tableau de bord : 4 indicateurs, commandes récentes, notifications avec « Tout marquer lu », chaque bloc charge et échoue séparément. Profil : formulaire (nom, description, localité, liens portfolio et vidéo, validation locale http(s) seulement, PATCH des seuls champs modifiés, erreurs 422 rattachées aux champs), carte de vérification (niveau, téléphone, identité, activité). Infobulle d'aide sur chaque champ. 12 fichiers de tests ajoutés ou étendus. Suit : revue croisée ; exécuter flutter pub get && flutter analyze && flutter test (Flutter indisponible : aucun test exécuté) ; FR-01 (connexion, jeton, navigation par rôle) pour que ces écrans fonctionnent hors développement (DEV_ACCESS_TOKEN ne sert qu'en debug) ; demande de vérification avec fichier (D31) ; liste des commandes (S3). À signaler : écrit hors de ma zone dans docs/ (BOARD, WORKLOG, OP-23 corrigé, OP-24 à OP-27). Aucun changement de contrat. Cloche, photo de profil et barre de navigation de la maquette non livrées (OP-26, OP-27).
## 2026-11-22 : FR-07 coque de navigation mobile (Flutter)

Instance : Claude (conversation, rôle développeur mobile), branche feat/fr07-mobile-shell. Fait : AppShell (barre verticale à droite, variante barre du bas), ShellController (rôle courant, onglet mémorisé par rôle, bascule autorisée seulement si le profil prestataire est actif ; échec de chargement du compte = client simple), deux boutons Client / Prestataire en haut de la barre, menus des deux rôles dans destinations.dart (une entrée sans écran affiche « Bientôt disponible »), pages construites à la première visite puis conservées, pages prestataire retirées si le profil n'est plus actif. Accueil prestataire = tableau de bord, Compte prestataire = profil professionnel, Accueil client = recherche (provisoire). main.dart ouvre la coque ; options de développement START=provider et FAKE_PROVIDER_ACTIVE=false. 2 fichiers de tests (contrôleur, coque). Suit : revue croisée ; flutter analyze et flutter test ; FR-01 (connexion, jeton) ; écran d'accueil client ; parcours « devenir prestataire ». À signaler : écrit hors de ma zone dans docs/ (OP-28, BOARD, WORKLOG). Aucun changement de contrat ; providerStatus dans EP-009 est une hypothèse.

## 2026-11-23 : FW-01 corrections de la revue de l'admin web
Instance : Claude (rôle développeur administration), branche `fix/fw01-admin-review` (issue de `main` après la fusion de la PR n°3).
Fait (tests écrits d'abord, vérifiés en échec puis en succès) : l'infobulle se ferme avec Échap même quand le focus reste sur le bouton, et reste accessible à la souris (WCAG 1.4.13) ; chargement des caractéristiques sans course entre catégories ni affichage de la liste de la catégorie précédente (hook `useCategoryAttributes`) ; le message de succès disparaît quand on change d'action ; `next-env.d.ts` n'est plus suivi (`typecheck` le régénère avec `next typegen`) ; `engines` et `.nvmrc` (Node 22.13 ou plus), `jsdom` 29 compatible avec Node 24.13 ; serveur factice sur les deux adresses locales (correctif `0f5b034`). 46 tests, typecheck, build et `npm audit` verts.
Suit : revue croisée ; OP-29 (catégories désactivées) à trancher avant S1-T6 ; les statuts de P-05 et FR-02, fusionnées, restent « En revue » dans `BOARD.md` : à passer à « Terminé » par l'humain.
À signaler : aucun changement de contrat ; OP-29 propose un ajout. Le mobile n'est pas touché. Hors zone : `docs/` seulement.

## 2026-11-24 : revue d'architecture, contrat v0.2, plan S2
Instance : Claude (rôle architecte), branches `docs/architecte-2026-11-24` (ce dépôt de pilotage) et `docs/contract-v0.2` (contrat et dictionnaire, PR séparée).
Fait : état des lieux (`docs/project/reviews/2026-11-24-architecte-etat-des-lieux.md`) ; contrat v0.2 : feuille Schémas (22 objets), 40 codes d'erreur manquants ajoutés (84 au total), conventions complétées, 7 cellules d'Endpoints corrigées, six points ajoutés à la feuille A valider du dictionnaire ; décisions D31 à D34 (Proposées) ; points ouverts OP-29 à OP-35 et propositions pour OP-15 à OP-35 ; plan S2 (brouillon) et ajustements du plan S1 ; registre du mémoire M19 à M23 ; tableau des tâches (FR-07 à FR-13, FW-02, PM-06 à PM-09, P-07 en cours) et règles 6 à 8 de `LANES.md`.
Suit : fusion de FW-01, du contrat v0.2 puis de cette PR, avec revue croisée ; décisions du responsable produit (OP-32 avant S1-T2) ; **démarrage du backend (S1-T0)** ; P-07 étape 2.
À signaler : aucun code applicatif modifié. Le backend n'a pas démarré ; le code mobile n'existe que dans un commit local non poussé. L'OP-21 de l'administration est devenu OP-29 (collision de numéros).

## 2026-11-24 : P-07 étape 1, OpenAPI généré du contrat
Instance : Claude (rôle architecte), branche `docs/openapi-p07` (issue de `docs/contract-v0.2`).
Fait : `docs/reference/tools/generate_openapi.py` et `docs/reference/openapi.yaml` (OpenAPI 3.1 valide, 114 opérations identiques au contrat, 63 schémas, 84 codes d'erreur, en-tête `Idempotency-Key` sur EP-038, 044, 050, 051 et 055). Mode `--check` utilisable en CI.
Suit : étape 2 (serveur factice commun aux deux fronts, à partir de ce schéma) ; précision des schémas restants tranche par tranche (20 routes sur 114 ont un schéma de réponse fixé).
À signaler : le fichier généré ne se modifie jamais à la main. Fusionner d'abord `docs/contract-v0.2`.

