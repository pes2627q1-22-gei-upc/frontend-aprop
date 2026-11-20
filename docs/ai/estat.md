# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasques actives: #261 (menú inferior al xat) i #28 (canviar idioma).

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #274 | [FE] Mapa a pantalla completa estil Google Maps | `feature/mapa-pantalla-completa` | PR #58; correccions de la revisió (proves, xips de 48 px, documentació, codi sense ús); només mapa per decisió de l’usuari (DP-061) |
| #273 | [FE] Intercanviar Inici i Descobreix | `feature/intercanviar-inici-descobreix` | PR #57; correccions de la revisió (marge de l'assistent, documentació, proves); DP-060 oberta |
| #28 | [FE] Canviar idioma (ca/es/en) | `feature/change-language-28` | Implementada (ARB + gen-l10n, selector a Configuració, `language` al backend, `?lang=`); DP-001 resolta; DP-054 i DP-055 obertes; pendent revisió humana i contracte backend |
| #261 | [FE] Amagar menú de navegació inferior en obrir el xat | `feature/fix-261-chat-navigation` | PR publicada a 1e89723; conflictes amb develop resolts; 532 proves i anàlisi correctes; sense commit/push del merge |
| #185 | [FE] Valoració d'1–5 estrelles a la fitxa i a l'Agenda | `feature/valorar-esdeveniment` | Implementada amb Demo; sense assistència ni #184 (DP-053); pendent revisió |
| #203 | [FE] Valorar l'organitzador (esdeveniments comunitaris) i actualitzar-ne la fiabilitat | `feature/valorar-organitzador-203` | PR oberta #50 (Demo DP-049); apilada sobre #45; pendent CI i revisió humana |
| #262 | [FE] Ajustar contrast i color del logotip respecte al fons | `feature/fix-262-logo-contrast` | Implementada; preparació de PR autoritzada; pendent CI i revisió humana |
| #277 | [FE] Perfil d'un altre usuari amb GET /users/{id} i privacitat dels plans (CA3) + tests | `feature/perfil-altre-usuari` | Implementada (HTTP i Demo); DP-063 oberta; pendent revisió humana |

## Base i abast

- Integració de `origin/develop@6988d40` a la branca de #261, sense reescriure historial ni publicar el merge.
- #262 ja fusionada a develop (PR #43): es conserven el PNG transparent, `APropLogo`, els dos usos i les proves de marca. DP-047 i DP-048 es mantenen amb els seus identificadors.
- `MainShell` conserva el navegador d’Inici i els ViewModels compartits. Només gestiona la visibilitat del menú durant `/assistant`.
- `_openAssistant` espera el final de la ruta i restaura la barra a `finally`, amb comprovació de `mounted`.
- Fletxa, retorn del sistema i dreceres restauren la navegació; conversa i inscripcions es conserven.
- Les fitxes obertes des del xat mantenen el flux sense barra (DP-048); les altres fitxes conserven el menú.
- Sense paquets, endpoints ni canvis al backend. No es modifica el contracte HTTP ni el ViewModel de l’assistent.
- Flux i límits a `docs/architecture.md`, `docs/ai/50-ui-mockups.md` i DP-048.

## Verificació (2026-11-18)

- Les noves proves de navegació i el recorregut existent reproduïen la barra visible abans de corregir-la.
- 7 proves de recorregut superades després: fletxa/sistema, scroll, teclat, Agenda/Configuració, resposta tardana, fi de sessió i inscripció des de la recomanació.
- Abans del merge: 530 proves. Després d’integrar #262: 532 proves superades i `flutter analyze` sense incidències.
- Conflictes limitats a `docs/ai/estat.md` i `docs/decisions-pendents.md`; el codi s’ha integrat automàticament.
- Format: 245 fitxers, cap canvi. `git diff --cached --check` correcte; sense fitxers pendents de resolució ni marcadors de conflicte.
- Captures reals amb Flutter, fonts Roboto i dades Demo a `PES/output/frontend/task-261-{assistent,conversa,retorn-inici}.png`; script de renderitzat superat.
- Revisió tècnica independent de la resolució sense bloquejos: codi i proves del xat idèntics a HEAD; logo, consumidors i proves idèntics a develop; DP-047/048 conservades íntegres. La revisió humana i la prova al dispositiu continuen pendents.
- Merge pendent de commit/push. L’usuari executa personalment aquests passos amb els comandos que se li facilitaran.

## Pendents / següents passos

1. Revisió humana, commit de resolució i push a la mateixa branca per actualitzar la PR existent de #261; després CI i aprovació. Sense publicació automàtica.
2. Repassar el xat al dispositiu Android i validar DP-048.
3. La resta de funcionalitats i contractes pendents es conserven a les seves guies/DP.
