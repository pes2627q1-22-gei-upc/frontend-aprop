# Integració d’Avisos — ampliació de #86

> **Sprint 2 · #164:** l’acceptació des d’Avisos i Perfil ja està integrada amb HTTP.
> Les notes anteriors sobre amistat només Demo corresponen a l’Sprint 1.
> Contracte, sincronització i límits actuals: [Acceptar una sol·licitud](friend-requests.md), DP-065.

## Abast i estat

Bústia rebuda, filtres, lectura persistent i navegació al detall compartit. L’usuari ha confirmat que
les accions socials són fora de l’Sprint 1. No es generen recordatoris/recomanacions al client ni es
configuren notificacions del sistema operatiu. Només s’ha modificat `frontend-aprop`.

Branca `feature/notifications-backend`, publicada a `8089a9d` com a PR #31. El 2026-10-27 s’hi integra
`origin/develop@572612a` amb `git merge --no-commit`, tal com demana la revisió del company. Es resolen
els conflictes a l’estat viu, les decisions pendents i la prova multi-repositori, conservant Perfil
(PR #32), la creació backend (PR #30), la verificació per enllaç (PR #33) i les seves proves.
No s’ha fet commit ni push automàtic de la resolució; l’usuari ha de completar el merge local i pujar
la mateixa branca per actualitzar la PR existent.

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
   aplicar el convertidor provisional de DP-036. Després de sincronitzar develop només s’envia bearer:
   no es restaura `X-User-ID` ni `ApiClient.isCanonicalUuid`, eliminats en aquella branca. El mapper
   continua comprovant el UUID real sense dependre del client de xarxa. Una sessió absent/canviada és
   un error, no una bústia buida.
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
- Social sense una sol·licitud identificada conserva el missatge genèric, sense botons d’amistat.
  Des de #164, les rebudes es consulten al seu endpoint i es correlacionen amb `friend-id` i
  `request-date` exactes; aquestes sí mostren Acceptar/Rebutjar amb resposta HTTP confirmada.
  Les rebudes sense avís automàtic també apareixen com a targetes, sense inventar lectura persistent
  (DP-065). Vegeu `friend-requests.md` per al contracte actual i la reconciliació amb el perfil.
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
- A l’Sprint 2: #164 ja integra identificador/estat i acceptar/rebutjar per l’API de sol·licituds. Queden l’avís automàtic en enviar, subtipus socials addicionals i l’historial resolt consultable (DP-065).

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


## Resolució de la revisió i conflictes de la PR #31 (2026-10-27)

El comentari del company, copiat per l’usuari, valora positivament implementació i cobertura i demana
sincronitzar develop. S’han preservat els canvis i proves de totes dues branques i les DP-039/040,
la resolució de DP-036 i l’ampliació de verificació web a DP-031. La prova multi-repositori conserva
els casos nous de creació; el seu bloc d’Avisos usa UUID real, catàleg i token i manté la lectura.
La cobertura dedicada de Perfil de develop es conserva sense duplicar-la en aquell smoke test.

La incompatibilitat de compilació amb l’ApiClient actual també s’ha corregit: no es passa `userId`
al constructor ni s’utilitza `isCanonicalUuid`, i no s’envia `X-User-ID`. Les proves d’Avisos comproven
la seva absència, el bearer i el UUID de destinatari. La sessió fixada per operació, els errors i els
controls de canvi de compte es conserven; no s’afegeix cap endpoint ni dada de negoci.

Verificació local: format de 234 fitxers sense canvis, analitzador net, **72 proves dirigides i 481 de
la suite completa superades**, APK debug i web compilats. Revisió tècnica sense bloquejos. Les
compilacions mantenen els avisos de Kotlin/Firebase, SDK XML i font Cupertino que no impedeixen
compilar; aquesta resolució no canvia dependències ni la configuració de CI. No es certifica una
execució remota de GitHub Actions: cal comprovar-la després de fer push. El repositori és privat i
no hi ha una connexió autenticada disponible per llegir els checks. El merge local queda preparat,
sense commit ni push automàtic; no cal crear cap PR nova.
