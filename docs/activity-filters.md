# Filtrar esdeveniments — Tasca #87

## Abast i comportament

Filtres **Dates** i **Categories** d'Inici, segons els mockups aprovats a
`PES/output/mockup/aprop-filtre-dates-v1.png` i `aprop-filtre-categories-v1.png`.
L'ID i el títol de Taiga estan confirmats; els criteris detallats s'han demanat per contrastar-los.
El panell de zona/municipi continua pendent d'abast i disseny.

- Cada panell edita un esborrany local. Resultats i capçalera només canvien amb **Aplicar**.
- **Netejar** esborra només l'esborrany d'aquell panell. Aplicar-lo buit elimina aquella restricció i
  conserva l'altre filtre. La creu, el fons, el gest de tancar i el retorn descarten els canvis.
- La capçalera mostra marca, contorn i resum dels filtres aplicats; permet netejar-los tots.
- Una selecció nova porta la llista al principi. Tornar d'una fitxa o canviar Mapa/Llista/secció conserva
  els filtres. Una sessió nova els reinicia. No afecten Descobreix, cerca, Agenda ni inscripcions.
- Sense coincidències hi ha un missatge i «Netejar filtres», diferenciat d'error o catàleg buit.

### Dates

Setmanes de dilluns a diumenge i navegació mensual. El primer toc tria un dia; el segon completa un
interval inclusiu i ordena els extrems si cal; el tercer comença una selecció nova. Es poden triar dies
passats perquè el catàleg conté activitats històriques.

«Avui» i «Demà» trien un dia. «Aquest cap de setmana» tria el proper dissabte i diumenge si és dia
laborable, o el dissabte/diumenge d'aquella setmana si ja és cap de setmana. Les dreceres i el calendari
comparteixen el mateix valor de selecció. El rellotge s'injecta per provar els exemples sense canviar
la data del dispositiu.

Es comparen dies civils: el dia final inclou totes les seves hores. El dia següent es construeix amb
el calendari, sense sumar 24 hores, per respectar canvis de mes, any i horari d'estiu.

### Categories

Caselles per a les categories de la font del catàleg. En HTTP es carreguen de `/categories`; les vuit
categories del mockup es conserven només al repositori Demo. Hi ha càrrega, error amb reintent i resposta
buida vàlida, sense substituir errors del servidor per opcions inventades. Les categories són **OR** i es combinen amb les dates
mitjançant **AND**. Cap categoria triada elimina la restricció de categoria.

La coincidència ignora majúscules, espais sobrants i accents; no inventa equivalències entre etiquetes
diferents. No es modifica la llista provisional de categories de creació (DP-018).

## Arquitectura i flux

| Fitxer | Responsabilitat |
|---|---|
| [activity_filters.dart](../lib/features/activities/models/activity_filters.dart) | Intervals, dreceres i filtres immutables en Dart pur. |
| [activities_view_model.dart](../lib/features/activities/presentation/view_models/activities_view_model.dart) | Propietari únic dels filtres confirmats, el catàleg i la seva projecció. |
| [activities_screen.dart](../lib/features/activities/presentation/screens/activities_screen.dart) | Retorn dels panells i mateixa regla de filtratge als resultats del mapa per zona. |
| [activities_header.dart](../lib/features/activities/presentation/widgets/activities_header.dart) | Controls, selecció i resum; emet callbacks. |
| [activity_filter_sheet.dart](../lib/features/activities/presentation/widgets/activity_filter_sheet.dart) | Estructura comuna, contingut desplaçable i accions fixes. |
| [activity_date_filter_sheet.dart](../lib/features/activities/presentation/widgets/activity_date_filter_sheet.dart) · [activity_filter_calendar.dart](../lib/features/activities/presentation/widgets/activity_filter_calendar.dart) | Esborrany de dates i calendari. |
| [activity_categories_filter_sheet.dart](../lib/features/activities/presentation/widgets/activity_categories_filter_sheet.dart) | Esborrany de categories; retorna una selecció immutable. |
| [activity_filter_formatter.dart](../lib/features/activities/presentation/formatters/activity_filter_formatter.dart) | Mesos, intervals i resums en català. |
| [activity_filter_feedback.dart](../lib/features/activities/presentation/widgets/activity_filter_feedback.dart) | Estats sense coincidències i categories no informades. |

`MainShell` ja crea el ViewModel per compte. Aplicar filtres reinicia la consulta a la pàgina 0 i passa
el valor immutable al repositori; carregar més o actualitzar el torna a passar. Les respostes d’una
consulta antiga s’ignoren. Una recàrrega de la mateixa consulta conserva dades si falla; un canvi de
consulta no mostra targetes anteriors sota la selecció nova. `Activity.categories` conserva totes les
categories rebudes i no permet canvis a través de la llista original ni del getter.

Un retorn nul del panell és cancel·lació; una selecció buida confirmada és vàlida. Només es modifica
el camp editat del filtre actual. Model i ViewModel no naveguen ni reben `BuildContext`. No s'afegeixen
paquets o repositoris nous.

La ruta modal arrel cobreix la navegació inferior. La pantalla la retira si desapareix el seu compte;
un resultat tardà no modifica un altre ViewModel. Confirmar/completar comprova que la ruta sigui actual
per evitar dues confirmacions durant la transició.

Si un filtre amaga el marcador seleccionat, `ActivitiesMap` tanca la targeta i informa d'alçada zero
després del frame. El botó «Crear activitat» torna al seu lloc; netejar no reobre aquella targeta.

## Accessibilitat

Dates amb nom complet, selecció i acció semàntica; caselles amb estat explícit. Les cel·les de dia
tenen superfícies mínimes de 48 px i la graella admet desplaçament horitzontal si no hi caben set columnes.
Amb text ampliat, subtítol i resum poden desplaçar-se amb el contingut; les accions es mantenen fixes
i passen a una columna. La capçalera d'Inici es pot desplaçar en espais petits per deixar lloc als
resultats. Colors del tema compartit i textos catalans.
Els missatges superposats al mapa també admeten desplaçament si el text ampliat supera l'espai disponible.

## Backend i límits (DP-035)

La llista filtra al servidor abans de paginar. Les dates es passen com a dies civils inclusius i les
categories es resolen a IDs de `/categories`; diverses seleccions combinen les peticions com OR.
Vegeu el contracte, la paginació i els límits a [la guia d’integració](inici-server-filters.md), DP-038.
La petició de mapa per zona i el seu marge no canvien: l’endpoint no admet aquests paràmetres. Una
resposta nova es filtra localment amb la selecció actual sense repetir la consulta.

DP-029 continua oberta: amb backend, Mapa i Llista encara tenen fonts diferents. `Activity` només té
data d'inici i conserva totes les categories informades. No s'infereix la durada d'un esdeveniment de diversos dies ni una categoria
que el backend no retorni. Una categoria buida o «Activitat» és no informada: amb categories triades
no és una coincidència i es mostra quantes activitats queden excloses dins de les dates seleccionades.
Sense restricció de categoria continuen visibles.

Quan falten categories al mapa es mostra l’abast de les dades excloses i un accés «Veure llista».
No es presenta aquesta falta de metadades com si la zona no tingués coincidències. Cal ampliar el
contracte del mapa abans de considerar completa la integració global amb els mateixos resultats.

## Verificació

Proves de model, ViewModel, panells i recorregut complet: límits inclusius, OR/AND, immutabilitat,
accents, mesos/anys, càrregues pendents, error/reintent, cancel·lació, neteja parcial, mapa, categories
desconegudes, targeta seleccionada, text ampliat, navegació, inscripcions i sessió tancada amb modal obert.

La base tenia un error preexistent en crear activitats: sumar 24 hores des de mitjanit podia retornar
el mateix dia quan acabava l'horari d'estiu. Es corregeix amb `DateTime(any, mes, dia + 1)` i una regressió
del 25 d'octubre de 2026; el recorregut complet de creació torna a passar.

La configuració local de Firebase d’Adam ja està generada (26 d’octubre). La verificació actual de la
integració s’indica a `inici-server-filters.md`; el resultat següent correspon a la implementació inicial.

Resultat del 25 d'octubre de 2026:

- Format i `git diff --check`: correctes.
- Anàlisi de `lib/app`, `lib/core`, `lib/features` i `test`: sense incidències.
- Bateria completa després d'integrar la PR #22 del mapa: **366 proves superades**, incloses 26 regressions
  de filtratge i una de canvi d'hora. El panell dels grups respecta les categories confirmades.
- `flutter analyze --no-pub`: només dos errors previs de `main.dart`, per l'absència de
  `firebase_options.dart` i, en conseqüència, `DefaultFirebaseOptions`. Compilació de producció pendent
  de generar la configuració real; no s'ha substituït per una configuració fictícia.
- Captures reals de Flutter revisades a 390 × 844, amb fonts i recursos de l'app. Disponibles localment
  a `PES/output/frontend/filters-dates.png`, `filters-categories.png` i `filters-list.png`, fora del repo.
- Revisió del diff: corregit el retorn al principi de la llista quan s'aplica un filtre des del mapa.
  Sense altres bloquejos detectats; pendent de revisió humana.

```bash
dart format --output=none --set-exit-if-changed lib test
dart analyze lib/app lib/core lib/features test
flutter test --no-pub
flutter analyze --no-pub
```

Branca `feature/activity-filters`, iniciada des de `develop` (`42b1bf5`); implementació publicada a
`e7d7343`. Integració de `origin/develop` (`c0815d9`, PR #22) resolta i verificada, pendent del commit
de merge i push. La decisió dels filtres passa de DP-034 a DP-035 per conservar la del mapa.
Revisió humana, criteris detallats de Taiga i comprovació amb el backend pendents.
