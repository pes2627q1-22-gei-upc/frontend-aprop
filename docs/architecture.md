# Arquitectura del frontend

## Objectiu i estat

Organitzem el projecte per funcionalitats i separem presentació, estat i dades amb un patró MVVM. Aquesta estructura orienta la implementació de la tasca #77 i les funcionalitats següents. Ja existeixen l’arrencada, el tema, el menú, l'accés amb comptes de demostració i la llista d'activitats amb dades de demostració i capçalera fixa.

La qualitat depèn de respectar les responsabilitats i revisar els canvis, no del nombre de carpetes. No creem implementacions fictícies, dependències o capes que encara no necessitem.

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
| `assets/images/` | Fotografies i imatges de contingut. |
| `assets/branding/` | Logotip i recursos d’identitat d’AProp!. |
| `test/features/activities/` | Proves del model de presentació i la UI d’activitats. |
| `test/features/auth/` | Proves dels ViewModels, validacions, repositori de demostració i pantalles d'accés. |
| `test/app/` | Proves del recorregut complet de l'aplicació, com entrar, registrar-se i tancar la sessió. |

`AuthGate` mostra `LoginScreen` si no hi ha sessió i `MainShell` si n'hi ha; el detall és a [Accés i sessió](#accés-i-sessió).

`MainShell` rep l'usuari de la sessió i l'acció de tancar-la. Crea i allibera `ActivitiesViewModel`, li injecta `DemoActivityRepository` i inicia la càrrega. Mostra `ActivitiesScreen` a Inici i, provisionalment, l'usuari i el botó «Tanca la sessió» a Perfil; conserva els textos provisionals a les altres seccions. Manté la navegació inferior i mostra un AppBar només fora d'Inici.

`ActivitiesScreen` col·loca `ActivitiesHeader` sobre un `Expanded` amb el contingut desplaçable. El `ListenableBuilder` escolta el ViewModel i actualitza els estats de càrrega, error, buit o llista. La capçalera rep la vista seleccionada i callbacks opcionals; no consulta repositoris ni guarda filtres. Un callback nul desactiva l'acció pendent. `ActivitiesView` només identifica les dues vistes visuals; no és un model de negoci.

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
8. L’estat d’inscripció d’una activitat haurà de tenir una font compartida entre llista, detall i agenda. No mantenim booleans independents en cada pantalla.

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
auth/presentation/screens/login_screen.dart
auth/presentation/screens/register_screen.dart
auth/presentation/widgets/password_field.dart
auth/presentation/widgets/auth_submit_button.dart
auth/presentation/widgets/google_sign_in_button.dart
app/navigation/auth_gate.dart
```

`AuthRepository.authStateChanges()` és l'única font de la sessió: emet l'usuari actual en subscriure-s'hi i cada canvi posterior. `main.dart` crea el repositori, `APropApp` el passa a `AuthGate` i aquest decideix què es mostra. Per això les pantalles no naveguen en iniciar o tancar la sessió. L'única excepció és `RegisterScreen`, que es tanca després d'un registre correcte perquè quedi visible l'aplicació que `AuthGate` ja mostra a sota.

Les operacions del repositori llancen `AuthFailure` quan l'error es pot explicar a l'usuari. Cada implementació hi tradueix els seus errors, i els ViewModels els converteixen en missatges en català. Els ViewModels també validen els camps abans de cridar el repositori i guarden l'error de cada camp. Quan l'usuari modifica un camp, se n'esborra l'error i també el missatge general; tot es torna a comprovar en enviar el formulari.

Criteris de Taiga aplicats: confirmació de contrasenya en el registre; contrasenya de mínim 8 caràcters amb majúscula, minúscula, número i caràcter especial; nom d'usuari únic; inici de sessió amb nom d'usuari o correu; i rebuig de credencials incorrectes.

Cada pantalla crea el seu ViewModel amb el repositori que rep i l'allibera en tancar-se. `LoginScreen` obre `RegisterScreen` amb el mateix repositori. El botó per tancar la sessió és provisionalment a Perfil, fins que existeixi la funcionalitat de perfil.

Integració pendent:

- `FirebaseAuthRepository`, amb accés per correu i amb Google, que substituirà `DemoAuthRepository` a `main.dart`.
- Alta de l'usuari al backend en registrar-se i consulta del perfil, amb el nom d'usuari, en iniciar la sessió.
- Un endpoint del backend que obtingui el correu a partir del nom d'usuari, o que faci ell mateix l'inici de sessió.
- Primer accés amb Google: una pantalla per triar el nom d'usuari. Per això `AppUser.username` pot ser nul.
- El token de Firebase per a les peticions autenticades de la resta de funcionalitats.

La recuperació de contrasenya és una altra història i no forma part de l'Sprint 1.

## Recursos i dependències

Els recursos van a `assets/`, fora de `lib/`. Les fotografies de demostració i l’avatar són a `assets/images/`, declarat a `pubspec.yaml`. S’han preparat amb la vista «Llista» aprovada com a referència; representen contingut fictici, no fotografies verificades d’esdeveniments reals. La procedència i els prompts es documenten a `docs/demo-assets.json`. `assets/branding/aprop_logo.png` és una còpia sense modificacions del logotip aprovat `output/logo/aprop-logo-oficial.png` de la carpeta PES; `assets/branding/` també està declarat a `pubspec.yaml`.

Afegim paquets només quan hi ha codi que els necessita i revisem també el lockfile. Els endpoints, DTO i credencials es configuraran amb el contracte real del backend; no els inventem per completar el frontend.

## Ampliació i revisió

Les futures funcionalitats tindran carpetes pròpies sota `features/`, per exemple `agenda/` o `profile/`, quan comencem a implementar-les. Seguim el mateix patró i compartim només el que té sentit. Si apareix lògica de negoci complexa o repetida entre ViewModels, podem afegir casos d’ús després de revisar la necessitat.

La interfície de l’aplicació és en català. Revisem els mockups, la llegibilitat, els estats de càrrega/buit/error i les interaccions abans de marcar una tasca com a completada. Les proves comproven comportaments; una PR amb dades de demostració ha d’indicar explícitament la integració pendent.
