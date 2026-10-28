# Perfil propi i Configuració

> **Estat actual (2026-10-27):** la [guia d’integració HTTP](profile-backend.md) substitueix els límits Demo d’aquesta descripció inicial. Nom, username, biografia, avatar, creades i `show-plans` ja tenen adaptador real. La biografia admet 500 bytes UTF-8 segons el backend. Les seccions següents documenten els mockups i la implementació original; no són una declaració que tota la configuració ja estigui integrada.

## Abast i referències

L'usuari aporta `perfil_1_principal.png` i `perfil_2_configuracio.png` i autoritza implementar-ne el frontend. Les còpies originals de referència són a `PES/output/mockup/aprop-perfil-principal-v2.png` i `aprop-perfil-configuracio-v2.png`. El contingut coincideix amb les figures 18–19 de la Incepció 2. L'usuari confirma la tasca **#230 Frontend perfil**; els criteris detallats de Taiga continuen pendents de contrastar.

S'implementen el perfil propi, les dues pestanyes, l'accés a fitxes, el panell d'edició de biografia/municipi, copiar el nom d'usuari, Configuració, preferències en memòria i tancament de sessió. DP-032 i DP-033 registren els contractes i les adaptacions provisionals. Els perfils públics d'altres persones i el sistema social complet continuen pendents.

## Identitat, dades demo i fidelitat

La identitat és sempre la del compte autenticat: el nom i `username` de la Núria del mockup no substitueixen la sessió real. El compte demo de Laia reutilitza la foto existent i els tres plans històrics del catàleg, amb les valoracions de mostra 5/4/5. Per això el comptador és 3 i no 9; no es creen sis activitats fictícies amb fitxes inexistents. Els 14 amics, 4,7 de valoració rebuda i 340/500 XP són projeccions de demostració exclusives d'aquell compte.

Un compte nou comença sense plans fets, amistats ni valoració rebuda, amb 0 XP i sense llindar deduït. No rep la foto, biografia, preferències o història de Laia. La valoració rebuda com a organitzador no es calcula a partir de les valoracions que dona l'usuari als seus plans. Apuntar-se no confirma assistència ni atorga XP.

Les cinc insígnies diferencien assolit, actual i pendent amb icones, contorn i semàntica. El progrés es calcula amb el valor retornat pel repositori: 340/500 = 68 %. No es dedueixen els llindars dels altres nivells a partir d'aquest exemple. La quadrícula passa de tres a dues columnes amb pantalla estreta o text ampliat; les insígnies poden desplaçar-se horitzontalment.

## Fitxers i responsabilitats

| Fitxer | Què fa |
|---|---|
| [user_profile.dart](../lib/features/profile/models/user_profile.dart) | Projecció immutable, plans amb assistència confirmada i valoracions opcionals, nivell i XP. |
| [profile_settings.dart](../lib/features/profile/models/profile_settings.dart) | Preferències immutables; el valor inicial de compartir plans és fals. |
| [profile_repository.dart](../lib/features/profile/repositories/profile_repository.dart) | Contracte de lectura del perfil propi i edició dels detalls opcionals. |
| [profile_settings_repository.dart](../lib/features/profile/repositories/profile_settings_repository.dart) | Contracte de consulta i modificació confirmada d'una preferència. |
| [demo_profile_repository.dart](../lib/features/profile/data/demo_profile_repository.dart) | Consulta el catàleg compartit, resol l'autoria per ID, aïlla l'edició per compte i aporta els exemples de Laia. |
| [demo_profile_settings_repository.dart](../lib/features/profile/data/demo_profile_settings_repository.dart) | Desa preferències per compte durant la mateixa execució; no programa notificacions ni gestiona permisos. |
| [profile_view_model.dart](../lib/features/profile/presentation/view_models/profile_view_model.dart) | Càrrega, recàrrega, validació i edició; conserva l'estat confirmat davant errors i ignora respostes després de `dispose`. |
| [profile_settings_view_model.dart](../lib/features/profile/presentation/view_models/profile_settings_view_model.dart) | Càrrega, escriptures serialitzades i tancament de sessió amb càrrega/error/reintent. |
| [profile_screen.dart](../lib/features/profile/presentation/screens/profile_screen.dart) | Observa el ViewModel, manté la pestanya i mostra capçalera, nivells, quadrícula i estats buits/error. |
| [profile_settings_screen.dart](../lib/features/profile/presentation/screens/profile_settings_screen.dart) | Crea/allibera el seu ViewModel i dibuixa els quatre blocs de Configuració. |
| [edit_profile_sheet.dart](../lib/features/profile/presentation/widgets/edit_profile_sheet.dart) | Formulari de biografia (≤200) i municipi (≤80); conserva el text si falla i només tanca després de confirmar el desament. |
| [profile_header.dart](../lib/features/profile/presentation/widgets/profile_header.dart) · [profile_progress_section.dart](../lib/features/profile/presentation/widgets/profile_progress_section.dart) · [profile_activity_tile.dart](../lib/features/profile/presentation/widgets/profile_activity_tile.dart) | Components de la pantalla; no accedeixen a repositoris. |
| [settings_group.dart](../lib/features/profile/presentation/widgets/settings_group.dart) · [profile_palette.dart](../lib/features/profile/presentation/widgets/profile_palette.dart) | Components de configuració i extensió de tema, amb colors subministrats per `AppTheme`. |

## Flux principal, en ordre

1. `APropApp` pot rebre els dos contractes. `AuthGate` fa servir els rebuts o crea els adaptadors demo amb el catàleg compartit. Aquestes instàncies duren la mateixa execució i conserven les preferències quan l'usuari tanca i torna a iniciar sessió.
2. Quan la sessió està verificada i ja té nom d'usuari, `MainShell` crea `ProfileViewModel(user: ..., repository: ...)`, crida `load()` i n'és el propietari. En canviar de compte es destrueix aquell `MainShell` i s'allibera el ViewModel. L'`IndexedStack` construeix totes les arrels: el perfil pot carregar-se abans de tocar Perfil.
3. El ViewModel consulta `getProfile(user)`. `DemoProfileRepository` llegeix el catàleg i selecciona les activitats amb `activity.creator.userId == user.id`. Dues persones amb el mateix nom no comparteixen autoria. Les noves activitats reben l'ID de la sessió a `MainShell` en obrir el formulari de creació.
4. `notifyListeners()` fa que Flutter executi de nou el `builder` de `ProfileScreen`. La pantalla no consulta l'API. Canviar de pestanya només modifica l'estat visual local; no crea ni duplica activitats.
5. Prémer una miniatura emet l'ID a `MainShell`, que obre `activityDetailsRoute` dins del navegador de Perfil amb les inscripcions compartides. Tornar recupera la pestanya i el desplaçament. Entrar de nou a Perfil refresca les dades per recollir activitats creades des d'Inici.
6. «Editar perfil» obre un panell amb el mateix ViewModel. El formulari manté una còpia editable dels dos textos. «Desar» valida i crida `updateDetails`; el perfil visible només canvia després de la confirmació. Tancar el panell sense desar descarta l'edició. No s'editen nom, correu, contrasenya ni `username` fora del contracte d'Auth.
7. «Compartir perfil» obre un diàleg al navegador de Perfil. Permet copiar `@username` al porta-retalls i confirma el resultat o error. No genera una URL pública falsa ni envia missatges a tercers. Si encara no hi ha `username`, l'acció queda desactivada.
8. L'engranatge obre `/profile/settings`. `ProfileSettingsScreen` crea `ProfileSettingsViewModel`, que consulta les preferències del compte. La barra inferior continua sent la de `MainShell`.
9. Un interruptor envia una preferència al repositori. Mentre s'espera, les altres escriptures queden bloquejades; no s'aplica un canvi optimista que pugui resultar fals. Si falla, el valor anterior es conserva i el mateix control permet reintentar. La recàrrega no sobreescriu una escriptura pendent.
10. «Tancar sessió» crida el callback asíncron d'Auth. El ViewModel gestiona l'espera i els errors; l'èxit arriba per `authStateChanges()` i `AuthGate` mostra Login. El ViewModel no navega ni rep `BuildContext`. El tancament continua disponible si la consulta de preferències falla.

## Configuració i límits

- Privacitat i els quatre tipus d'avís són preferències demo per compte. La UI informa que duren aquesta sessió de l'app. No modifiquen els avisos ja rebuts, no activen push i no creen amistats.
- Idioma i tema reflecteixen «Català» i «Clar». Els canvis globals requereixen les seves històries i continuen desactivats amb una explicació. «Castellà» corregeix al català l'etiqueta del mockup.
- Bloquejos, repetir test i eliminar compte es mostren pendents. No es simula una eliminació real ni es creen usuaris bloquejats ficticis.
- Calendar mostra «No connectat» perquè no hi ha integració. El correu del tancament ve de la sessió, sense atribuir-li un proveïdor Google que no tenim.
- La configuració és desplaçable; els controls i textos tenen espai per créixer. Amb text ampliat, l'estat de Calendar passa sota el títol per evitar consumir l'amplada de la fila.
- Falten els contractes autenticats, persistència entre execucions, assistència/valoracions reals, nivells, amistats i la privacitat aplicada al servidor. No s'afegeixen dependències ni endpoints.

## Verificació

Les proves cobreixen immutabilitat, autoria per ID, comptes nous, dades demo, errors/reintents, escriptures confirmades, duplicats, `dispose`, canvis de compte, navegació, edició, cancel·lació, porta-retalls i activitats acabades de crear. Es proven les dues pantalles a 320 px amb text al doble. Les proves d'Auth ara recorren Perfil → Configuració per tancar la sessió.

Resultat de la verificació local (2026-10-22): format correcte, `flutter analyze` sense incidències, **258 proves superades** (30 noves de Perfil) i APK de depuració compilat. La revisió tècnica ha detectat i corregit l'acció semàntica de les miniatures perquè TalkBack/VoiceOver les puguin activar; una prova comprova aquesta acció. Gradle ha avisat d'una diferència de versions de l'XML de l'SDK Android, però la compilació ha acabat correctament. Això no substitueix provar-lo en un dispositiu físic.

Captures generades amb Flutter a 390 × 844, fora del repositori: `PES/output/frontend/profile-principal.png`, `profile-configuracio.png` i `profile-configuracio-compte.png`. Es revisen els espais, les etiquetes de nivell i la configuració desplaçable; no són imatges generades amb IA.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Prova manual: entrar amb Laia, obrir Perfil, consultar una activitat i tornar; canviar a «Creats per mi», editar biografia i municipi, copiar el nom d'usuari, obrir Configuració i canviar una preferència. Tancar i tornar a iniciar sessió conserva aquella preferència durant la mateixa execució. Un altre compte ha de mostrar dades i preferències pròpies. Crear una activitat a Inici i comprovar-la a «Creats per mi».

Branca `feature/profile`, creada des de `origin/develop` (`3808c1d`, amb #96 integrada per PR #16). La tasca #230 està publicada al commit `aff43e6`. El 2026-10-25 s'integra `origin/develop` (`f1d1066`) per resoldre els conflictes; el commit de la resolució i el seu push queden per a l'usuari. Revisió humana i prova en Android físic pendents.

## Integració de `develop` (2026-10-25)

Es conserven Firebase, la tria del nom d'usuari, la verificació enganxant l'enllaç i l'opció de desapuntar-se. El perfil nou substitueix el placeholder anterior i el tancament passa per Configuració. `ActivityCreator` combina `AppUser.fullName` amb l'ID estable del compte. Les proves d'Auth de les dues branques es conserven i els noms d'usuari s'ajusten a la capçalera nova. Les decisions de Perfil es renumeren a DP-032/DP-033 perquè DP-025/DP-026 ja corresponen a Auth; no es canvia l'abast de cap decisió.

Aquesta còpia no té `lib/firebase_options.dart` ni `android/app/google-services.json`. Són configuracions locals ignorades que necessita la nova entrada de Firebase; no s'inventen ni es versionen. La generació i l'accés al projecte s'expliquen a `docs/firebase-auth.md`. Per això l'anàlisi completa i l'APK anteriors (2026-10-22) no es poden atribuir a aquesta integració fins que es generi aquella configuració.

Verificació després de la integració: `flutter pub get --enforce-lockfile` correcte sense canviar el lockfile de `develop`; format de 162 fitxers sense canvis; **318 proves superades** amb `flutter test --no-pub`; `dart analyze lib/app lib/core lib/features test` sense incidències. `flutter analyze --no-pub` només informa dels dos errors de `main.dart` causats per la configuració local de Firebase absent. No es reintenta l'APK mentre faltin els dos fitxers de configuració. La revisió de la resolució no detecta bloquejos; sense marcadors de conflicte ni entrades sense fusionar. No s'ha creat cap commit ni s'ha pujat aquesta resolució.
