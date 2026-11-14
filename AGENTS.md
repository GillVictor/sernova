# Consignes pour les agents IA (ServNova)

## Contexte
ServNova est une marketplace où les clients trouvent des offres de prestataires (ou publient une demande) et paient via des fonds réservés libérés à la validation. Projet de mémoire d'ingénieur : le code doit être clair, testé et défendable devant un jury.

## Sources de vérité (lire avant de coder)
1. `docs/reference/data-dictionary.xlsx` : tables, types, contraintes, énumérations, paramètres.
2. `docs/reference/api-contract.xlsx` : chemins, accès, erreurs. Ne pas inventer de route ni de champ : proposer le changement dans `docs/open-points.md` d'abord.
3. `docs/transaction-state-machine.md` : seules transitions autorisées.
4. `docs/decisions.md` : décisions déjà prises, à respecter.

## Pile technique
Backend : ASP.NET Core (dernière version LTS), EF Core avec Npgsql, PostgreSQL 17. Application client mobile : Flutter. Administration : Next.js. Conteneurs : Docker. Le front du prestataire est un point ouvert (voir `docs/open-points.md`).

## Architecture
Monolithe modulaire, six modules alignés sur le mémoire : Accounts, Catalog, Matching, Transactions, Payments, Notifications. Détails et règles de dépendance dans `docs/architecture.md`.
- Un module n'accède jamais au DbContext ou aux tables d'un autre module : il passe par une interface publique du module ou par un événement interne.
- La logique métier vit dans le domaine (entités, objets valeur, machine à états), pas dans les contrôleurs.
- Une fonctionnalité = un dossier de cas d'utilisation (requête, validation, gestionnaire, route).

## Conventions
- Code, identifiants et commentaires en anglais ; textes affichés à l'utilisateur en français via fichiers de ressources (traductions prévues). Les noms suivent le Glossaire du contrat d'API.
- Identifiants : `Guid.CreateVersion7()`. Dates : UTC, `TimeProvider` injecté (jamais `DateTime.Now`).
- Montants : objet valeur `Money` (entier en plus petite unité + devise ISO 4217). Jamais de `double` ni de `decimal` pour l'argent.
- Erreurs métier : exception de domaine avec code stable (voir feuille Erreurs du contrat), transformée en `application/problem+json` par un middleware unique.
- Validation des entrées : FluentValidation à la frontière HTTP.
- Journalisation structurée (Serilog) avec identifiant de corrélation égal à `traceId`.
- Tables en `snake_case`, un schéma PostgreSQL par module, horodatages `timestamptz`.

## Sécurité (non négociable)
- Aucun secret dans le dépôt ; configuration par variables d'environnement.
- JWT d'accès 15 min, renouvellement avec rotation et détection de réutilisation.
- Mots de passe avec `PasswordHasher` d'ASP.NET Core ; jamais renvoyés ni journalisés.
- Chaque route vérifie authentification, rôle ou permission, et propriété de la ressource (éviter les accès à la ressource d'un autre utilisateur).
- Limitation de débit sur connexion, codes SMS, code de remise, créations.
- Ne jamais exposer : téléphone ou e-mail d'un autre utilisateur, domicile précis, codes de remise en clair.
- Fichiers : liste blanche de types, taille maximale, accès par lien signé de courte durée.

## Méthode de travail pour chaque tâche
1. Lire les lignes EP concernées du contrat et les tables du dictionnaire.
2. Écrire d'abord les tests (xUnit, Testcontainers pour PostgreSQL, `WebApplicationFactory` pour l'API) : cas nominal et au moins un cas d'erreur par route.
3. Implémenter le plus petit changement qui fait passer les tests.
4. Exécuter `dotnet build` et `dotnet test` ; tout doit être vert.
5. Mettre à jour `docs/` si une décision ou une ambiguïté est apparue.
6. Commit atomique, message au format `type(module): résumé` (ex. `feat(accounts): register and verify phone`).

## Définition de « terminé »
Routes conformes au contrat (chemin, accès, erreurs), tests verts, migrations appliquées sur base vide, aucune alerte de sécurité évidente, documentation à jour.

## Interdits
- Modifier un statut de transaction autrement que par une action de la machine à états.
- Supprimer ou modifier `HistoriqueStatut` et `JournalAction`.
- Calculer de l'argent en flottants ; écrire des montants en dur ; coder en dur les délais et plafonds (ils viennent de `ParametrePlateforme`).
- Ajouter une dépendance sans la justifier dans `docs/decisions.md`.

## Travail à plusieurs instances (obligatoire)
Plusieurs instances d'IA et un humain (PDG Gilles, responsable produit) travaillent sur ce dépôt. Le dépôt est la mémoire commune : rien d'important ne doit exister seulement dans une conversation.
- Début de session : lire `docs/project/PROTOCOL.md`, `docs/project/BOARD.md`, les dix dernières entrées de `docs/project/WORKLOG.md`, puis la fiche de la tâche.
- Prendre une tâche = la marquer « En cours » dans `BOARD.md` (propriétaire, branche) dans un commit poussé avant de coder.
- Fin de session : mettre à jour `BOARD.md`, ajouter une entrée au `WORKLOG.md`, rédiger un passage de relais si la tâche est inachevée.
- Toute décision de conception qui touche un diagramme ou un tableau du mémoire : ajouter une ligne à `docs/project/MEMOIRE-TRACKER.md`.
- En cas de doute sur la sécurité, l'argent ou les données personnelles : s'arrêter, marquer la tâche « Bloqué », poser la question à l'humain.
