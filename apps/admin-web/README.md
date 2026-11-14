# ServNova : administration (Next.js)

Squelette de la console d'administration (tâche P-05, voie F). Consomme uniquement les routes de `docs/reference/api-contract.xlsx` ; la liste des routes utilisées est dans `src/lib/api/routes.ts` (EP-004, EP-005, EP-006, EP-009).

## Démarrer
```bash
cd apps/admin-web
npm install
cp .env.example .env.local
npm run mock      # serveur factice sur http://localhost:4010/api/v1
npm run dev       # http://localhost:3000
```
Identifiants du serveur factice (fictifs) : téléphone `+242060000000`, mot de passe `dev-only-password`.

## Vérifier
`npm run typecheck && npm test && npm run build`

## Infobulles d'aide
- Les textes sont dans `src/i18n/fr.json` (`<formulaire>.fields.<champ>.{label,placeholder,help}`).
- Tout champ de saisie passe par `TextField`, qui affiche toujours `FieldHelp` (survol, focus clavier, tap ; Échap pour fermer ; lecteur d'écran via `aria-describedby`). Un test interdit les `<input>` hors de ce composant.
- Pour ajouter un champ : ajouter ses trois textes dans `fr.json`, puis son nom dans le type `FieldName` de `TextField.tsx`.

## Sécurité
Les jetons restent en mémoire (jamais dans `localStorage`) ; recharger la page demande une nouvelle connexion (voir OP-15). Les messages d'erreur viennent des codes stables, jamais du texte renvoyé par le serveur.
