# ServNova : administration (Next.js)

Squelette de la console d'administration (tâche P-05, voie F). Consomme uniquement les routes de `docs/reference/api-contract.xlsx` ; la liste des routes utilisées est dans `src/lib/api/routes.ts` (EP-004, EP-005, EP-006, EP-009, EP-021, EP-022, EP-089, EP-090, EP-091).

## Prérequis
Node `^22.13`, `^24` ou `>=26` (voir `engines` dans `package.json` et `.nvmrc`). Avec une version plus ancienne, `npm install` affiche un avertissement `EBADENGINE` et les tests peuvent échouer.

## Démarrer
```bash
cd apps/admin-web
npm install
cp .env.example .env.local
npm run mock      # serveur factice sur http://localhost:4010/api/v1
npm run dev       # http://localhost:3000
```
Identifiants du serveur factice (fictifs) : téléphone `+242060000000`, mot de passe `dev-only-password`. `MOCK_NO_PERMISSION=1 npm run mock` fait répondre 403 aux routes d'administration ; désactiver la catégorie d'une racine renvoie 409 `CATEGORY_IN_USE` (cas de démonstration).

## Écrans
- `/login` : connexion (EP-004).
- `/` : tableau de bord (EP-009).
- `/categories` : arbre (EP-021), création (EP-089), modification et désactivation (EP-090), caractéristiques d'une catégorie (EP-022, EP-091). Les droits ne sont pas devinés côté interface : c'est le serveur qui répond 403 `FORBIDDEN` (voir OP-16).

## Vérifier
`npm run typecheck && npm test && npm run build`

`typecheck` génère d'abord `next-env.d.ts` (`next typegen`) : ce fichier n'est plus suivi par Git, Next.js le réécrit à chaque `next dev`.

## Infobulles d'aide
- Les textes sont dans `src/i18n/fr.json` (`<formulaire>.fields.<champ>.{label,placeholder,help}`).
- Tout champ de saisie passe par `TextField`, `SelectField` ou `CheckboxField`, qui affichent toujours `FieldHelp` (survol, focus clavier, tap ; Échap pour fermer ; lecteur d'écran via `aria-describedby`). Un test interdit `<input>`, `<select>` et `<textarea>` hors de ces composants.
- Pour ajouter un champ : ajouter ses trois textes sous `<formulaire>.fields.<champ>` dans `fr.json` ; le typage refuse un champ sans texte.

## Sécurité
Les jetons restent en mémoire (jamais dans `localStorage`) ; recharger la page demande une nouvelle connexion (voir OP-15). Les messages d'erreur viennent des codes stables, jamais du texte renvoyé par le serveur.
