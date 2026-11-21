# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #168: targeta de sol·licitud a Avisos, estats de presentació, accessibilitat i proves.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #183 | [FE] Targeta d’avís de cancel·lació a `NotificationsScreen` + tests (història #47) | `feature/avis-cancel-lacio` | Implementada (HTTP); DP-071 oberta; pendent revisió humana |
| #181 | [FE] Botó i diàleg de cancel·lació a la fitxa per a qui l’ha creada + reflex visual a l’Agenda i el catàleg + tests (història #46) | `feature/cancel-lar-activitat` | Implementada (HTTP i Demo); DP-069 oberta; pendent revisió humana |
| #168 | [FE] Targeta de sol·licitud amb Acceptar/Rebutjar a NotificationsScreen + tests | `feature/friend-request-notification-card-168` | Publicada a `314bd93`; merge amb develop verificat: 856 proves, anàlisi, format i APK correctes; pendent commit/push de la resolució |
| #193 | [FE] Acció «Rebutjar» a Avisos i perfil + tests | `feature/reject-friend-request-193` | Integrada a develop amb PR #68; DP-067 oberta |
| #164 | [FE] Acceptar en avís social i perfil + comptadors/distintiu reactius + tests | `feature/accept-friend-request-164` | Integrada a develop amb PR #66; DP-066 oberta |
| #212 | [FE] Targeta «Com va anar?» a `AgendaScreen` (fig. 13) + `AgendaViewModel` + tests (història #64) | `feature/confirmar-assistencia` | Integrada a develop amb PR #69; DP-068 oberta |
| #160 | [FE] Botó d'acció d'amistat al perfil aliè + integració al ViewModel + tests | `feature/boto-amistat` | Integrada a develop amb PR #63; DP-064 oberta |
| #162 | [FE] Vista y `UserSearchViewModel` integrada en el buscador de Descobreix (fig. 16) + navegación al perfil conservando estado + tests | `feature/user-search-162` | Integrada a develop amb PR #64 |
| #148 | [FE] Xat de l'activitat | `feature/xat-activitat` | Integrada a develop amb PR #59; correccions de la revisió (límit en runes, refresc sense encavalcar-se i pausat en segon pla, proves d'estats, documentació); DP-062 oberta |
| #197 | [FE] `FriendsListScreen` + `FriendsListViewModel` connectada des de `ProfileScreen` + tests (història #54) | `feature/llista-amics` | Integrada a develop amb PR #65; DP-065 oberta |
| #274 | [FE] Mapa a pantalla completa estil Google Maps | `feature/mapa-pantalla-completa` | PR #58; correccions de la revisió (proves, xips de 48 px, documentació, codi sense ús); només mapa per decisió de l’usuari (DP-061) |
| #273 | [FE] Intercanviar Inici i Descobreix | `feature/intercanviar-inici-descobreix` | PR #57; correccions de la revisió (marge de l'assistent, documentació, proves); DP-060 oberta |
| #28 | [FE] Canviar idioma (ca/es/en) | `feature/change-language-28` | Implementada (ARB + gen-l10n, selector a Configuració, `language` al backend, `?lang=`); DP-001 resolta; DP-054 i DP-055 obertes; pendent revisió humana i contracte backend |
| #261 | [FE] Amagar menú de navegació inferior en obrir el xat | `feature/fix-261-chat-navigation` | PR publicada a 1e89723; conflictes amb develop resolts; 532 proves i anàlisi correctes; sense commit/push del merge |
| #185 | [FE] Valoració d'1–5 estrelles a la fitxa i a l'Agenda | `feature/valorar-esdeveniment` | Implementada amb Demo; sense assistència ni #184 (DP-053); pendent revisió |
| #203 | [FE] Valorar l'organitzador (esdeveniments comunitaris) i actualitzar-ne la fiabilitat | `feature/valorar-organitzador-203` | PR oberta #50 (Demo DP-049); apilada sobre #45; pendent CI i revisió humana |
| #262 | [FE] Ajustar contrast i color del logotip respecte al fons | `feature/fix-262-logo-contrast` | Implementada; preparació de PR autoritzada; pendent CI i revisió humana |
| #277 | [FE] Perfil d'un altre usuari amb GET /users/{id} i privacitat dels plans (CA3) + tests | `feature/perfil-altre-usuari` | Implementada (HTTP i Demo); DP-063 oberta; pendent revisió humana |

## Base i abast actual (#168)

- Branca `feature/friend-request-notification-card-168`, commit publicat `314bd93`; merge local de `origin/develop@d2d5303` sense commit.
- #164 integrada amb PR #66 i #193 amb PR #68; cap branca pare pendent.
- Presentació de la petició extreta a `FriendRequestNotificationActions`, reutilitzada per `NotificationCard`.
- Mateix ViewModel/repositoris compartits; no es duplica estat ni s’afegeixen endpoints.
- Progrés visible, resultat amb text/icona i controls accessibles amb remitent; ca/es/en, 320 px amb text ×2.
- 18 proves noves superades: 11 de component (incloent focus/teclat) i 7 de pantalla. Suite completa: 843 proves; anàlisi sense incidències, format de 350 fitxers i APK debug correctes. Revisió tècnica independent aprovada.
- Backend `fb266a7` intacte; continuen els límits de generació automàtica d’avisos de DP-066.
- Guia de renderitzat/estats i proves: `docs/notification-request-card.md`.

## Verificació #168 (2026-11-21)

- 18 proves noves: estats de la targeta, lectura independent, callbacks, errors/reintent,
  altres peticions disponibles i destinació de perfil opcional.
- Ca/es/en a 390 px i a 320 px amb text ×2; superfícies de 48 px, etiquetes amb remitent i focus natiu.
- Prova de Tab/Enter/espai: focus accessible i activació de totes dues accions.
- Suite completa de **843 proves** superada; anàlisi sense incidències i format de 350 fitxers sense canvis.
- Poliment visual final verificat tornant a passar els 18 tests d’interfície i 2 recorreguts de render.
- `flutter build apk --debug` correcte després de l’ajust visual final.
- Revisió tècnica independent: incidència de semàntica nativa corregida i segona revisió aprovada.
- Captures Flutter amb fonts Roboto i Demo revisades a `PES/output/frontend/task-168-avisos-{pendent,enviant-acceptar,enviant-rebutjar,acceptat,rebutjat}.png`.
- Cap escriptura a Render ni prova amb comptes reals; backend intacte, sense commit ni push.

## Verificació #193 (2026-11-21)

- 18 proves noves: ViewModel, HTTP amb/sense avís persistent, error/reintent, lectura independent,
  accions oposades concurrents, respostes antigues, dispose, comptadors/privacitat i recorreguts d’app.
- Widgets comprovats a 320 px amb text ×2 en català, castellà i anglès.
- Suite completa: **825 proves superades**. `flutter analyze` sense incidències; format de 347 fitxers sense canvis.
- `flutter build apk --debug` correcte. `git diff --check` correcte.
- Revisió tècnica independent aprovada, incloses les dues proves límit finals i la documentació.
- Captures Flutter amb Demo i fonts Roboto revisades a `PES/output/frontend/task-193-{perfil-pendent,perfil-rebutjat,avisos-rebutjat,comptador-propi}.png`.
- Backend intacte; no s’han executat escriptures a Render ni verificació amb comptes reals. Sense commit/push.

## Verificació #164 (2026-11-20)

- 26 proves noves: contracte HTTP, participants, microsegons, single-flight, resposta falsa, error/reintent,
  canvi de compte, dispose, refrescos antics, comptadors, errors de lectura separats i pantalla estreta.
- Recorregut d’app actualitzat: Avisos → perfil → acceptar → tornar a Avisos → Perfil propi, amb recompte reactiu.
- Suite completa: **760 proves superades**. `flutter analyze` sense incidències. Format de 323 fitxers sense canvis.
- Revisió tècnica independent: dues carreres corregides i cobertes amb regressions; segona revisió sense bloquejos.
- Captures Flutter amb fonts Roboto i Demo a `PES/output/frontend/task-164-{avisos-pendent,perfil-pendent,perfil-acceptat,avisos-acceptat,comptador-propi}.png`.
- Contrast del distintiu confirmat ajustat amb colors del tema; proves de pantalla i render tornats a passar.
- Compilació `flutter build apk --debug` correcta (`build/app/outputs/flutter-apk/app-debug.apk`). No s’han executat el backend, migracions ni escriptures autenticades a Render.

## Pendents / següents passos

1. Resolució del merge de #168 preparada per a revisió humana; `git diff --check` correcte.
2. Revisar la resolució, fer el commit del merge i push a la mateixa branca per actualitzar la PR existent; CI i aprovació humana obligatòries.
3. Comprovar el recorregut amb dos comptes reals al desplegament i en Android.
4. Backend/equip: avís automàtic en enviar sol·licitud i política de zona de `request-date` (DP-066).
   Si cal historial resolt o lectura de sol·licituds després de reiniciar, falten aquests contractes.

## Resolució de conflictes amb develop (2026-11-20)

- `origin/develop@8b4b5dd` incorpora la llista d’amics #197 (PR #65) i el xat d’activitat #148 (PR #59).
- Es conserven tots els repositoris/callbacks d’ambdues branques; no es substitueix cap funcionalitat.
- DP-065 queda reservada a la llista d’amics. L’acceptació de #164 passa a DP-066 amb les seves referències.
- Traduccions ca/es/en regenerades després de combinar els ARB. Conjunt verificat: 807 proves superades, anàlisi sense incidències, format de 343 fitxers i APK debug correctes. Revisió tècnica independent sense bloquejos.
- El commit funcional `1bd9dc7` ja està publicat; la resolució del merge encara no té commit ni push; l’usuari actualitza la mateixa PR després de revisar-la.

## Resolució de conflictes de #168 (2026-11-21)

- `origin/develop@d2d5303` incorpora #212, confirmació d’assistència a Agenda (PR #69).
- Únic conflicte textual a `docs/ai/estat.md`: es conserven totes dues tasques i els estats d’integració actuals.
- La composició d’assistència, la condició per valorar i els seus tests es conserven tal com arriben de develop.
- La targeta de sol·licitud #168, focus/teclat, estats i callbacks es mantenen intactes.
- Traduccions ca/es/en regenerades amb les claus d’ambdues tasques. Conjunt verificat: 856 proves superades, anàlisi sense incidències, format de 359 fitxers i APK debug correctes. Revisió tècnica independent aprovada.
- Sense commit ni push de la resolució; l’usuari actualitza la mateixa PR després de revisar-la.
