# Avisos — Taiga #86

> **Sprint 2 · #164:** l’acceptació des d’Avisos i Perfil ja està integrada amb HTTP.
> Les notes anteriors sobre amistat només Demo corresponen a l’Sprint 1.
> Contracte, sincronització i límits actuals: [Acceptar una sol·licitud](friend-requests.md), DP-066.

## Estat actual de la integració (26 d’octubre de 2026)

La bústia i la lectura utilitzen el contracte real del servidor. Vegeu [la guia HTTP](notifications-backend.md)
per seguir UUID, tipus, context, errors i verificació, i [el traspàs](notifications-backend-handoff.md) per
les dependències del backend. Les accions socials són fora de l’Sprint 1, segons confirmació de l’usuari.
La descripció següent conserva l’abast i les proves de la implementació inicial de la UI amb Demo.

## Fonts i abast

Comportament contrastat amb la Incepció 2, figura 17 i text de les pàgines 29–30 (pàgines 30–31 del PDF), les restriccions del model conceptual i els prompts aprovats d'`output/mockup/aprop-avisos-*` de la carpeta PES. La capçalera conté només «Avisos»: el logotip i l'accés a l'assistent pertanyen a Inici.

La tasca implementa la bústia frontend. No configura ni envia notificacions del sistema operatiu, no programa recordatoris i no integra Firebase, l'API d'amistats ni perfils que encara no existeixen. Els criteris detallats de Taiga no són al repositori: cal confirmar-los en la revisió humana. DP-023 registra els contractes i les adaptacions provisionals.

## Comportament implementat

| Element | Comportament |
| --- | --- |
| Filtres | Selecció única: Tots / Social / Recordatoris / Recomanacions; efecte immediat i cap canvi de lectura |
| Llista | Del moment de recepció més recent al més antic; separadors Avui, Ahir o data completa segons el rellotge local |
| Sense llegir | Punt coral amb contorn fosc, superfície verda suau, èmfasi tipogràfic i semàntica «Sense llegir» |
| Obrir | Espera la confirmació de lectura i després emet el callback de destinació; si falla, conserva l'avís sense llegir i permet reintentar |
| Activitat | Obre la mateixa fitxa que Inici/Agenda; consultar-la no apunta l'usuari |
| Sol·licitud pendent | Acceptar / Rebutjar són independents d'obrir l'avís; els botons es bloquegen mentre s'espera confirmació |
| Sol·licitud resolta | Els botons se substitueixen per «Sol·licitud acceptada/rebutjada» després de confirmar-se |
| Perfil pendent | Text «Perfil disponible properament»; sense navegació fictícia. Es pot marcar l'avís com a llegit sense resoldre'l |
| Actualitzar | Arrossegar la llista recarrega la bústia. Una recàrrega fallida manté les dades i mostra error amb reintent |
| Buit | Missatge diferent per bústia global o filtre; «Veure tots els avisos» només si existeixen altres avisos |
| Tornar | Conserva filtre i desplaçament; cada secció manté el seu historial i la barra inferior fixa |

Els recordatoris rebuts continuen visibles encara que l'activitat hagi començat. Es mostren dates absolutes de l'activitat, separades de l'hora de recepció, per evitar textos històrics enganyosos com «Comença avui». No s'inclouen recordatoris futurs com si s'haguessin rebut.

## Fitxers i flux per aprendre el codi

1. `lib/features/notifications/models/app_notification.dart`: model immutable en Dart pur. `NotificationType` descriu sis casos visibles dels mockups i els agrupa en tres `NotificationCategory`. `isRead` i `requestStatus` són independents. Els constructors validen la coherència dels actors: recordatoris/recomanacions no tenen un amic associat, mentre que les publicacions i inscripcions socials necessiten context de persona. És una projecció de presentació, no una redefinició dels tipus UML ni del JSON del backend.
2. `repositories/notification_repository.dart`: contracte per a `getNotifications`, `markAsRead` i `respondToFriendRequest`. Les escriptures acaben quan s'han confirmat; la resposta retorna l'estat autoritatiu i mai `pending`. El futur servidor ha d'autoritzar el receptor i establir l'amistat mútua de manera atòmica.
3. `data/demo_notification_repository.dart`: dades històriques fictícies dels mockups, amb IDs del mateix catàleg. Comparteix la inicialització quan hi ha peticions concurrents, permet reintentar una inicialització fallida i separa les bústies per usuari. Una resposta ja resolta manté el primer resultat. Les dades duren durant la mateixa execució, inclòs tancar/tornar a iniciar sessió; desapareixen en reiniciar l'app.
4. `presentation/view_models/notifications_view_model.dart`: coordina càrrega, filtre, lectura i respostes. `notifyListeners()` anuncia cada canvi; la pantalla l'observa. Les col·leccions exposades no es poden modificar externament. Els guards eviten duplicats, recàrregues que sobreescriguin operacions pendents i callbacks després de `dispose`.
5. `presentation/formatters/notification_formatter.dart`: textos i dates en català. La data de recepció determina l'agrupació, no la data d'inici de l'activitat. El rellotge injectable permet provar límits de dia/mes/any sense esperar temps real.
6. `presentation/widgets/notification_card.dart`: presenta el tipus, l'hora, el missatge i els controls. Les accions de resposta són fora de la superfície que obre l'avís, per evitar navegació accidental. Utilitza inicials quan no hi ha avatar, i icones per a recordatoris/recomanacions.
7. `presentation/screens/notifications_screen.dart`: crea/allibera el ViewModel, mostra els estats i emet callbacks de navegació. `ListenableBuilder` es reconstrueix quan el ViewModel notifica. `PageStorageKey` conserva el desplaçament de cada filtre. `onPersonSelected` queda preparat, però no s'activa sense la funcionalitat real.
8. `lib/app/aprop_app.dart`, `navigation/auth_gate.dart` i `navigation/main_shell.dart`: trien/injecten el repositori una sola vegada. El canvi de compte recrea la presentació; els estats d'un compte no es mostren a l'altre. El callback cap al detall comprova que Avisos encara sigui la secció activa abans de navegar. `TickerMode` evita animacions de càrrega actives en seccions ocultes.
9. `lib/app/theme/app_theme.dart`: afegeix les paletes de les etiquetes Social i Recordatori mitjançant `NotificationBadgeTheme`; cap literal de color nou dins de la feature.

```text
MainShell construeix les seccions de l'IndexedStack
  → NotificationsScreen.initState
  → NotificationsViewModel.load
  → NotificationRepository.getNotifications(userId)
  → DemoNotificationRepository
  → ordenar dades + notifyListeners
  → ListenableBuilder mostra la llista

Usuari obre un avís
  → markAsRead → repositori confirma → actualitzar isRead
  → notifyListeners → callback amb ID → MainShell obre la fitxa

Usuari prem Acceptar/Rebutjar
  → respond → repositori confirma l'estat → actualitzar requestStatus + isRead
  → notifyListeners → resultat visible, sense obrir cap perfil
```

Les seccions es creen anticipadament en construir `MainShell`: seleccionar Avisos fa visible una pantalla ja inicialitzada i no torna a carregar ni marca la bústia com a llegida. Una nova consulta es pot demanar arrossegant la llista.

## Integracions pendents i demostració

- La simulació de resposta només conserva l'estat dins de la bústia. No existeix encara un graf d'amistats real ni es modifica el perfil d'una altra persona.
- Els actors dels mockups tenen IDs ficticis propis; no es resolen contra els comptes demo d'autenticació. Els avisos històrics no inscriuen ni afegeixen plans a Agenda.
- El repositori no genera recomanacions a partir del test ni programa recordatoris; mostra fixtures ja rebuts, amb les dates de setembre dels mockups. Si l'app s'obre un altre dia, l'agrupació mostra la data històrica correcta.
- El backend haurà d'acordar identitat autenticada, IDs, lectura persistent, errors, paginació/actualització i respostes d'amistat. No s'han inventat endpoints, DTOs ni credencials. Les notificacions de cancel·lació o nivell del projecte final no s'han assignat a un dels tres filtres sense un acord de producte.
- En pantalles estretes o amb text ampliat la fila de filtres es pot desplaçar i els botons passen a més d'una línia. Els textos no es trunquen per encaixar la captura.

## Verificació i prova manual

Les proves de `test/features/notifications/` comproven models, repositori, ViewModel, agrupació, filtres, càrrega/error/reintent, buit, lectura, respostes confirmades, duplicats i text ampliat. `test/app/notifications_flow_test.dart` comprova la ruta compartida, la conservació del filtre/desplaçament, que no hi hagi inscripció automàtica, canvis de secció amb peticions pendents i canvi de compte.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Prova manual: iniciar sessió amb el compte demo del README, obrir Avisos, canviar els filtres, consultar una recomanació i tornar. Comprovar que no ha apuntat l'usuari, i que l'avís continua visible com a llegit. A Social, llegir la sol·licitud i després acceptar-la o rebutjar-la; els botons han de quedar substituïts pel resultat. Tancar/tornar a iniciar sessió conserva el resultat dins de la mateixa execució. La prova en dispositiu físic, la revisió humana i la integració amb backend són pendents.

Validació inicial de #86: format correcte, `flutter analyze` sense problemes, les 163 proves del repositori superades (42 noves d'Avisos) i APK Android debug compilat. Captures de Tots, Social, resposta acceptada i Recordatoris renderitzades amb la composició real de l'app. La revisió del diff no ha detectat bloquejos ni decisions noves fora de DP-023.

El commit `c84a138` de `feature/notifications` ha estat publicat per Adam. El 2026-10-21 s'integra localment `origin/develop` (`740db0a`) per resoldre els conflictes de la PR, conservant el mapa i la creació d'activitats. La decisió d'Avisos passa de DP-017 a DP-023 per evitar la col·lisió amb la decisió de creació. El commit de fusió i el push queden pendents de revisió d'Adam.

Validació de la integració: format correcte (111 fitxers, cap canvi), anàlisi sense problemes, 196 proves superades i APK Android debug compilat. Revisió de decisions sense bloquejos; es conserven les DP-017 a DP-022 de `develop`. No s'ha verificat el mapa real en un dispositiu físic.
