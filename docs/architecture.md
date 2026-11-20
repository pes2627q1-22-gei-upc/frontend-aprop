# Arquitectura del frontend

## Objectiu i estat

Organitzem el projecte per funcionalitats i separem presentació, estat i dades amb un patró MVVM. Aquesta estructura orienta la implementació de la tasca #77 i les funcionalitats següents. Ja existeixen l’arrencada, el tema, el menú, l'accés amb comptes de demostració i la llista d'activitats amb dades de demostració i capçalera fixa.

La qualitat depèn de respectar les responsabilitats i revisar els canvis, no del nombre de carpetes. No creem implementacions fictícies, dependències o capes que encara no necessitem.

Les tasques #75 i #82 afegeixen el detall i les inscripcions compartides entre llista i detall. Vegeu `docs/activity-details.md` i `docs/event-enrollment.md` per seguir els fluxos i integrar l'agenda. La història #31 (tasca #93) permet crear activitats no oficials des d'Inici; vegeu `docs/create-activity.md`.

## Responsabilitats

| Ubicació | Responsabilitat |
| --- | --- |
| `lib/main.dart` | Arrencar l’aplicació i triar la implementació del repositori d'accés. |
| `lib/app/aprop_app.dart` | Configurar l’aplicació i passar les dependències a la navegació. |
| `lib/app/navigation/` | Porta d'accés (`AuthGate`), menú, navegació i connexió amb les pantalles. |
| `lib/app/theme/` | Colors, tipografia i estils compartits. |
| `lib/core/widgets/` | Components genèrics compartits entre funcionalitats. |
| `features/activities/models/` | Models de dades en Dart, preferentment immutables. |
| `features/activities/repositories/` | Contractes per obtenir o modificar dades; sense transport ni widgets. |
| `features/activities/data/` | Implementacions dels repositoris, dades de demostració i, més endavant, adaptadors del backend. |
| `features/activities/presentation/screens/` | Pantalles que mostren l’estat i reben interaccions. |
| `features/activities/presentation/view_models/` | Estat de la pantalla i coordinació de les accions amb els repositoris. |
| `features/activities/presentation/widgets/` | Targetes i components propis de les activitats. |
| `features/auth/` | Inici de sessió, registre i sessió, amb les mateixes capes que `activities/`. |
| `features/assistant/` | Conversa amb l'assistent cultural («Assistent»), interpretació de consultes i recomanació d'activitats. |
| `features/profile/` | Perfil propi, edició de detalls i preferències de Configuració, amb les mateixes capes i repositoris per compte. |
| `features/notifications/` | Bústia d'Avisos, filtres, lectura i resposta a sol·licituds de demostració, separats de l'enviament de notificacions. |
| `assets/images/` | Fotografies i imatges de contingut. |
| `assets/branding/` | Logotip i recursos d’identitat d’AProp!. |
| `assets/icons/` | Icones de tercers que no ofereix Material, com el logotip de Google. |
| `test/features/activities/` | Proves del model de presentació i la UI d’activitats. |
| `test/features/assistant/` | Proves del model (R12), repositori de demostració, ViewModel i pantalla de l'assistent. |
| `test/features/auth/` | Proves dels ViewModels, validacions, repositori de demostració i pantalles d'accés. |
| `test/app/` | Proves del recorregut complet de l'aplicació, com entrar, registrar-se i tancar la sessió. |

`AuthGate` mostra `LoginScreen` si no hi ha sessió, `VerifyEmailScreen` si l'usuari encara no ha verificat el correu i `MainShell` si tot és correcte; el detall és a [Accés i sessió](#accés-i-sessió).

`MainShell` receives the signed-in user, sign-out action and the shared activity/enrollment repository contracts from `AuthGate`. It owns `ActivitiesViewModel` and the account's shared `EnrollmentViewModel`. Each of the five sections has a nested `Navigator` inside the existing `IndexedStack`; the single bottom navigation bar remains outside those navigators. Section roots own their AppBars. `NavigatorPopHandler` sends system back actions only to the active section. Switching sections preserves each history; popping a detail reveals the original list and scroll position.

**Pestanyes (#273, DP-060):** la secció 0 («Inici») mostra `DiscoverScreen` amb la capçalera «AProp!», el «+» (`_openCreateActivity`) i la lupa (`_openDiscoverySearch`); la secció 2 («Mapa») mostra `ActivitiesScreen`. El botó «Assistent» surt a totes dues.

**Xat a pantalla completa (#261):** `MainShell._openAssistant` manté `/assistant` al navegador de la pestanya des d’on s’obre (Inici o Mapa) i amaga `bottomNavigationBar` mentre espera que aquesta ruta acabi. `_isAssistantOpen` és estat local de presentació, no estat del ViewModel ni del repositori. El bloc `finally` restaura la barra si el shell continua muntat, tant amb la fletxa com amb el retorn del sistema o una drecera de l’assistent. No es crea un navegador global ni es desmunten les seccions, els filtres o els ViewModels compartits. Obrir una fitxa recomanada conserva el flux sense barra fins que es tanca el xat (DP-048); les fitxes obertes des de les seccions mantenen la navegació habitual. El camp de consulta continua utilitzant el redimensionament i l’àrea segura de `Scaffold`/`SafeArea`, també amb el teclat obert. Les proves de `test/app/assistant_navigation_test.dart` cobreixen retorn, desplaçament, teclat, dreceres, resposta tardana i fi de sessió; `assistant_flow_test.dart` cobreix conversa, fitxa i inscripció compartida.

`ActivitiesScreen` places `ActivitiesHeader` above the scrollable content. Its `ListenableBuilder` observes the list ViewModel. `ActivityCard` invokes a callback, the screen forwards the activity ID through `onActivitySelected`, and `MainShell` opens `activityDetailsRoute`. Features do not import app navigation. Header callbacks remain disabled until their features are implemented.

`ActivityDetailsScreen` receives an activity ID and repository contract, creates and disposes `ActivityDetailsViewModel`, and renders its loading, error, not-found or loaded state. It reloads if its ID or repository changes. `ActivityRepository.getActivityById` returns null for a missing event and throws on a data-access failure. Detail loading does not depend on a previously loaded catalogue. The same entry point can be wired to Agenda, map, search or notifications through callbacks. See [the integration guide](activity-details.md).

## Flux de dades

```text
Pantalla i widgets
       │ mostren estat i envien accions
       ▼
    ViewModel
       │ depèn d’un contracte de repositori
       ▼
Contracte de repositori
       ▲ implementat per
       │
Repositori de demostració / Repositori del backend
```

La composició a `app/` tria i injecta la implementació del repositori. Així podrem substituir les dades de demostració sense reescriure els widgets. No hi ha encara un gestor d’estat extern ni un client HTTP incorporats; afegirem les dependències quan les utilitzem.

## Regles de dependència

1. Els widgets no contenen dades hardcoded del catàleg, peticions HTTP ni regles de negoci. Les dades d’exemple viuen a `data/`.
2. Els ViewModels reben el contracte del repositori pel constructor. No reben `BuildContext`, no creen widgets i no instancien el repositori concret.
3. Models i contractes no depenen de Flutter, de la navegació ni del format JSON d’una API. La conversió del backend a models pertany a `data/`.
4. Les implementacions de dades no importen pantalles ni ViewModels.
5. `core/` no importa `features/` ni `app/`. Un component específic d’activitats es queda a `activities/presentation/widgets/`.
6. Les funcionalitats no importen `app/`; la navegació i la composició connecten les funcionalitats des d’`app/`.
7. Entre funcionalitats es poden compartir models i contractes explícits. No s’importa la pantalla, el ViewModel o el repositori concret d’una altra funcionalitat per reutilitzar el seu estat.
8. `EnrollmentRepository` és la font compartida d'inscripcions per usuari. Llista i detall comparteixen un `EnrollmentViewModel`; l'agenda consumeix el mateix contracte des del seu propi `AgendaViewModel` (vegeu `docs/calendar.md`). No mantenim booleans independents en cada pantalla.

L’estat visual local, com l’índex del menú actual, pot utilitzar `setState`. La càrrega d’activitats, els errors i les accions del catàleg es coordinaran des del ViewModel. Qui creï un recurs que requereixi alliberament també ha de gestionar-ne el cicle de vida.

## Implementació de la tasca #77

Afegirem els fitxers a mesura que els implementem, amb noms consistents:

```text
activities/models/activity.dart
activities/repositories/activity_repository.dart
activities/data/demo_activity_repository.dart
activities/presentation/view_models/activities_view_model.dart
activities/presentation/screens/activities_screen.dart
activities/presentation/widgets/activity_card.dart
activities/presentation/widgets/activity_badges.dart
activities/presentation/widgets/activities_header.dart
```

La UI segueix el mockup aprovat: capçalera, controls de filtratge, selector de vista i targetes amb fotografia, informació i procedència. Les activitats d’usuaris incorporen informació de la persona creadora quan correspongui. Els controls pendents es mostren desactivats i «Llista» és la vista seleccionada. Evitem anticipar tot el model conceptual del sistema.

Cal revisar els criteris de Taiga per delimitar què implementa #77 i què correspon a altres tasques: mapa, filtres, inscripcions, detall, assistent i perfil. La presència d’un control en el mockup no implica que la seva funcionalitat estigui acabada.

## Accés i sessió

La història d'inici de sessió, registre i tancament de sessió es troba a `features/auth/`:

```text
auth/models/app_user.dart
auth/models/auth_failure.dart
auth/repositories/auth_repository.dart
auth/data/demo_auth_repository.dart
auth/presentation/view_models/login_view_model.dart
auth/presentation/view_models/register_view_model.dart
auth/presentation/view_models/auth_validators.dart
auth/presentation/view_models/auth_failure_message.dart
auth/presentation/view_models/verify_email_view_model.dart
auth/presentation/screens/login_screen.dart
auth/presentation/screens/register_screen.dart
auth/presentation/screens/verify_email_screen.dart
auth/presentation/widgets/password_field.dart
auth/presentation/widgets/auth_submit_button.dart
auth/presentation/widgets/google_sign_in_button.dart
auth/presentation/widgets/auth_secondary_action.dart
auth/presentation/widgets/auth_link_prompt.dart
auth/presentation/widgets/auth_status_message.dart
app/navigation/auth_gate.dart
```

`AuthRepository.authStateChanges()` és l'única font de la sessió: emet l'usuari actual en subscriure-s'hi i cada canvi posterior. `main.dart` crea el repositori, `APropApp` el passa a `AuthGate` i aquest decideix què es mostra. Per això les pantalles no naveguen en iniciar o tancar la sessió. L'única excepció és `RegisterScreen`, que es tanca després d'un registre correcte perquè quedi visible la pantalla que `AuthGate` ja mostra a sota.

Les operacions del repositori llancen `AuthFailure` quan l'error es pot explicar a l'usuari. Cada implementació hi tradueix els seus errors, i els ViewModels els converteixen en missatges en català. Els ViewModels també validen els camps abans de cridar el repositori i guarden l'error de cada camp. Quan l'usuari modifica un camp, se n'esborra l'error i també el missatge general; tot es torna a comprovar en enviar el formulari.

Criteris de Taiga aplicats: confirmació de contrasenya en el registre; contrasenya de mínim 8 caràcters amb majúscula, minúscula, número i caràcter especial; nom d'usuari únic; inici de sessió amb nom d'usuari o correu; i rebuig de credencials incorrectes.

L'aplicació queda bloquejada fins que l'usuari verifica el correu. El registre envia el correu de verificació i, mentre `AppUser.emailVerified` és fals, `AuthGate` mostra `VerifyEmailScreen` en lloc de l'app, també en tornar a iniciar la sessió o obrir l'aplicació. La pantalla permet comprovar de nou la verificació, tornar a enviar el correu i tancar la sessió, per si l'usuari s'ha equivocat de correu. Per no reenviar el correu sense parar, el botó d'enviar espera 60 segons en obrir la pantalla i després de cada enviament correcte (Firebase rebutja els reenviaments més seguits). `DemoAuthRepository` no envia cap correu: la comprovació simula que l'usuari ha obert l'enllaç.

Cada pantalla crea el seu ViewModel amb el repositori que rep i l'allibera en tancar-se. `LoginScreen` obre `RegisterScreen` amb el mateix repositori. El tancament de sessió és a Perfil → Configuració; el ViewModel espera la confirmació d'Auth i presenta un error si falla.

Integració pendent:

- `FirebaseAuthRepository`, amb accés per correu i amb Google, que substituirà `DemoAuthRepository` a `main.dart`.
- Verificació amb Firebase: enviar el correu amb `sendEmailVerification`, comprovar-la amb `reload` i escoltar `userChanges` (`authStateChanges` no avisa de la verificació). Després de verificar cal demanar un token nou perquè el backend vegi `email_verified`.
- El backend ha de rebutjar les peticions d'usuaris sense el correu verificat; el bloqueig del frontend no n'hi ha prou.
- Alta de l'usuari al backend en registrar-se i consulta del perfil, amb el nom d'usuari, en iniciar la sessió.
- Un endpoint del backend que obtingui el correu a partir del nom d'usuari, o que faci ell mateix l'inici de sessió.
- Primer accés amb Google: una pantalla per triar el nom d'usuari. Per això `AppUser.username` pot ser nul.
- El token de Firebase per a les peticions autenticades de la resta de funcionalitats.

La recuperació de contrasenya és una altra història i no forma part de l'Sprint 1.

## Enrollment — Taiga #82

`EnrollmentRepository` is a pure-Dart contract with `enroll(...)` and `watchEnrolledActivityIds(userId)`. The latter emits an initial immutable snapshot and subsequent confirmed changes. Enrollment is idempotent and expresses an intention to attend; attendance, reminders and unenrollment remain separate operations.

`AuthGate` owns the shared activity and demo enrollment repositories unless callers inject alternatives through `APropApp`. It retains them across sign-outs and disposes only repositories it creates. `MainShell`, keyed by account ID, owns an `EnrollmentViewModel` for the signed-in user, loads it and disposes it when the account changes. The list and detail route receive that same ViewModel.

`EnrollmentAction` renders initial, loading, pending, confirmed and retry states for both surfaces. List cards expose independent image/title navigation and enrollment actions. Confirmed plans are never cleared by a failed refresh, and a write is not displayed as successful before confirmation. Pending responses cannot notify a disposed ViewModel or another account.

Calendar integration must use the same repository instance and user ID through its own ViewModel; it must not import the activity presentation ViewModel. The demo repository is memory-only and validates event IDs against the catalogue. The authenticated backend adapter and calendar wiring are tracked in DP-010; no API endpoints or DTOs have been assumed.

## Avisos — Taiga #86

`NotificationRepository` és el contracte en Dart pur per consultar els avisos rebuts, confirmar-ne la lectura i respondre una sol·licitud. `HttpNotificationRepository` rep `ApiClient` i el contracte `ActivityDetailsRepository`; obté el UUID real de `/users/me`, valida la identitat sol·licitada i consulta `/notificationtypes` i la bústia. El mapping JSON és a `data/notification_json_mapper.dart`; models i ViewModel no coneixen HTTP ni IDs de tipus. `DemoNotificationRepository` conserva exemples separats per compte, sense modificar inscripcions. Les accions socials de Demo no es simulen al repositori HTTP (fora de l’Sprint 1, confirmat per l’usuari).

`AuthGate` crea o rep el repositori compartit, i `MainShell` l'injecta a `NotificationsScreen`. La pantalla crea i allibera el seu `NotificationsViewModel`. Els widgets no fan peticions ni contenen avisos de demostració. El ViewModel ordena i filtra, controla les operacions pendents i només confirma lectura/resposta després de l'èxit del repositori. Un error de recàrrega conserva els avisos ja carregats.

La navegació surt per `onActivitySelected` i `onPersonSelected`; la feature no importa cap pantalla ni ViewModel d'una altra feature. La fitxa s'obre amb la ruta i les inscripcions compartides. El callback de perfil queda absent fins que la funcionalitat existeixi, amb una indicació explícita a la UI. Cada filtre conserva el desplaçament i tornar d'una fitxa conserva l'estat. `TickerMode` atura les animacions de les seccions no visibles sense destruir-ne els navegadors.

Els colors addicionals de les etiquetes s'injecten des d'`AppTheme` amb `NotificationBadgeTheme`. La fila de filtres es pot desplaçar en pantalles estretes o amb text ampliat. Vegeu `docs/notifications.md` per seguir els fitxers i les proves.

El context d’activitats/persones es consulta una vegada per ID únic i refresc, amb màxim quatre peticions
simultànies. L’avís conserva la seva referència si el context falla o ja no existeix; un tipus desconegut
continua a «Tots». La lectura comprova destinatari i confirma `POST /read` abans de canviar la UI. Aquesta
comprovació al client no substitueix l’autorització pendent al servidor. Identitat, errors, límits i
dependències de generació/zona horària es documenten a `docs/notifications-backend.md`, DP-039/DP-023.

## Descobreix i cerca — Taiga #96

La descoberta i la cerca viuen dins de `features/activities/`, reutilitzant `ActivityCard`, `EnrollmentAction` i el detall. `DiscoveryRepository` declara `getFeed` i `searchActivitiesPage`; `DiscoveryFeed` i `ActivitySearchPage` són snapshots immutables en Dart pur, amb estats de disponibilitat per secció, total de cerca i continuació. Els ViewModels no coneixen HTTP, JSON, widgets ni `BuildContext`.

`HttpDiscoveryRepository` comprova el compte amb `/users/me`, fixa el bearer i consulta preferències/recomanacions i populars en paral·lel. Les dues seccions poden fallar separadament; preferències buides són un estat propi. No es fabriquen propostes personalitzades des del catàleg. `DiscoverViewModel` conserva la secció confirmada que ha fallat i actualitza la resta. Errors d’autenticació continuen globals. Demo manté els exemples del mockup.

`ActivitySearchViewModel` espera 350 ms mentre s’escriu i permet enviar immediatament. Cerca des de 0, total del servidor, continuacions serialitzades, deduplicació per ID, error/reintent de pàgina i invalidació per revisió. Canviar/esborrar la consulta o sortir invalida respostes; refrescar també invalida una continuació pendent. Les pantalles creen/alliberen els ViewModels i la UI reutilitza `ActivityListPagination`.

`AuthGate` injecta el repositori a `MainShell`, que compon Descobreix, `/discover/search` i les rutes de detall dins del mateix navegador de secció. Tornar conserva consulta, pàgines i scroll. Les dues pantalles reben el mateix `EnrollmentViewModel`; apuntar-se es confirma amb la font compartida d’Inici, detall i Agenda. «Persones» i el test d’interessos requereixen les seves històries. Vegeu `docs/discovery-backend.md`, DP-041/DP-024 per al contracte i els límits del ranking del servidor.

## Perfil propi i Configuració

`features/profile/` té models i contractes en Dart pur, adaptadors Demo/HTTP, ViewModels i presentació. Comparteix models i contractes d’Auth/activitats; no importa els seus widgets ni ViewModels. L’adaptador HTTP reutilitza el mapper d’activitats de la capa de dades. `ProfileRepository` separa metadades, activitats creades, edició i avatar; les inscripcions no s’interpreten com assistència. `ProfileCapabilities` indica els camps i col·leccions disponibles. `ProfileSettingsRepository` declara les preferències suportades i si són persistents.

`AuthGate` crea/injecta els dos repositoris i els conserva durant l’execució. `MainShell`, identificat pel compte, crea i allibera `ProfileViewModel`, com ja fa amb el catàleg i les inscripcions; el refresca en entrar a Perfil perquè reflecteixi activitats creades des d’Inici. `ProfileScreen` conserva només la pestanya local i observa aquest ViewModel. El panell d’edició comparteix el mateix estat; cap perfil no es duplica dins d’un widget.

`ProfileSettingsScreen` crea/allibera el seu `ProfileSettingsViewModel`; les escriptures se serialitzen per evitar sobreescriure snapshots concurrents. Idioma, tema i serveis no disponibles es mostren explícitament pendents. El callback de tancament de sessió ara retorna `Future<void>` i es confirma/gestiona sense navegar des del ViewModel. `MainShell` compon la ruta `/profile/settings`, les fitxes i el diàleg de copiar el nom d’usuari al navegador de Perfil.

`ProfileApi` captura el bearer de cada operació i valida l’UUID real i l’UID del compte contra `/users/me`. Les escriptures i la consulta de creades retenen aquelles capçaleres; no s’inventen UUID ni s’envia `X-User-ID`. Els DTOs es converteixen només a `data/`. El ViewModel conserva les col·leccions si falla una recàrrega i fusiona una col·lecció que arriba tard amb els detalls confirmats; els callbacks després de `dispose` s’ignoren.

`ProfileImagePicker` retorna bytes immutables o `null` en cancel·lar. `GalleryProfileImagePicker` encapsula `image_picker`; `MainShell` l’injecta només si el repositori suporta avatar. Un fitxer recuperat després d’una interrupció d’Android no es puja automàticament a un compte diferent. `ApiClient.postMultipart` comprova el límit del cos complet quan s’indica i permet retenir les capçaleres de l’operació. `ContentImage` és el component compartit per portades i avatars, sense enviar tokens al servidor d’imatges.

L’autoria usa IDs, mai noms; crear una activitat i compartir el perfil utilitzen el nom/username confirmats del `ProfileViewModel`. Colors de nivell centralitzats a `AppTheme` mitjançant `ProfilePalette`. HTTP conserva l’XP i l’ID de nivell, però no dibuixa cinc insígnies ni llindars sense contracte. Decisions DP-032/DP-033/DP-040 i guia a `docs/profile-backend.md`.

## Filtres d’Inici — Taiga #87

`ActivityFilters` i `ActivityDateRange` són valors immutables en Dart pur. `ActivitiesViewModel` conserva
el catàleg i és l’únic propietari dels filtres confirmats. `getActivitiesPage(filters: …)` aplica la
consulta a la font abans de paginar. Canviar-la buida les pàgines anteriors i invalida respostes antigues;
actualitzar sense canviar-la conserva les dades si falla.

`ActivitiesScreen` obre els panells reutilitzables Dates/Categories. Cada panell té un esborrany local;
només Aplicar retorna una selecció confirmada. La pantalla aplica el mateix valor als resultats de
`ActivitiesMapViewModel`, sense duplicar-lo ni tornar a demanar la zona. La ruta modal cobreix la barra
inferior i es retira quan desapareix el compte propietari. Widgets i ViewModel respecten les capes
existents; no s’afegeixen paquets ni repositoris concrets a presentació.

Les fonts diferents i metadades incompletes del mapa continuen a DP-029; l’abast provisional del
filtratge i el contracte pendent es registren a DP-035/DP-038. `getFilterCategories()` carrega les opcions
de la mateixa font: el ViewModel en gestiona càrrega/error/reintent i el panell només conserva l’esborrany.
L’adaptador HTTP resol les etiquetes a IDs reals, combina consultes d’una categoria com OR (màxim quatre
simultànies), elimina IDs d’activitats duplicats i conserva totes les categories d’una activitat en un
snapshot immutable. Cap crida HTTP ni mapping d’IDs als widgets. Vegeu `docs/inici-server-filters.md`.

## Llista paginada d'Inici

`ActivityRepository.getActivitiesPage` retorna un `ActivityPage` immutable amb el lot i la continuació,
amb índex inicial 0. HTTP, Demo i Combined comparteixen aquest contracte; `getActivities()` es conserva
per als consumidors existents. La pantalla no coneix el repositori concret.

`ActivitiesViewModel` manté cursor, catàleg carregat i projecció local, diferencia errors de càrrega,
refresc i continuació, i invalida respostes anteriors quan es refresca. La pantalla conserva les targetes
i el desplaçament en afegir pàgines. `ActivityImage` resol la presentació d'assets i `Activity.imageUrl`
a llista, fitxa i previsualització del mapa. Vegeu `docs/inici-list-backend.md` i DP-037. La integració
dels filtres al servidor queda fora d'aquesta primera tasca.

## Recursos i dependències

Els recursos van a `assets/`, fora de `lib/`. Les fotografies de demostració i l’avatar són a `assets/images/`, declarat a `pubspec.yaml`. S’han preparat amb la vista «Llista» aprovada com a referència; representen contingut fictici, no fotografies verificades d’esdeveniments reals. La procedència i els prompts es documenten a `docs/demo-assets.json`. `assets/branding/aprop_logo.png` és una còpia sense modificacions del logotip aprovat `output/logo/aprop-logo-oficial.png` de la carpeta PES i es conserva com a original. #262 afegeix `aprop_logo_transparent.png`, sense el fons crema opac i amb menys marge, per integrar-lo amb les superfícies clares de l’app. `APropLogo`, a `lib/core/widgets/aprop_logo.dart`, centralitza l’asset, l’ajust de proporcions i l’etiqueta accessible; Inici i Login el reutilitzen sense dependències de `core/` cap a `app/` o `features/`. `assets/branding/` ja està declarat a `pubspec.yaml`; no hi ha paquets nous. Vegeu `docs/branding.md` i DP-047. `assets/icons/google_g.png` és el logotip «G» de Google per al botó d'accés: s'ha retallat de `Theme=Light, Show text=No, Shape=Square` (PNG @4x) del paquet oficial `signin-assets.zip` de Google Identity i se n'ha tret el fons blanc, sense modificar-ne la forma ni els colors.

Afegim paquets només quan hi ha codi que els necessita i revisem també el lockfile. Els endpoints, DTO i credencials es configuraran amb el contracte real del backend; no els inventem per completar el frontend.

## Ampliació i revisió

Les futures funcionalitats tindran carpetes pròpies sota `features/` quan comencem a implementar-les, com ja fan `agenda/` i `profile/`. Seguim el mateix patró i compartim només el que té sentit. Si apareix lògica de negoci complexa o repetida entre ViewModels, podem afegir casos d’ús després de revisar la necessitat.

La interfície de l’aplicació és en català. Revisem els mockups, la llegibilitat, els estats de càrrega/buit/error i les interaccions abans de marcar una tasca com a completada. Les proves comproven comportaments; una PR amb dades de demostració ha d’indicar explícitament la integració pendent.
