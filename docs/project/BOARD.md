# Tableau des tâches

Statuts : À faire, En cours, En revue, Bloqué, Terminé. Pour prendre une tâche : changer le statut, renseigner propriétaire et branche, committer et pousser avant de coder.

## Pilotage
| ID | Tâche | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|
| PM-01 | Fournir le calendrier (jalons en heures : dépôt 720, moyenne 840, application terminée 960 ; capacité 160 h par semaine) | | Terminé | Humain | |
| PM-02 | Trancher les points ouverts OP-01 à OP-14 | | Terminé | Humain + architecte | |
| PM-03 | Ajouter CodeSms au dictionnaire et la route de contenu signé au contrat (OP-12, OP-13) | PM-02 | Terminé | Architecte | |
| PM-04 | Dépôt GitHub créé (https://github.com/gkoanga-design/servnova) ; décider de sa visibilité, protéger la branche principale, activer la CI | | En cours | Humain | |
| PM-06 | Arbitrer OP-15 à OP-17 et les catégories désactivées (D32 à D35) ; PR docs : contrat (EP-009, EP-089, EP-091, EP-115), dictionnaire, décisions, points ouverts | | En revue | Claude (développeur backend) | docs/op-15-17-29-arbitrage |
| PM-05 | Adapter les maquettes du prestataire à Flutter (OP-11, D26) | PM-02 | À faire | Humain + architecte | |

## Tranche S1 : socle (voir `docs/plan-S1.md`)
| ID | Tâche | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|
| S1-T0 | Initialisation de la solution, santé, erreurs, CI | PM-04 | À faire | | |
| S1-T1 | Noyau partagé et persistance | S1-T0 | À faire | | |
| S1-T2 | Pays et localités | S1-T1, OP-09 | À faire | | |
| S1-T3 | Authentification | S1-T1 | À faire | | |
| S1-T4 | Compte et appareils | S1-T3 | À faire | | |
| S1-T5 | Permissions et journal | S1-T3 | À faire | | |
| S1-T6 | Catégories et attributs | S1-T5 | À faire | | |
| S1-T7 | Fichiers | S1-T3 | À faire | | |
| S1-T8 | Profil prestataire | S1-T2, S1-T6, S1-T7 | À faire | | |
| S1-T9 | Paramètres | S1-T5 | À faire | | |
| S1-T10 | Durcissement et recette | S1-T0 à S1-T9 | À faire | | |

## Fronts (à détailler après PM-02)
| ID | Tâche | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|
| FR-01 | Mobile : authentification. Tranche 1 : connexion (EP-004), renouvellement avec rotation (EP-005), déconnexion (EP-006), session, jeton derrière une interface de stockage. Tranche 2 : inscription et vérification du téléphone (EP-001 à EP-003), écrite sur feat/fr01-signup, flutter test : 247 tests réussis le 2026-11-26 (poste de Gilles), analyze à confirmer, pas d'essai à l'écran ni contre le backend ; stockage sécurisé (D31) validé et écrit | S1-T3 | En cours | Claude (développeur mobile) | feat/fr01-mobile-auth (tranche 1 faite : flutter test 172 réussis le 2026-11-24, poste de Gilles ; D31 validée : stockage sécurisé du jeton écrit le 2026-11-25, pas encore exécuté) |
| FR-02 | Squelette de l'administration Next.js : connexion, gestion des catégories (écrans sur serveur factice ; branchement au vrai backend après S1-T6) | S1-T6, P-05 | En revue | Claude (développeur administration) | feat/fr02-admin-categories |
| FR-08 | Administration web alignée sur D33 à D35 : permissions[] (EP-009), catégories désactivées (EP-115), formulaires catégories (D34) | FR-02, PM-06 | En revue | Claude (développeur administration) | feat/fr08-admin-web-d33-d35 |
| FR-09 | Brancher l'administration web au vrai backend (API réelle à la place du serveur factice, contrat revérifié, jeton selon D32 / OP-30) | S1-T6, FR-08 | À faire | | |
| FR-03 | Écran de recherche d'offres (mobile) sur EP-035, EP-021, EP-023, avec le socle Flutter minimal nécessaire (client d'API, textes, infobulles) ; reste de P-04 à faire | contrat | En revue | Claude (développeur mobile) | feat/fr03-mobile-search | | FR-04 | Écran de détail d'une offre (mobile) sur EP-037, branché depuis la recherche ; commande (S3) et profil public (EP-019) à brancher plus tard | FR-03 | En revue | Claude (développeur mobile) | feat/fr04-mobile-offer-detail | | FR-05 | Tableau de bord prestataire (mobile) : EP-014, EP-009, EP-065, EP-043, EP-109 à EP-112 ; l'accès réel demande FR-01 (authentification) | FR-03, contrat | En revue | Claude (développeur mobile) | feat/fr05-mobile-provider-dashboard | | FR-06 | Profil professionnel prestataire (mobile) : EP-014, EP-015, EP-018, EP-023 ; la demande de vérification (fichier) reste à faire | FR-05 | En revue | Claude (développeur mobile) | feat/fr06-mobile-provider-profile |
| FR-04 | Écran de détail d'une offre (mobile) sur EP-037, branché depuis la recherche ; commande (S3) et profil public (EP-019) à brancher plus tard | FR-03 | En revue | Claude (développeur mobile) | feat/fr04-mobile-offer-detail |
| FR-05 | Tableau de bord prestataire (mobile) : EP-014, EP-009, EP-065, EP-043, EP-109 à EP-112 ; l'accès réel demande FR-01 (authentification) | FR-03, contrat | En revue | Claude (développeur mobile) | feat/fr05-mobile-provider-dashboard |
| FR-06 | Profil professionnel prestataire (mobile) : EP-014, EP-015, EP-018, EP-023 ; la demande de vérification (fichier) reste à faire | FR-05 | En revue | Claude (développeur mobile) | feat/fr06-mobile-provider-profile |
| FR-07 | Coque de navigation mobile : barre de navigation (barre verticale à droite, provisoire), bascule Client / Prestataire (providerStatus de EP-009), onglet mémorisé par rôle | FR-06 | En revue | Claude (développeur mobile) | feat/fr07-mobile-shell |

## Voies parallèles (voir `LANES.md`)
| ID | Tâche | Voie | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|---|
| P-01 | Machine à états de la transaction, logique pure, tests par table de la matrice | B | S1-T1 | À faire | | |
| P-02 | Couverture, éligibilité d'une demande, règle « offre valable », logique pure | C | S1-T1 | À faire | | |
| P-03 | Interface de paiement, fournisseur simulé, états du paiement | D | S1-T1 | À faire | | |
| P-04 | Squelette Flutter : thème, i18n, infobulles d'aide, client d'API, serveur factice | E | contrat | À faire | | |
| P-05 | Squelette Next.js : connexion, client d'API, serveur factice | F | contrat | En revue | Claude (développeur administration) | feat/p05-admin-skeleton |
| P-06 | Collection de requêtes et liste de contrôle de sécurité | G | S1-T3 | À faire | | |
| P-07 | Génération du schéma OpenAPI et du serveur factice à partir du contrat | H | | À faire | | |
| P-08 | Fichier des quartiers de Brazzaville et de Pointe-Noire | Humain | | À faire | | |

## Tranches suivantes (plan détaillé à rédiger avant démarrage)
| ID | Tranche | Plan | Statut |
|---|---|---|---|
| S2 | Catalogue, recherche, carte | docs/plan-S2.md | À faire |
| S3 | Voie A et paiement | docs/plan-S3.md | À faire |
| S4 | Voie B | docs/plan-S4.md | À faire |
| S5 | Clôture et administration | docs/plan-S5.md | À faire |
| S6 | Notifications, livraison, messagerie | docs/plan-S6.md | À faire |

## Mémoire
| ID | Tâche | Dépend de | Statut | Propriétaire |
|---|---|---|---|---|
| M-01 | Reporter les modifications du registre `MEMOIRE-TRACKER.md` | P7 terminée | À faire | Humain + architecte |
| M-02 | Rédiger les chapitres 4 et 5 | P7 terminée | À faire | Humain + architecte |
