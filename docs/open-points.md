# Points ouverts

Les points OP-01 à OP-14 ont été arbitrés le 2026-11-14 (voir `decisions.md`, D17 à D28). Restent ouverts :

| # | Sujet | Responsable | Échéance |
|---|---|---|---|
| OP-07b | Valeur du taux de commission | Humain | Avant la tranche S3 |
| OP-09b | Liste des quartiers de Brazzaville et de Pointe-Noire (fichier `congo-districts.csv`) | Humain | Avant la fin de la tranche S2 |
| OP-14b | Choix du fournisseur SMS pour la démonstration | Humain | Avant la tranche S6 |
| OP-15 | Admin web : où garder les jetons ? Choix actuel : mémoire seulement (sûr contre le XSS, mais reconnexion à chaque rechargement). Alternative : cookie `HttpOnly` posé par le serveur, ce qui demande un changement du contrat (EP-004/005) | Humain + architecte | Avant FR-02 |
| OP-16 | Admin web : comment le front sait-il quelles permissions admin (ex. `categories.manage`) a l'utilisateur ? Le contrat dit « lues dans le jeton » ; la réponse de EP-009 ne les liste pas. Proposition : ajouter `permissions[]` à EP-009 | Architecte | Avant FR-02 |
| OP-17 | Schémas de FR-02 : le contrat donne des noms de champs « indicatifs ». Hypothèses faites par l'admin web : catégorie `{id, name, order, active, family, minVerificationLevel, children[]}` ; `family` et `minVerificationLevel` aux valeurs du dictionnaire (`Numerique`…, `N0`…) ; `options` d'une caractéristique envoyée en texte, valeurs séparées par des virgules ; `parentId` ou `family` (jamais les deux) à la création. À confirmer ou corriger à S1-T6 | Architecte | Avant S1-T6 |
| OP-18 | Durcissement restant du front : CSP à nonce (sans `'unsafe-inline'`) demande un rendu dynamique ; épingler les actions GitHub par empreinte | Architecte | Avant la démonstration |
| OP-21 | Admin web : EP-021 ne renvoie que les catégories actives, et aucune route admin ne liste toutes les catégories. Une catégorie désactivée disparaît de l'écran d'administration et ne peut plus être réactivée. Proposition : un paramètre `includeInactive` sur EP-021 réservé à `categories.manage`, ou une route `GET /admin/categories` | Architecte | Avant S1-T6 |
