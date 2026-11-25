# Décisions

Statut : Validée (acceptée en séance) ou Proposée (à valider, voir open-points.md). Le mémoire n'est pas modifié avant le dépôt final : ce journal sert à l'y intégrer.

| # | Décision | Statut |
|---|---|---|
| D01 | Compte unique : un utilisateur peut être client et prestataire (profil prestataire facultatif) | Validée |
| D02 | Le client cherche des offres ; la carte affiche les prestataires ayant au moins une offre valable ; une recherche n'ouvre jamais de conversation | Validée |
| D03 | Offre valable = Publiée + profil Actif + créneau libre (si rendez-vous) + article disponible (si vente) + validation internationale acquise | Validée |
| D04 | La localité appartient au prestataire : lieu de travail et domicile, avec une localisation active ; pas de zones par offre ; domicile jamais précis en public | Validée |
| D05 | Couverture par mode (Quartier, Ville par défaut, Rayon, Pays) ; rayon facultatif | Validée |
| D06 | Domaines d'activité saisis explicitement, ajout automatique à la publication d'une offre, 1 à 5 par profil | Validée |
| D07 | Demandes diffusées aux prestataires éligibles ; plafond de 10 propositions actives (paramétrable) ; fenêtre de 72 h ; nombre réel de destinataires communiqué au client | Validée |
| D08 | Conversation : client + prestataire explicites, origine demande ou transaction ; lecture seule dès litige ou clôture ; messagerie à réaliser (hors mémoire pour l'instant) | Validée |
| D09 | Fonds réservés puis libérés à la validation (Paiement = réservation, Reversement = libération) ; remboursement automatique si le prestataire ne démarre pas ; acompte et jalons en perspective | Validée |
| D10 | Confirmation automatique après 72 h ; contestation dans cette fenêtre ; évaluation sous 7 jours | Validée |
| D11 | Cinq services pilotes, quatre garantis (domicile, vente, numérique, livraison), travaux et réparation selon l'avancement | Validée |
| D12 | F19 (carte) livrée en V1 | Validée |
| D13 | Stock non géré : l'article est disponible ou en rupture | Validée |
| D14 | La livraison est une transaction de type Livraison liée à la vente ; le livreur est choisi par couverture au point de ramassage | Validée |
| D15 | Paiement simulé en V1 derrière `IPaymentProvider` ; connecteur Mobile Money en test selon l'avancement | Validée |
| D16 | Pile : ASP.NET Core, PostgreSQL, Docker ; Flutter pour le client et le prestataire (D26) ; Next.js pour l'administration | Validée |
| D17 | Identifiant de connexion : téléphone obligatoire, e-mail facultatif (OP-01) | Validée |
| D18 | Créneaux rattachés au profil du prestataire, pas à l'offre (OP-02) | Validée |
| D19 | La capacité Prestataire est dérivée du profil actif (OP-03) | Validée |
| D20 | Niveaux de vérification N0 à N3 ; lien avec les catégories à définir plus tard (OP-04) | Validée |
| D21 | Identifiants UUID v7 et référence lisible sur la transaction (OP-05) | Validée |
| D22 | Code en anglais, glossaire français (OP-06) | Validée |
| D23 | Commission : taux unique supporté par le prestataire, valeur à fixer avant S3 (OP-07) | Validée |
| D24 | Masquage des numéros dans les messages : plus tard, règle d'usage en V1 (OP-08) | Validée |
| D25 | Annulation d'accord entre les parties en cours de prestation : via l'administrateur en V1 (OP-10) | Validée |
| D26 | Front du prestataire : Flutter, dans la même application que le client (OP-11) | Validée |
| D27 | Table CodeSms ajoutée ; route de contenu signé EP-114 ajoutée au contrat ; SMS : console en développement (OP-12 à OP-14) | Validée |
| D28 | Localités : deux niveaux seulement, ville et quartier facultatif, sans région ni département en V1 ; dix villes du Congo au niveau ville ; quartiers de Brazzaville et de Pointe-Noire ajoutés ensuite ; le mode de couverture Quartier n'est proposé que là où des quartiers existent | Validée |
| D29 | Dépendances de `apps/admin-web` : `next`, `react`, `react-dom` (pile D16) ; en développement `typescript`, `vitest`, `jsdom`, `@testing-library/*`, `@vitejs/plugin-react` (tests de composants). Pas de bibliothèque d'internationalisation ni de client HTTP : `fr.json` + `fetch` suffisent en V1. Serveur factice sans dépendance (`mock/server.mjs`) en attendant P-07 | Proposée |
| D30 | Dépendances de `apps/mobile` : `http` (client HTTP, testable avec `MockClient`) ; en développement `flutter_test` et `flutter_lints`. Pas de bibliothèque d'état (`ChangeNotifier`), de navigation ni d'internationalisation en V1 : `fr.json` suffit, comme pour l'administration (D29). Polices : aucune dépendance, police embarquée plus tard | Proposée |
| D31 | Stockage du jeton de rafraîchissement sur le mobile (D32, OP-30) : paquet `flutter_secure_storage` ^11.2.0 (Keychain sur iOS, Keystore sur Android), derrière l'interface `TokenStore` de `apps/mobile` (`SecureTokenStore`). Alternatives écartées : `shared_preferences` (texte en clair) ; code natif maison (coût et risque pour un gain nul). Seul le jeton de rafraîchissement est stocké, le jeton d'accès reste en mémoire. Conséquences : Android `minSdk` 24 (exigé par la version 11) ; sauvegarde automatique Android désactivée (`allowBackup=false`), pour qu'une sauvegarde restaurée sur un autre appareil ne reprenne pas un fichier chiffré dont la clé n'existe plus ; iOS : accessibilité `first_unlock_this_device` (non restauré sur un autre appareil). Une entrée illisible est supprimée et l'utilisateur se reconnecte avec son mot de passe. Version 11 choisie : il n'y a aucune donnée à migrer depuis les anciens chiffrements retirés. Le sélecteur de fichier (EP-024, demande de vérification) fera l'objet d'une ligne séparée | Validée (Gilles, 2026-11-25) |
| D32 | Jetons de l'administration web (OP-15) : en mémoire pour la démonstration. Avant la production, le jeton de rafraîchissement passe en cookie `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth` (protection CSRF sur EP-005, CORS avec credentials, admin et API sur le même site) ; le jeton d'accès reste en mémoire. Le mobile garde `refreshToken` dans le corps : le mode cookie est une variante propre au web (mécanisme : OP-30), à fixer avant S1-T3 | Validée |
| D33 | Permissions admin (OP-16) : EP-009 renvoie `permissions[]` (codes du contrat, ceux de l'appelant, lus en base). Affichage seulement, le serveur reste l'autorité. Code de référence : `disputes.resolve` (le dictionnaire est aligné) | Validée |
| D34 | Schémas des catégories (OP-17) : champs `id, name, order, active, family, minVerificationLevel, children[]` ; valeurs du dictionnaire (`FamilleService`, `Niveau`, `TypeValeur`) ; `options` en texte séparé par des virgules (Texte 500, obligatoire si type Liste) ; création : `parentId` OU `family`, jamais les deux ; `minVerificationLevel` facultatif (défaut N0) | Validée |
| D35 | Catégories désactivées (ex-OP-21 de l'admin web, renuméroté) : nouvelle route EP-115 `GET /admin/categories` (permission `categories.manage`, sans cache) plutôt qu'un paramètre sur EP-021 (public, mis en cache). La réactivation reste `PATCH active=true` (EP-090) | Validée |
