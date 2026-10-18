---
name: pantalla-flutter
description: Crea o amplia una pantalla o un widget de l'app Flutter seguint el MVVM del projecte (contracte, ViewModel amb ChangeNotifier, pantalla amb ListenableBuilder), el tema únic, textos en català, accessibilitat WCAG AA i proves de ViewModel i de widget. Fes-la servir quan s'hagi d'implementar una pantalla, secció o component visual.
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Pantalla Flutter

Llegeix abans `docs/architecture.md` (regles de dependència) i la fila de la pantalla a `docs/ai/50-ui-mockups.md`.
No afegeixis paquets (ni Riverpod, ni go_router, ni Dio): el projecte fa servir `ChangeNotifier` i
`Navigator`. Plantilles completes: `references/plantilles.md`.

## Passos

1. **Model** a `features/<f>/models/` (immutable, sense Flutter). Reutilitza'l si ja existeix.
2. **Contracte** a `features/<f>/repositories/<x>_repository.dart` (`abstract interface class`). Documenta
   quan retorna `null` i quan llança una excepció.
3. **Implementació** a `features/<f>/data/` (`Demo<X>Repository` mentre no hi hagi backend). No inventis cap DTO.
4. **ViewModel** a `presentation/view_models/`: rep el contracte pel constructor; exposa l'estat amb getters
   (`isLoading`, `errorMessage`, dades); evita peticions duplicades; té el flag `_isDisposed` i ignora les
   respostes posteriors al `dispose`. Missatges d'error en català.
5. **Pantalla** a `presentation/screens/`: `StatefulWidget` que crea el ViewModel a `initState`, l'allibera a
   `dispose` i el pinta amb `ListenableBuilder`. Té quatre estats: càrrega, error amb «Torna-ho a provar»,
   buit i contingut. La navegació surt per callbacks (`onActivitySelected`); la feature **no** importa `app/`.
6. **Widgets** propis a `presentation/widgets/`; els genèrics, a `core/widgets/`.
7. **Composició** a `app/` (`MainShell` o la ruta corresponent): hi injectes el repositori compartit.
8. **Proves:** ViewModel (estats, errors, duplicats, dispose) i widget (renderitzat de cada estat,
   interacció, text ampliat). *Fake* a `test/features/<f>/fake_<x>_repository.dart`.
9. Documentació: actualitza `README.md` § «Estat actual» i `docs/architecture.md` si canvies l'estructura.

## Tema i design tokens

- Colors: `Theme.of(context).colorScheme` o les constants d'`AppTheme`. Cap hex fora de `lib/app/theme/`.
- Tipografia: `Theme.of(context).textTheme`. Espaiats: múltiples de 4 (`TODO`: tokens d'espaiat a `AppTheme`
  quan es facin servir en més d'una pantalla).
- Mode fosc: encara no existeix; no l'implementis si la història no ho demana (Configuració › tema).

## Accessibilitat (WCAG 2.1 AA)

- Contrast de text ≥ 4,5:1 (≥ 3:1 en text gran). `muted #667078` dona ≈ 4,9:1 sobre `cardBackground`
  (passa), però només ≈ 4,4:1 sobre `cream` (**no passa** en text normal): sobre el fons de pantalla fes-lo
  servir només en text gran o enfosqueix el token.
- Àrees tàctils ≥ 48×48. Els botons que només tenen icona porten `tooltip` o `Semantics(label:)`.
- Les imatges decoratives porten `excludeSemantics`; les informatives, `semanticLabel`.
- Prova amb `tester.platformDispatcher.textScaleFactorTestValue = 2.0` que no hi hagi desbordaments.
- L'estat no es comunica només amb el color («Apuntat» porta text i icona).

## Textos

En català, to de proximitat (vegeu la skill `i18n-textos`). Encara no hi ha fitxers de traducció: no afegeixis
`flutter_localizations` sense una decisió de l'equip. Mentre no n'hi hagi, les cadenes de la pantalla es queden
a la pantalla o a una classe `<F>Strings` de la feature si es repeteixen.

## Verificació

```bash
dart format lib test
flutter analyze
flutter test test/features/<f>/
flutter test
```

Sortida a l'usuari: fitxers creats o modificats, estats coberts, què és de demostració i què queda pendent (≤ 15 línies).
