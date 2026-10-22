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
- **Resolució:**

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
- **Provisionalment:** 2026-10-22: per al login s'ha seguit A amb Firebase Auth (vegeu DP-026). `flutterfire configure` genera `lib/firebase_options.dart` i `android/app/google-services.json` (projecte `aprop-919ec`). Es van versionar en un primer moment (repo privat), però el 2026-10-22 l'equip va decidir **no versionar-los**: són al `.gitignore`, la clau s'ha renovat (l'antiga queda a l'historial de la branca `feature/autenticacio`, però ja no és vàlida) i cada persona els genera amb `flutterfire configure` (`docs/firebase-auth.md`). Sense aquests fitxers l'app no compila. Pendent: restringir les claus noves (Android: paquet + SHA-1; navegador: `localhost:5000` i `aprop-919ec.firebaseapp.com`) i, si s'afegeix CI, generar-los des de secrets de GitHub.
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
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-018 · Categories de les activitats: llista i nombre per activitat
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Claude Code (Opus 5.5) · Taiga #93 / #31
- **Context:** `activity_options.dart` (`activityCategories`), `CreateActivityViewModel`, formulari «Crea una activitat».
- **Dubte:** la llista tancada de categories no està definida, i el CA1 diu «categoria (≥ 1)» mentre que el model `Activity` en té una sola.
- **Opcions:** A) una sola categoria (com ara) · B) diverses categories (cal canviar `Activity.category` i la llista, la fitxa i l'agenda).
- **Provisionalment:** una sola categoria triada d'una llista provisional (Música, Teatre, Exposicions) (`TODO(DP-018)`). L'usuari ho ha decidit així de moment per no canviar el model.
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

### DP-024 · Descobreix i cerca: contractes, seleccions i abast social
- **Estat:** oberta
- **Obert per:** 2026-10-21 · Codex · Taiga #96 Frontend de cerca
- **Context:** figures 14–16, `DiscoveryRepository`, `DemoDiscoveryRepository`, `DiscoverScreen` i `ActivitySearchScreen`. L'usuari autoritza Descobreix i la cerca d'activitats del Sprint 1; confirma el número/títol de Taiga, però els criteris detallats no estan disponibles localment.
- **Dubte:** falten el contracte de cerca/recomanacions, els criteris de coincidència/ordenació, els interessos persistits i les funcionalitats de persones/perfil.
- **Opcions:** A) integrar el contracte autenticat quan estigui acordat · B) validar primer el recorregut amb el catàleg compartit i un adaptador de demostració.
- **Provisionalment:** B, sense endpoints ni paquets nous. La selecció demo reutilitza els IDs d'exposició i teatre dels mockups, sense fingir personalització: el subtítol és «Una selecció per començar» fins que `isPersonalized` sigui cert. Es conserven les dates històriques del catàleg compartit; no són propostes actualitzades de producció. La cerca local ignora majúscules/accents/espais repetits i exigeix totes les paraules entre títol, categoria, municipi i descripció. Espera de 350 ms i enviament immediat amb el teclat. «Persones» es mostra desactivat amb explicació i l'accés inicial diu «Cerca activitats»; no es creen perfils ni amistats. La capçalera i la navegació segueixen el patró actual; missatges nous de buit/error provisionals en català. `TODO(DP-024)` marca aquestes adaptacions.
- **Qui decideix:** frontend + backend + responsables d'interessos/perfils
- **Resolució:**

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
- **Dubte:** el backend encara no desa el perfil, no comprova que el nom d'usuari sigui únic, no guarda nom i cognoms i no permet entrar amb el nom d'usuari (Firebase només accepta correu).
- **Opcions:** entrar amb nom d'usuari: A) només correu · B) endpoint públic usuari → correu · C) login fet pel backend. Nom i cognoms: A) columnes al backend · B) treure'ls del registre.
- **Provisionalment:** paquets nous `firebase_core` 5, `firebase_auth` 7, `google_sign_in` 7 i `shared_preferences` 2. Nom i cognoms al `displayName` de Firebase (separats pel primer espai); nom d'usuari desat al dispositiu; si s'escriu un nom d'usuari en lloc del correu, l'app demana el correu (`AuthFailure.emailRequired`). Android i web (Google amb `signInWithPopup` de Firebase a la web); a iOS es continuen fent servir els comptes de demostració. `TODO(DP-026)` al repositori i a `main.dart`.
- **Qui decideix:** equip + backend (contracte) · PO (criteri «usuari o correu» de #7)
- **Resolució:**

## Resoltes

(cap)
