# Plan de la tranche S2 : catalogue, recherche, carte

**Statut : brouillon de l'architecte (2026-11-24).** À relire juste avant le démarrage de S2 (règle de planification de la feuille de route) ; il est publié maintenant parce que les deux fronts consomment déjà ces routes. Dépend des points OP-30, OP-33, OP-34 et OP-35 et de D34.

Objectif : un prestataire publie une offre, un client la trouve (liste et carte). 12 points d'accès : EP-026 à EP-037. Schémas : feuille Schémas du contrat v0.2 (`offerSummary`, `offerSearchItem`, `offerDetail`, `offerItem`, `slot`, `page<T>`). Chaque tâche se termine par `dotnet test` vert et un commit.

**Prérequis** : S1 terminée (T2 localités, T6 catégories et attributs, T7 fichiers, T8 profil prestataire) et P-02 (règle « offre valable » en logique pure) fusionnée. Extensions PostgreSQL à activer par migration : `pg_trgm`, `unaccent`, `btree_gist` (exclusion des créneaux).

## T0 Modèle du catalogue
Tables `Offre`, `Article`, `ValeurAttribut`, `Creneau` (et `OffrePhoto` si OP-30 est accepté) dans le schéma `catalog`. Contrainte d'exclusion des créneaux d'un même profil (`btree_gist`, intervalle), unicité (offre, définition) des valeurs d'attribut, index sur (statut, catégorie), (profil), index trigramme sur titre et description. Montants en `bigint` + devise.
Critères : migration appliquée sur base neuve ; deux créneaux qui se chevauchent refusés au niveau de la base.

## T1 Offres : création, modification, liste (EP-026, EP-027, EP-030)
Règles de création : profil Actif (`PROFILE_NOT_ACTIVE`), catégorie feuille active (`CATEGORY_NOT_LEAF`), niveau minimal de la catégorie (`VERIFICATION_LEVEL_TOO_LOW`), caractéristiques obligatoires (`ATTRIBUTE_REQUIRED`), prix exigé si Fixe ou Horaire, devise par défaut = devise du pays du profil, `deliveryFee` et `handoverModes` réservés aux biens. Montants : objet `{amount, currency}`. Modification : `OFFER_LOCKED` seulement si l'offre est Désactivée (OP-33) ; PATCH selon les conventions (absent = inchangé, `null` = efface). Liste du prestataire, filtrable par statut, par curseur.
Critères : un autre prestataire reçoit 403 ; une offre créée est en Brouillon et absente de la recherche.

## T2 Publication et désactivation (EP-028, EP-029)
Publier : profil Actif, offre complète (`OFFER_INCOMPLETE` : prix selon le mode, au moins un article pour un bien, lieu de travail renseigné si la modalité est physique), offre internationale non validée refusée (`INTERNATIONAL_NOT_VALIDATED`). Désactiver : retire de la recherche sans toucher aux transactions. Une offre Désactivée peut être republiée.
Critères : transitions Brouillon → Publiée → Désactivée → Publiée ; chaque changement écrit dans `JournalAction`.

## T3 Articles (EP-031, EP-032)
Articles d'une offre de type Bien seulement (`OFFER_NOT_A_GOOD`) ; prix > 0 ; photo = fichier appartenant à l'appelant (`FILE_NOT_OWNED`) ; disponible ou en rupture, sans stock (D13).
Critères : un bien dont tous les articles sont en rupture disparaît de la recherche, et revient quand un article est disponible.

## T4 Créneaux du profil (EP-033, EP-034)
Créneaux rattachés au profil (D18), en UTC, début dans le futur, fin après début. Suppression refusée si réservé (`SLOT_RESERVED`) ; chevauchement refusé (`SLOT_OVERLAP`).
Critères : deux offres du même profil se partagent les créneaux ; aucun doublon possible, même en requêtes simultanées (test de concurrence).

## T5 Règle « offre valable » (branchement de P-02)
Une seule requête ou vue (`valid_offers`) réutilisée par la recherche, la carte, le détail public et, plus tard, la livraison. Conditions (D03) : offre Publiée ; profil Actif ; si Service à domicile ou en local, au moins un créneau libre à venir (OP-34) ; si Bien, au moins un article disponible ; si Internationale, validation acquise. Test par table de toutes les combinaisons, partagé avec la logique pure de P-02.
Critères : la requête SQL et la fonction pure donnent le même résultat sur le jeu de cas de la table.

## T6 Recherche (EP-035)
Filtres : texte `q` (insensible aux accents et à la casse, `pg_trgm`), `categoryId` (inclut les sous-catégories), `priceMin`/`priceMax` (comparés dans la devise de l'offre), point de référence `locationId` ou `lat`+`lng`. `coverageOnly=true` : seules les offres dont la couverture du prestataire contient le point (Quartier : même quartier ; Ville : même ville ; Rayon : distance au centroïde de la localité active ≤ `radiusKm` ; Pays : même pays). Tri fixe (Conventions) : `distance` exige un point de référence (sinon 422), défaut `distance` avec point, sinon `rating`. Distance de Haversine sur les centroïdes de localités, arrondie à 0,1 km (D34). Curseur opaque (clé de tri, id), `limit` par défaut 20, maximum 100. Réponse : `offerSearchItem` ; `photoUrl` null tant qu'OP-30 n'est pas tranché.
Critères : scénarios S2-06 et S2-07 ; aucune coordonnée précise ni domicile dans la réponse.

## T7 Carte (EP-036)
`bbox` obligatoire, surface maximale à fixer (paramètre `surfaceMaxCarte`, valeur à valider) ; un marqueur par prestataire ayant au moins une offre valable dans la boîte, au centroïde du quartier de sa localisation active (au centroïde de la ville si pas de quartier) ; `offerCount` ; filtre `categoryId`. `coverageOnly` retiré (OP-35).
Critères : scénario S2-08 ; jamais le domicile précis.

## T8 Détail public (EP-037)
Offre, prestataire (avec `completionRate`), articles, créneaux libres à venir (20 au plus), caractéristiques. La route est publique ; avec un jeton valide du propriétaire, les brouillons et désactivées sont visibles (champ `status`), sinon 404. Liens de photos signés de courte durée (EP-114).
Critères : scénario S2-10.

## T9 Performance et données de démonstration
Jeu de démonstration reproductible : au moins 15 prestataires et 40 offres réparties sur les cinq familles, des créneaux, un bien avec articles. Mesure sur 10 000 offres valables générées : recherche à 300 ms au 95e centile (cible à valider avec le responsable produit) ; contrôle d'absence de requêtes en cascade (N+1).
Critères : rapport de mesure joint à la recette.

## T10 Durcissement et recette
Test qui compare les routes exposées au contrat (EP-026 à EP-037 présentes, chemins identiques, les routes littérales `/offers/mine` et `/offers/map` avant `/offers/{id}`) ; tout code d'erreur renvoyé figure dans la feuille Erreurs ; tests de sécurité (modifier l'offre d'un autre : 403 ; brouillon invisible d'un tiers ; aucune donnée personnelle dans les réponses publiques) ; collection de requêtes ; README ; étiquette `s2-done`.

## Scénarios de recette S2
S2-01 un prestataire publie une offre de service, elle apparaît dans la recherche. S2-02 offre à domicile sans créneau libre invisible ; un créneau ajouté la rend visible. S2-03 bien dont l'article est en rupture invisible, puis visible. S2-04 offre internationale non validée refusée à la publication et invisible. S2-05 profil suspendu : offres invisibles. S2-06 couverture Ville : un client d'une autre ville ne voit pas l'offre avec `coverageOnly`, la voit sans. S2-07 tri par distance, pagination sans doublon ni trou. S2-08 carte : un marqueur par prestataire au niveau quartier. S2-09 créneau : chevauchement refusé, suppression d'un créneau réservé refusée. S2-10 détail : le propriétaire voit son brouillon, un tiers reçoit 404.

## Tâches des fronts rattachées à S2
| Front | Tâche | État |
|---|---|---|
| Mobile | Recherche et détail (FR-03, FR-04) : brancher le vrai serveur après S2-T6 et T8 | Écrans prêts, sur serveur factice |
| Mobile | Création et gestion des offres par le prestataire (EP-026 à EP-032), créneaux (EP-033, EP-034) | À ouvrir |
| Mobile | Carte (EP-036) | À ouvrir |
| Administration | Aucune écran nouveau ; EP-086 à EP-088 (validation internationale) viennent en S5 | |
