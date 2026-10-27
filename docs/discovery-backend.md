# Descobreix connectat al backend — #96

## Abast i contracte

Integració autoritzada el 2026-10-27 a `feature/discovery-backend`, des de `origin/develop@60fbebc`,
amb Perfil i Avisos fusionats. Backend consultat a `be6c25e`; només es modifica el frontend. Sense
paquets nous, accessos a BD, migracions, commits ni push automàtics. DP-041 actualitza els límits de DP-024.

| Petició | Ús i resposta |
|---|---|
| `GET /users/me` | Confirma la identitat del feed: UUID real i Firebase UID del compte. |
| `GET /preferences` | Pesos de categories del compte. `[]` significa que no hi ha preferències. |
| `GET /events/recommended?pageNum=0&pageSize=5` | Selecció de «Per a tu» amb l’ordre retornat pel servidor. Llista d’activitats. |
| `GET /events/popular?pageNum=0&pageSize=5` | Selecció de «Destacats», ordenada pel backend per inscripcions. Llista d’activitats. |
| `GET /events/search?q=…&pageNum=0&pageSize=20` | Cerca paginada amb `query`, `total`, `page-num`, `page-size` i `events`. |

Les dues seleccions són mostres de la primera pàgina, no llistes exhaustives. La cerca permet
consultar la resta de resultats. Detall i inscripcions reutilitzen els endpoints, contractes i
ViewModel compartits; no s’hi guarda cap segon booleà d’inscripció.

## Flux del codi, en ordre

1. `main.dart` injecta `HttpDiscoveryRepository(apiClient: …)`; ja no rep un catàleg per fabricar un feed.
   `AuthGate` el passa a `MainShell`, que manté el navegador de Descobreix i l’estat d’inscripcions del compte.
2. `DiscoverScreen` crea `DiscoverViewModel`, que crida `DiscoveryRepository.getFeed(userId: …)`.
   Models i contractes són Dart pur; cap URL/JSON ni client HTTP arriba al ViewModel o als widgets.
3. `HttpDiscoveryRepository` captura bearer, comprova `/users/me` i carrega en paral·lel preferències/
   recomanacions i populars. No s’envia `X-User-ID`. Les peticions d’una operació retenen el mateix bearer;
   una sessió absent, aliena o rebutjada no produeix un feed personalitzat.
4. Un `DiscoveryFeed` immutable expressa dades i disponibilitat de cada secció. Preferències buides
   mostren «Coneguem els teus gustos» i no criden recomanacions. Un error de preferències/recomanacions
   no es confon amb aquell estat ni elimina els destacats. Errors 401/403 continuen sent errors globals.
5. El ViewModel conserva l’última llista de la secció que falla i n’ensenya l’avís; l’altra secció es pot
   actualitzar. El mateix reintent/refresc torna a consultar el feed. Després de `dispose` no s’aplica res.
6. La cerca manté 350 ms d’espera en escriure i enviament immediat amb el teclat. Consulta completa a
   `searchActivitiesPage`, primera pàgina **0**. `ActivitySearchPage` conté activitats immutables, total i
   continuació. El mapper comprova query, pàgina, mida, total, llista i coherència de la resposta.
7. `ActivitySearchViewModel` carrega més pàgines amb un únic cursor, evita duplicats per ID i serialitza
   continuacions. La UI mostra el total del servidor i «Carregar més activitats». Un error manté les
   targetes i el cursor per reintentar la mateixa pàgina; el total no és el nombre de targetes carregades.
8. Canviar/esborrar la consulta o sortir invalida les respostes antigues. Refrescar reinicia a 0 i invalida
   una continuació pendent; si falla, conserva els resultats confirmats de la mateixa consulta.
9. `ActivityCard` i `EnrollmentAction` continuen sent els components compartits. La pantalla emet IDs a
   `MainShell`, que obre el detall al navegador de Descobreix. Tornar conserva consulta, pàgines i scroll.
   Apuntar-se espera la confirmació HTTP i actualitza també Inici, detall i Agenda.

Fitxers principals: `models/activity_search_page.dart`, `models/discovery_feed.dart`,
`repositories/discovery_repository.dart`, `data/http_discovery_repository.dart`, els dos ViewModels i
les pantalles `DiscoverScreen`/`ActivitySearchScreen`. `ActivityListPagination` es reutilitza sense
canviar-lo. Demo implementa el mateix contracte paginat i conserva la cerca local dels mockups.

## Límits contrastats i peticions concretes al backend

- Recomanacions reordena **dins d’una pàgina del catàleg**; no és un rànquing global paginat. Es conserva
  l’ordre rebut, sense atribuir-li un «top» global. Per obtenir-lo, ordenar per preferències abans de paginar.
- Sense pesos per a alguna categoria, recomanacions retorna 500 genèric. El frontend evita el cas de
  preferències buides amb `/preferences`, però una preferència incompleta continua sent un error real.
  Cal acordar un valor neutre al servidor i un error específic/estat d’onboarding.
- Populars i recomanacions no filtren activitats acabades. No s’inventen dates ni filtres de client que
  amaguen tota una primera pàgina. Acordar si les seleccions han de ser futures i aplicar-ho abans de paginar.
- Cerca HTTP compara la consulta completa amb títol, lloc, municipi i descripció (`ILIKE`); no inclou
  categories ni la normalització d’accents/totes les paraules de Demo. El text inicial no promet aquesta
  cerca per categories. Confirmar la semàntica desitjada amb l’equip.
- La consulta SQL pagina abans del join de categories i no explicita ordre al SELECT exterior. Hi ha
  deduplicació per ID al client, però cal garantir ordre estable i agrupació al servidor entre pàgines.
- «Persones», graf social i perfils aliens continuen fora d’aquesta tasca/Sprint 1 segons l’acord existent.
- El test d’interessos té endpoints, però la seva pantalla, onboarding i accés per repetir-lo són una
  història separada. Aquí es consulten els gustos guardats, no se n’inventen ni es generen respostes.

## Verificació i prova real

Resultat local (2026-10-27): format de 237 fitxers sense canvis pendents, analitzador net i
**497 proves superades** (481 a la base; 16 noves). APK debug i web compilats. Revisió tècnica sense
bloquejos. Captures reals de Flutter revisades a `PES/output/frontend/discovery-backend-{feed,search,
page-1}.png`, amb fixtures HTTP; no són dades de producció ni imatges generades amb IA.
Les compilacions mantenen els avisos previs de migració Kotlin/Firebase i font Cupertino; finalitzen
correctament. No es modifica la configuració de CI ni s’hi afegeixen dependències.

Proves HTTP: endpoints/pàgina 0, ordre/portades, preferències absents, errors parcials, JSON invàlid,
identitat/bearer, totals i metadades de cerca. ViewModels: continuacions duplicades, reintents, resultats
antics, refresc durant paginació i conservació independent de seccions. Widgets: total real, reintent,
text ampliat a 320 px i missatge de gustos. El flux d’app simula el transport HTTP de descoberta,
catàleg i inscripcions: feed → apuntar-se → cerca → pàgina 1 → detall → retorn → Inici.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Cal provar-ho amb comptes reals a Render (amb i sense preferències), comprovar que el desplegament
inclou els endpoints nous i verificar persistència després de reiniciar. Fixtures i compilacions no
acrediten producció. El repàs global de l’MVP es farà després d’aquesta integració.
