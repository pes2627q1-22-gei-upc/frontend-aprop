# Descobreix i cerca — Taiga #96 Frontend de cerca

## Abast i referències

Implementació del recorregut Descobreix → Cerca d'activitats → Fitxa, amb les figures 14–16 i els prompts aprovats d'`output/mockup/aprop-descobreix-*` de PES. L'usuari confirma #96 i autoritza implementar Descobreix i la cerca d'activitats. Els criteris detallats de Taiga encara s'han de contrastar en la revisió humana.

La pantalla inicial té la capçalera «Descobreix», l'accés «Cerca activitats», «Per a tu» i «Destacats». No afegeix el logotip, l'assistent ni els filtres d'Inici. Comparteix les targetes, la fitxa i les inscripcions existents. La barra inferior continua sent única, propietat de `MainShell`.

DP-024 registra el contracte pendent i les adaptacions: les seleccions demo són l'exposició i el teatre del catàleg compartit, amb les seves dates històriques. No representen interessos persistits ni un rànquing real. El subtítol és «Una selecció per començar»; només un feed amb `isPersonalized: true` mostra «Segons els teus interessos». «Persones» és una opció desactivada amb una explicació; la cerca de persones, els perfils i les amistats no s'implementen en aquesta tasca.

## Fitxers i responsabilitats

Tots els fitxers nous de producció, excepte la composició, són dins de `lib/features/activities/`: descobrir i cercar són altres formes de consultar el mateix catàleg. Això permet reutilitzar-ne la presentació sense importar widgets o ViewModels d'una altra funcionalitat.

| Fitxer | Responsabilitat |
|---|---|
| [discovery_feed.dart](../lib/features/activities/models/discovery_feed.dart) | Snapshot immutable de les dues seleccions i indicador de personalització. No conté inscripcions. |
| [discovery_repository.dart](../lib/features/activities/repositories/discovery_repository.dart) | Interfície en Dart pur: obtenir el feed i cercar activitats. No defineix rutes HTTP ni widgets. |
| [demo_discovery_repository.dart](../lib/features/activities/data/demo_discovery_repository.dart) | Implementa la interfície llegint el mateix `ActivityRepository` de la resta de l'app. Selecciona els exemples i cerca en memòria. |
| [discover_view_model.dart](../lib/features/activities/presentation/view_models/discover_view_model.dart) | Carrega el feed per usuari, evita peticions duplicades i conserva el feed davant un error de recàrrega. |
| [activity_search_view_model.dart](../lib/features/activities/presentation/view_models/activity_search_view_model.dart) | Gestiona la consulta, l'espera, els resultats, els errors i la invalidació de respostes antigues. |
| [discover_screen.dart](../lib/features/activities/presentation/screens/discover_screen.dart) | Crea/allibera el seu ViewModel, mostra el feed i emet callbacks de cerca i activitat. |
| [activity_search_screen.dart](../lib/features/activities/presentation/screens/activity_search_screen.dart) | Gestiona el camp, focus i teclat; mostra els estats del ViewModel i emet callbacks de retorn/detall. |
| [discovery_message.dart](../lib/features/activities/presentation/widgets/discovery_message.dart) | Presenta missatges de buit/error i el botó de reintent. |
| [auth_gate.dart](../lib/app/navigation/auth_gate.dart) | Crea o rep el repositori de descoberta i l'injecta a `MainShell`. |
| [main_shell.dart](../lib/app/navigation/main_shell.dart) | Substitueix el text provisional de la lupa, obre la cerca al navegador de Descobreix i connecta la fitxa compartida. |

## Flux principal, en ordre

1. `APropApp` rep opcionalment un `DiscoveryRepository`. `AuthGate` fa servir el rebut o crea `DemoDiscoveryRepository(activityRepository: ...)`. Aquest objecte és una implementació concreta de la interfície, no un objecte instanciable de la interfície.
2. Després de verificar la sessió, `MainShell` injecta el repositori a `DiscoverScreen` i li passa el mateix `EnrollmentViewModel` que tenen Inici i les fitxes. L'`IndexedStack` construeix totes les arrels; el feed pot carregar-se abans de tocar la lupa.
3. `DiscoverScreen.initState()` crea `DiscoverViewModel` i crida `load()`. El ViewModel consulta `repository.getFeed(userId: ...)`. Quan té dades o error, crida `notifyListeners()`, i Flutter executa de nou el `builder` del `ListenableBuilder`.
4. Prémer «Cerca activitats» executa el callback de composició `_openDiscoverySearch()`. `MainShell` afegeix `/discover/search` al navegador de la secció 2. La pantalla de cerca crea el seu propi ViewModel; el menú inferior continua fora de les rutes.
5. El `TextField` envia cada canvi a `updateQuery()`. El ViewModel invalida la resposta anterior, neteja resultats antics i programa la cerca al cap de 350 ms. Tornar a escriure cancel·la aquest temporitzador. L'acció de cerca del teclat crida `searchNow()` immediatament i tanca el teclat.
6. `searchNow()` consulta `repository.searchActivities(query)`. L'adaptador demo torna a llegir el catàleg compartit; per això també troba activitats acabades de crear. Una resposta només s'aplica si pertany a la revisió vigent de la consulta i el ViewModel no està alliberat.
7. La pantalla mostra el recompte i els mateixos `ActivityCard` d'Inici. Prémer la foto o el títol emet un ID; `MainShell` obre `activityDetailsRoute`. Obrir el detall no apunta l'usuari.
8. `EnrollmentAction` envia «M’hi apunto» al `EnrollmentViewModel` compartit. Només es mostra «Apuntat» després de confirmar-ho el repositori; un error permet reintentar. Agenda rep les mateixes inscripcions a través del contracte compartit.
9. En tornar de la fitxa, la ruta de cerca continua viva: es mantenen el text, els resultats i el desplaçament. Canviar de pestanya també conserva la ruta. Tornar de Cerca a Descobreix conserva el feed i el seu desplaçament; una cerca nova comença buida.

## Estats i regles de cerca

- Consulta buida o només espais: missatge inicial, sense consulta al repositori.
- Espera mentre s'escriu o consulta pendent: càrrega, sense mostrar resultats d'una consulta anterior.
- Coincidències: recompte singular/plural i llista desplaçable.
- Sense coincidències: «0 activitats trobades» i proposta de canviar les paraules.
- Error: missatge en català i «Tornar-ho a provar»; no es presenta com una cerca amb zero coincidències.
- La creu esborra la consulta i invalida peticions pendents. Una resposta antiga no pot repoblar la pantalla.
- La cerca local ignora majúscules, accents i espais repetits. Totes les paraules han de coincidir en algun punt del títol, categoria, municipi o descripció. Aquesta regla és provisional fins a acordar la cerca de producció.
- S'ignoren enviaments duplicats durant la mateixa petició. Una consulta nova pot executar-se encara que l'anterior continuï pendent; només la nova pot modificar l'estat.
- Cada pantalla allibera el seu ViewModel. La cerca cancel·la el temporitzador en sortir. Canviar de compte destrueix el `MainShell` anterior i evita mostrar resultats de la sessió prèvia.
- El feed i els resultats permeten actualitzar arrossegant. El contingut usa llistes amb construcció sota demanda i suporta text ampliat i pantalles estretes.

## Validació i prova manual

Les proves noves cobreixen l'adaptador demo, immutabilitat, ViewModels, concurrència, errors/reintent, estats de pantalla, text ampliat a 320 px, navegació, desplaçament, canvi de compte i sincronització d'inscripcions amb Inici/Agenda. Són a `test/features/activities/*discovery*`, `*discover*`, `activity_search_view_model_test.dart` i `test/app/discovery_flow_test.dart`.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Prova manual: entrar amb el compte demo del README, obrir Descobreix, consultar l'exposició i tornar; cercar «teatre», consultar-ne la fitxa, tornar i comprovar la consulta. Apuntar-s'hi des de Cerca i comprovar el mateix «Apuntat» a la fitxa i a Inici. Provar «musica barcelona», una cerca sense coincidències i esborrar la consulta. Les dates dels exemples són de setembre de 2026: a Agenda cal consultar aquell mes per veure'ls.

Integració pendent: API de cerca, recomanacions de producció/interessos, paginació segons el contracte real, cerca de persones i perfils. Aquesta implementació frontend no prova que aquestes funcionalitats backend estiguin acabades. Cap paquet ni endpoint nou.

Validació local: format correcte, `flutter analyze` sense problemes, 228 proves superades (32 noves) i APK Android debug compilat. Captures reals de Flutter de Descobreix, cerca amb resultat i cerca buida revisades. Text ampliat a 320 px i desplaçament amb 25 resultats comprovats en proves de widgets. Revisió de decisions sense bloquejos ni DP noves fora de DP-024. La prova manual en un dispositiu Android físic continua pendent.

Branca `feature/discover`, creada des de `origin/develop` (`45fe346`, amb #86 integrada via PR #15). Sense commit ni push de la tasca #96; pendent de revisió humana i contrast dels criteris detallats de Taiga.
