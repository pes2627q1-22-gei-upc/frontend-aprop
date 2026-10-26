# Llista real d'Inici — ampliació de #77

## Abast

Primera de les dues tasques acordades: llista paginada del servidor, portades i retorn de la fitxa.
La segona connectarà els filtres al servidor. No es modifica cap fitxer d'`api-aprop` ni s'inventen
endpoints. El contracte s'ha contrastat amb `api-aprop@develop`, commit `c94ab70`.

L'usuari associa aquest treball a la tasca original #77 «Frontend llista d'esdeveniments»; abans del
commit cal confirmar-ne l'estat a Taiga. Branca `feature/inici-list-backend`, des de `c0c2545`.

## Com funciona

1. En entrar a Inici, el ViewModel demana la pàgina **0** de 50 activitats.
2. La pantalla mostra les targetes i, si pot haver-hi més dades, «Carregar més activitats» al final.
3. Una petició nova manté les targetes visibles. Els resultats s'afegeixen sense reiniciar el desplaçament
   ni duplicar IDs. Un error permet reintentar exactament la mateixa pàgina.
4. Arrossegar des de dalt actualitza la primera pàgina. Es conserva el catàleg anterior mentre s'espera
   i també si falla; una resposta d'una petició anterior ja no el pot substituir.
5. La foto o el títol obren la fitxa per ID. Tornar conserva les pàgines carregades i la posició.
   Les inscripcions continuen utilitzant l'estat compartit existent.

`GET /events` no retorna un total. Una resposta completa indica que **pot** haver-hi una altra pàgina;
una resposta curta o buida marca el final. Si el total és múltiple de 50 cal una última petició buida.
Es respecta l'ordre del backend: ordenar cada pàgina per separat alterava la coherència entre pàgines.

Els filtres actuals només afecten les dades carregades. Si no hi ha coincidències però queden pàgines,
el text és «Cap coincidència entre les activitats carregades» i es pot continuar carregant. No s'afirma
que tot el catàleg estigui buit. Aplicar-los no fa peticions de filtratge al servidor en aquesta tasca.

## Arquitectura i recorregut del codi

| Fitxer | Responsabilitat |
|---|---|
| [activity_page.dart](../lib/features/activities/models/activity_page.dart) | Snapshot immutable d'una pàgina, amb activitats i continuació. Dart pur. |
| [activity_repository.dart](../lib/features/activities/repositories/activity_repository.dart) | Contracte compartit: `getActivitiesPage(page, pageSize)`. Els consumidors antics conserven `getActivities()`. |
| [http_activity_repository.dart](../lib/features/activities/data/http_activity_repository.dart) | `GET /events?pageNum=0&pageSize=50`, conversió i detecció del final. Errors HTTP o JSON invàlid no es converteixen en un catàleg buit. |
| [activity_json_mapper.dart](../lib/features/activities/data/activity_json_mapper.dart) | JSON kebab-case a `Activity`; ID/títol/data vàlids i portada remota. |
| [activities_view_model.dart](../lib/features/activities/presentation/view_models/activities_view_model.dart) | Propietari del catàleg, cursor, càrrega inicial, continuació i errors. Generació de petició per ignorar respostes antigues; filtre local i fusionat per ID. |
| [activities_screen.dart](../lib/features/activities/presentation/screens/activities_screen.dart) | Mostra l'estat i envia accions. No consulta HTTP directament. |
| [activity_list_pagination.dart](../lib/features/activities/presentation/widgets/activity_list_pagination.dart) | Recompte carregat, acció de continuació, progrés i reintents. |
| [activity_image.dart](../lib/features/activities/presentation/widgets/activity_image.dart) | Foto remota o asset local, càrrega sense animacions innecessàries i alternativa si falla. Reutilitzada per targeta, fitxa i previsualització del mapa. |

```text
MainShell crea ActivitiesViewModel amb el contracte compartit
  → load() / loadMore()
  → ActivityRepository.getActivitiesPage
  → HttpActivityRepository → ApiClient → GET /events
  → JSON → ActivityPage → ViewModel.notifyListeners()
  → ActivitiesScreen / ActivityCard / ActivityImage
  → onActivitySelected(id) → ruta de detall → GET /events/{id}
```

`DemoActivityRepository` i `CombinedActivityRepository` implementen el mateix contracte. No es fa
cap conversió a la classe HTTP concreta des de widgets o ViewModels. No s'afegeixen paquets ni estat
duplicat d'inscripcions. Canviar de compte destrueix el ViewModel i una resposta tardana s'ignora.

## Imatges i dates

`Activity.imageAsset` continua amb els recursos locals; `imageUrl` és independent. L'adaptador admet
URL HTTP(S) absolutes i selecciona la primera portada utilitzable de `images`. Les rutes oficials
`/content/dam/…` es resolen contra `https://agenda.cultura.gencat.cat`; els espais i accents es codifiquen.
No es construeixen URL per a altres rutes desconegudes ni s'accepten esquemes com `file:` o `javascript:`.

Els exemples relatius i múltiples s'han verificat al [dataset oficial de Gencat](https://analisi.transparenciacatalunya.cat/resource/rhpv-yr4f.json?%24select=imatges&%24where=imatges%20%3E%20%27%27&%24limit=3).
També s'ha comprovat una [imatge del domini oficial](https://agenda.cultura.gencat.cat/content/dam/agenda/ca/activitats/2025/08/21/003/annexos/00l.jpg)
amb resposta HTTP 200 i tipus `image/jpeg`.

Les imatges es carreguen sense les capçaleres d'autenticació de l'API. A web, l'estratègia de Flutter
permet utilitzar un element HTML si el servidor d'imatges no admet la càrrega habitual amb CORS.
La imatge manté dimensions estables i etiqueta semàntica; si és absent, falla o encara no s'ha decodificat,
hi ha una alternativa coherent amb el tema. No se substitueix per una foto fictícia d'una altra activitat.

Es conserven els dies civils retornats pel backend (DP-029). El temps zero de Go, `0001-01-01…`,
mostra «Data no informada»; no s'inventa una data de 2026. El model de dates desconegudes i la seva
representació a l'Agenda continuen pendents del contracte explícit de dates nul·les (DP-013 / DP-037).

## Comprovació i límits

Les proves utilitzen el JSON real del contracte Go amb transport HTTP simulat, sense credencials ni BD.
Inclouen pàgina 0, ordre, final, duplicats, càrregues concurrents, errors/reintents, refresc contra respostes
antigues, dispose, categories provisionals, imatges vàlides/error i recorregut llista–fitxa–retorn. També
s'ha comprovat la UI a 320 px amb text al doble.

Comprovacions del 26 d'octubre de 2026: bateria completa de **398 proves superades** (375 inicials i
23 de noves), anàlisi sense incidències i compilació APK de depuració correcta. Format i diff verificats.
Captures reals de components Flutter amb fonts i fixtures de demostració a
`PES/output/frontend/inici-list-loaded.png` i `inici-list-retry.png`, fora del repositori.

L'última consulta de verificació a `https://api-aprop.onrender.com/events`, sense credencials, va esgotar
15 segons sense rebre resposta HTTP. Per tant, el recorregut real autenticat contra Render i la
verificació manual en navegador/dispositiu continuen pendents; no es presenten els transports simulats
com si fossin dades de producció. El backend continua sense canvis.

Per demanar als companys del backend (sense modificar-lo aquí):

- Garantir un ordre estable amb desempat per ID a `GET /events`. El client elimina duplicats però no
  pot recuperar registres omesos per una paginació inestable.
- Retornar dates absents com `null` i definir-ne el comportament al calendari.
- Permetre CORS i la petició `OPTIONS` des del frontend web; en el codi Go revisat no hi ha aquest tractament.
- Comprovar disponibilitat i desplegament de Render abans de donar per validat el recorregut amb dades
  reals. La compilació i els transports simulats no acrediten una sessió completa contra producció.
- Per a la segona tasca: categories al mapa, selecció múltiple i format de dates dels filtres (DP-035).

La configuració local de Firebase continua ignorada per Git. Aquesta tasca no canvia el login, la BD,
el desplegament, les API de creació ni les operacions d'amistat. No hi ha commit ni push automàtics.
