# Decisions pendents

> **Quan llegir-ho:** abans de començar una tasca (per saber què no està decidit), quan facis un canvi sense
> estar-ne segur i en revisar una PR. Hi registren entrades tant els agents d'IA com les persones.
> Vigilància: el subagent `vigilant-decisions` (després d'implementar, abans de `/pr` i `/revisar`).

## Quan s'hi ha d'afegir una entrada

Sempre que es faci (o es deixi de fer) un canvi basat en un supòsit que ningú no ha confirmat:

- requisit o criteri d'acceptació ambigu o contradictori (Taiga, PDFs, mockups);
- contracte del backend o d'un altre equip que encara no existeix;
- dependència, paquet o servei nou;
- desviació del mockup, de l'arquitectura o d'una convenció;
- dades, valors o noms deduïts (enums, llindars, textos);
- dubte de seguretat, privacitat o integritat.

**Al codi**, el punt afectat es marca amb `TODO(DP-NNN)` (no amb un `TODO` genèric). A la resposta a l'usuari,
l'agent indica quines DP ha obert. Mai no es presenta un supòsit com a decisió presa.

## Format

```markdown
### DP-NNN · <Títol curt>
- **Estat:** oberta | resolta AAAA-MM-DD | descartada AAAA-MM-DD
- **Obert per:** AAAA-MM-DD · <persona o agent (eina, model)> · Taiga #<ID> si n'hi ha
- **Context:** <fitxers o pantalla afectats>
- **Dubte:** <què no se sap, en 1–2 línies>
- **Opcions:** A) … · B) …
- **Provisionalment:** <què s'ha fet mentrestant i on hi ha el `TODO(DP-NNN)`>, o «res, bloqueja la tasca»
- **Qui decideix:** equip | frontend | backend | PO (professor) | altre equip
- **Resolució:** <quan es tanqui: decisió + on queda (ADR, memoria.md, codi)>
```

Regles: numeració correlativa (no es reutilitza cap número); les noves van al final d'«Obertes». En resoldre una DP,
omple «Resolució», canvia'n l'estat, mou-la a «Resoltes» i substitueix els `TODO(DP-NNN)` del codi. Si la
resolució és d'arquitectura, crea un ADR; si és una convenció, afegeix-la a `docs/ai/memoria.md`.

## Obertes

### DP-001 · Internacionalització de la UI
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `lib/` (textos dins de les pantalles), skill `i18n-textos`
- **Dubte:** l'NFR demana textos en fitxers de traducció i ca/es/en; el mockup de Configuració només mostra ca/es; `AGENTS.md` prohibeix afegir paquets sense necessitat.
- **Opcions:** A) `flutter_localizations` + `intl` amb ARB (ca/es/en) · B) el mateix però només ca/es · C) ajornar-ho fins a la història «Canviar idioma»
- **Provisionalment:** UI només en català; cap paquet afegit.
- **Qui decideix:** equip
- **Resolució:** 2026-11-19 · decidit per l'usuari (#28 «Canviar idioma»): opció A, ca/es/en, català per defecte. `flutter_localizations` + `intl` amb ARB (`lib/l10n/app_{ca,es,en}.arb`, plantilla `app_ca.arb`, `l10n.yaml`, `flutter: generate: true`). Els límits que queden són a DP-054 i DP-055.

### DP-002 · Llibreria de migracions de BD
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `api-aprop/migrations/`, skill `migracio-bd`
- **Dubte:** la memòria diu «llibreria migrations», però no és a `go.mod`.
- **Opcions:** A) `golang-migrate/migrate` amb `embed` · B) una altra llibreria · C) un runner propi mínim amb `database/sql`
- **Provisionalment:** convenció de fitxers `NNNNNN_nom.up.sql` / `.down.sql`.
- **Qui decideix:** backend
- **Resolució:**

### DP-003 · Mètode d'accés: Google o usuari i contrasenya
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `lib/features/auth/`, mockups (Incepció 2 §8), Taiga #7
- **Dubte:** els mockups preveuen l'accés amb Google; el codi i els criteris de #7 implementen usuari o correu + contrasenya.
- **Opcions:** A) tots dos via Firebase · B) només Google · C) només correu i contrasenya
- **Provisionalment:** comptes de demostració amb contrasenya; botó de Google desactivat.
- **Qui decideix:** equip / PO
- **Resolució:**

### DP-004 · Claus de Firebase i Google Maps al client
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `docs/ai/30-arquitectura.md`, ADR-0003
- **Dubte:** els PDFs diuen que totes les claus van al backend, però el login de Firebase i el SDK de Maps normalment s'executen al client amb claus restringides.
- **Opcions:** A) SDK al client amb claus restringides per app · B) tot via backend (proxy)
- **Provisionalment:** 2026-10-22: per al login s'ha seguit A amb Firebase Auth (vegeu DP-026). `flutterfire configure` genera `lib/firebase_options.dart` i `android/app/google-services.json` (projecte `aprop-919ec`). Es van versionar en un primer moment (repo privat), però el 2026-10-22 l'equip va decidir **no versionar-los**: són al `.gitignore`, la clau s'ha renovat (l'antiga queda a l'historial de la branca `feature/autenticacio`, però ja no és vàlida) i cada persona els genera amb `flutterfire configure` (`docs/firebase-auth.md`). Sense aquests fitxers l'app no compila. Pendent: restringir les claus noves (Android: paquet + SHA-1; navegador: `localhost:5000` i `aprop-919ec.firebaseapp.com`). 2026-10-26: la CI (`.github/workflows/ci.yml`) escriu versions de mostra dels dos fitxers (sense claus ni secrets de GitHub), perquè les proves i el build de depuració no es connecten a Firebase.
- **Qui decideix:** equip (cal un ADR)
- **Resolució:**

### DP-005 · Clau única dels esdeveniments oficials
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `event_model.Event.Code`, UML R1 «(Oficial, codi)»
- **Dubte:** el `Code` de la Generalitat no és únic (es reutilitza), però el UML el fa servir com a clau.
- **Opcions:** A) clau composta (codi + data d'inici + espai) · B) ID propi + `UNIQUE` a una altra combinació · C) corregir el UML
- **Provisionalment:** ID intern assignat pel repositori.
- **Qui decideix:** backend
- **Resolució:**

### DP-006 · Contractes amb Talaia i Mobilicat
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `docs/ai/40-api-i-serveis.md`
- **Dubte:** rutes, formats, autenticació i versionat dels serveis que intercanviem.
- **Opcions:** —
- **Provisionalment:** interfície + fake al backend quan es comenci la integració.
- **Qui decideix:** altre equip + backend
- **Resolució:**

### DP-007 · Contrast de `AppTheme.muted` sobre `cream`
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `lib/app/theme/app_theme.dart`
- **Dubte:** ≈ 4,4:1 sobre `cream`, per sota de l'AA de WCAG (4,5:1) en text normal; sobre `cardBackground` és ≈ 4,9:1.
- **Opcions:** A) enfosquir `muted` · B) fer-lo servir només sobre targetes o en text gran
- **Provisionalment:** cap canvi al tema.
- **Qui decideix:** frontend
- **Resolució:**

### DP-008 · Primera versió SemVer
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** skill `release-semver`
- **Dubte:** la primera release ha de ser `v0.1.0` o el MVP ha de ser `v1.0.0`?
- **Opcions:** A) `v0.x` fins al MVP i `v1.0.0` al MVP · B) `v1.0.0` al final de l'Sprint 1
- **Provisionalment:** res.
- **Qui decideix:** equip
- **Resolució:**

### DP-009 · Atributs i valors d'enum que només són al diagrama UML
- **Estat:** oberta
- **Obert per:** 2026-10-16 · configuració IA (Cursor)
- **Context:** `docs/ai/20-model-domini.md` (marques `TODO(confirmar)`)
- **Dubte:** el diagrama és una imatge; falten atributs i valors exactes (estat del compte, del NoOficial, de la denúncia, llindars d'XP).
- **Opcions:** —
- **Provisionalment:** noms deduïts de les restriccions textuals.
- **Qui decideix:** qui va fer el diagrama
- **Resolució:**

### DP-010 · Enrollment backend contract and Calendar integration
- **Estat:** oberta
- **Obert per:** 2026-10-18 · Codex · Taiga #82
- **Context:** `EnrollmentRepository`, `DemoEnrollmentRepository`, list/detail participation controls and future Agenda integration.
- **Dubte:** enrollment endpoints, error format, authenticated identity and persistence are not agreed in the available backend contract. The calendar feature is developed separately and is not present on `develop`.
- **Opcions:** A) implement an authenticated API adapter once backend and Calendar agree the contract · B) keep the frontend on the shared demo repository until then.
- **Provisionalment:** implement a Dart-only repository contract with confirmed, idempotent enrollment and a stream of enrolled activity IDs per user. Demo data is retained in memory across sign-outs and cleared on app shutdown. Calendar will subscribe to the same repository; no HTTP endpoints, enrollment DTOs or calendar screen are invented. `TODO(DP-010)` marks the demo adapter.
- **Qui decideix:** frontend + backend + calendar owner
- **Resolució:**

### DP-011 · Identitat provisional `X-User-ID` als endpoints d'inscripció
- **Estat:** oberta
- **Obert per:** 2026-10-19 · agent (Cursor, Claude) amb confirmació de l'usuari · Taiga #39
- **Context:** `api-aprop`: `POST /events/{id}/signup` (capçalera `X-User-ID`) i `GET /users/{userId}/events`
- **Dubte:** encara no hi ha Firebase Auth al backend ni taula d'usuaris; qualsevol client pot apuntar o consultar els plans d'un altre UUID.
- **Opcions:** A) validar el token de Firebase en un middleware i obtenir-ne l'usuari (eliminar `X-User-ID` i comprovar que `{userId}` és el de la sessió) · B) mantenir-ho només en desenvolupament
- **Provisionalment:** l'UUID arriba a la capçalera o a la ruta sense autorització; `TODO(DP-011)` als handlers. El frontend continua amb el repositori de demostració (DP-010).
- **Qui decideix:** backend + equip (ADR-0003)
- **Resolució:**

### DP-012 · Unicitat de `SignUp` (R1) sense restricció a la BD
- **Estat:** oberta
- **Obert per:** 2026-10-19 · agent (Cursor, Claude) amb confirmació de l'usuari · Taiga #39
- **Context:** `api-aprop/migrations/000001_initial_migration.up.sql` (PK `(UserID, Event, SignUpDate)`), `queries/signups.sql`
- **Dubte:** la clau primària inclou la data, de manera que la BD admet inscripcions duplicades del mateix usuari al mateix esdeveniment.
- **Opcions:** A) migració amb `UNIQUE (UserID, Event)` (eliminant duplicats) + `ON CONFLICT DO NOTHING` · B) mantenir la comprovació a la consulta
- **Provisionalment:** `INSERT … WHERE NOT EXISTS`, idempotent en peticions seqüencials però no davant peticions concurrents; la llista fa `DISTINCT`. `TODO(DP-012)` a la consulta/repositori.
- **Qui decideix:** backend
- **Resolució:**

### DP-013 · Dates dels plans a l'Agenda: diversos dies, permanents, sense data i hora
- **Estat:** oberta
- **Obert per:** 2026-10-19 · vigilant-decisions (Cursor) · Taiga #39 / #84
- **Context:** `AgendaViewModel._resolvePlans` (agrupa per `_dateOnly(activity.startsAt)`), `AgendaPlanCard` (`formatAgendaTime(startsAt)`), `Activity` (només `startsAt`); `api-aprop`: `Events.StartDate` és `Date` i admet `NULL` (migració 000002), `EndDate`, `Permanent`, `Schedule` en text lliure, i `ListUserSignedUpEvents` filtra per solapament `[StartDate, COALESCE(EndDate, StartDate)]`.
- **Dubte:** el frontend posa el punt només al dia d'inici, mentre que el backend ja retorna els esdeveniments de diversos dies per solapament; tampoc no hi ha criteri per als permanents o sense data d'inici, ni d'on surt l'hora «19.00 h» si el backend només té dates i un horari en text.
- **Opcions:** A) afegir `endsAt` (i una hora opcional) a `Activity` i marcar tots els dies de l'interval · B) marcar només el dia d'inici i mostrar el període a la targeta · C) excloure de l'Agenda els permanents/sense data
- **Provisionalment:** només `startsAt` (documentat com a fora d'abast a `docs/calendar.md`); sense marcador al codi.
- **Qui decideix:** frontend + backend (+ PO per als permanents)
- **Resolució:**

### DP-014 · Desviacions de l'Agenda respecte del mockup (fig. 11) i textos inventats
- **Estat:** oberta
- **Obert per:** 2026-10-19 · vigilant-decisions (Cursor) · Taiga #39 / #84
- **Context:** `agenda_plan_card.dart`, `agenda_date_formatter.dart` (`formatAgendaMonth`), `agenda_screen.dart`, `main_shell.dart`; `docs/source/incepcio-2.pdf` p. 25
- **Dubte:** el mockup i el seu text diuen que la targeta mostra categoria (xip), municipi, hora, **procedència** («Font: Agenda Cultural · Generalitat») i l'etiqueta «Apuntat ✓»; la implementació no mostra ni la procedència ni «Apuntat» i posa hora i categoria en una sola línia. El títol del mes és «Setembre de 2026» (mockup: «Setembre 2026») i s'ha eliminat el subtítol «Els teus plans culturals». Els textos del dia buit («No tens cap pla per a aquest dia.», «Apunta’t a activitats des d’Inici…») i d'error no són al mockup (només diu «missatge específic»).
- **Opcions:** A) alinear la targeta, el títol i el subtítol amb el mockup i validar els textos · B) acceptar la versió compacta i actualitzar `docs/ai/50-ui-mockups.md`
- **Provisionalment:** 2026-10-19, confirmat per l'usuari: la targeta ja mostra la procedència («Font: Agenda Cultural · Generalitat» o «Publicat per …») i «Apuntat ✓», i el títol es manté «Setembre de 2026» (forma catalana correcta). Queden per validar amb l'equip el subtítol i els textos del dia buit i d'error; sense marcador al codi.
- **Qui decideix:** frontend + equip (disseny)
- **Resolució:**

### DP-015 · Accessibilitat del calendari mensual
- **Estat:** oberta
- **Obert per:** 2026-10-19 · vigilant-decisions (Cursor) · Taiga #39 / #84
- **Context:** `month_calendar.dart` (`_DayCell`, punt `colors.secondary`)
- **Dubte:** el punt coral sobre `cream` té un contrast ≈ 2,7:1 (WCAG 1.4.11 en demana 3:1 per a elements gràfics; la semàntica sí que diu «amb plans»). Les cel·les fan 48 px d'alt, però l'amplada és 1/7 de la pantalla: a 320 px queden ≈ 41 px, per sota dels 48 dp recomanats.
- **Opcions:** A) enfosquir el punt o fer-lo més gran i reduir el farciment lateral per assolir 48 dp · B) acceptar-ho (el color ve del mockup) i documentar-ho
- **Provisionalment:** 2026-10-19, confirmat per l'usuari: el punt passa a `forest` (`colorScheme.primary`, ≈ 12:1 sobre `cream`; `cream` sobre el dia seleccionat). Queda oberta l'amplada de les cel·les en pantalles estretes; sense marcador al codi.
- **Qui decideix:** frontend
- **Resolució:**

### DP-016 · Contracte d'API de l'assistent (xatbot) amb el backend
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Antigravity · Taiga #91 / #14
- **Context:** `AssistantRepository`, `DemoAssistantRepository`, `AssistantMessage`, `AssistantInterpretation` (`lib/features/assistant/`).
- **Dubte:** l'endpoint HTTP del backend per consultar Gemini, el format JSON de la consulta/resposta (criteris interpretats de tipus, municipi i dates, i llista d'activitats recomanades) i la persistència de `ConversaXatbot` no estan definits a `api-aprop`.
- **Opcions:** A) l'endpoint retorna el text, els filtres interpretats i les activitats completes · B) l'endpoint retorna IDs d'activitats que es resolen contra `ActivityRepository`.
- **Provisionalment:** contracte `AssistantRepository` en Dart pur i `DemoAssistantRepository` (marcat amb `TODO(DP-016)`) que interpreta tipus, municipi i dates en local sobre `ActivityRepository` sense inventar rutes ni DTO HTTP.
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-017 · Contracte del backend per crear activitats no oficials
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93 / #31
- **Context:** `ActivityRepository.createActivity`, `NewActivity`, `DemoActivityRepository`, `MainShell._showCreatedActivity`.
- **Dubte:** no hi ha endpoint per publicar un `NoOficial` a `api-aprop`: ruta, JSON, format del preu (s'ha fet servir `double` en euros, `0` = gratuïta) i si el backend apunta automàticament la persona creadora.
- **Opcions:** A) el backend crea l'activitat i la inscripció de qui la crea en una sola operació · B) el frontend crida després l'endpoint d'inscripció.
- **Provisionalment:** `createActivity` en Dart pur i implementació en memòria; `MainShell` apunta la creadora amb `EnrollmentViewModel` (`TODO(DP-017)`).
- **Amb el backend (2026-10-26, Claude Code (Opus 5.5) amb confirmació de l'usuari):** `POST /events` ja existeix i `HttpActivityRepository.createActivity` (PR #23, Taiga #231) l'envia. S'hi ajusta `newActivityToJson`:
  - la data s'envia amb l'hora d'aquí com si fos UTC: el backend desa només el dia i, passant-la a UTC, una activitat a les 00.30 h quedaria el dia anterior (DP-029);
  - la categoria és l'etiqueta del backend (DP-018);
  - les indicacions van només a `address` (abans també a `place`, i en llegir-la sortien repetides);
  - `free` només s'envia si hi ha preu: sense preu no se sap si és gratuïta.
  No es desen al backend l'import del preu, la imatge triada (#94, DP-019) ni l'hora. El backend no apunta qui crea l'activitat: `MainShell` la continua apuntant (opció B). Després de crear-la, el mapa d'Inici torna a demanar la zona visible perquè hi surti. El backend treu el creador del token des de la PR #35 d'api-aprop (Tasca #236, Arnau), que també afegeix `PUT` i `DELETE /events/{id}` per editar i esborrar els esdeveniments no oficials (encara sense pantalla).
- **Camps opcionals (2026-10-28, Claude Code (Opus 5.5), a petició de l'usuari, Taiga #93):** el municipi deixa de ser obligatori (el backend no l'exigeix; s'envia buit i les targetes, la fitxa, el mapa, l'Agenda i els avisos no en mostren la fila) i s'afegeix una data i hora de fi opcional. Queda per decidir:
  - el formulari demana que la fi sigui **posterior** a l'inici; el backend (R5) també n'accepta una d'igual;
  - sense data de fi s'envia `end-date` igual a `start-date`, com fins ara;
  - el backend només desa el dia de la fi (DP-029) i l'app encara no llegeix ni mostra `end-date` (`Activity` no en té camp).
- **Editar (2026-11-16, Claude Code (Opus 5.5) amb confirmació de l'usuari, Taiga #189 / US #50):** el llapis «Edita l’activitat» de la fitxa només surt a qui l'ha creada (l'UUID del backend o l'UID de la sessió), si no és oficial i si encara no ha començat («activa» = no començada). Obre el mateix formulari amb les dades i «Desa els canvis», que envia `PUT /events/{id}` amb el mateix JSON que crear; el backend torna a comprovar l'autoria i R5. Ara l'app llegeix `end-date` (`Activity.endsAt`) perquè editar no la perdi. El backend no desa l'import del preu: d'una activitat de pagament no se'n sap, i si el camp es deixa buit no es converteix en gratuïta. La portada triada tampoc no es desa (DP-019). Després de desar, la fitxa es torna a carregar i la llista i el mapa es posen al dia.
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-018 · Categories de les activitats: llista i nombre per activitat
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93 / #31
- **Context:** `activity_options.dart` (`activityCategories`), `CreateActivityViewModel`, formulari «Crea una activitat».
- **Dubte:** la llista tancada de categories no està definida, i el CA1 diu «categoria (≥ 1)» mentre que el model `Activity` en té una sola.
- **Opcions:** A) una sola categoria (com ara) · B) diverses categories (cal canviar `Activity.category` i la llista, la fitxa i l'agenda).
- **Provisionalment:** una sola categoria triada d'una llista provisional (Música, Teatre, Exposicions) (`TODO(DP-018)`). L'usuari ho ha decidit així de moment per no canviar el model.
- **Amb el backend (2026-10-26, Claude Code (Opus 5.5) amb confirmació de l'usuari):** amb backend, el formulari carrega `GET /categories` (`HttpActivityRepository.getCategories`) i només ofereix les de l'Agenda Cultural (`agenda:categories/…`), ordenades pel nom. No ofereix els àmbits (`agenda:ambits/…`) ni les que s'han creat escrivint un nom nou. S'envia l'etiqueta (p. ex. `agenda:categories/teatre`), perquè `POST /events` crea una categoria nova amb qualsevol nom que no existeixi. El nom que es veu surt de l'etiqueta i no porta accents («Conferencies», DP-029). Sense backend, continua la llista provisional. Els filtres d'Inici també carreguen `GET /categories` (DP-038) i filtren al servidor per l'ID de la categoria, així que una activitat creada amb una categoria de l'Agenda Cultural surt en filtrar per aquesta categoria.
- **Diverses categories (2026-11-17, amb confirmació de l’usuari):** el formulari en deixa triar fins a 3; la primera és la que fa de distintiu a les targetes, que hi afegeixen «+N». La fitxa les mostra totes (DP-059).
- **Qui decideix:** equip
- **Resolució:**

### DP-019 · Imatge de portada de les activitats creades
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93 / #94
- **Context:** `activity_options.dart` (`activityImageTemplates`), portada i panell «Imatge de portada» del formulari.
- **Dubte:** el CA1 diu que el cartell és opcional i es puja a S3; les plantilles definitives no existeixen i la pujada (#94) necessita un paquet (com `image_picker`) i un endpoint.
- **Opcions:** A) imatge obligatòria, amb una plantilla per defecte (com ara) · B) imatge opcional amb un marcador quan no n'hi ha.
- **Provisionalment:** les tres fotografies de demostració fan de plantilla; la primera és la portada per defecte; «Puja una foto» és al panell però desactivat (`TODO(DP-019)`).
- **Qui decideix:** equip
- **Resolució:**

### DP-020 · Ubicació exacta de les activitats creades i paquet de mapes
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93 / #31 / #21
- **Context:** camp «Municipi» del formulari; història #21 (mapa). Relacionada amb DP-004.
- **Dubte:** el CA1 i el CA2 demanen espai/coordenades i que l'activitat surti al mapa; no hi ha paquet de mapes ni servei per passar d'adreça a coordenades.
- **Opcions:** A) `flutter_map` + OpenStreetMap (sense clau) · B) Google Maps (clau d'API, vegeu DP-004); en tots dos casos, centrar el mapa al municipi i deixar ajustar el marcador.
- **Provisionalment:** 2026-10-20, l'usuari (Sukhjeet) ha triat B: `google_maps_flutter` al formulari, amb la clau a `android/local.properties` (`docs/google-maps.md`); la clau de l'equip la crea un altre membre i iOS encara no està configurat. El municipi es converteix en coordenades amb una llista de demostració (`DemoLocationRepository`) i l'usuari ajusta el marcador (`TODO(DP-020)`). Cal que l'equip ho confirmi, perquè la història #21 farà servir el mateix paquet.
- **Qui decideix:** equip
- **Resolució:**

### DP-021 · Disseny del formulari de creació sense mockup
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93
- **Context:** `CreateActivityScreen`, `start_date_time_sheet.dart`, botó flotant «Crear activitat» (`AppTheme.sage`).
- **Dubte:** el CA1 cita el botó de la fig. 7, però no hi ha mockup del formulari. L'usuari l'ha dissenyat prenent Partiful i Luma com a referència: portada a dalt, categories en fila horitzontal, rodes de data i hora, camp d'indicacions.
- **Opcions:** A) validar-lo tal com està · B) fer-ne un mockup i ajustar-lo.
- **Provisionalment:** implementat així (`TODO(DP-021)`).
- **Qui decideix:** equip
- **Resolució:**

### DP-022 · Mapa d'Inici: vista inicial, càrrega per zona i estil dels grups
- **Estat:** oberta
- **Obert per:** 2026-10-20 · Claude Code (Opus 5.5) · Taiga #21 / #79
- **Context:** `ActivitiesScreen` (selector Mapa / Llista), `activities_map.dart`, `DemoActivityRepository`.
- **Dubte:** el mockup (fig. 7) obre Inici amb el mapa; el CA3 demana carregar per zona visible en < 3 s, i no hi ha endpoint per zona; el número dels grups surt amb l'estil per defecte de Google, no amb el verd del mockup.
- **Opcions:** A) vista inicial mapa · B) vista inicial llista (com ara); per a la zona: endpoint amb els límits del mapa o carregar-ho tot; per als grups: acceptar l'estil de Google o fer l'agrupació a Dart amb icones pròpies.
- **Provisionalment:** la llista és la vista inicial (si Google Maps falla o no hi ha clau, Inici funciona igual); es mostren totes les activitats carregades; grups amb l'estil de Google (`TODO(DP-022)`).
- **Targeta del marcador (2026-11-15, Claude Code (Opus 5.5) a petició de l'usuari):** tocar qualsevol lloc de la targeta obre la fitxa (com ja passa a les targetes de llista, l'assistent i l'Agenda), i el botó «Veure activitat» del mockup (fig. 7) es canvia pel d'apuntar-se («M’hi apunto» / «✓ Apuntat · Desapunta’m»). Desviació del mockup per confirmar amb l'equip.
- **Grups propis (2026-11-16, Claude Code (Opus 5.5) a petició de l'usuari, Taiga #254):** els grups ja no els fa Google (`ClusterManager`), sinó l'app (`activity_map_groups.dart`): els marcadors que amb el zoom actual queden a menys de 64 px s'ajunten, i després s'ajunten també els grups que es tocarien segons la mida real del cercle, perquè mai no quedin l'un sobre l'altre. És igual a la web i al mòbil. El cercle és propi, amb el color principal de l'app, vora clara i el número total exacte (el cercle creix amb les xifres), en lloc dels cercles blaus i vermells de Google. Els grups es refan quan el mapa s'acaba de moure. Les activitats d'un mateix lloc sempre van en grup. El radi de 64 px i el disseny del cercle no surten del mockup (`TODO(DP-022)`).
- **Només mapa (2026-11-20, decisió de l’usuari, Taiga #274):** la pestanya Mapa ja no té selector Mapa / Llista: s’obre sempre amb el mapa (com la fig. 7 del mockup; la fig. 8 tenia el selector). La llista només surt, en lloc del mapa, si Google Maps no es pot dibuixar (vegeu DP-061), perquè es continuï complint el CA3 de la #21.
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-023 · API d'Avisos, respostes d'amistat i accés als perfils
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Codex · Taiga #86
- **Identificador:** renumerat de DP-017 a DP-023 el 2026-10-21 en integrar `develop`, per conservar la DP-017 de creació d’activitats sense col·lisions.
- **Context:** `features/notifications/`, mockups aprovats d'Avisos i Incepció 2 pp. 29–30; no hi ha contracte de notificacions/amistats ni funcionalitat de perfils disponible al client.
- **Dubte:** falten endpoints autenticats de bústia/lectura/resposta, persistència, sincronització d'amistats i enviament d'avisos. Les publicacions d'amics dels mockups tampoc no tenen una variant explícita al UML. Els criteris complets de Taiga #86 no són al repositori.
- **Opcions:** A) acordar contractes i integrar perfils/amistats · B) validar primer la pantalla i les interaccions amb dades demo aïllades.
- **Provisionalment:** projecció de bústia en Dart pur, dades demo per compte, lectura/resposta confirmades i callbacks de destinació. El perfil s'indica com a pendent fins que hi hagi un callback real. La resposta d'amistat simula només el resultat a la bústia: no implementa un graf d'amistats, push, programació de recordatoris, tipus UML nous ni rutes d'API. Els recordatoris històrics no creen inscripcions. Filtres desplaçables amb pantalla estreta/text ampliat, paletes centrals al tema i inicials si no hi ha avatar. `TODO(DP-023)` marca els límits demo/integració. Textos nous de càrrega/error/buit provisionals en català.
- **Qui decideix:** frontend + backend + responsables de perfils/amistats

- **Actualització 2026-10-26:** l’usuari confirma que les accions socials són fora de l’Sprint 1. Bústia i lectura s’integren amb HTTP; no s’infereixen subtipus socials ni s’hi confirmen accions locals. Identitat, tipus i context es contrasten amb backend; límits actuals a DP-039.

### DP-024 · Descobreix i cerca: contractes, seleccions i abast social
- **Estat:** oberta
- **Obert per:** 2026-10-21 · Codex · Taiga #96 Frontend de cerca
- **Context:** figures 14–16, `DiscoveryRepository`, `DemoDiscoveryRepository`, `DiscoverScreen` i `ActivitySearchScreen`. L'usuari autoritza Descobreix i la cerca d'activitats del Sprint 1; confirma el número/títol de Taiga, però els criteris detallats no estan disponibles localment.
- **Dubte:** falten el contracte de cerca/recomanacions, els criteris de coincidència/ordenació, els interessos persistits i les funcionalitats de persones/perfil.
- **Opcions:** A) integrar el contracte autenticat quan estigui acordat · B) validar primer el recorregut amb el catàleg compartit i un adaptador de demostració.
- **Provisionalment:** B, sense endpoints ni paquets nous. La selecció demo reutilitza els IDs d'exposició i teatre dels mockups, sense fingir personalització: el subtítol és «Una selecció per començar» fins que `isPersonalized` sigui cert. Es conserven les dates històriques del catàleg compartit; no són propostes actualitzades de producció. La cerca local ignora majúscules/accents/espais repetits i exigeix totes les paraules entre títol, categoria, municipi i descripció. Espera de 350 ms i enviament immediat amb el teclat. «Persones» es mostra desactivat amb explicació i l'accés inicial diu «Cerca activitats»; no es creen perfils ni amistats. La capçalera i la navegació segueixen el patró actual; missatges nous de buit/error provisionals en català. `TODO(DP-024)` marca aquestes adaptacions.
- **Qui decideix:** frontend + backend + responsables d'interessos/perfils
- **Resolució:**

- **Actualització 2026-10-27:** integració HTTP de recomanacions/populars/cerca amb el contracte real de `api-aprop@be6c25e`. Total i pàgines des de 0, disponibilitat/error per secció i preferències absents. Els límits nous s’especifiquen a DP-041; Demo conserva la seva semàntica local.

- **Actualització 2026-11-20 (#162):** cerca de persones amb el contracte implementat de #161 (`GET /users?q=&pageNum=&pageSize=`) i perfil públic de #277. S’habilita el selector amb dades i destinació disponibles, consulta per nom/username, total/pàgines del servidor i retorn amb estat conservat. Es respecten els límits actuals del backend (100 punts de codi Unicode, 20 files per petició, màxim 50 configurable). L’adaptador només consumeix el resum públic; bloquejos i comptes visibles els filtra el servidor. No s’implementen amistats noves. La resta de límits de la cerca d’activitats es manté a DP-041. Guia `docs/user-search.md`; pendent prova autenticada del desplegament.

### DP-025 · Primer accés amb Google: nom d'usuari i contracte amb el backend
- **Estat:** oberta
- **Obert per:** 2026-10-21 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #7
- **Context:** `AuthRepository.signInWithGoogle` i `chooseUsername`, `ChooseUsernameScreen`, `AuthGate`, `DemoAuthRepository`.
- **Dubte:** el mockup diu que en el primer accés amb Google «es completa el perfil», però no hi ha disseny d'aquesta pantalla ni contracte del backend per desar el nom d'usuari i saber si encara falta.
- **Opcions:** A) pantalla pròpia que només demana el nom d'usuari (nom i cognoms de Google) · B) formulari de perfil complet. En tots dos casos, cal un endpoint per desar-lo i un per consultar l'usuari actual.
- **Provisionalment:** A amb dades de demostració: el selector de Google se simula amb un compte fix (Jordi Puig) que el primer cop no té nom d'usuari; textos de la pantalla sense mockup (`TODO(DP-025)`). El test d'interessos del primer accés queda fora d'aquesta tasca.
- **Qui decideix:** equip (pantalla) · backend (contracte)
- **Resolució:**

### DP-026 · Firebase Auth al client: paquets i dades provisionals fins a `POST /auth/sync`
- **Estat:** oberta
- **Obert per:** 2026-10-22 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #73
- **Context:** `FirebaseAuthRepository`, `firebase_auth_failure.dart`, `main.dart`, `pubspec.yaml`; backend `api-aprop` branca `feature/auth` (`POST /auth/sync`, sense fusionar).
- **Dubte:** el backend encara no desa el perfil, no comprova que el nom d'usuari sigui únic, guarda nom i cognoms en un sol camp `name` i no permet entrar amb el nom d'usuari (Firebase només accepta correu).
- **Opcions:** entrar amb nom d'usuari: A) només correu · B) endpoint públic usuari → correu · C) login fet pel backend. Nom i cognoms: A) columnes al backend · B) treure'ls del registre.
- **Provisionalment:** paquets nous `firebase_core` 5, `firebase_auth` 7, `google_sign_in` 7 i `shared_preferences` 2. Nom i cognoms al backend amb `PATCH /users/me` (`{"name"}`, un sol camp de 100 caràcters com a màxim) i també al `displayName` de Firebase; es tornen a separar pel primer espai. Si el backend encara no té el nom (p. ex. comptes de Google o un error en registrar-se), l'app hi desa el `displayName` en entrar. Sense URL del backend, es desa al dispositiu. Nom d'usuari amb `POST /auth/sync` (DP-028; sense servidor, al dispositiu); si s'escriu un nom d'usuari en lloc del correu, l'app demana el correu (`AuthFailure.emailRequired`). Android i web (Google amb `signInWithPopup` de Firebase a la web); a iOS es continuen fent servir els comptes de demostració. `TODO(DP-026)` al repositori i a `main.dart`.
- **Qui decideix:** equip + backend (contracte) · PO (criteri «usuari o correu» de #7)
- **Resolució:**

### DP-027 · Desapuntar-se: endpoint del backend i diàleg de confirmació
- **Estat:** oberta
- **Obert per:** 2026-10-23 · Claude Code (Opus 5.5) amb confirmació de l'usuari · HU «Desapuntar-se d'un esdeveniment»
- **Context:** `EnrollmentRepository.unenroll`, `DemoEnrollmentRepository`, `EnrollmentViewModel.unenroll`, `EnrollmentAction` (llista, fitxa i Agenda a través de la fitxa). Els números DP-025 i DP-026 són de `feature/autenticacio`.
- **Dubte:** el backend no té cap endpoint per desapuntar-se (només `POST /events/{id}/signup`) i no hi ha mockup de com es desapunta ni del diàleg de confirmació.
- **Opcions:** endpoint: A) `DELETE /events/{id}/signup` (simètric al d'apuntar-se) · B) un altre que acordi el backend. Interfície: A) tocar «Apuntat» obre una confirmació (com ara) · B) un botó «Desapunta'm» separat a la fitxa.
- **Provisionalment:** contracte `unenroll` idempotent amb el repositori de demostració; a la interfície, tocar «Apuntat» obre el diàleg «Vols desapuntar-te?» amb «Mantén el pla» i «Desapunta’m», perquè un toc sense voler no tregui el pla. Textos sense mockup (`TODO(DP-027)` al repositori i al diàleg).
- **Interfície B (2026-11-15, Claude Code (Opus 5.5) amb confirmació de l'usuari, Taiga #258):** l'estat i l'acció se separen. El distintiu «✓ Apuntat» (`EnrollmentStatusBadge`) surt a les targetes de llista (Inici, Descobreix, cerca, assistent), a la targeta del marcador del mapa i a la fitxa, al costat de la categoria. El botó diu què fa: «M’hi apunto» o «Desapunta’m». Disseny del distintiu sense mockup. A l'Agenda (Taiga #259), cada pla té el mateix distintiu i el botó «Desapunta’m» (`AgendaScreen.participationActionBuilder`, amb l'`EnrollmentViewModel` compartit).
- **«Desfer» a la llista (2026-11-15, Claude Code (Opus 5.5) amb confirmació de l'usuari, Taiga #257):** a la llista d'Inici, «Desapunta’m» no pregunta: el pla marxa de seguida i surt l'avís «T’has desapuntat de «…».» amb «Desfer» durant 5 segons (`unenrollUndoDelay`). El backend no rep res fins que s'acaba el temps; «Desfer» o tornar a prémer «M’hi apunto» abans no fan cap petició. Si en acabar falla, el pla torna amb l'error. Si es tanca la sessió abans, la baixa s'envia igualment. El títol de la tasca diu «anul·lar reserva», però a la interfície no es parla de reserves (`AGENTS.md`). Amb el lector de pantalla actiu, Flutter pot deixar l'avís obert més estona: passat el temps, «Desfer» ja no fa res.
- **Només «Desfer», a tot arreu (2026-11-15, decisió de l'usuari, Taiga #257 / #259):** no hi ha cap diàleg de confirmació: a la llista, Descobreix, la cerca, l'assistent, el mapa, la fitxa i l'Agenda, «Desapunta’m» treu el pla i ofereix «Desfer» durant 5 segons. Ser coherent pesa més que tenir dues maneres de desapuntar-se; desapuntar-se es pot desfer, així que no cal preguntar. Substitueix la confirmació que demanava la #259. A l'Agenda, el pla no desapareix fins que s'envia la baixa (mentrestant hi surt «M’hi apunto»).
- **Qui decideix:** equip (interfície) · backend (endpoint)
- **Resolució:**

### DP-028 · Connexió amb el backend: `POST /auth/sync` i adreça del servidor
- **Estat:** oberta
- **Obert per:** 2026-10-23 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #73
- **Context:** `UserSyncRepository`, `HttpUserSyncRepository`, `DemoUserSyncRepository`, `FirebaseAuthRepository`, `lib/core/config/api_config.dart`, `main.dart`, `android/app/src/debug/AndroidManifest.xml`. El número DP-027 és a `feature/apuntar-esdeveniment`, encara sense fusionar.
- **Dubte:** el contracte de `POST /auth/sync` s'ha llegit de la branca `feature/auth` d'api-aprop, que encara no està fusionada; no hi ha servidor desplegat (ni URL), i el backend respon 422 tant si l'usuari encara no existeix com si el nom no és vàlid.
- **Opcions:** resposta per a «cal triar nom»: A) 422 (com ara) · B) un codi propi (p. ex. 404 o `username required`). URL: A) `--dart-define=API_BASE_URL` en executar i compilar (com ara) · B) un fitxer de configuració per entorn.
- **Provisionalment:** paquet nou `http`; la URL es passa amb `--dart-define=API_BASE_URL=…` i, si no n'hi ha, el nom d'usuari es desa al dispositiu (`DemoUserSyncRepository`, que reserva `laiasoler` per provar el nom repetit). Amb URL, s'envia el token de Firebase a `Authorization: Bearer` i es tracten 200/201, 409 i 422 (sense nom → cal triar-ne un). Si el backend no respon, es fa servir l'últim nom conegut desat al dispositiu. Si el nom ja és d'algú altre en registrar-se, el compte es crea igualment i l'usuari en tria un altre després de verificar el correu; la pantalla ho explica («El nom «…» ja és d'una altra persona»). Per avisar-ho abans de crear el compte caldria un endpoint públic del backend per comprovar si un nom està lliure. HTTP sense xifrar només a la versió de depuració. `TODO(DP-028)` al codi.
- **Qui decideix:** backend + frontend
- **Resolució:**

### DP-029 · Mapa d'Inici amb el backend: endpoint sense fusionar i adaptació de les dades
- **Estat:** oberta
- **Obert per:** 2026-10-23 · Claude Code (Opus 5.5) · Taiga #21
- **Identificador:** DP-025 a DP-028 ja són a altres branques sense fusionar; es fa servir DP-029 per no col·lidir-hi.
- **Context:** `HttpActivityMapRepository`, `ActivitiesMapViewModel`, `ActivitiesScreen` (vista Mapa), `AuthGate`, `MainShell`. L'usuari demana connectar només el mapa (no la llista) i que la fitxa oberta des del mapa també vingui del backend.
- **Dubte:**
  - `GET /events/map` (zona visible, `is-official`, `has-friends`) només és a la branca `feature/events-map` d'api-aprop (US #21), sense fusionar; aquesta branca no té les categories de `develop`.
  - Mapa i llista mostren conjunts diferents (backend / demostració), contra el mockup.
  - Les dades arriben en brut:
    - municipi i categoria són etiquetes sense accents («Tarrega», «Musica»);
    - no hi ha imatge amb URL completa ni el nom de qui crea l'activitat;
    - la data no té hora (sempre «00.00 h»);
    - `has-friends` diu si hi va alguna amistat, no si l'ha publicada.
  - La resposta per a tot Catalunya fa ~3,5 MB (1.631 activitats amb la descripció sencera).
- **Opcions:** A) fusionar `feature/events-map` i que el backend doni nom de municipi, categoria, URL d'imatge i hora · B) adaptar-ho al client (com ara).
- **Provisionalment:** B.
  - El mapa carrega la zona visible amb un 50 % de marge i no torna a demanar una zona ja carregada. Una resposta antiga no substitueix la de la zona actual.
  - Si falla, es conserven els marcadors i surt un avís amb «Tornar-ho a provar».
  - Municipi a partir de l'etiqueta (o el lloc, si no n'hi ha), primera categoria o «Activitat», imatge per defecte i creador «un usuari» sense distintiu d'amistat.
  - Lloc i adreça com a indicacions, i preu 0 si és gratuïta.
  - Sense `API_BASE_URL`, tot continua amb les dades de demostració.
  - Apuntar-se des d'una fitxa del backend falla, perquè la inscripció de demostració no troba l'activitat (DP-010).
  - `TODO(DP-029)` marca aquestes adaptacions.
- **Token (2026-10-25):** el backend ja exigeix `Authorization: Bearer` a totes les rutes (`feature/auth` fusionada). `HttpActivityMapRepository` l'envia si `AuthRepository.currentIdToken()` en retorna un; amb els comptes de demostració és nul i no s'envia. En ajuntar-ho amb el login de Firebase (`feature/autenticacio`, ja a `develop`), `FirebaseAuthRepository.currentIdToken()` retorna el token de Firebase de la sessió (`_auth.currentUser?.getIdToken()`), que Firebase renova sol.
- **Hora (2026-11-17):** la fitxa, les targetes i l’Agenda ja no mostren «00.00 h»: llegeixen l’«Horari» (`schedule`), que el formulari omple amb l’hora triada (DP-059).
- **Apuntar-se des del mapa (2026-10-25):** la inscripció i l'Agenda buscaven l'activitat només al catàleg de demostració i fallaven amb les del backend. Amb `API_BASE_URL`, `CombinedActivityRepository` busca al backend els ID numèrics i al catàleg els `demo-…`.
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-032 · Perfil propi, edició, autoria i gamificació de demostració
- **Estat:** oberta
- **Obert per:** 2026-10-21 · Codex · Taiga #230 Frontend perfil
- **Identificador:** renumerat de DP-025 a DP-032 el 2026-10-25 en integrar `develop`, per conservar la decisió d'Auth amb el número anterior.
- **Context:** mockup `perfil_1_principal.png`, figura 18 i `features/profile/`. L'usuari autoritza el frontend i confirma la tasca #230; els criteris detallats de Taiga continuen pendents.
- **Dubte:** contractes autenticats de perfil/edició/assistència, amistats, valoració rebuda i nivells/llindars inexistents; l'autoria anterior només tenia un nom no únic. No hi ha enllaç públic de perfil ni flux d'edició detallat.
- **Opcions:** A) integrar els contractes quan estiguin acordats · B) validar el perfil propi amb una projecció demo per compte i l'autoria per ID.
- **Provisionalment:** B. La identitat sempre ve de la sessió, no es força la Núria del mockup. Només `demo-laiasoler` té la foto existent, 14 amics, valoració rebuda 4,7 i 340/500 XP d'exemple; mostra els tres plans històrics disponibles amb valoracions 5/4/5. Els nous comptes comencen sense plans fets/amics/valoració i amb 0 XP; no s'inventen llindars. Apuntar-se no confirma assistència ni dona XP. `ActivityCreator.userId` és opcional; es completa al crear activitats i al fixture de Laia, i «Creats per mi» filtra només per ID. L'edició desa biografia (≤200) i municipi (≤80) opcionals en memòria per compte; no modifica la identitat d'Auth. Compartir ofereix copiar `@username`, sense URL fictícia. Cerca d'amics i perfils aliens continuen pendents. Els mòduls, textos nous i adaptacions responsives són provisionals. `TODO(DP-032)` marca les integracions.
- **Qui decideix:** frontend + backend + responsables de perfils/gamificació
- **Resolució:**

### DP-033 · Preferències de Configuració i integracions pendents
- **Estat:** oberta
- **Obert per:** 2026-10-21 · Codex · Taiga #230 Frontend perfil
- **Identificador:** renumerat de DP-026 a DP-033 el 2026-10-25 en integrar `develop`, per conservar la decisió d'Auth amb el número anterior.
- **Context:** mockup `perfil_2_configuracio.png`, figura 19, `ProfileSettingsRepository` i pantalla Configuració.
- **Dubte:** falten contractes de preferències/privacitat, enviament de notificacions, bloquejos, Calendar, eliminació de compte, traduccions globals i tema fosc. No es pot afirmar que Calendar estigui connectat ni mostrar un proveïdor Google a l'accés demo.
- **Opcions:** A) completar cada integració dins de la seva història · B) habilitar canvis de preferències demo i mantenir explícitament pendents les accions sense servei.
- **Provisionalment:** B. Privacitat i quatre tipus d'avís s'editen amb confirmació del repositori i s'aïllen per compte durant l'execució; per defecte els plans no es comparteixen. No alteren la bústia rebuda ni despleguen permisos/push o un graf d'amistats. Català/Clar reflecteixen l'app actual; canviar idioma/tema, bloquejos, repetir test i eliminar compte estan desactivats amb explicació. Calendar mostra «No connectat». «Tancar sessió» utilitza l'Auth existent, espera confirmació i gestiona errors. No s'afegeixen paquets ni endpoints; el mode fosc i la internacionalització globals es faran en les seves històries. La UI informa que les preferències duren aquesta sessió de l'app. `TODO(DP-033)` marca els límits.
- **Qui decideix:** frontend + backend + responsables d'Auth/notificacions/Calendar
- **Resolució:**

### DP-034 · Mapa d'Inici: què fa tocar un grup de marcadors
- **Estat:** oberta
- **Obert per:** 2026-10-25 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #79 / #21
- **Context:** `ActivitiesMap` (`_onGroupTap`, `_SamePlaceSheet`), `isSamePlace` a `activity_map_groups.dart`, llegenda del mapa. En provar-ho a l'emulador, tocar un grup no feia res.
- **Dubte:** no hi ha mockup de què passa en tocar un grup. A més, moltes activitats de l'Agenda Cultural comparteixen el mateix punt exacte (a la BD local, 2.019 de 2.335 activitats amb ubicació, en 603 llocs i fins a 32 en un de sol): apropar-s'hi no les separaria mai.
- **Opcions:** A) només apropar-s'hi · B) apropar-s'hi i, si són al mateix lloc, mostrar-ne la llista · C) mostrar sempre la llista.
- **Provisionalment:** B, triada per l'usuari («que t'augmenti la pantalla»). El mapa s'apropa fins que hi caben tots els marcadors del grup, amb 64 px de marge. Si les activitats són a menys de 0,0003° (uns 30 m) entre elles, surt un full inferior «N activitats en aquest lloc» amb el municipi, les activitats ordenades per data amb la data completa, i en tocar-ne una s'obre la fitxa. Molt a prop, Google deixa d'agrupar i els marcadors d'un mateix lloc queden apilats (provat a Girona: 4 activitats a l'Auditori i només se'n podia obrir una); per això tocar un marcador que en té d'altres al mateix lloc també mostra aquesta llista en lloc de la targeta. El llindar i el disseny del full són provisionals (`TODO(DP-034)`).
- **Qui decideix:** equip
- **Resolució:**

### DP-035 · Filtres de dates i categories: dades disponibles i contracte pendent
- **Estat:** oberta
- **Obert per:** 2026-10-25 · frontend · Taiga #87 Frontend filtrar esdeveniments
- **Identificador:** renumerat de DP-034 a DP-035 en integrar la PR #22 de `develop`, per conservar la decisió publicada del mapa amb DP-034.
- **Context:** `ActivityFilters`, `ActivitiesViewModel`, panells Dates/Categories i mapa per zona. Mockups aprovats; ID i títol de Taiga confirmats, criteris detallats demanats a l'usuari.
- **Dubte:** falta contracte de consulta amb filtres i IDs canònics de categories. El mapa pot no retornar categoria (DP-029), Mapa/Llista tenen fonts diferents i `Activity` només conté inici i una categoria. Zona/municipi no té abast ni disseny confirmats.
- **Opcions:** A) backend amb filtres, metadades i catàleg compartit · B) filtratge local sobre dades disponibles, amb límits explícits.
- **Provisionalment:** B per a Dates/Categories. Un únic valor immutable a `ActivitiesViewModel` s'aplica al catàleg i a la zona carregada; sense endpoints/paràmetres nous. Interval inclusiu de dies civils basat en l'inici; categories OR i dates AND; vuit etiquetes dels mockups, coincidència tolerant a accents i sense equivalències deduïdes. Cap categoria = sense restricció. Categories no informades excloses quan se'n tria una, amb recompte visible. Cap de setmana = dissabte/diumenge actual si ja és cap de setmana, o el següent en dies laborables. Esborrany local, Aplicar confirma, tancar descarta; filtres per sessió i només d'Inici. Zona/municipi pendent. `TODO(DP-035)` al model; detalls a `docs/activity-filters.md`.
- **Qui decideix:** frontend + backend + equip (criteris i categories)
- **Actualització 2026-10-26:** la llista consulta el servidor amb dates i categories reals abans de paginar. Les opcions deixen de ser les vuit de demostració quan s’injecta HTTP. El mapa continua limitat al filtratge local i metadades absents. Detalls a DP-038; la decisió continua oberta per font compartida i abast global.
- **Actualització 2026-11-16 · #253:** el backend `6f4979e` incorpora les categories al mapa. El filtre local ja pot comprovar totes les categories rebudes i el distintiu mostra la primera etiqueta usable. Les metadades absents es continuen tractant explícitament (DP-046). La font compartida i els filtres globals de servidor segueixen pendents.
- **Resolució:**

### DP-037 · Llista real d'Inici: paginació i metadades disponibles
- **Estat:** oberta
- **Obert per:** 2026-10-26 · frontend · ampliació de la tasca #77
- **Context:** primera tasca d'integració d'Inici autoritzada per l'usuari. Només es modifica `frontend-aprop`; `api-aprop@c94ab70` s'ha consultat, sense executar-lo ni modificar-lo. Referència #77 indicada per l'usuari; cal confirmar l'estat de Taiga abans del commit.
- **Dubte:** `GET /events` retorna una llista sense total ni cursor. El backend compta pàgines des de 0 i ordena per `enddate`, sense desempatar per ID. Les imatges de Gencat poden ser relatives i separades per comes. Les dates absents es serialitzen com `0001-01-01…` (DP-013).
- **Provisionalment:** `ActivityPage` i `getActivitiesPage` mantenen la paginació fora dels widgets. Pàgines de 50, botó explícit «Carregar més activitats», final inferit per pàgina curta/buida. Es conserva l'ordre del servidor, es fusiona per ID i un lot complet sense cap ID nou ofereix reintentar la mateixa pàgina. Una recàrrega invalida les respostes antigues. No es descarrega tot el catàleg ni es fingeix un total. `Activity.imageUrl` conserva la portada remota; només les rutes `/content/dam/` es resolen contra el domini oficial verificat `agenda.cultura.gencat.cat`. Errors d'imatge mostren un placeholder; el temps zero de Go es presenta com «Data no informada», sense inventar cap data.
- **Límits:** deduplicar no garanteix exhaustivitat amb un ordre inestable del servidor; cal desempatar per ID. Cal un contracte de dates nul·les abans de poder situar plans sense data a l'Agenda. Filtres continuen locals sobre les pàgines carregades (DP-035), amb missatge de buit parcial i accés a les pàgines següents. CORS, disponibilitat de Render, categories del mapa i filtres del servidor s'han de coordinar amb backend; no es modifiquen en aquesta tasca.
- **Qui decideix:** frontend + backend + equip (ordenació i UX de paginació). Guia i comprovacions a `docs/inici-list-backend.md`.
- **Actualització 2026-10-26:** #87 passa filtres al servidor i un lot pot unir pàgines de diverses categories. Un lot sense IDs nous ja no es rebutja: pot ser un solapament legítim entre aquestes fonts. Cada acció explícita avança la pàgina; no hi ha càrrega automàtica en bucle. Es mantenen les limitacions d’ordenació de l’API.
- **Resolució:**

### DP-038 · Filtres d’Inici amb el contracte actual del servidor
- **Estat:** oberta
- **Obert per:** 2026-10-26 · frontend · ampliació de #87 Frontend filtrar esdeveniments
- **Context:** segona tasca autoritzada; només frontend. Contracte consultat a `api-aprop@c94ab70`: `/events` admet una categoria i dates; `/categories` retorna ID/nom; `/events/map` només límits geogràfics i no informa categories.
- **Dubte:** selecció múltiple OR sense paràmetre múltiple; etiquetes del mockup diferents de la taxonomia real; mapa sense metadades/filtres; dates en format Go estricte sense zona; sense ordre global estable entre consultes.
- **Provisionalment:** opcions HTTP carregades i validades des de `/categories`, cache de sessió amb reintent si falla. Etiqueta llegible del nom/últim segment del tag, sense equivalències semàntiques inventades. Noms visibles coincidents agrupen els seus IDs amb OR. La pàgina N és un lot de la pàgina N de cada categoria, amb màxim quatre peticions simultànies; resposta atòmica, deduplicació per ID i continuació si alguna font retorna una pàgina completa. Ordre determinista per ID de categoria i ordre del servidor dins de cada resposta; no es promet ordre cronològic global. Poden carregar-se més de 50 activitats en un lot de diverses categories. Totes les categories d’una activitat es conserven en un snapshot immutable. Dates civils inclusives `YYYY-MM-DDT00:00:00.000`, sense UTC. Canviar filtres reinicia a 0 i invalida respostes antigues. Refresc/error conserva dades només de la mateixa consulta.
- **Mapa:** es manté la consulta geogràfica existent i s’apliquen filtres locals a dades informades. Si falten categories, s’indica el nombre exclòs i s’ofereix «Veure llista»; no s’afirma falsament que no hi ha coincidències. No s’envien paràmetres que el servidor ignora ni es fan peticions de detall per cada marcador.
- **Actualització 2026-11-16 · #253:** PR #54 del backend fusionada a `6f4979e`: `/events/map` retorna les categories de les activitats. El frontend les llegeix amb el mapper compartit i filtra la zona carregada per qualsevol etiqueta rebuda. Prova HTTP de Mapa/Llista amb categoria secundària i IDs reals; contracte de categories resolt en codi, desplegament pendent de prova autenticada. Multiselecció en servidor i ordre global continuen oberts.
- **Qui decideix:** equip frontend/backend; demanar multiselecció i ordre estable al servidor, filtres/categories al mapa i confirmar la taxonomia visible. Guia: `docs/inici-server-filters.md`. Render ha esgotat 15 s a `/categories`; verificació autenticada pendent. No es canvia cap fitxer del backend.
- **Resolució:**

### DP-039 · Avisos HTTP: identitat real, tipus, context i dependències del servidor
- **Estat:** oberta
- **Obert per:** 2026-10-26 · frontend · ampliació de #86 Frontend pantalla notificacions
- **Context:** integració autoritzada només al frontend. Contracte de notificacions, perfils i middleware contrastat amb `api-aprop@c94ab70` i `origin/develop@d01f231`; aquests fitxers no han canviat entre les revisions. Usuari confirma accions socials fora de l’Sprint 1.
- **Dubte:** IDs de tipus generats, identitat de Firebase diferent del UUID intern, Social sense subtipus/estat, context nullable/eliminat, timestamp sense zona i rutes de notificacions sense comprovació del destinatari autenticat. No es troba cap productor automàtic de recordatoris/recomanacions al `develop` inspeccionat.
- **Provisionalment:** token i capçaleres d’una operació fixats; `/users/me` ha de retornar UUID real i correspondre al FirebaseUID/UUID sol·licitat. No es deriva ni s’inventa l’ID. DTO estricte amb propietari, ID, tipus, data i lectura; els errors no es transformen en buit. `/notificationtypes` classifica per noms definits, no IDs fixos. Social es presenta genèric; tipus desconeguts continuen a Tots com «Avís». Es consulta el context per ID únic amb màxim quatre peticions simultànies; falta de context no esborra l’avís. Activitat eliminada sense enllaç mort; error temporal permet obrir la fitxa. Reminders/recomanacions no reben actors encara que el DTO contingui `friend-id`. Dates amb offset es respecten; sense zona es mantenen locals fins a acordar la política. La lectura comprova destinatari amb GET abans de POST i només confirma després de resposta correcta; la comprovació client no substitueix l’autorització del servidor.
- **Pendent del backend:** autoritzar GET/list/read pel destinatari de la sessió i evitar confiar en l’ID rebut; establir zona horària RFC 3339 amb offset; confirmar generació de recordatoris/recomanacions si entra a l’Sprint 1, perquè només s’ha trobat creació via `POST /notifications`. La consulta de disponibilitat a `/notificationtypes` ha esgotat 15 s sense resposta HTTP. No s’han executat backend, migracions ni escriptures reals.
- **Fora de l’Sprint 1:** acceptar/rebutjar amistats, subtipus i estat de sol·licituds, graf social. L’adaptador HTTP no emet sol·licituds accionables ni simula una confirmació. Demo conserva els exemples del projecte final.
- **Qui decideix:** equip frontend/backend. Guia `docs/notifications-backend.md`; missatge revisable per comunicar `docs/notifications-backend-handoff.md`.
- **Actualització 2026-10-27 · PR #31:** sincronitzada amb `origin/develop@572612a`, que ja resol l’UID al backend. Avisos envia només bearer; desapareix `X-User-ID` i la dependència de `ApiClient.isCanonicalUuid`. La validació del UUID real es conserva al mapper; les proves comproven que no s’envia cap identitat auxiliar. Es conserven DP-040 (Perfil), DP-031 (verificació web) i la resolució de DP-036.
- **Resolució:**

### DP-040 · Perfil HTTP, capacitats i camps sense contracte
- **Estat:** oberta · 2026-10-27 · Taiga #230 Frontend perfil.
- **Context:** ampliació autoritzada del perfil propi, només frontend. Referència: handlers/models/services de `api-aprop` a `origin/develop@a67ae9e`, llegits sense modificar-los. DP-039 es reserva per a la integració d’Avisos publicada a la branca separada `feature/notifications-backend` (`8089a9d`); no es reutilitza.
- **Disponible:** `GET /users/me`, `PATCH /users/me` (nom/username/biografia/`show-plans`), `POST /users/me/avatar` i `GET /users/me/created-events`. Identitat validada amb UUID real i Firebase UID del compte; bearer capturat per operació. Sense `X-User-ID` ni dades Auth/Demo substituint errors.
- **Adaptació provisional:** metadades i creades tenen càrregues/errors independents. `plans-count` s’etiqueta «Plans», no assistències confirmades; `completed-plans-count` només compta inscripcions acabades i no omple «Plans fets». HTTP inicia «Creats per mi»; historial confirmat pendent. L’XP s’ensenya tal com arriba i el FK `level` es conserva sense assignar-lo a les cinc insígnies/llindars del mockup. Demo conserva els seus exemples.
- **Camps pendents:** municipi, historial/valoracions de plans amb assistència confirmada, metadades dels nivells i preferències de notificació. Només `show-plans` es desa al servidor; els quatre interruptors d’avisos queden pendents. Social fora del Sprint 1 segons l’usuari. Test d’interessos (amb endpoints propis), Calendar, eliminació, idioma/tema i bloquejos requereixen les seves històries; no s’integren aquí.
- **Foto:** necessitat concreta de seleccionar un fitxer per al multipart existent; s’afegeix `image_picker ^1.2.4` (plugin oficial Flutter), encapsulat darrere `ProfileImagePicker`. Només galeria; text d’accés a fotos a iOS, sense càmera/micròfon. JPEG/PNG/WebP segons S3 del backend. Màxim de 5 MiB comprovat sobre el multipart complet, abans d’enviar. Android recupera l’estat d’una selecció interrompuda però demana triar de nou: mai puja un fitxer antic automàticament.
- **Validació:** nom no buit ≤100 bytes UTF-8, biografia ≤500 bytes UTF-8 i username `[A-Za-z0-9_]{3,30}`. HTTP 409 mostra nom ocupat; només s’aplica la resposta confirmada. AppBar, compartir i crear activitat consumeixen el nom/username confirmats del perfil.
- **Qui decideix:** equip frontend/backend per tancar les diferències amb els mockups; cal prova autenticada a Render, persistència entre execucions, configuració/accessibilitat S3 i galeria en Android/iOS físic. Guia i peticions concretes: `docs/profile-backend.md`.
- **Relació:** actualitza parcialment DP-032 i DP-033; no les dona per resoltes ni completa les històries socials/gamificació.
- **Resolució:**

### DP-041 · Descobreix HTTP: preferències, seleccions i cerca paginada
- **Estat:** oberta · 2026-10-27 · Taiga #96 Frontend de cerca.
- **Context:** només frontend, branca `feature/discovery-backend` des de `60fbebc`; backend contrastat a `be6c25e`, conservat sense canvis. Actualitza parcialment DP-024; no completa social ni el frontend del test.
- **Disponible:** `GET /users/me`, `/preferences`, `/events/recommended`, `/events/popular` i `/events/search`. Bearer fixat per operació i propietat del perfil validada; sense UUID inventats ni `X-User-ID`. Seleccions inicials de 5 activitats a pàgina 0, sense afirmar que siguin exhaustives. La cerca usa pàgines de 20, també des de 0.
- **Estats:** preferències buides no criden recomanacions i s’expliquen a «Per a tu». Errors de preferències/recomanacions/populars s’indiquen per secció, preservant dades confirmades en refrescar; 401/403 són globals. Sense successos buits de JSON invàlid ni propostes oficials/comunitàries substituint el ranking.
- **Cerca:** resultat immutable amb total i continuació; es comproven query, pàgina i mida rebudes. Deduplicació per ID, una continuació alhora, reintent sobre el mateix cursor i invalidació de respostes en editar/esborrar/refrescar/sortir. Es conserven cards i cursor davant errors de pàgina. El total és el del servidor, no el recompte carregat.
- **Límits backend:** recomanacions ordena dins d’una pàgina i retorna 500 per pesos de categories absents. Populars/recomanacions no filtren activitats acabades; la cerca usa la consulta completa amb ILIKE sobre títol/lloc/municipi/descripció, sense categories ni folding d’accents de Demo. El join exterior de cerca no garanteix ordre explícit entre files; s’ha de garantir agrupació i ordre estable al servidor.
- **Provisionalment:** conservar l’ordre/dates reals i mostrar error de recomanacions sense amagar populars. El text de cerca no promet categories. La UI mostra el test pendent sense inventar un accés a una pantalla inexistent. Els nous missatges i la continuació de cerca reutilitzen estils/components del projecte. `TODO(DP-041)` marca els límits de ranking al repositori.
- **Qui decideix:** equip frontend/backend per ordre global, preferències incompletes, vigència temporal i semàntica de cerca. Guia i missatge de traspàs a `docs/discovery-backend.md`. Cal prova autenticada a Render i en Android/web; no s’ha modificat ni executat el backend.
- **Resolució:**

### DP-042 · Test d’interessos: «m’agrada» no inscriu i accés només des de Configuració
- **Estat:** oberta
- **Obert per:** 2026-10-28 · agent (Claude Code, Opus 5.5) · Taiga #99
- **Context:** `lib/features/interest_test/`, `profile_settings_screen.dart`, `main_shell.dart`; backend `GET/POST /preferences/test` (`api-aprop` `origin/develop`).
- **Dubte:** la petició diu «si llisca a la dreta li agrada i *se lo apuntamos*». S’ha interpretat com a registrar la resposta (`likes: true`), no com a inscriure l’usuari a l’activitat: el test mostra fins a 25 activitats (ordenades per ID, potser ja passades) i apuntar-se és una intenció d’assistir. Tampoc no està decidit si el test s’ha de mostrar en el primer accés (mockups) ni si cal refrescar «Per a tu» en acabar.
- **Opcions:** A) només registrar el gust (fet) · B) a més, inscriure a les activitats que agraden · C) oferir «Apuntar-m’hi» a la targeta, separat del gust.
- **Provisionalment:** A. Les respostes s’envien totes juntes en acabar (el backend només accepta el lot sencer); si falla, es conserven i es pot reintentar. Accés des de Configuració › «Tornar a fer el test d’interessos». `TODO(DP-042)` a `interest_test_screen.dart`.
- **Qui decideix:** equip / PO
- **Resolució:**

### DP-045 · Mapa a la web: els clics sobre la targeta arriben al mapa
- **Estat:** oberta
- **Obert per:** 2026-11-15 · Claude Code (Opus 5.5) a petició de l'usuari · Taiga #255 / #258
- **Context:** `ActivitiesMap._onMapTap` (`activities_map.dart`).
- **Dubte:** a la web, el mapa de Google queda per sota de Flutter i rep també els clics fets sobre la targeta, els panells i els calendaris. En prémer «M’hi apunto» a la targeta del marcador, el mapa ho prenia com un toc al mapa i la tancava. A Android no passa.
- **Opcions:** A) ignorar el toc al mapa que arriba just després d'un clic sobre qualsevol cosa de Flutter que el tapi: targeta, avís de «Desfer», diàlegs (fet) · B) el paquet oficial `pointer_interceptor`, que talla els clics damunt del mapa; serviria també per als panells i calendaris (#255), però és una dependència nova.
- **Provisionalment:** A, amb un marge de 500 ms (`_cardClickEcho`). Sense paquets nous (`TODO(DP-045)`). El mapa encara pot rebre l'arrossegament fet sobre la targeta.
- **Qui decideix:** equip (paquet nou)
- **Resolució:**

### DP-057 · Geolocalització al mapa d'Inici: paquet, permís i disseny
- **Estat:** oberta
- **Identificador:** es va obrir com a DP-049; renumerada a DP-057 en integrar develop (de la DP-047 a la DP-056 ja estan agafades).
- **Obert per:** 2026-11-17 · Claude Code (Opus 5.5) a petició de l'usuari · Taiga #266
- **Context:** `UserLocationRepository`, `GeolocatorUserLocationRepository`, `UserLocationViewModel`, `ActivitiesMap` (punt «ets aquí» i botó «La meva ubicació»), `AndroidManifest.xml`, `Info.plist`, `UserLocationTheme` a `app_theme.dart`.
- **Dubte:**
  - Cal un paquet nou per al permís i la posició (`geolocator`).
  - El mockup (fig. 7) té el botó, però no se'n coneix la posició, l'aspecte ni quan s'ha de demanar el permís.
  - A la web, Google Maps no dibuixa el punt blau (`myLocationEnabled` no hi funciona).
- **Opcions:** A) demanar el permís en prémer el botó · B) demanar-lo en obrir el mapa, com Google Maps.
- **Provisionalment:** A.
  - `geolocator` 14 per al permís i la posició a Android, iOS i web.
  - El permís només es demana en prémer el botó. Si ja s'havia donat, en obrir el mapa surt on és la persona sense preguntar res, però el mapa no s'hi mou.
  - Punt i cercle de precisió dibuixats per l'app (iguals a la web i al mòbil), en blau `#1A73E8` com Google Maps.
  - Botó rodó a baix a la dreta, per sobre d'«Assistent», que puja amb la targeta. En prémer-lo, el mapa hi va amb zoom 14.
  - Si no es pot, un avís explica per què: permís denegat; denegat per sempre (amb «Configuració» al mòbil, o com fer-ho al navegador a la web); ubicació del dispositiu desactivada (amb «Activar»).
  - Només s'escolta la posició mentre el mapa és visible, cada 10 m.
  - Textos sense mockup. `TODO(DP-057)` marca aquestes adaptacions.
- **Qui decideix:** equip (paquet nou) + disseny

### DP-046 · Categories d’Inici: entrades sense nom i catàleg buit
- **Estat:** oberta · 2026-11-15 · Taiga #253 [FE] Corregir que no es mostren les categories.
- **Identificador:** renumerada de DP-045 a DP-046 en integrar develop per conservar la decisió publicada de clics sobre el mapa.
- **Context:** filtre «Categories» compartit per Mapa/Llista a `frontend-aprop@5b0c95c`; backend consultat a `api-aprop@0fdba4f`, sense modificar-lo. El catàleg de proves existent ja inclou una fila amb nom buit, mentre que el carregador del filtre rebutjava tota la resposta quan en trobava una. Un catàleg buit també quedava en memòria durant tota la sessió i el panell no oferia reintent.
- **Provisionalment:** ometre únicament entrades amb ID vàlid i nom sense etiqueta visible; conservar noms i IDs reals de totes les altres categories, inclosos els àmbits. Un objecte invàlid, un ID invàlid, un nom que no és text o un error HTTP continuen sent errors amb reintent. Compartir peticions simultànies, conservar en memòria el catàleg no buit i permetre tornar a consultar una resposta buida des del mateix panell. `TODO(DP-046)` al repositori HTTP.
- **Mapa (actualització 2026-11-16):** PR #54 del backend fusionada a `6f4979e`, amb categories a `/events/map`. El mapper compartit elimina etiquetes sense nom visible abans de triar el distintiu i conserva totes les vàlides per filtrar. Es comproven categories secundàries i canvi de vista amb el mateix filtre, sense peticions de detall per marcador. Es manté l’avís només per activitats genuïnament sense categoria usable.
- **Verificació:** regressions de repositori i de panell HTTP des de Mapa/Llista, amb una entrada sense nom al costat de categories vàlides; reintent de catàleg buit. Tres regressions addicionals reproduïdes abans de corregir la conversió, inclòs el recorregut complet de categories del mapa. La consulta a Render sense sessió retorna 401: manca comprovació autenticada de producció; la presència del codi fusionat no acredita desplegament.
- **Qui decideix:** frontend/backend per a la neteja de dades i el contracte de categories del mapa. Guia `docs/inici-server-filters.md`.
- **Resolució:**

### DP-047 · Contrast del logotip sobre el fons de l’app
- **Estat:** oberta · 2026-11-16 · Taiga #262 [FE] Ajustar contrast i color del logotip respecte al fons.
- **Context:** el PNG original té fons crema texturat i marges amplis. Inici i Login el pintaven directament, amb un rectangle diferent del fons del tema i poca mida útil per al símbol.
- **Provisionalment:** derivació transparent del recurs existent, conservant mapa, tres marcadors, text i paleta. S’elimina el fons i es redueix el marge sense canviar el tema global. L’original queda intacte. `APropLogo` centralitza la mateixa imatge i semàntica a les dues pantalles, mantenint alçades de 80 i 96 píxels lògics respectivament. El mode fosc queda fora d’aquesta tasca.
- **Verificació:** dues proves reprodueixen el fons opac abans del canvi i comproven transparència i contrast del color majoritari del logo sobre les superfícies clares després. Revisió visual de captures renderitzades amb Flutter. Guia `docs/branding.md`.
- **Qui decideix:** equip/PO per validar l’edició visual de marca; la representació és reversible perquè es conserva el recurs original.
- **Resolució:**

### DP-056 · Recuperar la contrasenya: disseny i textos sense mockup
- **Estat:** oberta
- **Identificador:** es va obrir com a DP-047; renumerada a DP-056 en integrar develop (la DP-047 és el logotip i de la DP-048 a la DP-055 ja estan agafades).
- **Obert per:** 2026-11-16 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #263 (US #11)
- **Context:** `ForgotPasswordScreen`, `ForgotPasswordViewModel`, enllaç «Has oblidat la contrasenya?» de `LoginScreen`, `AuthRepository.sendPasswordResetEmail`.
- **Dubte:** no hi ha mockup de la pantalla. La tasca #118 (Arnau) descrivia el mateix frontend; l'usuari ho fa tot a la #263 i avisa l'Arnau.
- **Provisionalment:** pantalla pròpia amb el mateix estil que «Verifica el teu correu». Si al login hi ha escrit un correu, ja hi ve. Després d'enviar, sempre es mostra el mateix missatge («Si hi ha un compte amb aquest correu…»), sense revelar si el compte existeix (CA2): si Firebase respon `user-not-found`, es tracta com un enviament correcte. Espera de 60 s entre enviaments, com a la verificació. La contrasenya nova es tria a la pàgina de Firebase que obre l'enllaç (correu en català). `TODO(DP-056)` a la pantalla.
- **Qui decideix:** equip (disseny)

### DP-048 · Navegació de les fitxes obertes des del xat
- **Estat:** oberta · 2026-11-16 · Taiga #261 [FE] Amagar menú de navegació inferior en obrir el xat.
- **Context:** la tasca demana explícitament ocultar el menú en obrir l’Assistent. Les recomanacions poden obrir una fitxa sobre el xat, mentre que els mockups anteriors mostraven navegació inferior a les fitxes.
- **Dubte:** mantenir el flux del xat sense barra també en aquestes fitxes o tornar-la a mostrar temporalment.
- **Provisionalment:** mantenir-la amagada fins a sortir de `/assistant`. Això conserva la seqüència xat → fitxa → xat → Inici; les fitxes obertes des de les seccions habituals continuen amb barra. `TODO(DP-048)` a `MainShell._openAssistant`. La conversa i les inscripcions mantenen els ViewModels compartits.
- **Verificació:** recorregut d’inscripció des del xat, fitxa i retorn; restauració de barra amb fletxa, retorn del sistema i dreceres a Agenda/Configuració.
- **Qui decideix:** equip/PO a la revisió visual de #261. Ocultar la barra al xat ja és el requisit explícit; només queda oberta la fitxa que s’hi obre a sobre.

### DP-059 · Horari i informació extra de les activitats no oficials
- **Estat:** oberta · 2026-11-17 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #189
- **Identificador:** es va obrir com a DP-051; renumerada a DP-055 i després a DP-059 en integrar develop (la DP-054 i la DP-055 són de #28, idiomes).
- **Context:** formulari «Crea una activitat» / «Edita l’activitat» (`CreateActivityViewModel`), `activity_json_mapper.dart`, targetes, Agenda i fitxa. Backend consultat a `api-aprop@develop` sense modificar-lo: `POST /events` i `PUT /events/{id}` desen `schedule`, `modality`, `permanent` i `activity-url`.
- **Decisions de l’usuari:**
  - **Hora:** `start-date` només desa el dia (DP-029), i l’app mostrava sempre «00.00 h». Ara es mostra l’«Horari» (`schedule`); si no n’hi ha i l’hora és 00.00, només surt el dia. En crear o editar, l’horari es genera amb les rodes, en el format d’hora de l’idioma actiu («19.00 h», o «19.00 h – 21.00 h» si acaba el mateix dia) i s’hi pot afegir un text opcional («19.00 h · Durada: 1 h», màxim 120 caràcters).
  - **Categories:** fins a 3 per activitat (DP-018). Les targetes i l’Agenda mostren la primera i «+N»; la fitxa, totes.
  - **Formulari:** «Modalitat» (Presencial / En línia / Les dues), amb un enllaç opcional per connectar-s’hi si no és presencial, i «Activitat permanent».
  - **Només es mostren (no al formulari):** web, enllaços relacionats, entrades, correu i telèfon. Correu i telèfon no es demanen a les activitats no oficials per privadesa.
- **Dubtes:**
  - La modalitat s’envia amb els valors de l’`enum` de la BD (`Face-to-Face`, `Online`, `Online and Face-to-Face`); no hi ha contracte escrit.
  - En editar, l’hora d’inici (i de fi) es llegeix del principi de l’horari (accepta «19.00 h», «19:00 h» i «19:00»), perquè el backend la torna a 00.00; el text que la segueix és la nota opcional. Si l’horari s’ha escrit d’una altra manera, es mostra sencer com a nota.
  - Les activitats de l’Agenda Cultural tenen l’horari en text lliure i pot ser llarg: a les targetes se’n mostra la primera línia (màxim 40 caràcters).
- **Codi:** `TODO(DP-059)` al mapper (valors de `modality`) i a la generació de l’horari.
- **Qui decideix:** frontend + backend (valors de `modality`)
- **Resolució:**

### DP-060 · Pestanyes Inici i Mapa (#273): desviació del mockup
- **Estat:** oberta · 2026-11-20 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #273
- **Context:** `MainShell` (barra inferior, capçaleres i botons flotants), `DiscoverScreen`, `ActivitiesHeader`.
- **Dubte:** al mockup, Inici és el mapa/llista i Descobreix és una pestanya a part. La tasca #273 els intercanvia.
- **Decisions de l’usuari:**
  - Pestanyes: «Inici» (icona de casa) mostra les recomanacions de Descobreix; «Mapa» (icona de mapa), al lloc on era Descobreix, mostra el mapa i la llista. Clau nova `navMap`.
  - Capçalera d’Inici: «AProp!» (el logotip) al centre, el «+» per crear una activitat a l’esquerra i la lupa de la cerca a la dreta. El camp de cerca que hi havia a dalt de les recomanacions desapareix, perquè ja hi és la lupa.
  - El botó «Assistent» surt a Inici i al Mapa; l’assistent s’obre a la pestanya on es prem. El «+» ja no surt al Mapa.
- **Deduït (sense confirmar):**
  - Els enllaços de l’assistent `home` i `discover` porten tots dos a Inici, perquè ara Inici mostra Descobreix. Cap enllaç no porta al Mapa.
  - La pestanya «Mapa» continua obrint-se amb la llista (DP-022: si Google Maps falla, l’app no queda bloquejada). La #274 la deixa només amb el mapa i la llista com a reserva.
  - El logotip de la capçalera d’Inici fa 40 px d’alçada (cap en una barra de 56 px); DP-047 fixava 80 px quan era a la pantalla. Validació de marca pendent.
  - En crear o editar una activitat, les recomanacions d’Inici es tornen a carregar; en tornar del formulari es veu Inici, no la llista.
  - El feed d’Inici deixa 96 px al final perquè el botó «Assistent» no tapi l’última targeta.
- **Qui decideix:** equip (disseny)
- **Resolució:**

### DP-061 · Mapa a pantalla completa (#274): sense llista ni capçalera
- **Estat:** oberta · 2026-11-20 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #274
- **Context:** `ActivitiesScreen`, `MapFilterBar` (nou; substitueix `ActivitiesHeader`), `google_maps_availability*.dart`, `MainShell`.
- **Decisions de l’usuari:**
  - La pestanya Mapa és només el mapa, a tota la pantalla i sense capçalera. A sobre hi suren el camp «Cerca activitats» (obre la cerca, a la mateixa pestanya) i una sola fila de xips que es desplaça: Dates, Categories i, si hi ha filtres, un xip només amb la icona per treure’ls.
  - Ja no hi ha llista ni selector Mapa / Llista. Per complir el CA3 de la #21 (si Google Maps falla, l’app no queda bloquejada), la llista surt en lloc del mapa quan Google Maps no es pot dibuixar.
- **Deduït (sense confirmar):**
  - «No es pot dibuixar» vol dir que a la web no s’ha carregat el script de Google Maps (`google.maps`, p. ex. sense clau). Al mòbil el mapa és del sistema i es considera sempre disponible: sense clau surt gris i no se’n pot detectar l’error.
  - Els xips mostren la selecció en lloc del nom del filtre («Avui», «Música»), com a Google Maps.
  - Desapareix el xip desactivat «Catalunya» (filtre d’ubicació encara no fet); el botó «La meva ubicació» ja és al mapa.
  - L’avís d’activitats sense categoria ja no ofereix «Veure llista».
  - `ActivitiesViewModel` continua carregant el catàleg per als filtres i per al mapa sense backend, encara que no hi hagi llista.
- **Qui decideix:** equip (disseny)
- **Resolució:**

## Resoltes

### DP-058 · Enllaços de la fitxa: obrir-los amb `url_launcher`
- **Estat:** resolta · 2026-11-17 · Claude Code (Opus 5.5) · Taiga #189 (feedback de l’edició d’esdeveniments)
- **Identificador:** es va obrir com a DP-050; renumerada a DP-054 i després a DP-058 en integrar develop (la DP-050 és la fiabilitat visible, #204, i la DP-054 és de #28, idiomes).
- **Context:** `activity_details_screen.dart` (`_ActivityLinkRow`). La fitxa mostra la secció «Enllaços»: l’enllaç per connectar-s’hi, la web de l’activitat (`url`), «Informació d’accés» (`tickets-url`; no es diu «Entrades» per evitar vocabulari transaccional) i els enllaços relacionats (`related-urls` amb els noms d’`url-names`), sense repetir cap adreça.
- **Dubte:** per obrir un enllaç al navegador cal el paquet `url_launcher`, i l’equip no hi ha afegit paquets sense una necessitat concreta.
- **Opcions:** A) afegir `url_launcher` i obrir-los · B) només copiar-los al porta-retalls.
- **Provisionalment (primer):** B, amb `TODO(DP-058)`.
- **Qui decideix:** equip
- **Resolució:** A, per decisió de l’usuari (2026-11-17). S’afegeix `url_launcher` (`lib/core/links/open_external_link.dart`, injectat a `ActivityDetailsScreen` com a `openLink`). Tocar un enllaç l’obre fora de l’app (navegador o app que li correspon); si no es pot, surt «No s’ha pogut obrir l’enllaç.». El botó del costat el continua copiant. A Android s’hi declaren els `<queries>` d’`http`/`https`. Desapareix el botó desactivat «Consultar informació original»: la font continua a la fitxa com a text.

### DP-031 · Enllaços de verificació amb la clau d'API antiga
- **Estat:** resolta 2026-11-09
- **Obert per:** 2026-10-25 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #73
- **Context:** `VerifyEmailScreen`, `VerifyEmailViewModel`, `AuthRepository.verifyEmailWithLink`, `verificationCodeFromLink`. Relacionada amb DP-004. Els números DP-027, DP-029 i DP-030 són a altres branques sense fusionar.
- **Dubte:** en renovar la clau (DP-004) es va esborrar la «Browser key» original, però Firebase Authentication la continua posant als enllaços dels correus (`client.apiKey` de la configuració, de només lectura: ni la consola ni l'API la deixen canviar). La pàgina de Firebase que obre l'enllaç falla i diu «ha caducat o ja s'ha fet servir»: ningú no pot verificar el correu fent clic a l'enllaç.
- **Opcions:** A) demanar al suport de Firebase que hi associïn la clau nova · B) projecte de Firebase nou · C) recuperar la clau antiga restringida a `aprop-919ec.firebaseapp.com` · D) enganxar l'enllaç a l'app (com ara) · E) pàgina pròpia per als enllaços a Firebase Hosting.
- **Provisionalment:** D, triada per l'usuari (descarta C i E): a «Verifica el teu correu» es pot enganxar l'enllaç del correu; l'app en treu el codi (`oobCode`) i el confirma amb `applyActionCode` i la clau de l'app. Fer clic a l'enllaç continua fallant. `TODO(DP-031)` al repositori i a la pantalla.
- **Opció E en curs (2026-10-27, Claude Code (Opus 5.5) amb confirmació de l'usuari, Taiga #73):** l'usuari descarta pegar l'enllaç perquè queda lleig i prova una pàgina pròpia per als enllaços:
  - si la web s'obre amb `?mode=…&oobCode=…`, `main.dart` en treu l'`EmailAction` i `APropApp` mostra `EmailActionScreen` en lloc de l'inici de sessió;
  - `AuthRepository.confirmEmailVerification` confirma el codi amb `applyActionCode` i la clau de l'app, **sense sessió** (l'enllaç sovint s'obre al navegador del mòbil); si la web ja tenia la sessió del compte, també entra;
  - «Continua a AProp!» passa a l'app normal. Altres tipus d'enllaç (p. ex. `resetPassword`) mostren que no es poden obrir aquí;
  - no es neteja l'adreça: si es recarrega la pàgina, el codi ja s'ha fet servir i surt l'avís de caducat;
  - textos i disseny sense mockup (`TODO(DP-031)`).
  Falta, en aquest ordre: publicar la web amb el canvi a `frontend-aprop.onrender.com`; afegir-hi el domini a *Authorized domains* de Firebase; posar `https://frontend-aprop.onrender.com/` a *Templates → Personalitza l'URL d'acció* (vegeu `docs/firebase-auth.md`); provar-ho amb un compte nou. Quan funcioni, treure l'opció d'enganxar l'enllaç (D) i resoldre aquesta DP amb E.
- **Qui decideix:** equip
- **Resolució:** C, a Google Cloud (2026-11-07, l'usuari). S'ha restaurat la clau antiga, la que Firebase posa als enllaços, i s'ha restringit a llocs web (`aprop-919ec.firebaseapp.com`, `aprop-919ec.web.app`, `frontend-aprop.onrender.com`) i a les API Identity Toolkit i Token Service. Ara la pàgina de Firebase verifica el correu en fer clic a l'enllaç. També s'ha configurat un SMTP propi amb un Gmail de l'equip, però no desbloqueja l'URL d'acció (`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`, pla Spark): E no és possible. El 2026-11-09 (Taiga #73) s'esborren l'opció d'enganxar l'enllaç (D) i la pàgina pròpia (E): `EmailActionScreen`, `EmailAction`, `AuthRepository.verifyEmailWithLink`, `confirmEmailVerification`, `verificationCodeFromLink` i `AuthFailure.invalidVerificationLink`. **No esborreu la clau restaurada:** sense ella, els enllaços tornarien a fallar.

### DP-036 · Format UUID de `X-User-ID` i sincronització d'UID de Firebase a Render
- **Estat:** resolta 2026-10-26
- **Obert per:** 2026-10-25 · Antigravity · Taiga #231
- **Identificador:** renumerat de DP-034 a DP-036 en integrar `develop` (PR #22 i #24), que ja feien servir DP-034 i DP-035.
- **Context:** `ApiClient.toCanonicalUuid` (`lib/core/network/api_client.dart`), `HttpEnrollmentRepository`, `main.dart`; `api-aprop` (`normalizeUserID` a `event_service`, `signup_service`, `assistant_service`).
- **Dubte:** en mode tolerant a Render (sense `FIREBASE_CREDENTIALS_FILE`), el middleware d'autenticació llegeix la capçalera `X-User-ID`, però els serveis d'esdeveniments, inscripcions i assistent validen que l'identificador d'usuari tingui format UUID canònic de 36 caràcters (`8-4-4-4-12`), mentre que els UID de Firebase Auth fan 28 caràcters alfanumèrics (i els comptes demo tenen prefix `demo-...`), provocant `HTTP 400: {"error": "invalid user id"}`.
- **Opcions:** A) que el backend resolgui sempre el `firebase_uid` cap a l'UUID intern de `Users` al middleware o accepti `firebase_uid` als serveis · B) transformar de manera determinista qualsevol identificador no UUID a un UUID v4 canònic al client (`ApiClient.toCanonicalUuid`) quan s'envia `X-User-ID`.
- **Provisionalment:** B (`TODO(DP-036)` a `lib/core/network/api_client.dart`), de manera que les peticions a Render amb `X-User-ID` funcionen tant amb UID de Firebase com amb comptes de demostració sense fallar per validació d'UUID.
- **Qui decideix:** backend + frontend
- **Resolució:** A, al backend. `fix/resolve-user-id` (PR #36 d'api-aprop, Tasca #237, Wen) i `feature/esdeveniment-no-ofi` (PR #35, Tasca #236, Arnau) tradueixen l'UID de Firebase del token a l'UUID de `users` (`requester.ID`, `EventService.ResolveUserID` amb `GetByFirebaseUID`) a inscripcions, crear esdeveniments, xatbot i preferències. `X-User-ID` només es llegeix quan el backend funciona sense Firebase. Al frontend (2026-10-26, Taiga #82) ja no s'envia `X-User-ID`: l'usuari surt només del token. `AppUser.serverId` (l'`id` de `POST /auth/sync`) es continua fent servir per a `GET /users/{id}/events` i com a clau de les inscripcions.

### DP-043 · Xatbot: botó `interest-test` i entrada de veu
- **Estat:** parcialment resolta 2026-11-08 (`interest-test` integrat amb `InterestTestScreen` de la PR #35; entrada de veu pendent de paquet de dictat).
- **Context:** `AssistantScreenTarget.fromApi` (`assistant_message.dart`), `_openAssistantTarget` (`main_shell.dart`); contracte `api-aprop/api/openapi.yaml` (`AssistantAction`).
- **Dubte:** el backend pot enviar `screen: interest-test`. A `develop` ja hi ha la pantalla del test d'interessos (PR #35). Entrada de veu: cal triar paquet de dictat.
- **Provisionalment:** `interest-test` obre la pantalla de test d'interessos (`InterestTestScreen`) des de la secció de Perfil (`_openInterestTest`). La veu continua desactivada.
- **Qui decideix:** equip frontend i l'usuari (paquet de veu).

### DP-044 · Assistent: recomanacions amb fila compacta
- **Estat:** oberta 2026-11-07
- **Context:** `assistant_activity_tile.dart`; el mockup 10 (`docs/ai/50-ui-mockups.md`) diu «targeta estàndard».
- **Dubte:** la targeta estàndard (~330 px) deixa veure només una activitat per pantalla al xat.
- **Provisionalment:** fila compacta (miniatura 72 px, títol, municipi · data i la mateixa acció d'apuntar-se). Mateix estat d'inscripcions, mateix detall en tocar. Sense avatar del creador ni «Font». `TODO(DP-044)`: confirmar amb l'equip/mockup.
- **Qui decideix:** equip frontend (UX)

### DP-065 · Llista d’amics (#54): una petició per amic i sense privacitat
- **Estat:** oberta · 2026-11-20 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #197 (història #54)
- **Context:** `FriendsListScreen`, `FriendsListViewModel`, `HttpFriendsRepository`, `DemoFriendsRepository`, `ProfileHeader` (comptador «Amics»). Backend consultat a `api-aprop@develop` sense modificar-lo: `GET /users/{id}/friends` (i `me`).
- **Decisions de l’usuari:**
  - L’API només retorna els identificadors dels amics. L’app demana el perfil de cada amic (`GET /users/{id}`, de 4 en 4, com els Avisos): 1 + N peticions. Si el backend retornés nom, `username` i foto, només canviaria `HttpFriendsRepository`.
  - El comptador «Amics» obre la llista al perfil propi i també al d’altres persones. Qualsevol la pot veure: el backend no té cap opció de privacitat per als amics.
- **Deduït (sense confirmar):**
  - Un amic que ja no existeix (404) no surt a la llista; qualsevol altre error fa fallar la càrrega, amb reintent.
  - A la pròpia llista no hi surts tu; a la d’una altra persona sí, si en sou amics, i en tocar-te s’obre la pestanya Perfil.
  - Demo: els amics del compte són els exemples marcats com a amics (Laia i Júlia), i Laia i Júlia són amigues entre elles. El comptador de Laia (14) no coincideix amb la llista.
- **Codi:** `TODO(DP-065)` a `http_friends_repository.dart` i `demo_public_profile_repository.dart`.
- **Qui decideix:** backend (dades dels amics a `/users/{id}/friends`) + equip (privacitat de la llista)
- **Resolució:**

### DP-064 · Botó d’amistat al perfil d’una altra persona (#160)
- **Estat:** oberta · 2026-11-20 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #160 (història #33)
- **Context:** `PublicProfileScreen`, `PublicProfileViewModel`, `HttpPublicProfileRepository.sendFriendRequest`. Backend consultat a `api-aprop@develop` sense modificar-lo: `POST /users/{id}/friend-requests`.
- **Decisions de l’usuari:** botó amb tres estats: «Afegeix com a amic» → (enviant) → «Sol·licitud enviada» (desactivat); «Amics» (desactivat) si ja ho sou. No surt al perfil propi ni amb un bloqueig. Si el servidor diu que ja hi ha una sol·licitud, passa a «Sol·licitud enviada».
- **Dubtes (contracte del backend):**
  - Tots els rebuigs (sol·licitud pendent, ja amics, bloqueig, a un mateix) són un 400; l’app els distingeix pel text de l’error. Si el backend canvia el text, el rebuig es mostra com un error que es pot tornar a provar. Caldria un codi d’estat (p. ex. 409) o un camp `code`.
  - `GET /users/{id}` no diu si hi ha una sol·licitud pendent ni si hi ha un bloqueig. En obrir el perfil surt «Afegeix com a amic» i l’app ho descobreix quan el servidor la rebutja. La pantalla recorda la sol·licitud mentre és oberta.
  - «Ja hi ha una sol·licitud» pot ser una que t’ha enviat l’altra persona; també es mostra «Sol·licitud enviada». Es podria indicar que la responguis a Avisos amb `GET /users/me/friend-requests`.
  - Amb bloqueig no hi ha botó i un text diu que no hi pots enviar una sol·licitud.
- **Deduït:** en Demo, les sol·licituds enviades es recorden durant l’execució; Laia i Júlia ja són amigues.
- **Codi:** `TODO(DP-064)` a `http_public_profile_repository.dart` i `public_profile_view_model.dart`.
- **Qui decideix:** backend (codis d’error i estat de la sol·licitud a `GET /users/{id}`)
- **Resolució:**

### DP-063 · Perfil d’una altra persona (#277): plans fets, privacitat i dades Demo
- **Estat:** oberta · 2026-11-20 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #277 (història #36, CA3)
- **Context:** `PublicProfileScreen`, `HttpPublicProfileRepository` i `DemoPublicProfileRepository`. Backend consultat a `api-aprop@develop` sense modificar-lo: `GET /users/{id}` (amb `is-friend` i `plans-visible`), `GET /users/{id}/created-events` i `GET /users/{userId}/events`. No hi ha mockup del perfil d’una altra persona.
- **Decisions de l’usuari:** es fa com la fig. 18, sense «Editar perfil» ni engranatge; «Compartir perfil» copia el `username`. S’obre des de «Veure perfil» de la fitxa i des dels avisos d’una persona. La cerca de persones continua desactivada (DP-024) i el botó d’amistat és la #160.
- **Deduït (sense confirmar):**
  - «Plans fets» són les inscripcions de `GET /users/{id}/events` que ja han començat, de més nova a més antiga: l’API no confirma l’assistència (com a DP-053).
  - Els plans només es demanen si el servidor diu `plans-visible: true`; si el camp falta, es tracten com a privats. Si són privats, el text diu «no comparteix els seus plans» quan `is-friend` és cert i «només els poden veure els seus amics» si no.
  - Sense plans visibles, el perfil s’obre a «Creats»; amb plans, a «Plans fets».
  - No es mostren la barra d’XP ni les insígnies d’una altra persona; l’API només dona `level` com a identificador (DP-040).
  - Si l’ID és el de la mateixa persona, «Veure perfil» porta a la pestanya Perfil.
  - Demo: Laia (amiga, plans visibles), Marc (no amic) i Júlia (amiga, plans ocults) són exemples fixos, sense graf d’amistats.
- **Risc del backend:** `GET /users/{userId}/events` no comprova la privacitat; qualsevol que cridi l’API veu els plans d’una altra persona. L’app respecta `plans-visible`, però la protecció ha de ser al servidor.
- **Codi:** `TODO(DP-063)` a `http_public_profile_repository.dart`, `demo_public_profile_repository.dart` i `public_profile_screen.dart`.
- **Qui decideix:** equip (què és un «pla fet») + backend (privacitat de `/users/{id}/events`)
- **Resolució:**

### DP-062 · Xat de l’activitat (#26): sense temps real i disseny sense mockup
- **Estat:** oberta
- **Obert per:** 2026-11-20 · Claude Code (Opus 5.5) a petició de l'usuari · Taiga #26 / #148
- **Identificador:** la DP-060 (#273) i la DP-061 (#274) són a branques sense fusionar; es fa servir DP-062 per no col·lidir-hi.
- **Context:** `lib/features/activity_chat/` (`ActivityChatScreen`, `ActivityChatViewModel`, `HttpActivityChatRepository`), botó «Xat de l’activitat» d’`ActivityDetailsScreen`, `MainShell._openActivityChat`.
- **Dubte:**
  - El backend (`GET`/`POST /events/{id}/messages`, #147) no avisa dels missatges nous: no hi ha websockets ni cap altre mecanisme de temps real.
  - Els missatges no tenen identificador.
  - El mockup (fig. 9) només mostra el botó; no hi ha disseny de la pantalla del xat.
- **Opcions:** A) demanar els missatges nous cada pocs segons mentre el xat és obert (fet) · B) temps real al backend (websockets o SSE), fora de l’abast actual.
- **Provisionalment:** A.
  - Cada 5 s es torna a demanar la pàgina més recent i s’hi afegeixen els missatges nous; quan es tanca el xat, s’atura. Si falla, es torna a provar sense avisar. Mai no hi ha dues peticions de refresc alhora, i mentre l’app és en segon pla no se’n fa cap; en tornar, es refresca de seguida (revisió de la PR #59).
  - Un missatge s’identifica per autor i data d’enviament: el backend no deixa enviar-ne dos al mateix instant (409).
  - Pàgines de 50, de la més recent a la més antiga, amb «Veure missatges anteriors». Les pàgines van per posició: la que es demana es calcula amb els missatges que ja es tenen, perquè els nous no la desplacin. Si n’arriben més de 50 entre dos refrescos (per exemple, després d’un tall llarg), pot quedar un forat a l’historial sense cap avís; ho resoldria una paginació per data al backend (`before=<date-sent>`), que no existeix.
  - Si arriben missatges mentre es llegeix l’historial, la llista es desplaça (els nous entren a baix). Es podria mostrar «Missatges nous ↓» en lloc de moure-la; queda per a la revisió visual.
  - Pantalla completa per sobre de la barra inferior, com el xat de l’Assistent (#261). Missatges propis a la dreta (color principal) i dels altres a l’esquerra amb el nom. Hora al peu: només l’hora si és d’avui, «Ahir · …» o la data si és més antic. No es mostra la foto de perfil.
  - Màxim 1.000 runes (punts de codi), com compta el backend: un emoji compost en pot ocupar més d’una. El camp talla el text sense partir cap caràcter i el comptador només surt a prop del límit. Si el backend rebutja el text (400), es diu que és massa llarg, no que es torni a provar.
  - Sense inscripció, el botó de la fitxa queda desactivat i el backend respon 403, que es mostra com a avís amb «Tornar a la fitxa» en lloc de reintentar.
  - Un missatge sense data vàlida es descarta i no amaga la resta de la pàgina.
  - Sense backend, un xat de demostració en memòria.
  - Textos i disseny sense mockup. `TODO(DP-062)` al ViewModel.
- **Qui decideix:** equip + disseny (temps real: backend)
- **Resolució:**

### DP-053 · Valoració d'activitats (#185): requisit d'assistència i contracte de #184
- **Estat:** oberta 2026-11-17
- **Context:** `features/ratings/`, `_buildRating` a `main_shell.dart`; R8–R10 (`docs/ai/20-model-domini.md`); mockup 13 «Com va anar?».
- **Dubte:** (1) el `develop` del backend ja té `PATCH /events/{id}/enrollment/attendance` (`{"attendance": true|false|null}`), però el frontend encara no modela ni té UI per confirmar l'assistència («Sí, hi vaig anar»); R10 exigeix assistència certa per valorar. (2) #184 (`POST /events/{id}/ratings`, `{score}`) respon `409` (ja valorada), `403` (sense assistència) i `404` (no trobada) a `feature/event-rating` (PR #59), però encara no és desplegat a Render i no hi ha consulta prèvia de la valoració pròpia.
- **Actualització (2026-11-21, #64):** les estrelles només surten si la persona ha contestat «Sí, hi vaig anar» a «Com va anar?» (DP-068); el punt (1) queda resolt al frontend.
- **Provisionalment (abans de #64):** les estrelles surten a la fitxa i a l'Agenda si l'usuari és inscrit i l'activitat ja ha començat (sense data de fi al model: `startsAt` fa de substitut, de manera que l'usuari pot valorar durant l'esdeveniment; R10 només es compleix al servidor); el servidor farà valdre R8–R10. `main.dart` injecta `HttpRatingRepository` quan `ApiConfig.isConfigured` és cert (mentre #184 no estigui desplegat, valorar mostrarà l'error de desament), i tradueix `409` a `AlreadyRatedException`. En mode Demo, `DemoRatingRepository` (en memòria) és el per defecte. Sense consulta prèvia de la valoració pròpia, l'estat «ja valorada» abans d'enviar només es coneix en Demo durant la sessió o en rebre `409`. `TODO(DP-053)` al codi.
- **Qui decideix:** equip (frontend i backend)

### DP-049 · Fiabilitat de l'organitzador (#203): recàlcul en Demo i contracte HTTP
- **Estat:** oberta 2026-11-17
- **Context:** `ActivityRating` (organitzador destacat), `DemoProfileRepository.organizerRating`; `/fiabilitat` = mitjana de les valoracions dels esdeveniments NoOficial creats per l'usuari (R9/R10, `docs/ai/20-model-domini.md`).
- **Dubte:** (1) en Demo, què passa amb el 4,7 sembrat del compte d'exemple quan arriben valoracions reals; (2) amb HTTP no es coneix cap endpoint de valoració ni si `reliability` es recalcula al servidor en valorar (#184).
- **Provisionalment:** Demo: `organizerRating` = mitjana de les puntuacions de `DemoRatingRepository` dels esdeveniments comunitaris creats per l'usuari; si cap no està valorat, queda el sembrat (4,7 només al compte d'exemple, `null` als altres). Amb la primera valoració real el sembrat se substitueix. Només compta el que es valora en aquesta sessió. HTTP: sense canvis; el perfil es torna a carregar en obrir la pestanya Perfil (`MainShell._selectDestination`) i mostra el `reliability` del servidor. `TODO(DP-049)` al codi. L'organitzador no pot valorar el seu propi esdeveniment (no hi ha cap regla R que ho digui; s'oculta per no inflar la pròpia fiabilitat, comparant `creator.userId` amb l'id de Firebase i el del servidor). Sense `creator.userId` es mostra el bloc genèric. El perfil de Demo depèn de `DemoRatingRepository` concret (cablejat provisional a `auth_gate`); caldria un contracte de lectura.
- **Qui decideix:** equip (frontend i backend)

### DP-050 · Fiabilitat visible (#204): contracte `creator-reliability` i valors deduïts
- **Estat:** oberta 2026-11-18
- **Context:** `ActivityCreator.reliability`, `activityFromJson`, bloc «Publicat per» de la fitxa (mockup 9) i tercer comptador de `ProfileHeader` (mockup 18).
- **Dubte:** (1) `GET /events/{id}` publica `creator-name`/`creator-reliability` a `api-aprop` (`float32` nul·lable a `api/openapi.yaml` del `develop` del backend); (2) què vol dir un `0`; (3) l'etiqueta i el text del bloc.
- **Provisionalment:** `creator-reliability` = nombre finit 0–5 o nul; un valor no vàlid s'ignora (`reliability` nul) en lloc de fer fallar tota l'activitat. Com al perfil, `0` es tracta com a «sense valoracions» (les valoracions són 1–5). Nul → «—» als dos llocs, sense estrella. Text del bloc: «Fiabilitat 4,7 ★»; etiquetes Semantics «Fiabilitat de l'organitzador: …». El tercer comptador del perfil ja existia («Valoració»); només s'hi ha afegit Semantics i el format compartit (`core/formatters/reliability_formatter.dart`). Demo: el 4,7 sembrat de Laia Soler a l'activitat demo coincideix amb el perfil, però no es recalcula amb les valoracions de la sessió (DP-049 queda oberta, no es resol).
- **Qui decideix:** equip (frontend i backend)

### DP-052 · Modificar o eliminar la valoració pròpia (#206): contracte de #205 i estat inicial
- **Estat:** oberta 2026-11-18
- **Context:** `features/ratings/` (`RatingRepository.updateRating`/`deleteRating`, `ActivityRating`), `ApiClient.put`/`putJson`; contracte `api-aprop-205/api/openapi.yaml` (`PUT`/`DELETE /events/{id}/ratings/me`, branca de #205 sense fusionar ni desplegada). Es basa en #185 (DP-053), ja a `develop`.
- **Dubte:** (1) cap endpoint no retorna la valoració pròpia (DP-053): l'app no sap el `score` d'una valoració feta en una sessió anterior. (2) `GET /events/{id}` ja exposa `creator-reliability` (#204, DP-050), però no es torna a llegir en editar o eliminar la valoració.
- **Provisionalment:** (1) «Modifica» i «Elimina» surten sempre que l'activitat consta com a valorada (sessió actual o `409`); si el `score` és desconegut, en editar es mostren les estrelles buides i el valor nou substitueix el del servidor. (2) Després d'editar/eliminar només s'actualitza `RatingViewModel`; quan #204 mostri la fiabilitat a la fitxa/perfil, caldrà tornar-la a llegir (cal verificar si el perfil recarrega la fiabilitat en obrir-lo). `404` → `RatingNotFoundException`: es deixa de mostrar com a valorada. `TODO(DP-052)` a `http_rating_repository.dart`. (3) «Modifica» i «Elimina» també apareixen a les targetes d'Agenda, perquè el bloc de valoració és el mateix que el de la fitxa (decidit: es deixen; el requisit de #61 només esmenta la fitxa).
- **Qui decideix:** equip (frontend i backend)

### DP-054 · Canviar idioma (#28): contracte `language` al backend i sincronització
- **Estat:** oberta 2026-11-19
- **Context:** `ProfileSettingsRepository.updateLanguage`, `HttpProfileSettingsRepository`, `ApiClient.language`, `LocaleController` (`lib/core/l10n/`).
- **Dubte:** (1) el backend afegeix `language` (`ca`/`es`/`en`) a la configuració d'usuari i al `PATCH /users/me`, i el paràmetre opcional `lang` als endpoints d'`events`; el contracte encara no és al `develop` del backend ni desplegat. (2) Si el valor del servidor ha de guanyar sobre el local en entrar des d'un altre dispositiu.
- **Provisionalment:** l'idioma s'aplica a l'instant i es desa localment (`shared_preferences`, clau `ui-language`; per defecte `ca`); alhora s'envia `{"language": "<codi>"}` a `PATCH /users/me` (sense llegir-lo a la resposta). Si l'enviament falla, es manté el nou idioma i es mostra un avís. En Demo no s'envia res. No es llegeix `language` del servidor ni se sincronitza en iniciar sessió: el local és la font de veritat. `ApiClient` afegeix `?lang=<idioma actual>` a totes les peticions `events…` (si el servidor no el coneix, l'ignora). `TODO(DP-054)` a `http_profile_settings_repository.dart`.
- **Qui decideix:** equip (frontend i backend)

### DP-055 · Internacionalització (#28): textos que continuen en català
- **Estat:** oberta 2026-11-19
- **Context:** `lib/features/*/data/` (repositoris HTTP i Demo), `models/` (excepcions), ViewModels.
- **Dubte:** els models i els contractes han de ser independents de Flutter (`AGENTS.md`), i els ViewModels no tenen `BuildContext`.
- **Provisionalment:** (1) Els ViewModels, validadors i formatadors fan servir `currentL10n` (`LocaleController.active`, global) i els widgets `context.l10n`. Els missatges d'error que un ViewModel ja ha desat (p. ex. «No hem pogut carregar…») no es tornen a traduir fins al pròxim intent; els widgets sí que es redibuixen. El missatge de benvinguda de l'assistent es resol en cada renderitzat i els xips de suggeriments es tornen a demanar en canviar d'idioma. Els errors d'avatar (`AvatarSelectionException`) són un enum que el ViewModel tradueix. (2) Es queden en català: les dades de demostració (`demo_*_repository`: respostes de l'assistent, activitats, avisos), els missatges `ApiException`/`StateError` dels repositoris HTTP que no es mostren tal qual i els errors `{"error": "…"}` del backend. `updateLanguage` fa un `GET users/me` addicional abans del `PATCH` (acceptat, pendent de simplificar quan el backend ho permeti). (3) Els noms de categories i el contingut dels esdeveniments (títol, descripció) no van als ARB; la traducció d'esdeveniments és del backend (`?lang=`). (4) Mockup fig. 19 només mostrava ca/es: s'afegeix l'anglès per decisió de l'usuari.
- **Qui decideix:** equip

### DP-066 · Acceptació d’amistat i targetes rebudes sense avís automàtic (#164)
- **Estat:** oberta · 2026-11-20 · Taiga #164, història #35 · només frontend.
- **Identificador:** renumerada de DP-065 a DP-066 en integrar `origin/develop@8b4b5dd`, per conservar la DP-065 de la llista d’amics #197.
- **Context:** backend contrastat a `454e22b`. Hi ha consulta de rebudes i resposta amb data exacta; acceptar confirma l’amistat recíproca en transacció. Enviar no crea avís; la bústia només exposa Social genèric i l’historial de sol·licituds resoltes no és consultable.
- **Decisió provisional:** afegir targetes socials des de les sol·licituds rebudes, no des de text lliure. Correlació amb avisos existents per remitent i `request-date` exactes; quan manca l’avís, ID de presentació separat, sense punt de no llegit ni escriptura de lectura fictícia. Cache de confirmacions per compte durant l’execució, sense inventar històric en reiniciar. Comptadors recarregats del perfil, privacitat de plans controlada pel servidor.
- **Data:** el camp `request-date` de PostgreSQL pot ometre zona; es compara com a UTC amb `date-sent`. Les mutacions retenen el `date-sent` autoritatiu amb microsegons i UTC `Z`. Aquesta regla és només per identificar sol·licituds, no canvia l’horari general d’Avisos.
- **Textos:** distintiu inclusiu «Amiga/Amic» (guia i18n); la informació de gènere no forma part del contracte. Mateixos estats/accions amb traduccions ca/es/en.
- **Pendent backend/equip:** generar el primer avís Social amb remitent/data i definir la política de zona horària. Historial resolt i lectura de sol·licituds, si es requereixen després de reiniciar, necessiten contracte. Es conserva el risc d’autorització de lectura d’avisos de DP-039.
- **Codi:** `TODO(DP-066)` a `notification_json_mapper.dart` i `http_notification_repository.dart`. Guia: `docs/friend-requests.md`.
- **Resolució:**

**Actualització #164 de DP-023/DP-039/DP-064 (2026-11-20):** l’abast fora de l’Sprint 1 es manté com a històric. A l’Sprint 2 ja hi ha acceptació/rebuig amb HTTP i estat compartit. Les sol·licituds **rebudes** es consulten i permeten «Acceptar» al perfil; les sortints i els bloquejos continuen sense estat explícit al DTO del perfil (DP-064). No es crea ni es modifica cap endpoint.

### DP-067 · Accions rebudes i feedback de rebuig al perfil (#193)
- **Estat:** oberta · 2026-11-21 · Taiga #193, història #52 · només frontend.
- **Context:** el backend `fb266a7` ja retorna `Rejected` amb `/users/{sender}/friend-requests/{date}/deny`. #164 aporta el repositori compartit i Avisos ja té les dues accions. No hi ha mockup específic de la petició rebuda dins del perfil públic.
- **Deduït de la figura 17 i del flux existent:** afegir «Rebutjar» com a botó secundari al costat d’«Acceptar», amb Compartir a sota. Totes dues accions queden desactivades mentre es confirma la resposta; cap diàleg addicional, igual que a Avisos.
- **Després de confirmar:** mostrar «Sol·licitud rebutjada» i recuperar l’acció normal «Afegeix com a amic». No s’envia una nova petició automàticament; no es bloqueja la persona ni es canvien comptadors o privacitat. Una petició pendent posterior substitueix aquest feedback. Les confirmacions són de sessió com a DP-066, sense historial resolt inventat en reiniciar.
- **Dependència de lliurament:** branca #193 sobre `94793c2` de #164 mentre aquella PR és pendent. Per revisar només #193 es compara amb la pare; abans de fusionar #193 cap a `develop`, #164 ha d’estar integrada.
- **Codi:** `TODO(DP-067)` a `public_profile_screen.dart`. Documentació del flux a `docs/friend-requests.md`.
- **Qui decideix:** equip frontend (presentació i acció posterior al rebuig).
- **Resolució:**

### DP-068 · Confirmar l’assistència (#64): el «No» només es recorda al dispositiu
- **Estat:** oberta · 2026-11-21 · Claude Code (Opus 5.5) amb confirmació de l’usuari · Taiga #212 (història #64)
- **Context:** `features/attendance/` (`AttendanceViewModel`, `HowDidItGoCard`, `HttpAttendanceRepository`, `RememberedAttendanceRepository`), `AgendaScreen`, `_buildRating` a `main_shell.dart`. Backend consultat a `api-aprop@develop` sense modificar-lo: `PATCH /events/{id}/enrollment/attendance` (`{"attendance": true|false|null}`, 404 sense inscripció, 409 abans de començar) i `GET /events/{id}/enrollment/attendance` (`{has-attended}`).
- **Dubte:** el backend desa true/false/null, però cap resposta de lectura no torna el valor: `GET` només diu `has-attended`. L’app no pot distingir «No hi vaig anar» de «sense contestar», i el CA1 demana preguntar només en el segon cas.
- **Decisió de l’usuari:** l’app recorda al dispositiu (`shared_preferences`, per compte) les activitats contestades «No», i es demana al backend que torni el valor (per exemple, `attendance` a `GET /events/{id}/enrollment`). Quan hi sigui, només canvia `HttpAttendanceRepository` i sobra `RememberedAttendanceRepository`.
- **Limitació:** en un altre dispositiu o després de reinstal·lar, a qui va contestar «No» se li torna a preguntar.
- **Deduït (sense confirmar):**
  - «Com va anar?» surt a dalt de l’Agenda, sigui quin sigui el dia, per als plans que ja han començat (`startsAt` anterior a ara; el model no té data de fi) i sense resposta.
  - «Més tard» l’amaga fins a la propera vegada que s’obre la pestanya Agenda.
  - Si no es pot llegir l’assistència, no es pregunta (millor no preguntar que preguntar per error).
  - Les estrelles de valoració (fitxa i Agenda) surten només si s’ha contestat «Sí, hi vaig anar» (R10): substitueix el criteri provisional de DP-053.
- **Codi:** `TODO(DP-068)` a `http_attendance_repository.dart` i `main.dart`.
- **Qui decideix:** backend (tornar el valor de l’assistència)
- **Resolució:**
