# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #170: targeta d’amistat acceptada, navegació al perfil i proves. Classificació HTTP pendent de contracte (DP-070).

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #170 | [FE] Targeta d’amistat acceptada a NotificationsScreen amb navegació al perfil + tests | `feature/accepted-friendship-notification-170` | Publicada a `df48032`; merge amb develop `085a03a` verificat: 877 proves, anàlisi, format i APK correctes; pendent commit/push de la resolució; HTTP pendent (DP-070) |
| #181 | [FE] Botó i diàleg de cancel·lació a la fitxa per a qui l’ha creada + reflex visual a l’Agenda i el catàleg + tests (història #46) | `feature/cancel-lar-activitat` | Integrada a develop amb PR #71 (`085a03a`); DP-069 oberta |
| #168 | [FE] Targeta de sol·licitud amb Acceptar/Rebutjar a NotificationsScreen + tests | `feature/friend-request-notification-card-168` | Integrada a develop amb PR #70 (base `c7f4895`); verificació del merge: 856 proves, anàlisi, format i APK correctes |
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

## Base i abast actual (#170)

- Branca `feature/accepted-friendship-notification-170`, commit publicat `df48032`; merge local de `origin/develop@085a03a` sense commit. #181 (cancel·lació, PR #71) preservada.
- `NotificationCard` afegeix «Veure perfil» només al model tipat `friendRequestAccepted`, amb nom accessible, ca/es/en i mida mínima de 48 px.
- Reutilitza model, formatador, lectura confirmada, ViewModel, callbacks i navegació existents; cap estat de negoci duplicat ni dependència nova.
- 14 proves noves; conjunt focal de 28 proves superat: targeta en 3 idiomes a 390/320 px, lectura/error/reintent, canvi de compte/dispose, retorn amb estat i guard HTTP.
- Backend `fb266a7` intacte. L’usuari confirma que no hi ha una altra branca: Social no identifica l’acceptació estructuradament. La classificació HTTP queda pendent a DP-070; no s’interpreta text lliure.
- Guia i missatge per al backend: `docs/accepted-friendship-notification.md`. Revisió tècnica independent aprovada; pendent revisió humana i CI.

## Verificació #170 (2026-11-21)

- 14 proves noves: targeta, ca/es/en, semàntica i 48 px; lectura confirmada, duplicats, ja llegit,
  error/reintent, destinació opcional, canvi de compte/dispose, retorn amb estat i guard HTTP.
- Conjunt focal de 28 proves superat; suite completa final: **870 proves superades**.
- Ajust d’una prova anterior de rebuig: tornar a fer visible el cos de la targeta abans de prémer-lo
  després de resoldre la petició. Es mantenen totes les assertions de navegació i comptadors.
- `flutter analyze` sense incidències; format de 362 fitxers sense canvis; `git diff --check` correcte.
- `flutter build apk --debug` correcte. Revisió tècnica independent aprovada, també per l’ajust del test.
- Captures Flutter amb fonts Roboto i Demo revisades a `PES/output/frontend/task-170-{avisos-acceptacio,perfil-amiga,retorn-avisos}.png`.
- Backend intacte. Sense escriptures a Render ni verificació amb comptes reals. Sense commit/push.

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

1. Revisió de la resolució dels conflictes #170, commit del merge i push a la mateixa branca per actualitzar la PR existent. CI i aprovació humana obligatòries; abast UI i DP-070 explícits.
2. Backend/equip: discriminador estructurat d’acceptació a la bústia (DP-070); després integrar el JSON real i comprovar el recorregut amb dos comptes al desplegament i Android.
3. Backend/equip: avís automàtic en enviar sol·licitud i política de zona de `request-date` (DP-066).
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

## Resolució de conflictes de #170 (2026-11-21)

- `origin/develop@085a03a` incorpora #181, cancel·lació d’activitats (PR #71).
- Conflictes a `docs/ai/estat.md` i `docs/decisions-pendents.md`: es conserven totes dues tasques i decisions.
- DP-069 es manté per a la cancel·lació; la dependència del subtipus d’acceptació passa a DP-070,
  amb totes les referències de codi, guia, README i arquitectura actualitzades.
- Lògica i proves de #170 i #181 preservades. Traduccions ca/es/en regenerades amb les claus d’ambdues branques.
- Conjunt verificat: **877 proves superades**, anàlisi sense incidències, format de 364 fitxers,
  `git diff --cached --check` i APK debug correctes. Revisió tècnica independent aprovada.
- Cap canvi al backend ni escriptura a Render. Sense commit ni push de la resolució;
  l’usuari actualitza la mateixa PR després de revisar-la.
