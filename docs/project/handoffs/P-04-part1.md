# Passage de relais : P-04 (partie 1) Squelette Flutter
- Date et instance : 2026-11-14, Claude (rôle développeur mobile).
- État : les ressources de texte sont prêtes et contrôlées (`apps/mobile/lib/l10n/app_fr.arb`, 55 messages, 12 champs avec aide ; `node apps/mobile/tool/check_l10n.mjs` vert). Aucun code Dart n'a été écrit ni exécuté : le SDK Flutter n'a pas pu être installé (le téléchargement du moteur Dart est bloqué par le réseau de l'environnement).
- Branche et dernier commit : `feat/p04-mobile-l10n`.
- Reste à faire : tout le projet Flutter (voir `apps/mobile/README.md`, section « Pour l'instance qui crée le projet Flutter ») : création du projet, `HelpTextField` avec infobulle obligatoire, thème, navigation, client d'API (EP-001 à EP-009), serveur factice ou réutilisation de `apps/admin-web/mock/server.mjs` à étendre, tests `flutter analyze` et `flutter test`.
- Pièges rencontrés : en ARB, les clés doivent être en lowerCamelCase ; un nom de clé finissant par `Label`, `Hint` ou `Help` est considéré par le contrôleur comme un champ de saisie.
- Décisions prises ou questions pour l'humain : aucune règle de mot de passe ni longueur de code SMS dans le contrat ou le dictionnaire (les aides n'en citent pas) ; à trancher avec S1-T3.
