# Logotip compartit — #262

## Problema i canvi

El recurs `assets/branding/aprop_logo.png` inclou un fons crema texturat que no coincideix amb
el fons uniforme del tema. A les alçades d’Inici i Login apareixia un rectangle i part de l’espai
quedava ocupat pels marges de la imatge.

`aprop_logo_transparent.png` és una edició del logotip existent per retirar el fons i reduir els
marges, mantenint la composició Catalunya, tres marcadors i el text exacte «AProp!». L’original
queda intacte. La referència de paleta continua sent verd bosc, coral, mostassa i crema;
no es modifica `AppTheme` ni el logotip de Google.

L’edició es va obtenir a partir del PNG original amb l’eina d’edició d’imatges: eliminar el fons,
conservar la identitat i presentar vores suaus sobre alfa transparent. El resultat seleccionat
es desa dins del repositori i no depèn d’una ruta externa a l’aplicació. DP-047 registra la
validació visual de marca pendent de l’equip.

## Implementació

`lib/core/widgets/aprop_logo.dart` defineix `APropLogo`: asset compartit, alçada configurable,
`BoxFit.contain`, alineació i etiqueta accessible «AProp!». No té estat de negoci, peticions HTTP
ni dependències de `app/` o `features/`.

- Capçalera d'Inici (`MainShell`): alçada de 40 píxels lògics (DP-060).
- `LoginScreen`: alineació centrada i alçada de 96 píxels lògics.
- L’asset respecta les proporcions i ja queda inclòs per `assets/branding/` al pubspec.
- Sense paquets nous, filtres de color que alterin els marcadors ni canvis de navegació/autenticació.

## Verificació

`test/app/branding_test.dart` prova els widgets reals d’Inici i Login. Llegeix la imatge que
consumeix cadascun, comprova alfa zero a les cantonades i mesura el contrast del color opac
majoritari sobre `AppTheme.cream` i `AppTheme.cardBackground`, amb un objectiu de 7:1.
Aquesta mesura es refereix al color principal, no a tots els accents ni als píxels suavitzats.
Les dues proves fallaven amb el PNG anterior perquè les cantonades eren opaques.

Captures de revisió a `PES/output/frontend/task-262-inici.png` i `task-262-login.png`, renderitzades
amb els widgets Flutter i dades de demostració, sense connexions al backend.

Ordres de comprovació:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

# Icona de l’app i pantalla de càrrega — #282

Substitueixen les de Flutter. Es fa servir només el mapa amb els tres marcadors, sobre
`AppTheme.cream` (`#F6EFE2`): el logotip sencer és massa allargat per a una icona.

- **Origen:** totes les imatges surten d’`aprop_logo_transparent.png`, sense paquets nous. El mapa
  se separa del text com a forma connexa i se’n fa opac l’interior (l’original té alfa 245–254, i el
  fons s’hi veia com a taques). El logotip original no canvia.
- **Android 8 o posterior:** icona adaptable (`mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_foreground`).
  El mapa queda a 29 dp del centre; el cercle segur en fa 33, de manera que cap forma no el talla.
  Les versions anteriors fan servir `mipmap-*/ic_launcher.png`.
- **Pantalla de càrrega:** des d’Android 12 el sistema hi posa la icona i l’app només en tria el fons
  (`values-v31`, `values-night-v31`). Abans, `launch_background.xml` amb `launch_logo`. El fons és crema
  en clar i en fosc, perquè l’app només té tema clar.
- **iOS:** `AppIcon` (quadrades, sense transparència), `LaunchImage` i fons crema del `LaunchScreen`.
- **Web:** icones, favicon, i nom, descripció i colors del `manifest.json` i l’`index.html`.

La icona de les notificacions push (silueta blanca) és també de la #282, però va a la branca de push (#276).

Comprovat a l’emulador d’Android (API 37): icona al menú i pantalla de càrrega en clar i en fosc, sense
imatges de Flutter ni canvis de color. **Pendent:** iOS no s’ha pogut provar (cal un Mac), ni Android
anterior a la 12; la validació de marca de l’equip és a DP-047.
