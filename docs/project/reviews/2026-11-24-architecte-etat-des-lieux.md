# État des lieux de l'architecte, 2026-11-24

Sources : l'archive du projet envoyée par le responsable produit (copie de travail du 2026-11-24) et le dépôt GitHub. Rédigé par l'architecte ; aucun code applicatif n'a été modifié.

## 1. Ce qui existe

| Zone | État | Preuve |
|---|---|---|
| Backend (voie A, S1-T0 à T10) | **Aucune ligne de code.** Dossiers vides (`.gitkeep`), aucune tâche prise | `backend/` |
| Administration web (voie F) | Connexion, tableau de bord, catégories (EP-004, 005, 006, 009, 021, 022, 089, 090, 091), 46 tests. P-05 et FR-02 fusionnés dans `main` ; FW-01 (corrections de revue) poussée, PR à ouvrir | `main` = `3bc88c5`, branche `fix/fw01-admin-review` |
| Application mobile (voie E) | Recherche, détail d'offre, tableau de bord et profil prestataire, coque de navigation (EP-009, 014, 015, 018, 021, 023, 035, 037, 043, 065, 109 à 112), 112 fichiers suivis, une vingtaine de fichiers de tests | **Un seul commit local** `9080ca2` « Nouveau navbar », branche locale `wip/mes-modifs-avant-fw01`, **jamais poussé** |
| Contrat et dictionnaire | Complets pour le périmètre (114 routes, 28 classes) mais les schémas de réponse étaient « indicatifs » | `docs/reference/` |
| Documents de pilotage | Utilisés, mais en dérive (voir 3) | `docs/project/` |

## 2. Le risque principal

Le chemin critique (le backend, 110 h prévues pour S1) n'a pas démarré, alors que les deux fronts ont avancé loin devant, sur des schémas qu'ils ont dû deviner. Chaque jour sans backend augmente le coût de réalignement des fronts. Le jalon « dépôt à 720 h » suppose que S1 à S5 et le début de S6 soient livrés ; rien ne permet aujourd'hui de dire où en est le compteur d'heures (à fournir, voir plus bas).

## 3. Écarts constatés entre les documents et la réalité

1. `BOARD.md` annonce cinq branches (`feat/fr03-mobile-search` à `feat/fr07-mobile-shell`) qui **n'existent ni localement ni sur `origin`**. Le code est dans le commit local `9080ca2`.
2. Lignes FR-03 à FR-06 mal formées (cellules décalées) ; FR-07 absente du tableau alors que le journal la décrit. Corrigé dans cette PR.
3. Numéros en collision entre branches : OP-19, OP-20 et OP-21 existaient côté mobile et côté administration/mobile non fusionnés. Le point de l'administration devient OP-29 ; ma fiche FM-01 (publication de demande, non poussée) est reprise sous OP-31 et OP-32.
4. D29 et D30 sont « Proposée » alors que le code correspondant est déjà fusionné ou prêt ; D31 est citée par le mobile (OP-26, OP-28) mais n'existait pas. Ajoutée.
5. `PM-04` désigne `https://github.com/gkoanga-design/servnova` ; le dépôt réellement utilisé est `https://github.com/GillVictor/sernova` (nom sans « v »). À confirmer.
6. La branche `feat/p04-mobile-l10n` (textes en format `.arb`) est **abandonnée** : le mobile a retenu `assets/i18n/fr.json`, comme l'administration (D32).

## 4. Hygiène du dépôt (hors `docs/`, à faire par le responsable ou le développeur concerné)

- Ajouter un `.gitattributes` (`* text=auto eol=lf`) : sans lui, 77 fichiers apparaissent « modifiés » sous Windows à cause des fins de ligne.
- Renommer l'identifiant Android `com.example.servnova_mobile` (`namespace` et `applicationId`) avant toute configuration de notifications ou de signature.
- Supprimer `backend/package-lock.json` (fichier vide produit par un `npm install` lancé dans `backend/`).
- Ne pas archiver `apps/mobile/build/`, `android/local.properties` ni les `.iml` (déjà ignorés par Git).
- Le dossier `.github/` manque dans l'archive envoyée : vérifier qu'il est bien présent dans le dépôt (il l'est sur `origin/main`).

## 5. Ce que cette PR change dans `docs/`

Contrat et dictionnaire : PR séparée `docs/contract-v0.2` (règle 3 du protocole). Ici : décisions D31 à D34 (Proposées), points ouverts OP-29 à OP-35 et propositions de l'architecte pour OP-15 à OP-35, plan de la tranche S2 (brouillon), ajustements du plan S1, registre du mémoire M19 à M23, tableau des tâches, voies de travail.

## 6. La suite proposée

**Cette semaine (déblocage)**
1. Responsable produit : pousser le code mobile (`git branch feat/mobile-baseline 9080ca2`, puis push), ouvrir les PR dans l'ordre : FW-01, contrat v0.2, cette PR d'architecture, mobile. Revue croisée pour chacune.
2. **Démarrer le backend maintenant** : une instance prend S1-T0 puis S1-T1 (voie A). Dès S1-T1 : P-01, P-02, P-03 en parallèle (domaine pur).
3. Architecte : P-07 en deux temps (schéma OpenAPI généré depuis le contrat, puis serveur factice commun aux deux fronts) afin que les fronts cessent d'écrire chacun le leur.
4. Fronts : s'aligner sur la feuille Schémas v0.2 (changements attendus : administration, `options` en tableau et `includeInactive` ; mobile, aucun).
5. Responsable produit : trancher OP-32 (pays et devise), valider D29 à D34, répondre aux propositions de la section « Propositions de l'architecte » de `open-points.md`.

**Ensuite**
- S1 (backend) avec FR-01 (authentification mobile) dès S1-T3, puis branchement des écrans existants au vrai serveur.
- S2 (plan fourni en brouillon : `docs/plan-S2.md`) ; les écrans de recherche et de détail sont déjà prêts côté mobile.
- Tâches front manquantes pour S2 : création d'offre et gestion des créneaux par le prestataire (EP-026 à EP-034), carte (EP-036).

## 7. Informations à fournir par le responsable produit

- Heures consommées à ce jour sur les 720 h (ou dates de début de chaque voie) : sans elles, le calendrier ne peut pas être recalé.
- Pays de lancement et devise (OP-32).
- Qui tient le rôle backend, et à partir de quand.
