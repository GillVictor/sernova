# Points ouverts

Les points OP-01 à OP-14 ont été arbitrés le 2026-11-14 (voir `decisions.md`, D17 à D28). Restent ouverts :

| # | Sujet | Responsable | Échéance |
|---|---|---|---|
| OP-07b | Valeur du taux de commission | Humain | Avant la tranche S3 |
| OP-09b | Liste des quartiers de Brazzaville et de Pointe-Noire (fichier `congo-districts.csv`) | Humain | Avant la fin de la tranche S2 |
| OP-14b | Choix du fournisseur SMS pour la démonstration | Humain | Avant la tranche S6 |
| OP-15 | Admin web : où garder les jetons ? Choix actuel : mémoire seulement (sûr contre le XSS, mais reconnexion à chaque rechargement). Alternative : cookie `HttpOnly` posé par le serveur, ce qui demande un changement du contrat (EP-004/005) | Humain + architecte | Avant FR-02 |
| OP-16 | Admin web : comment le front sait-il quelles permissions admin (ex. `categories.manage`) a l'utilisateur ? Le contrat dit « lues dans le jeton » ; la réponse de EP-009 ne les liste pas. Proposition : ajouter `permissions[]` à EP-009 | Architecte | Avant FR-02 |
