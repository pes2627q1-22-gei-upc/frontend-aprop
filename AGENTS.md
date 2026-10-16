# Instruccions per als assistents de codi — AProp! (frontend)

AProp! és l'app mòbil de FiveGuys (PES, FIB–UPC) per descobrir i planificar activitats culturals a
Catalunya a partir de les Dades Obertes de la Generalitat. Aquest repo és el **client Flutter**. El backend
Go és un altre repo (`../api-aprop`, amb el seu `AGENTS.md`).

## Abans de començar

1. Llegeix `docs/ai/estat.md` (sprint, història i branca actives). És curt.
2. Per a codi, llegeix `docs/architecture.md`. Carrega la resta de `docs/ai/` **només si la tasca ho
   necessita** (índex al final).
3. **No llegeixis `docs/source/*.pdf`** si no t'ho demanen explícitament: `docs/ai/` ja en conté el resum.

## Límit d'acció (regla de l'equip)

- L'usuari aprèn Flutter implementant el projecte per blocs. Si demana explicacions o codi per copiar,
  **no modifiquis fitxers**. Si autoritza canvis, aplica només l'abast autoritzat.
- **Revisió humana obligatòria:** cap agent no fa `git commit`, `git push`, merge ni tag sense una
  confirmació explícita en aquell mateix torn. Proposa el missatge de commit i deixa els canvis per revisar.
- Indica sempre què has modificat i què has pogut verificar. No presentis com a acabada una integració
  pendent ni dades de demostració com si fossin reals.
- **Decisions pendents:** si fas un canvi sense estar-ne segur (requisit ambigu, contracte inexistent, paquet nou,
  desviació del mockup, valor deduït), registra'l a `docs/decisions-pendents.md` (DP-NNN), marca el codi amb
  `TODO(DP-NNN)` i digues-ho a la resposta. Consulta les DP obertes abans de tocar el que hi està relacionat.

## Stack

Flutter 3.47 / Dart 3.13 (Android + iOS; la web només per desenvolupar) · MVVM amb `ChangeNotifier` ·
sense gestor d'estat extern ni client HTTP de moment · API REST pròpia (Go, `net/http`) · Firebase Auth
(pendent) · PostgreSQL, S3 i EC2 al backend.

## Ordres

```bash
flutter pub get
flutter run -d <id>                                   # Android/iOS; `-d chrome` només per revisar la UI
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test                                          # o: flutter test test/features/<x>/<fitxer>_test.dart
flutter build apk --debug                             # mateixa comprovació que la CI
bash scripts/ai/run-quiet.sh flutter test             # mateixa ordre amb la sortida retallada (estalvia tokens)
```

## Arquitectura i codi

- Funcionalitats a `lib/features/<f>/`: `models/`, `repositories/` (contractes), `data/` (implementacions),
  `presentation/{screens,view_models,widgets}`.
- Injecta els contractes de repositori per constructor. Cap dada de demostració ni petició HTTP als widgets.
- Models i contractes, independents de Flutter. Els ViewModels no depenen de `BuildContext` ni construeixen widgets.
- `core/` només conté elements compartits i no depèn de `features/` ni d'`app/`. Les funcionalitats no importen `app/`.
- No dupliquis estat de negoci entre pantalles: llista, detall i agenda comparteixen la font d'inscripcions.
- Segueix els mockups aprovats (`docs/ai/50-ui-mockups.md`). **UI en català.** Colors i estils només des de
  `lib/app/theme/app_theme.dart`.
- No incorporis paquets, endpoints, credencials ni funcionalitats fora de l'abast sense una necessitat concreta.
  No inventis contractes del backend.
- Crea les carpetes d'una funcionalitat quan en comenci el desenvolupament. Conserva amb `.gitkeep` les
  carpetes inicials buides fins que tinguin fitxers reals.
- Codi i identificadors en anglès; noms del domini segons `docs/ai/70-glossari.md`.

## Verificació

- Canvis de Dart: format, `flutter analyze` i les proves pertinents.
- Canvis només de carpetes o documentació: comprova l'estructura i que el codi existent es conserva. No
  afegeixis proves que no verifiquin comportament.
- Les proves verifiquen comportaments (estats de càrrega, buit, error i interaccions), no detalls interns.

## Git

- Gitflow: `master`/`main` i `develop` estan protegides. Treballa a `feature/<nom>` des de `develop` o a
  `hotfix/<nom>` des de `main`. PR cap a `develop` amb ≥ 1 revisió d'algú que no l'ha implementada i CI verd.
- Commit: `Tasca #<ID> <Títol de la tasca>: <descripció concisa>`. Fes servir el número real de Taiga.
- Prohibit: `push --force`, reescriure l'historial compartit, commits a branques protegides i versionar
  `.env` o claus.

## Definition of Done

Implementada · criteris d'acceptació de Taiga complerts · proves superades · revisada per una altra persona ·
fusionada a `develop` · documentació actualitzada · Taiga actualitzat (estat i hores reals).

## No facis mai

- Accedir a la BD des de Flutter o posar claus d'API al client.
- Afegir frameworks al backend Go (només `net/http`).
- Fer commits directes a `master`, `main` o `develop`, o fer commits sense revisió humana.
- Fer servir vocabulari transaccional («comprar», «reservar») o publicitat a la UI: apuntar-se és una intenció d'assistir.
- Llegir o mostrar `.env` o secrets.

## Índex de `docs/ai/` (carrega sota demanda)

| Fitxer | Llegeix-lo quan… |
|---|---|
| `estat.md` | sempre a l'inici; traspàs entre eines |
| `docs/decisions-pendents.md` (fora de `docs/ai/`) | abans d'una tasca relacionada amb una DP oberta; quan tinguis un dubte |
| `memoria.md` | abans de prendre o reobrir una decisió tècnica |
| `00-resum-projecte.md` | no coneixes el producte o dubtes de l'abast (IS / IS NOT) |
| `10-requisits.md` | planifiques, estimes o comences una història |
| `20-model-domini.md` | models, BD, endpoints o proves d'integritat (R1–R15) |
| `30-arquitectura.md` | canvis entre capes o repos, infraestructura o serveis externs |
| `40-api-i-serveis.md` | consumeixes o crees un endpoint; Talaia o Mobilicat |
| `50-ui-mockups.md` | implementes o revises una pantalla |
| `60-metodologia-i-qualitat.md` | PR, release, bugs, CI, NFR |
| `70-glossari.md` | poses nom a alguna cosa del domini |
| `decisions/` | justifiques o canvies una decisió d'arquitectura (ADR) |
| `tokens.md` · `repartiment-eines.md` | quina eina o model fer servir i com estalviar context |
| `README.md` | configuració de les eines d'IA d'aquest repo |

Els fluxos repetibles són skills a `.agents/skills/` (Cursor i Antigravity les carreguen automàticament).
