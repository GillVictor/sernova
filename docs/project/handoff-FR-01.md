# Passage de relais : FR-01 tranche 1, authentification mobile
- Date et instance : 2026-11-24, Claude (développeur mobile)
- État : code et tests de la tranche 1 écrits (EP-004, EP-005, EP-006, session, page de connexion, porte, bouton de déconnexion). `flutter test` : 172 tests réussis sur le poste de Gilles (2026-11-24), dont les 6 fichiers de la tranche 1 et tout le code FR-03 à FR-07. `flutter analyze` : à reconfirmer (« No issues found » attendu après le retrait de l'import inutile de test/widget_test.dart). Non vérifié à l'écran : la disposition du bouton de déconnexion, et aucun essai contre un vrai backend (EP-004 à EP-006 testés avec des réponses simulées seulement).
- Branche et dernier commit : feat/fr01-mobile-auth, issue de docs/op-15-17-29-arbitrage (1018f44) ; voir `git log` de la branche.
- Reste à faire :
  1. Lancer l'application contre le backend (API_BASE_URL) et essayer connexion, renouvellement et déconnexion de bout en bout, puis regarder le bouton de déconnexion à l'écran.
  2. D31 validée le 2026-11-25 : `SecureTokenStore` (flutter_secure_storage ^11.2.0) est écrit et branché, mais PAS exécuté : lancer `flutter pub get` (régénère pubspec.lock, à commiter), `flutter analyze`, `flutter test`. Si pub get refuse la version 11 pour ton Flutter, passer à ^10.3.1. Puis essayer sur un appareil ou un émulateur : se connecter, fermer l'application, la rouvrir (la session doit revenir).
  3. FR-01 tranche 2 : inscription EP-001, vérification du téléphone EP-002, renvoi du code EP-003, parcours PHONE_NOT_VERIFIED (OP-32).
  4. Parcours « devenir prestataire » EP-011 dans l'onglet Compte.
  5. Bouton de déconnexion pour la disposition `NavPlacement.bottomBar` (absente pour l'instant).
- Pièges rencontrés : le jeton de rafraîchissement ne doit jamais être utilisé deux fois (rotation, révocation de la famille) : le renouvellement est à appel unique partagé (`SessionController.refresh`). Le bouton de déconnexion est placé dans `NavigationRail.trailing` à l'intérieur d'un `IntrinsicHeight` : disposition non vérifiée à l'écran. `test/widget_test.dart` était un test par défaut cassé (corrigé).
- Décisions prises ou questions pour l'humain : D31 à valider (paquet de stockage sécurisé). OP-32 (PHONE_NOT_VERIFIED absent de la feuille Erreurs) et OP-33 (déconnexion avec jeton d'accès expiré, sens de TOKEN_EXPIRED, format du téléphone). Brancher le dépôt GitHub à la session pour pouvoir pousser.

## Mise à jour 2026-11-25 : tranche 2 (inscription et vérification du téléphone)
- État : écrite sur feat/fr01-signup (issue de main 953f4e6). `flutter test` : 247 tests réussis sur le poste de Gilles (2026-11-26). `flutter analyze` : « No issues found » (2026-11-27). Jamais essayée à l'écran ni contre un backend.
- Essai à l'écran : créer un compte (E.164, ex. +242…), recevoir le code, le saisir (la session s'ouvre et les pages d'inscription disparaissent), tester « Renvoyer le code », puis une connexion refusée avec PHONE_NOT_VERIFIED (le lien « Vérifier mon numéro » apparaît).
- Restent : EP-011 (devenir prestataire), bouton de déconnexion de la barre du bas, essai contre le vrai backend, sélecteur d'indicatif (OP-40). Questions : OP-37 à OP-40.

## Mise à jour 2026-11-26 : EP-011 (branche feat/fr09-become-provider)
- État : écrite, empilée sur feat/fr01-signup (fusionner la PR FR-01 d'abord). `flutter analyze` propre et 271 tests réussis le 2026-11-27 (poste de Gilles). Jamais essayée à l'écran ni contre un backend.
- Essai à l'écran : client simple, onglet Compte, « Créer mon profil prestataire », remplir, valider : le bouton Prestataire doit apparaître dans le menu. En mode factice (`USE_FAKE_API=true FAKE_PROVIDER_ACTIVE=false`) le compte passe en Actif après l'envoi.
- Questions : OP-41 à OP-43.
