# Arquitectura del frontend

## Objectiu i estat

Organitzem el projecte per funcionalitats i separem presentació, estat i dades amb un patró MVVM. Aquesta estructura orienta la implementació de la tasca #77 i les funcionalitats següents. Ja existeixen l’arrencada, el tema, el menú i la llista d'activitats amb dades de demostració i capçalera fixa.

La qualitat depèn de respectar les responsabilitats i revisar els canvis, no del nombre de carpetes. No creem implementacions fictícies, dependències o capes que encara no necessitem.

## Responsabilitats

| Ubicació | Responsabilitat |
| --- | --- |
| `lib/main.dart` | Arrencar l’aplicació. |
| `lib/app/aprop_app.dart` | Configurar l’aplicació i connectar les dependències quan les incorporem. |
| `lib/app/navigation/` | Menú, navegació i connexió amb les pantalles. |
| `lib/app/theme/` | Colors, tipografia i estils compartits. |
| `lib/core/widgets/` | Components genèrics compartits entre funcionalitats. |
| `features/activities/models/` | Models de dades en Dart, preferentment immutables. |
| `features/activities/repositories/` | Contractes per obtenir o modificar dades; sense transport ni widgets. |
| `features/activities/data/` | Implementacions dels repositoris, dades de demostració i, més endavant, adaptadors del backend. |
| `features/activities/presentation/screens/` | Pantalles que mostren l’estat i reben interaccions. |
| `features/activities/presentation/view_models/` | Estat de la pantalla i coordinació de les accions amb els repositoris. |
| `features/activities/presentation/widgets/` | Targetes i components propis de les activitats. |
| `assets/images/` | Fotografies i imatges de contingut. |
| `assets/branding/` | Logotip i recursos d’identitat d’AProp!. |
| `test/features/activities/` | Proves del model de presentació i la UI d’activitats. |

`MainShell` crea i allibera `ActivitiesViewModel`, li injecta `DemoActivityRepository` i inicia la càrrega. Mostra `ActivitiesScreen` a Inici i conserva els textos provisionals a les altres seccions. Manté la navegació inferior i mostra un AppBar només fora d'Inici.

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

## Recursos i dependències

Els recursos van a `assets/`, fora de `lib/`. Les fotografies de demostració i l’avatar són a `assets/images/`, declarat a `pubspec.yaml`. S’han preparat amb la vista «Llista» aprovada com a referència; representen contingut fictici, no fotografies verificades d’esdeveniments reals. La procedència i els prompts es documenten a `docs/demo-assets.json`. `assets/branding/aprop_logo.png` és una còpia sense modificacions del logotip aprovat `output/logo/aprop-logo-oficial.png` de la carpeta PES; `assets/branding/` també està declarat a `pubspec.yaml`.

Afegim paquets només quan hi ha codi que els necessita i revisem també el lockfile. Els endpoints, DTO i credencials es configuraran amb el contracte real del backend; no els inventem per completar el frontend.

## Ampliació i revisió

Les futures funcionalitats tindran carpetes pròpies sota `features/`, per exemple `agenda/`, `auth/` o `profile/`, quan comencem a implementar-les. Seguim el mateix patró i compartim només el que té sentit. Si apareix lògica de negoci complexa o repetida entre ViewModels, podem afegir casos d’ús després de revisar la necessitat.

La interfície de l’aplicació és en català. Revisem els mockups, la llegibilitat, els estats de càrrega/buit/error i les interaccions abans de marcar una tasca com a completada. Les proves comproven comportaments; una PR amb dades de demostració ha d’indicar explícitament la integració pendent.
