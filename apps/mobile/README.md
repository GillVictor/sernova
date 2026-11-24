# apps/mobile : application Flutter ServNova

Client et prestataire dans la même application (D26).

## Lancer
```
flutter pub get
# Sans backend : données factices (aucun appel réseau)
flutter run --dart-define=USE_FAKE_API=true
# Avec l'API (HTTPS obligatoire, sauf localhost en développement)
flutter run --dart-define=API_BASE_URL=https://api.exemple.cg/api/v1
```
Options : `DEFAULT_COUNTRY_CODE` (défaut `CG`).

Navigation : barre verticale à droite ; les deux boutons Client / Prestataire en haut de la barre
n'apparaissent que si le profil prestataire du compte est actif (EP-009).
```
flutter run --dart-define=USE_FAKE_API=true                                  # prestataire actif : boutons visibles
flutter run --dart-define=USE_FAKE_API=true --dart-define=FAKE_PROVIDER_ACTIVE=false   # client simple : pas de boutons
```
Pour ajouter une page à un menu : voir `lib/shell/destinations.dart`.

Espace prestataire (développement uniquement, en attendant FR-01) :
```
flutter run --dart-define=USE_FAKE_API=true --dart-define=START=provider
# avec l'API : ajouter --dart-define=DEV_ACCESS_TOKEN=<jeton> (ignoré en release)
```

## Tester
```
flutter analyze && flutter test
```

## Règles
- Seules les routes de `docs/reference/api-contract.xlsx` sont appelées (voir `lib/core/api/routes.dart`).
- Textes affichés : `assets/i18n/fr.json` (jamais en dur dans les widgets). Chaque champ de saisie a une infobulle d'aide (`HelpTooltip`).
- Montants : entiers en plus petite unité + devise ISO 4217 (`Money`).
