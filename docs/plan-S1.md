# Plan de la tranche S1 : socle

Objectif : un backend démarrable, sécurisé, avec comptes, profils prestataires, référentiels, fichiers et administration de base. 34 points d'accès (EP-001 à EP-025, EP-082, EP-089 à EP-092, EP-094, EP-095, EP-113, EP-114). Suivre l'ordre ci-dessous ; chaque tâche se termine par `dotnet test` vert et un commit.

## T0 Initialisation (EP-113)
Créer la solution : `dotnet new sln -n ServNova -o backend`, projet `ServNova.Api` (web API avec contrôleurs), `ServNova.SharedKernel`, un projet de bibliothèque par module sous `backend/src/Modules/`, projets de tests dans `backend/tests` (xUnit). Paquets : Npgsql.EntityFrameworkCore.PostgreSQL, FluentValidation, Serilog.AspNetCore, Microsoft.AspNetCore.Authentication.JwtBearer, Testcontainers.PostgreSql, Microsoft.AspNetCore.Mvc.Testing. Mettre en place : route `GET /api/v1/health`, middleware `problem+json` avec `code` et `traceId`, limitation de débit, OpenAPI, Serilog, CORS, lecture de la configuration par variables d'environnement.
Critères : `docker compose up -d` puis l'API démarre ; `/health` répond 200 ; la CI passe.

## T1 Noyau partagé et persistance
`Money` (entier + devise), `TimeProvider`, base d'entité (id UUID v7, creeLe, modifieLe), pagination par curseur, exception de domaine avec code, conventions EF (snake_case, `timestamptz`, un schéma par module), journal d'actions (écriture), jeu de tests d'intégration avec PostgreSQL réel.
Critères : migration vide appliquée sur base neuve ; tests unitaires de `Money` et de la pagination.

## T2 Pays et localités (EP-023, EP-092)
Tables Pays, Localite (avec la clé normalisée villeCle). Données de départ : `docs/reference/seed/congo-localities.csv` (dix villes du Congo, niveau ville) ; vérifier ou compléter les coordonnées, puis passer coord_status à `verifie`. Les quartiers de Brazzaville et de Pointe-Noire viendront d'un second fichier. L'unicité (pays, ville, quartier) doit traiter le quartier vide comme une valeur. Recherche assistée de localités ; création par un administrateur.
Critères : recherche par texte et pays ; doublon (pays, ville, quartier) refusé (DUPLICATE_LOCATION).

## T3 Authentification (EP-001 à EP-008)
Tables Utilisateur, RefreshToken, CodeSms (OP-12, ajoutée au dictionnaire). Interface `ISmsSender` avec implémentation « console » en développement. Inscription, vérification du numéro, renvoi du code, connexion, rotation des jetons avec détection de réutilisation, déconnexion, réinitialisation du mot de passe. Limitation de débit stricte sur les routes de code.
Critères : un code ne sert qu'une fois, expire, et est limité en essais ; un compte suspendu ne se connecte pas (423) ; un jeton de renouvellement réutilisé révoque la famille ; le mot de passe n'apparaît dans aucune réponse ni aucun journal.

## T4 Compte et appareils (EP-009, EP-010, EP-012, EP-013)
Lecture et modification du compte, enregistrement et retrait des jetons de notification.
Critères : un utilisateur n'accède qu'à son compte ; e-mail déjà utilisé refusé (409).

## T5 Permissions et journal (EP-082)
Tables Permission, UtilisateurPermission, JournalAction. Politique d'autorisation par permission (10 codes du contrat). Premier administrateur créé par configuration ou commande, pas par une route.
Critères : sans la permission, 403 ; toute modification de permissions est journalisée ; `JournalAction` n'a ni mise à jour ni suppression.

## T6 Catégories et attributs (EP-021, EP-022, EP-089 à EP-091)
Tables Categorie, DefinitionAttribut. Arbre en lecture publique (mis en cache), création et modification par un administrateur, famille héritée du parent. Données de départ : cinq familles racines (numérique, domicile, travaux, vente, livraison) et quelques sous-catégories.
Critères : une catégorie utilisée ne peut pas être supprimée (409) ; le nom est unique sous un même parent.

## T7 Fichiers (EP-024, EP-025)
Table Fichier. Interface `IFileStorage` (disque local en développement). Contrôle du type réel et de la taille, accès par lien signé de courte durée, servi par EP-114 (OP-13).
Critères : un type interdit renvoie 415, un fichier trop gros 413 ; un autre utilisateur n'obtient pas le lien (403).

## T8 Profil prestataire (EP-011, EP-014 à EP-020)
Tables ProfilPrestataire, ProfilCategorie, Verification. Activation de la capacité prestataire (1 à 5 domaines), modification du profil (règles de localisation et de couverture du dictionnaire), demande de vérification, profil public au niveau quartier, liste des avis (vide jusqu'à S5).
Critères : la localisation active pointe une adresse renseignée ; rayon obligatoire seulement en mode Rayon ; le domicile n'est jamais précis en public ; plus de cinq domaines refusé.

## T9 Paramètres (EP-094, EP-095)
Table ParametrePlateforme, données de départ du contrat (13 paramètres), accesseur typé avec cache invalidé à la modification, journalisation des changements.
Critères : une modification s'applique aux nouvelles opérations sans redéploiement.

## T10 Durcissement et recette
Test qui compare les routes exposées au contrat (EP de S1 tous présents, chemins identiques) ; tests de sécurité (accès à la ressource d'un autre, routes admin sans permission, limites de débit) ; collection de requêtes de démonstration ; README à jour ; étiquette `s1-done`.

## Scénarios de recette S1
S1-01 inscription, code, connexion. S1-02 réutilisation d'un jeton refusée. S1-03 compte suspendu refusé. S1-04 activation prestataire avec 1 à 5 domaines. S1-05 localisation active vide refusée. S1-06 profil public sans domicile précis. S1-07 catégories en arbre. S1-08 route admin sans permission refusée. S1-09 téléversement refusé (type, taille). S1-10 modification d'un paramètre journalisée.

## Ajustements du 2026-11-24 (architecte)
Issus du contrat v0.2 (feuille Schémas) et de la revue des fronts. Aucune route ajoutée.
- **T0** : épingler les actions GitHub par empreinte (OP-18) ; ajouter un test qui vérifie que tout code d'erreur renvoyé figure dans la feuille Erreurs (84 codes depuis la v0.2).
- **T2** : le jeu de départ dépend d'OP-32 (pays de lancement) ; ne pas charger les villes avant sa réponse.
- **T3** : les réponses d'EP-002, EP-004 et EP-005 suivent `tokenPair` (avec `expiresIn`).
- **T4** : EP-009 renvoie `{user, capacities, providerStatus, permissions[]}` (`permissions` vide jusqu'à T5, `providerStatus` null jusqu'à T8).
- **T6** : EP-021 accepte `includeInactive` pour les titulaires de `categories.manage` ; `options` d'une caractéristique est un tableau de textes ; données de départ : attribut « Délai » sur les catégories de services (OP-23) ; catégories de départ alignées sur les maquettes (Informatique, Design, Bricolage, Transport, après décision d'OP-32).
- **T8** : `completionRate` (prestations achevées) et `profileCompleteness` (complétude) sont deux valeurs dérivées distinctes (OP-24) ; photo de profil selon OP-30.
- **T10** : ajouter un test de routage des routes littérales avant les routes à paramètre (Conventions).
