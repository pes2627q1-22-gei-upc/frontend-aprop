# Filtres d’Inici al servidor — ampliació de #87

## Abast i base

Dates i Categories de la llista d’Inici, després de la paginació de #77. Només `frontend-aprop`.
Branca `feature/inici-server-filters`, basada en `9c35672` de #77. Aquesta primera PR encara no era a
`origin/develop` en començar: cal integrar-la abans de portar aquesta segona PR a `develop`.
No s’ha fet commit, push ni merge automàtic.

S’ha consultat el contracte de `api-aprop@c94ab70`, sense modificar-lo:

- `GET /events`: `pageNum`, `pageSize`, `filterCategory` (un únic ID), `startAfter`, `startBefore`.
- `GET /categories`: llista d’objectes amb `id` positiu i `name`.
- El parser Go espera dates amb mil·lisegons i sense zona; SQL compara `startdate >=` i `<=` com dates.
- `GET /events/map`: consulta per límits geogràfics. A la base inicial no emplenava categories;
  el contracte nou de `6f4979e` s’integra a la correcció #253 descrita més avall.

## Què passa quan l’usuari filtra

1. Obrir Dates o Categories crea un esborrany. Tancar-lo no canvia la consulta ni envia una cerca.
2. Categories carrega les opcions del repositori. Hi ha càrrega, error amb reintent i resposta buida
   vàlida. Aplicar queda desactivat durant la càrrega o l’error; no hi ha fallback silenciós a dades Demo.
3. Aplicar una selecció diferent confirma el valor, descarta les pàgines anteriors, torna al principi
   i demana la pàgina 0. No mostra targetes de la consulta antiga sota el resum nou.
4. Carregar més i actualitzar passen exactament els mateixos filtres. Els errors de continuació no
   perden les targetes ni avancen la pàgina. Una resposta antiga no pot canviar les dades ni els errors.
5. Actualitzar la mateixa consulta conserva les dades si falla; canviar de consulta i fallar mostra
   l’error corresponent, no targetes anteriors presentades com coincidències.
6. Netejar un panell només modifica el seu filtre. Netejar-los tots torna a la pàgina 0 sense restriccions.
   Confirmar de nou la mateixa selecció no envia una altra petició.

Les dates són dies civils inclusius. Seleccionar del 25 al 26 d’octubre de 2026 envia:

```text
GET /events?pageNum=0&pageSize=50
    &startAfter=2026-10-25T00:00:00.000
    &startBefore=2026-10-26T00:00:00.000
```

No es converteix la mitjanit a UTC ni s’exclou el dia final. La comparació continua basada en l’inici,
com al filtre aprovat; no s’inventa la durada d’una activitat.

## Categories múltiples amb l’API actual

### Correcció #253 — 15–16/11/2026

Una entrada de `/categories` amb ID vàlid i nom buit, només espais o una etiqueta sense segment final
ja no impedeix mostrar les categories vàlides del catàleg. La validació de l’estructura i dels IDs
es conserva; no es substitueixen errors de xarxa o JSON incorrecte per opcions de demostració.
Els noms originals i els IDs es mantenen per consultar el servidor.

Les peticions simultànies comparteixen la mateixa càrrega i el catàleg no buit es conserva a la sessió.
Una resposta buida es pot tornar a consultar: el panell mostra «Tornar-ho a provar» i permet continuar
sense restricció. El mateix component serveix per a Mapa i Llista. Decisió registrada a DP-045.

El backend `6f4979e` (PR #54) ja retorna `categories` com a llista de noms canònics a `/events/map`,
igual que el catàleg i el detall. El mapper compartit conserva totes les etiquetes vàlides i elimina
les que no tenen nom visible abans d’escollir el distintiu. Una categoria buida al principi no tapa
la següent: `["agenda:categories/", "agenda:categories/musica"]` mostra «Musica».

Els filtres es continuen aplicant localment sobre les activitats retornades per a la zona del mapa.
Es comprova qualsevol categoria de l’activitat; no només la primera que es veu al distintiu. La llista
consulta el servidor amb els IDs reals de les mateixes opcions. Canviar de vista conserva la selecció.
No es fan peticions de detall per marcador ni es passen filtres a un endpoint que no els admet.
Si una activitat no té cap categoria usable, es conserva «Activitat» i l’avís de metadades absents.
No es modifica el backend ni es pressuposa que la versió fusionada ja estigui desplegada a Render.

Verificació específica: prova HTTP de categories múltiples i buides, i recorregut amb transport simulat
llista → mapa → targeta → filtre d’una categoria secundària → llista → mapa. Confirma IDs, marcadors,
distintius i absència de peticions de detall addicionals. La comprovació autenticada de producció és manual.
Resultat final del 16/11/2026: 532 proves superades, analitzador i format correctes, revisió independent
sense bloquejos. Branca `feature/fix-253-categories`, sense commit ni push automàtics.

Les opcions HTTP venen de `/categories`. Els noms de taxonomia es presenten amb el seu últim segment,
sense guions, com ja feien les targetes. No es dedueix que «Concerts» equivalgui a «Música» ni s’inventen
IDs fixos. Noms visibles coincidents representen tots els IDs que els produeixen. Les vuit opcions dels
mockups continuen al repositori Demo, no al panell HTTP.

El servidor només admet un ID per petició. Per conservar OR, seleccionar dues categories demana la
pàgina N de cadascuna i combina els resultats per ID d’activitat. Dates s’afegeixen a totes les peticions.
Hi ha màxim quatre peticions simultànies; si una falla, el lot complet falla i es pot reintentar sense
incorporar una resposta parcial. No es descarrega tot el catàleg ni es demana el detall de cada marcador.

El lot pot tenir més de 50 activitats. Es conserva l’ordre del servidor dins de cada resposta i l’ordre
d’IDs de categoria entre respostes; no es promet un ordre cronològic global. Si alguna font retorna una
pàgina completa pot haver-hi més dades. Un lot pot solapar-se amb l’anterior sense ser un error: la
següent acció avança el número de pàgina, encara que no hi hagi IDs nous. No hi ha bucle de càrrega automàtic.

`Activity.categories` conserva totes les etiquetes, en una llista immutable independent de l’entrada.
El primer valor continua sent el distintiu visual. El filtre local de suport comprova qualsevol valor,
de manera que una activitat etiquetada amb dues categories no desapareix en triar-ne la segona.

## Recorregut del codi

| Fitxer | Responsabilitat |
|---|---|
| [activity_filters.dart](../lib/features/activities/models/activity_filters.dart) | Dies inclusius, categories OR i combinació AND; Dart pur. |
| [activity_repository.dart](../lib/features/activities/repositories/activity_repository.dart) | Contracte paginat amb filtres i consulta d’opcions; no coneix HTTP ni widgets. |
| [http_activity_repository.dart](../lib/features/activities/data/http_activity_repository.dart) | IDs reals, cache de categories amb reintent, dates Go, fan-out limitat i unió atòmica. |
| [activity_json_mapper.dart](../lib/features/activities/data/activity_json_mapper.dart) | Conserva totes les categories i comparteix la conversió d’etiquetes amb les opcions. |
| [activities_view_model.dart](../lib/features/activities/presentation/view_models/activities_view_model.dart) | Única selecció confirmada; cursor per consulta, generació de peticions i estat d’opcions. |
| [activities_screen.dart](../lib/features/activities/presentation/screens/activities_screen.dart) | Obre panells, envia la selecció i reinicia el desplaçament. Sense HTTP ni IDs de backend. |
| [activity_categories_filter_sheet.dart](../lib/features/activities/presentation/widgets/activity_categories_filter_sheet.dart) | Esborrany i representació d’opcions/càrrega/error; accions fixes accessibles. |
| [activity_filter_feedback.dart](../lib/features/activities/presentation/widgets/activity_filter_feedback.dart) | Dades absents del mapa, sense fals buit, i accés a la llista. |

```text
Categories → ViewModel.loadFilterCategories → contracte → HTTP /categories
Aplicar → ViewModel.applyFilters → getActivitiesPage(filters, page: 0)
  → adaptador HTTP → /events amb dates i ID(s)
  → ActivityPage → ViewModel.notifyListeners → targetes
Carregar més → mateixa consulta, pàgina següent
```

Demo i Combined implementen el mateix contracte. La font d’inscripcions continua compartida: aquest
canvi no modifica «M’hi apunto», l’autenticació, la creació ni les altres seccions.

## Mapa i dependències del backend

Es conserva la selecció entre Mapa/Llista i es filtren localment els esdeveniments de la zona.
No s’envien paràmetres ignorats per `/events/map`. Les dates informades permeten filtrar per dia; les
categories absents s’indiquen amb recompte i «Veure llista». No es diu que la zona estigui buida quan
la causa és falta de categories. La llista oberta conserva la selecció i consulta el servidor.

Per completar la mateixa experiència a totes dues vistes, demanar als companys:

- Filtres de dates/categories al servidor a `/events/map`; les categories de la resposta ja estan disponibles des de `6f4979e`.
- Multiselecció OR al servidor per tenir una sola paginació i ordre global estable amb desempat per ID.
- Confirmació de la taxonomia visible; no convertir semànticament etiquetes diferents al client.
- Disponibilitat de Render i CORS/OPTIONS per verificar el recorregut web autenticat.

DP-029, DP-035 i DP-037 continuen afectades; DP-038 recull l’adaptació provisional i els seus límits.
La consulta sense credencials a `/categories` del 26 d’octubre ha esgotat 15 segons sense resposta HTTP.
Les proves HTTP simulades no acrediten persistència ni una sessió completa contra producció.

## Verificació del 26 d’octubre de 2026

- Bateria completa: **417 proves superades** (398 a la base, 19 de noves).
- Cobertura de comportament nova: dates inclusives/horari d’estiu, IDs reals, OR entre pàgines,
  deduplicació, fallada atòmica, concurrència limitada, categories invàlides/desconegudes,
  immutabilitat, respostes antigues, error/reintent i cancel·lació abans d’enviar una consulta.
- Panells amb càrrega/error/buit, opcions dinàmiques i mapa sense categories; proves de text al doble
  i pantalla estreta conservades. Recorregut de l’app amb transport HTTP simulat: carregar opcions,
  cancel·lar/aplicar, obtenir una activitat absent de la consulta inicial i netejar.
- Compilació Android de depuració correcta. Captures reals Flutter revisades, amb fonts i dades de
  prova, a `PES/output/frontend/server-filters-categories.png`, `server-filters-categories-error.png`,
  `server-filters-dates.png` i `server-filters-list.png`. No són dades de producció.
- Format sense canvis, anàlisi sense incidències i `git diff --check` correcte.
- Revisió del diff: categories copiades defensivament i comprovació de mutació afegida. Sense canvis
  al backend, paquets, configuració de Firebase o secrets. Verificació real amb Render pendent.
