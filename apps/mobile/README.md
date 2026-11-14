# ServNova : application mobile (Flutter)

État : **partie 1 de P-04** (ressources de texte et infobulles). Le projet Flutter lui-même (`pubspec.yaml`, `lib/main.dart`, thème, navigation, client d'API, serveur factice) reste à créer par une instance qui dispose du SDK Flutter ; voir `docs/project/handoffs/P-04-part1.md`.

## Contenu
- `lib/l10n/app_fr.arb` : tous les textes français des champs de saisie de l'authentification (EP-001 à EP-008) : pour chaque champ, `<formulaire><Champ>Label`, `…Hint` (exemple affiché dans le champ, vide si aucun) et `…Help` (texte de l'infobulle). S'y ajoutent les messages d'erreur par code stable du contrat (`error<Code>`) et les libellés d'accessibilité (`a11yHelpButton`, `a11yHelpClose`).
- `l10n.yaml` : configuration de `flutter gen-l10n`.
- `tool/check_l10n.mjs` : contrôle sans Flutter (`node tool/check_l10n.mjs`) : JSON valide, identifiants Dart valides, paramètres déclarés, et **chaque champ a un libellé, un exemple et une aide**. Il tourne en CI.

## Pour l'instance qui crée le projet Flutter
1. `flutter create --org com.servnova --project-name servnova_mobile .` dans ce dossier, puis dans `pubspec.yaml` : dépendances `flutter_localizations` (SDK) et `intl`, et `flutter: generate: true`.
2. `flutter gen-l10n` génère `AppLocalizations` ; l'ajouter à `MaterialApp` (`localizationsDelegates`, `supportedLocales: [Locale('fr')]`).
3. Écrire un widget unique `HelpTextField` (équivalent de `TextField`/`FieldHelp` de l'admin web) qui reçoit `label`, `hint` et `help` **obligatoires**, affiche un bouton « ? » avec `Tooltip(triggerMode: TooltipTriggerMode.tap, showDuration: …)` et `Semantics(label: l10n.a11yHelpButton(label))`. Tout champ de saisie de l'application doit passer par lui (ajouter un test qui cherche les `TextField`/`TextFormField` hors de ce widget).
4. Ajouter à CI : `flutter pub get`, `flutter analyze`, `flutter test`.
5. N'appeler que les routes du contrat (EP-001 à EP-008 pour ces écrans).

## Limites connues
- Longueurs de champ reprises du dictionnaire (téléphone E.164, nom affiché 60, e-mail 254). La règle de complexité du mot de passe et la longueur du code SMS ne sont pas définies : les aides n'en promettent aucune. À compléter quand le backend (S1-T3) les fixera.
- Les textes d'aide du profil prestataire (EP-011, EP-015) et des offres seront ajoutés avec les écrans correspondants.
