# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #164: acceptar amistats des d’Avisos i Perfil amb estat reactiu compartit.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #164 | [FE] Acceptar en avís social i perfil + comptadors/distintiu reactius + tests | `feature/accept-friend-request-164` | Implementada amb HTTP/Demo; 760 proves; revisió tècnica correcta; APK debug correcte; DP-065 oberta; sense commit/push |
| #160 | [FE] Botó d'acció d'amistat al perfil aliè + integració al ViewModel + tests | `feature/boto-amistat` | Integrada a develop amb PR #63; DP-064 oberta |
| #162 | [FE] Vista y `UserSearchViewModel` integrada en el buscador de Descobreix (fig. 16) + navegación al perfil conservando estado + tests | `feature/user-search-162` | Integrada a develop amb PR #62 |
| #274 | [FE] Mapa a pantalla completa estil Google Maps | `feature/mapa-pantalla-completa` | PR #58; correccions de la revisió (proves, xips de 48 px, documentació, codi sense ús); només mapa per decisió de l’usuari (DP-061) |
| #273 | [FE] Intercanviar Inici i Descobreix | `feature/intercanviar-inici-descobreix` | PR #57; correccions de la revisió (marge de l'assistent, documentació, proves); DP-060 oberta |
| #28 | [FE] Canviar idioma (ca/es/en) | `feature/change-language-28` | Implementada (ARB + gen-l10n, selector a Configuració, `language` al backend, `?lang=`); DP-001 resolta; DP-054 i DP-055 obertes; pendent revisió humana i contracte backend |
| #261 | [FE] Amagar menú de navegació inferior en obrir el xat | `feature/fix-261-chat-navigation` | PR publicada a 1e89723; conflictes amb develop resolts; 532 proves i anàlisi correctes; sense commit/push del merge |
| #185 | [FE] Valoració d'1–5 estrelles a la fitxa i a l'Agenda | `feature/valorar-esdeveniment` | Implementada amb Demo; sense assistència ni #184 (DP-053); pendent revisió |
| #203 | [FE] Valorar l'organitzador (esdeveniments comunitaris) i actualitzar-ne la fiabilitat | `feature/valorar-organitzador-203` | PR oberta #50 (Demo DP-049); apilada sobre #45; pendent CI i revisió humana |
| #262 | [FE] Ajustar contrast i color del logotip respecte al fons | `feature/fix-262-logo-contrast` | Implementada; preparació de PR autoritzada; pendent CI i revisió humana |
| #277 | [FE] Perfil d'un altre usuari amb GET /users/{id} i privacitat dels plans (CA3) + tests | `feature/perfil-altre-usuari` | Implementada (HTTP i Demo); DP-063 oberta; pendent revisió humana |

## Base i abast

- Branca `feature/accept-friend-request-164`, des de `origin/develop@44b7bf1` (#160 i #162 integrades).
- Backend contrastat a `454e22b`, intacte. Només frontend; cap commit, push o PR automàtics.
- Contracte `FriendshipRepository`, models de sol·licitud/resolució i adaptadors HTTP/Demo a Perfil.
- Mateixa instància per a Avisos, perfil propi i perfils públics. Cap dependència entre ViewModels.
- Consulta autoritativa de rebudes amb `/users/me/friend-requests`; acceptació/rebuig per remitent i data UTC exacta.
- Sol·licituds rebudes com a targetes quan manca l’avís automàtic; la lectura real continua separada. DP-065.
- Botó «Acceptar»/«Acceptant…»/«Amiga/Amic», error/reintent i textos ca/es/en.
- Comptadors recarregats del servidor; refresc pendent durant càrregues/edicions i descart de respostes antigues.
- La privacitat dels plans continua depenent de `plans-visible`.
- Guia de flux/contracte/límits: `docs/friend-requests.md`.

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

1. Canvis preparats per revisar; `git diff --check` correcte.
2. Revisió humana, commit de #164, push, PR a `develop` i CI; l’usuari fa aquests passos personalment.
3. Comprovar el recorregut amb dos comptes reals al desplegament i en Android.
4. Backend/equip: avís automàtic en enviar sol·licitud i política de zona de `request-date` (DP-065).
   Si cal historial resolt o lectura de sol·licituds després de reiniciar, falten aquests contractes.
