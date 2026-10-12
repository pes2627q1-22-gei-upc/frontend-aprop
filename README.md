# AProp! · Frontend

Aplicació mòbil per descobrir i planificar activitats culturals a Catalunya. Projecte de FiveGuys per a PES, FIB–UPC.

## Estat actual

Base Flutter amb tema compartit i navegació inferior entre Inici, Agenda, Descobreix, Avisos i Perfil. Inici mostra una capçalera fixa amb el logotip, els controls i la vista «Llista» seleccionada, seguida d'una llista desplaçable d'activitats de demostració. Inclou estats de càrrega, error amb reintent i llista buida. Les altres quatre seccions encara mostren textos provisionals.

Els controls de localització, dates, categories, mapa i assistent estan desactivats fins que implementem les seves accions; els tooltips indiquen que estaran disponibles properament. La tasca **#77 — Frontend llista d’esdeveniments** encara està en desenvolupament: el detall, les inscripcions i la integració amb el backend continuen pendents.

## Estructura

```text
lib/
  main.dart
  app/
    aprop_app.dart
    navigation/
    theme/
  core/
    widgets/
  features/
    activities/
      models/
      repositories/
      data/
      presentation/
        screens/
        view_models/
        widgets/
assets/
  images/
  branding/
test/
  widget_test.dart
  features/
    activities/
docs/
  architecture.md
```

Llegeix [les regles d’arquitectura](docs/architecture.md) abans d’afegir codi. Els fitxers `.gitkeep` permeten conservar les carpetes encara buides a Git i es poden retirar quan hi hagi fitxers reals.

## Desenvolupament

Executa les ordres des de l’arrel del repositori, on hi ha `pubspec.yaml`:

```bash
flutter pub get
flutter devices
flutter run -d ID_DEL_DISPOSITIU
```

Substitueix `ID_DEL_DISPOSITIU` per l’identificador del teu Android. Per revisar la interfície ràpidament al navegador:

```bash
flutter run -d chrome
```

Android i iOS són els objectius mòbils. La web és una eina de desenvolupament i no substitueix la comprovació en mòbil.

Abans de publicar una PR:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Col·laboració

Treballa en una branca de funcionalitat i obre la PR cap a `develop`, amb revisió d’un altre membre. Utilitza el número real de Taiga; per a la llista, **#77**. Explica quines parts funcionen amb dades de demostració i quina integració continua pendent. La carpeta creada no implica que la funcionalitat estigui implementada.
