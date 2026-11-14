# Registre des modifications du mémoire

Le mémoire n'est pas modifié avant le dépôt final ; ce registre liste tout ce qu'il faudra y reporter. Statuts : À faire, Fait.

| # | Où | Modification | Source | Statut |
|---|---|---|---|---|
| M01 | Ch. 3, figure 26 | `Utilisateur–Permission` 0..* ; `ProfilPrestataire` : lieuTravail, domicile, localisationActive, modeCouverture, rayonKm (tauxAchèvement et noteMoyenne dérivés) ; association avec `Catégorie` (domaines) ; supprimer `Offre–Localité` ; `Offre` : devise, statut ; ajouter `Offre–ValeurAttribut` ; rattacher `Créneau` au `ProfilPrestataire` (plus à l'offre) ; `Catégorie` : famille, niveauVérificationMin ; renommer l'étiquette « parent » en « décrite par » | decisions D04 à D06 | À faire |
| M02 | Ch. 3, figure 27 | Scinder en deux figures (mise en relation, transaction) ; ajouter `LigneTransaction`, `Conversation`, `Message` ; `Transaction` : type, dateLimiteConfirmation, adresseIntervention, prestataire vers `ProfilPrestataire`, contrainte xor ; `Livraison` : codeRemiseHaché ; associations Créneau–Transaction et Transaction réflexive ; `Demande` : nbDestinataires, maxPropositions ; `Justificatif` : auteur | D07, D08, D14 | À faire |
| M03 | Ch. 3, figure 28 | `Paiement` : dateConfirmation, motifÉchec, statuts Initié/Réservé/Libéré/Remboursé/Échoué ; `Litige` : montantRembourse, preuves ; `Notification–Demande` | D09 | À faire |
| M04 | Ch. 3, texte | « vingt-quatre classes » devient « vingt-huit classes » ; texte annonçant trois vues devient quatre | | À faire |
| M05 | Ch. 3, tableau des choix de conception | Remplacer « Localité portée par l'offre » ; ajouter fonds réservés, diffusion des demandes et plafond, conversation rattachée au contexte | D04 à D09 | À faire |
| M06 | Ch. 2, section 1 et Tableau 15 | Remplacer par le tableau fondé sur les fonctionnalités F01 à F29 (fichier Chapitre2_comparaison_fonctionnalites.docx) ; compléter les cellules « ? » ; supprimer le score /18 | | À faire |
| M07 | Ch. 2, conclusion | Réécrire à partir du nouveau tableau ; mettre à jour F18 si la messagerie est livrée | | À faire |
| M08 | Ch. 1, résultats attendus | « Cinq familles modélisées, quatre livrées de bout en bout, la cinquième selon l'avancement » ; corriger « quatre » ou cinq services pilotes | D11 | À faire |
| M09 | Ch. 1 et 3 | F19 classée A ; vocabulaire « recherche d'offres » et « carte des offres » | D02, D12 | À faire |
| M10 | Ch. 1, périmètre hors V1 | Retirer la messagerie si elle est livrée ; mettre à jour le Tableau 15 | D08 | À faire |
| M11 | Ch. 1 et 3, stack | Si le front du prestataire passe sur Flutter : contraintes non fonctionnelles, figures 30 à 32, maquettes | OP-11 | À faire |
| M12 | Ch. 1 | Compléter les espaces réservés : effectifs par pays, sources, seuil à ajuster, « tableau 3.X » | | À faire |
| M13 | Pages liminaires | Date de soutenance, dédicace, remerciements, résumé, abstract ; erreurs de sommaire | | À faire |
| M14 | Figures | Aligner la liste des figures et la numérotation du texte | | À faire |
| M15 | Enquête | Pourcentages arrondis (certains dépassent 100 %) ; effectifs par pays | | À faire |
| M16 | Bibliographie | Ajouter des références académiques sur les plateformes et le cadre réglementaire | | À faire |
| M17 | Ch. 4 et 5 | À rédiger après la réalisation : architecture, choix de la pile, copies d'écran, mesures, conclusion et perspectives (acompte, jalons, réservation différée) | | À faire |
| M18 | Ch. 3, outils utilisés | Aligner la liste (Figma, Lucidchart, Mermaid, outils de la pile) | | À faire |
