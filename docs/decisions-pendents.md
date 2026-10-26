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
- **Apuntar-se des del mapa (2026-10-25):** la inscripció i l'Agenda buscaven l'activitat només al catàleg de demostració i fallaven amb les del backend. Amb `API_BASE_URL`, `CombinedActivityRepository` busca al backend els ID numèrics i al catàleg els `demo-…`.
- **Qui decideix:** frontend + backend
- **Resolució:**

### DP-031 · Enllaços de verificació amb la clau d'API antiga
- **Estat:** oberta
- **Obert per:** 2026-10-25 · Claude Code (Opus 5.5) amb confirmació de l'usuari · Taiga #73
- **Context:** `VerifyEmailScreen`, `VerifyEmailViewModel`, `AuthRepository.verifyEmailWithLink`, `verificationCodeFromLink`. Relacionada amb DP-004. Els números DP-027, DP-029 i DP-030 són a altres branques sense fusionar.
- **Dubte:** en renovar la clau (DP-004) es va esborrar la «Browser key» original, però Firebase Authentication la continua posant als enllaços dels correus (`client.apiKey` de la configuració, de només lectura: ni la consola ni l'API la deixen canviar). La pàgina de Firebase que obre l'enllaç falla i diu «ha caducat o ja s'ha fet servir»: ningú no pot verificar el correu fent clic a l'enllaç.
- **Opcions:** A) demanar al suport de Firebase que hi associïn la clau nova · B) projecte de Firebase nou · C) recuperar la clau antiga restringida a `aprop-919ec.firebaseapp.com` · D) enganxar l'enllaç a l'app (com ara) · E) pàgina pròpia per als enllaços a Firebase Hosting.
- **Provisionalment:** D, triada per l'usuari (descarta C i E): a «Verifica el teu correu» es pot enganxar l'enllaç del correu; l'app en treu el codi (`oobCode`) i el confirma amb `applyActionCode` i la clau de l'app. Fer clic a l'enllaç continua fallant. `TODO(DP-031)` al repositori i a la pantalla.
- **Qui decideix:** equip
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
- **Context:** `ActivitiesMap` (`_onClusterTap`, `isSamePlace`, `_SamePlaceSheet`), llegenda del mapa. En provar-ho a l'emulador, tocar un grup no feia res.
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
- **Resolució:**

## Resoltes

### DP-036 · Format UUID de `X-User-ID` i sincronització d'UID de Firebase a Render
- **Estat:** resolta 2026-10-26
- **Obert per:** 2026-10-25 · Antigravity · Taiga #231
- **Identificador:** renumerat de DP-034 a DP-036 en integrar `develop` (PR #22 i #24), que ja feien servir DP-034 i DP-035.
- **Context:** `ApiClient.toCanonicalUuid` (`lib/core/network/api_client.dart`), `HttpEnrollmentRepository`, `main.dart`; `api-aprop` (`normalizeUserID` a `event_service`, `signup_service`, `assistant_service`).
- **Dubte:** en mode tolerant a Render (sense `FIREBASE_CREDENTIALS_FILE`), el middleware d'autenticació llegeix la capçalera `X-User-ID`, però els serveis d'esdeveniments, inscripcions i assistent validen que l'identificador d'usuari tingui format UUID canònic de 36 caràcters (`8-4-4-4-12`), mentre que els UID de Firebase Auth fan 28 caràcters alfanumèrics (i els comptes demo tenen prefix `demo-...`), provocant `HTTP 400: {"error": "invalid user id"}`.
- **Opcions:** A) que el backend resolgui sempre el `firebase_uid` cap a l'UUID intern de `Users` al middleware o accepti `firebase_uid` als serveis · B) transformar de manera determinista qualsevol identificador no UUID a un UUID v4 canònic al client (`ApiClient.toCanonicalUuid`) quan s'envia `X-User-ID`.
- **Provisionalment:** B (`TODO(DP-036)` a `lib/core/network/api_client.dart`), de manera que les peticions a Render amb `X-User-ID` funcionen tant amb UID de Firebase com amb comptes de demostració sense fallar per validació d'UUID.
- **Canvi (2026-10-26, Claude Code (Opus 5.5) amb confirmació de l'usuari, Taiga #82):** des de `userid-fixes` (US #222), l'`id` de `users` és un UUID i les inscripcions tenen clau forana cap a `users(id)`. L'UUID calculat al client (B) no existeix a `users` i la BD el rebutja. Ara:
  - `AppUser.serverId` és l'`id` que retorna `POST /auth/sync` (l'UUID real), desat també al dispositiu com el nom d'usuari;
  - `X-User-ID` envia aquest UUID; sense sessió o sense backend no s'envia;
  - apuntar-se i l'Agenda fan servir `serverId` (o l'`id` del compte amb dades de demostració), perquè `GET /users/{id}/events` necessita l'UUID;
  - s'han eliminat `ApiClient.toCanonicalUuid` i `isCanonicalUuid`.
  Amb Firebase actiu al backend continua fallant: `getUserID` agafa l'UID de Firebase del token i no el tradueix (`GetByFirebaseUID` només es fa servir a `/auth/sync` i al perfil). Cal l'opció A al backend; quan hi sigui, `X-User-ID` sobrarà (`TODO(DP-036)` a `main.dart`).
- **Qui decideix:** backend + frontend
- **Resolució:** A, al backend. `fix/resolve-user-id` (PR #36 d'api-aprop, Tasca #237, Wen) i `feature/esdeveniment-no-ofi` (PR #35, Tasca #236, Arnau) tradueixen l'UID de Firebase del token a l'UUID de `users` (`requester.ID`, `EventService.ResolveUserID` amb `GetByFirebaseUID`) a inscripcions, crear esdeveniments, xatbot i preferències. `X-User-ID` només es llegeix quan el backend funciona sense Firebase. Al frontend (2026-10-26, Taiga #82) ja no s'envia `X-User-ID`: l'usuari surt només del token. `AppUser.serverId` (l'`id` de `POST /auth/sync`) es continua fent servir per a `GET /users/{id}/events` i com a clau de les inscripcions.
