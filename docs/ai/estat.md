# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #162: cerca de persones i navegació al perfil amb estat conservat.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #197 | [FE] `FriendsListScreen` + `FriendsListViewModel` connectada des de `ProfileScreen` + tests (història #54) | `feature/llista-amics` | Implementada (HTTP i Demo); DP-065 oberta; pendent revisió humana |
| #160 | [FE] Botó d'acció d'amistat al perfil aliè + integració al ViewModel + tests | `feature/boto-amistat` | Implementada (HTTP i Demo); DP-064 oberta; pendent revisió humana |
| #162 | [FE] Vista y `UserSearchViewModel` integrada en el buscador de Descobreix (fig. 16) + navegación al perfil conservando estado + tests | `feature/user-search-162` | Implementada amb HTTP/Demo; 725 proves, anàlisi i revisió tècnica correctes; sense commit/push |
| #274 | [FE] Mapa a pantalla completa estil Google Maps | `feature/mapa-pantalla-completa` | PR #58; correccions de la revisió (proves, xips de 48 px, documentació, codi sense ús); només mapa per decisió de l’usuari (DP-061) |
| #273 | [FE] Intercanviar Inici i Descobreix | `feature/intercanviar-inici-descobreix` | PR #57; correccions de la revisió (marge de l'assistent, documentació, proves); DP-060 oberta |
| #28 | [FE] Canviar idioma (ca/es/en) | `feature/change-language-28` | Implementada (ARB + gen-l10n, selector a Configuració, `language` al backend, `?lang=`); DP-001 resolta; DP-054 i DP-055 obertes; pendent revisió humana i contracte backend |
| #261 | [FE] Amagar menú de navegació inferior en obrir el xat | `feature/fix-261-chat-navigation` | PR publicada a 1e89723; conflictes amb develop resolts; 532 proves i anàlisi correctes; sense commit/push del merge |
| #185 | [FE] Valoració d'1–5 estrelles a la fitxa i a l'Agenda | `feature/valorar-esdeveniment` | Implementada amb Demo; sense assistència ni #184 (DP-053); pendent revisió |
| #203 | [FE] Valorar l'organitzador (esdeveniments comunitaris) i actualitzar-ne la fiabilitat | `feature/valorar-organitzador-203` | PR oberta #50 (Demo DP-049); apilada sobre #45; pendent CI i revisió humana |
| #262 | [FE] Ajustar contrast i color del logotip respecte al fons | `feature/fix-262-logo-contrast` | Implementada; preparació de PR autoritzada; pendent CI i revisió humana |
| #277 | [FE] Perfil d'un altre usuari amb GET /users/{id} i privacitat dels plans (CA3) + tests | `feature/perfil-altre-usuari` | Implementada (HTTP i Demo); DP-063 oberta; pendent revisió humana |

## Base i abast

- Branca independent des de `origin/develop@9245291`; backend contrastat a `454e22b`, sense modificar-lo.
- `GET /users` de #161 i perfil públic de #277 disponibles. Autenticació Bearer, paginació des de zero, 20 files i límit de 100 punts de codi segons el contracte actual.
- Models/contracte/adaptadors de dades d’usuaris a Perfil; `UserSearchViewModel` i files a la presentació del cercador existent. Sense dependències entre ViewModels de diferents features.
- `main.dart` injecta HTTP; AuthGate disposa d’un adaptador Demo sobre les mateixes identitats que els perfils ficticis.
- Mateix cercador des d’Inici i Mapa, respectant #273/#274. Consulta compartida entre modes i resultats independents.
- Navegació al perfil al navegador de la secció; text, mode, pàgines i scroll conservats. El resultat propi obre Perfil sense destruir la cerca.
- Textos ca/es/en als ARB i fitxers generats amb `flutter gen-l10n`; sense paquets nous ni canvis al backend.
- Guia: `docs/user-search.md`; DP-024 actualitzada amb l’ampliació #162.

## Verificació (2026-11-20)

- 48 proves focalitzades superades: repositoris, ViewModel, pantalla i recorreguts de cerca/perfil; també es mantenen les de cerca d’activitats.
- Comprovats debounce, Unicode, respostes tardanes, neteja, continuació, error/reintent, dispose, mode, scroll, perfil propi/aliè, accés des de Mapa, ca/es/en i 320 px amb text ×2.
- Suite completa: 725 proves superades. `flutter analyze` sense incidències; format de 310 fitxers sense canvis; `git diff --check` correcte.
- Revisió tècnica independent sense bloquejos. Captures Flutter amb fonts Roboto i dades Demo a `PES/output/frontend/task-162-{persones,perfil,retorn}.png`, renderitzat i retorn comprovats visualment. El script temporal reutilitza el mapa substituït de les proves del projecte.
- No s’han executat peticions autenticades a Render ni el backend. Cap commit/push; l’usuari executa personalment aquests passos.

## Pendents / següents passos

1. Revisió humana, commit de #162, PR a develop i CI. Sense publicació automàtica.
2. Comprovar la cerca/perfil amb una sessió real al desplegament i en Android.
3. La resta de funcionalitats i contractes pendents es conserven a les seves guies/DP.
