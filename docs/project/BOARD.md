# Tableau des tâches

Statuts : À faire, En cours, En revue, Bloqué, Terminé. Pour prendre une tâche : changer le statut, renseigner propriétaire et branche, committer et pousser avant de coder.

## Pilotage
| ID | Tâche | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|
| PM-01 | Fournir le calendrier (jalons en heures : dépôt 720, moyenne 840, application terminée 960 ; capacité 160 h par semaine) | | Terminé | Humain | |
| PM-02 | Trancher les points ouverts OP-01 à OP-14 | | Terminé | Humain + architecte | |
| PM-03 | Ajouter CodeSms au dictionnaire et la route de contenu signé au contrat (OP-12, OP-13) | PM-02 | Terminé | Architecte | |
| PM-04 | Dépôt GitHub créé (https://github.com/gkoanga-design/servnova) ; décider de sa visibilité, protéger la branche principale, activer la CI | | En cours | Humain | |
| PM-05 | Adapter les maquettes du prestataire à Flutter (OP-11, D26) | PM-02 | À faire | Humain + architecte | |
| PM-06 | Pousser le code mobile (branche issue du commit `9080ca2`) et ouvrir les PR dans l'ordre : FW-01, contrat v0.2, architecture, mobile | | À faire | Humain | |
| PM-07 | Hygiène du dépôt : `.gitattributes` (fins de ligne), identifiant Android `com.example`, supprimer `backend/package-lock.json` | | À faire | Humain + développeur concerné | |
| PM-08 | Fournir les heures consommées (calendrier PM-01) et confirmer l'adresse du dépôt (PM-04) | | À faire | Humain | |
| PM-09 | Valider D29 à D34 et répondre aux propositions de `open-points.md`, dont OP-32 (pays) avant S1-T2 | | À faire | Humain | |

## Tranche S1 : socle (voir `docs/plan-S1.md`)

> Chemin critique : aucune tâche S1 n'est prise au 2026-11-24 (le backend ne contient que des dossiers vides). À démarrer immédiatement par S1-T0 (voir l'état des lieux de l'architecte, `docs/project/reviews/`).
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
| FR-01 | Squelette de l'application Flutter (client et prestataire) : navigation, thème, authentification | S1-T3 | À faire | | |
| FR-02 | Squelette de l'administration Next.js : connexion, gestion des catégories (écrans sur serveur factice ; branchement au vrai backend après S1-T6) | S1-T6, P-05 | En revue | Claude (développeur administration) | feat/fr02-admin-categories |
| FR-03 | Écran de recherche d'offres (mobile) sur EP-035, EP-021, EP-023, avec le socle Flutter minimal nécessaire (client d'API, textes, infobulles) ; reste de P-04 à faire | contrat | En revue | Claude (développeur mobile) | feat/fr03-mobile-search |
| FR-04 | Écran de détail d'une offre (mobile) sur EP-037, branché depuis la recherche ; commande (S3) et profil public (EP-019) à brancher plus tard | FR-03 | En revue | Claude (développeur mobile) | feat/fr04-mobile-offer-detail |
| FR-05 | Tableau de bord prestataire (mobile) : EP-014, EP-009, EP-065, EP-043, EP-109 à EP-112 ; l'accès réel demande FR-01 (authentification) | FR-03, contrat | En revue | Claude (développeur mobile) | feat/fr05-mobile-provider-dashboard |
| FR-06 | Profil professionnel prestataire (mobile) : EP-014, EP-015, EP-018, EP-023 ; la demande de vérification (fichier) reste à faire | FR-05 | En revue | Claude (développeur mobile) | feat/fr06-mobile-provider-profile |
| FR-07 | Coque de navigation mobile : bascule Client / Prestataire, onglets, compte | FR-05, FR-06 | En revue | Claude (développeur mobile) | commit local `9080ca2` (non poussé, voir PM-06) |
| FR-08 | Création et gestion des offres par le prestataire (mobile) : EP-026 à EP-032, d'après la feuille Schémas | S2-T1 à T3 | À faire | | |
| FR-09 | Créneaux du prestataire (mobile) : EP-033, EP-034 | S2-T4 | À faire | | |
| FR-10 | Carte des prestataires (mobile) : EP-036 | S2-T7 | À faire | | |
| FR-11 | Accueil client d'après la maquette (EP-021, EP-035, EP-110) : reprise de la fiche FM-01 | OP-28, OP-31 | À faire | | |
| FR-12 | Publier une demande d'après la maquette (EP-038), sur serveur factice | FR-11, OP-31 | À faire | | |
| FR-13 | Devenir prestataire (mobile) : EP-011 | OP-28 | À faire | | |
| FW-02 | Administration : s'aligner sur le contrat v0.2 (`options` en tableau, `includeInactive`, lecture de `permissions`) | contrat v0.2 | À faire | | |

> Note de l'architecte (2026-11-24) : les branches `feat/fr03-…` à `feat/fr07-…` annoncées plus haut n'existent ni en local ni sur `origin` ; le code correspondant est dans le commit local `9080ca2` de la branche `wip/mes-modifs-avant-fw01`. Les lignes restent « En revue » à titre indicatif jusqu'à PM-06. Règle 7 de `LANES.md`.
| FW-01 | Corrections de la revue de l'admin web : infobulle (touche Échap), chargement des caractéristiques, fichiers générés, version de Node | FR-02 | En revue | Claude (développeur administration) | fix/fw01-admin-review |

## Voies parallèles (voir `LANES.md`)
| ID | Tâche | Voie | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|---|
| P-01 | Machine à états de la transaction, logique pure, tests par table de la matrice | B | S1-T1 | À faire | | |
| P-02 | Couverture, éligibilité d'une demande, règle « offre valable », logique pure | C | S1-T1 | À faire | | |
| P-03 | Interface de paiement, fournisseur simulé, états du paiement | D | S1-T1 | À faire | | |
| P-04 | Squelette Flutter : thème, i18n, infobulles d'aide, client d'API, serveur factice (le socle a été livré par FR-03 à FR-07 ; textes en `fr.json`, D32 ; la branche `feat/p04-mobile-l10n` est abandonnée ; reste : infobulles d'aide sur tous les champs) | E | contrat | À faire | | |
| P-05 | Squelette Next.js : connexion, client d'API, serveur factice | F | contrat | En revue | Claude (développeur administration) | feat/p05-admin-skeleton |
| P-06 | Collection de requêtes et liste de contrôle de sécurité | G | S1-T3 | À faire | | |
| P-07 | Génération du schéma OpenAPI et du serveur factice à partir du contrat | H | | En cours | Claude (architecte) | `docs/openapi-p07` (étape 1 faite : `docs/reference/openapi.yaml` généré du contrat, 114 opérations ; étape 2 : serveur factice commun) |
| P-08 | Fichier des quartiers de Brazzaville et de Pointe-Noire | Humain | | À faire | | |

## Tranches suivantes (plan détaillé à rédiger avant démarrage)
| ID | Tranche | Plan | Statut |
|---|---|---|---|
| S2 | Catalogue, recherche, carte | `docs/plan-S2.md` (brouillon) | Brouillon |
| S3 | Voie A et paiement | docs/plan-S3.md | À faire |
| S4 | Voie B | docs/plan-S4.md | À faire |
| S5 | Clôture et administration | docs/plan-S5.md | À faire |
| S6 | Notifications, livraison, messagerie | docs/plan-S6.md | À faire |

## Mémoire
| ID | Tâche | Dépend de | Statut | Propriétaire |
|---|---|---|---|---|
| M-01 | Reporter les modifications du registre `MEMOIRE-TRACKER.md` | P7 terminée | À faire | Humain + architecte |
| M-02 | Rédiger les chapitres 4 et 5 | P7 terminée | À faire | Humain + architecte |
