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
- **Provisionalment:** res integrat.
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

## Resoltes

(cap)
