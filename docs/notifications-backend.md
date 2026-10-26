# Integració d’Avisos — ampliació de #86

## Abast i estat

Bústia rebuda, filtres, lectura persistent i navegació al detall compartit. L’usuari ha confirmat que
les accions socials són fora de l’Sprint 1. No es generen recordatoris/recomanacions al client ni es
configuren notificacions del sistema operatiu. Només s’ha modificat `frontend-aprop`.

Branca `feature/notifications-backend`, des de `8aee081` (#87 publicada). Aquella ampliació encara no
era a `origin/develop` en començar; cal comprovar-ne la integració abans d’obrir aquesta PR a develop.
No s’ha fet commit ni push automàtic.

Contracte contrastat amb `api-aprop@c94ab70` i referència remota `origin/develop@d01f231`; els fitxers
de notificacions, perfils i middleware són iguals en aquestes revisions. No s’ha canviat el checkout,
executat el servidor, accedit a la BD ni creat avisos reals. DP-023/DP-039 recullen els límits.

## Contracte que es consumeix

| Endpoint | Ús |
|---|---|
| `GET /users/me` | UUID intern real i identitat Firebase del compte autenticat. |
| `GET /notifications/user/{uuid}` | Bústia del compte. Errors no es converteixen en `[]`. |
| `GET /notificationtypes` | IDs i noms actuals: Social, Recomanacio, Recordatori. |
| `GET /notifications/{id}` | Comprovar destinatari i estat abans de marcar-lo llegit. |
| `POST /notifications/{id}/read` | Confirmació persistent abans de modificar l’estat visual/navegar. |
| `GET /events/{id}` · `GET /users/{uuid}` | Context d’activitat i nom de la persona, si existeixen. |

El JSON de notificació usa `id`, `user-id`, `notification-date`, `friend-id`, `request-date`, `event`,
`type` i `read`. Usuari/amic són UUID; `event` és enter nullable. `type` és una clau de la taula de
tipus, no l’índex d’un enum de sis accions socials.

## Flux per entendre el codi

1. `main.dart` ja injectava `HttpNotificationRepository`. La composició existent a `AuthGate` i
   `MainShell` el passa a `NotificationsScreen`, amb l’ID del compte. No s’ha afegit un segon estat global.
2. La pantalla crea `NotificationsViewModel`. `load()` demana la bústia al contracte i mostra càrrega,
   error/reintent, buit o contingut. Un refresc fallit conserva els avisos del mateix compte.
3. L’adaptador fixa les capçaleres/token de l’operació i consulta `/users/me`. El perfil ha de
   correspondre al FirebaseUID o UUID sol·licitat. Fa servir el UUID retornat, sense inventar-lo ni
   aplicar el convertidor provisional de DP-036. Una sessió absent/canviada és un error, no una bústia buida.
4. El mapper valida IDs, propietari, tipus, data i lectura. Un payload malformat, dates absents/zero de Go,
   notificacions duplicades o files alienes no s’accepten silenciosament.
5. El catàleg de tipus es consulta si la bústia no és buida. La classificació depèn del nom, independent
   dels IDs de PostgreSQL. Un tipus nou/desconegut es conserva a Tots amb etiqueta «Avís», sense una
   categoria falsa ni un cinquè filtre.
6. El context es consulta una vegada per ID únic i refresc, amb màxim quatre peticions simultànies entre
   activitats i persones. Una fallada de context no elimina l’avís rebut; un 401 sí que es propaga.
7. El ViewModel ordena per recepció i filtra localment la bústia completa. No canvia lectura en filtrar.
   No es mostren registres de recepció futura com si ja s’haguessin rebut; actualitzar torna a consultar.
8. Obrir una targeta comprova destinatari i estat amb GET i confirma POST/read. Només llavors el
   ViewModel elimina l’indicador sense llegir i la pantalla emet el callback. Una fallada manté l’estat
   i permet reintentar. El detall reutilitza les inscripcions existents; obrir-lo no apunta l’usuari.
9. Canviar de compte recrea la presentació. Respostes després de dispose no naveguen ni modifiquen el
   compte nou. No hi ha cache d’identitat o de confirmacions socials entre comptes al repositori HTTP.

| Fitxer | Responsabilitat |
|---|---|
| [notification_repository.dart](../lib/features/notifications/repositories/notification_repository.dart) | Contracte pur Dart, lectura confirmada i resposta d’amistat explícita. |
| [http_notification_repository.dart](../lib/features/notifications/data/http_notification_repository.dart) | Transport, UUID autenticat, catàleg, context limitat i operacions confirmades. |
| [notification_json_mapper.dart](../lib/features/notifications/data/notification_json_mapper.dart) | DTO kebab-case i validació, sense widgets. |
| [app_notification.dart](../lib/features/notifications/models/app_notification.dart) | Snapshot immutable, categoria opcional i referència de l’activitat independent del seu context carregat. |
| [notifications_view_model.dart](../lib/features/notifications/presentation/view_models/notifications_view_model.dart) | Estat del compte, filtre, ordre i confirmació abans de canviar lectura. |
| [notifications_screen.dart](../lib/features/notifications/presentation/screens/notifications_screen.dart) | Estat visible i callbacks de destinació. Sense HTTP. |
| [notification_card.dart](../lib/features/notifications/presentation/widgets/notification_card.dart) · [notification_formatter.dart](../lib/features/notifications/presentation/formatters/notification_formatter.dart) | Presentació catalana, context absent, semàntica i paleta compartida. |

```text
MainShell → NotificationsScreen → ViewModel.load
  → NotificationRepository → HttpNotificationRepository
  → perfil autenticat → UUID real → bústia + catàleg + context
  → AppNotification → ViewModel.notifyListeners → targetes

Tocar targeta → comprovar destinatari → POST/read → confirmar estat
  → callback amb ID → fitxa compartida → tornar conserva filtre i posició
```

## Context absent, desconegut o social

- Una activitat eliminada conserva l’avís i el seu ID. Es mostra «L’activitat ja no està disponible.»
  i permet llegir l’avís, sense navegar a un enllaç mort.
- Si falla temporalment el context, l’avís també es conserva i permet intentar obrir la fitxa per ID.
- Una persona absent conserva el context genèric «Una persona»; no s’inventa un nom, avatar o amistat.
- Social no permet distingir publicació, inscripció o sol·licitud. S’utilitza un missatge social genèric.
  HTTP no genera botons Acceptar/Rebutjar; el seu mètode de resposta falla explícitament si es crida.
  Demo conserva els exemples del projecte final, sense representar-los com persistència real.
- Recordatoris/recomanacions no reben un actor encara que un registre contingui `friend-id`, ni
  depenen d’altres avisos socials que comparteixin la mateixa persona.
- Dates de l’activitat desconegudes es presenten «Data no informada». La recepció necessita una data
  vàlida: no es substitueix per ara. Es respecten offsets explícits; timestamps sense zona continuen
  locals fins a concretar el contracte de zona horària.

## Què queda pendent del backend i de la prova real

El [missatge de traspàs](notifications-backend-handoff.md) separa:

- Per comprovar l’Sprint 1: disponibilitat/URL, autorització per destinatari, zona horària i dades de
  prova; confirmar si entra la generació automàtica de recordatoris/recomanacions. Només s’ha trobat
  creació via `POST /notifications`; cap servei la invoca automàticament al `develop` revisat.
- Per a un sprint posterior: subtipus socials, identificador/estat de sol·licitud i acceptar/rebutjar.

La comprovació de disponibilitat sense credencials a `/notificationtypes` ha esgotat **15 segons sense
resposta HTTP**. No s’ha validat una sessió real ni persistència contra producció. Tampoc s’ha enviat
el missatge a l’equip automàticament. No s’ha modificat Firebase, backend, paquets ni credencials.

## Verificació

Bateria completa: **441 proves superades** (417 a la base i 24 noves). Inclou HTTP amb UUID real,
classificació dinàmica, buit/error, payload invàlid, canvi de compte/token, destinatari aliè, fallada i
reintent de lectura, context eliminat/temporal, solapament d’actors, concurrència limitada, tipus
desconeguts i text al doble. La prova d’app obre el detall compartit, conserva el filtre i comprova
lectura en una nova instància de bústia sobre el mateix servidor simulat. No hi ha inscripció automàtica.
La posició de cada filtre es verifica independentment en tornar-hi. Tancament de verificació el 27
d’octubre de 2026; els transports són simulats i no acrediten disponibilitat de producció.

L’antiga prova multi-repositori s’ha actualitzat: usava IDs numèrics i cap token, contradient el
contracte real de notificacions. No s’ha eliminat ni s’ha suavitzat la comprovació de l’adaptador.

Format correcte, anàlisi sense incidències i APK Android debug compilat. Captures de components Flutter
amb fonts reals i transport simulat a `PES/output/frontend/notifications-http-{all,social,reminders,
recommendations,refresh-error}.png`, fora del repositori. Són fixtures, no avisos de producció.
