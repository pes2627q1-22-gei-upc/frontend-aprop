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

### DP-016 · Contracte d'API de l'assistent (xatbot) amb el backend
- **Estat:** oberta
- **Obert per:** 2026-10-19 · Antigravity · Taiga #91 / #14
- **Context:** `AssistantRepository`, `DemoAssistantRepository`, `AssistantMessage`, `AssistantInterpretation` (`lib/features/assistant/`).
- **Dubte:** l'endpoint HTTP del backend per consultar Gemini, el format JSON de la consulta/resposta (criteris interpretats de tipus, municipi i dates, i llista d'activitats recomanades) i la persistència de `ConversaXatbot` no estan definits a `api-aprop`.
- **Opcions:** A) l'endpoint retorna el text, els filtres interpretats i les activitats completes · B) l'endpoint retorna IDs d'activitats que es resolen contra `ActivityRepository`.
- **Provisionalment:** contracte `AssistantRepository` en Dart pur i `DemoAssistantRepository` (marcat amb `TODO(DP-016)`) que interpreta tipus, municipi i dates en local sobre `ActivityRepository` sense inventar rutes ni DTO HTTP.
- **Qui decideix:** frontend + backend
- **Resolució:**

## Resoltes

(cap)
