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
| FR-01 | Squelette de l'application Flutter (client et prestataire) : navigation, thème, authentification | S1-T3 | À faire | | |
| FR-02 | Squelette de l'administration Next.js : connexion, gestion des catégories | S1-T6 | À faire | | |

## Voies parallèles (voir `LANES.md`)
| ID | Tâche | Voie | Dépend de | Statut | Propriétaire | Branche |
|---|---|---|---|---|---|---|
| P-01 | Machine à états de la transaction, logique pure, tests par table de la matrice | B | S1-T1 | À faire | | |
| P-02 | Couverture, éligibilité d'une demande, règle « offre valable », logique pure | C | S1-T1 | À faire | | |
| P-03 | Interface de paiement, fournisseur simulé, états du paiement | D | S1-T1 | À faire | | |
| P-04 | Squelette Flutter : thème, i18n, infobulles d'aide, client d'API, serveur factice | E | contrat | À faire | | |
| P-05 | Squelette Next.js : connexion, client d'API, serveur factice | F | contrat | À faire | | |
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
