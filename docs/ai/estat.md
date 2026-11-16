# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #261: amagar el menú inferior en obrir el xat.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #261 | [FE] Amagar menú de navegació inferior en obrir el xat | `feature/fix-261-chat-navigation` | Implementada i verificada; preparada per revisió humana i PR; sense commit/push |

## Base i abast

- Branca independent des de `origin/develop@a5e15f5`, amb #253 i les millores de mapa de la PR #42.
- #262 (logotip) continua a la seva branca; no es barreja amb aquesta tasca.
- `MainShell` conserva el navegador d’Inici i els ViewModels compartits. Només gestiona la visibilitat del menú durant `/assistant`.
- `_openAssistant` espera el final de la ruta i restaura la barra a `finally`, amb comprovació de `mounted`.
- Fletxa, retorn del sistema i dreceres restauren la navegació; conversa i inscripcions es conserven.
- Les fitxes obertes des del xat mantenen el flux sense barra (DP-048); les altres fitxes conserven el menú.
- Sense paquets, endpoints ni canvis al backend. No es modifica el contracte HTTP ni el ViewModel de l’assistent.
- Flux i límits a `docs/architecture.md`, `docs/ai/50-ui-mockups.md` i DP-048.

## Verificació (2026-11-16)

- Les noves proves de navegació i el recorregut existent reproduïen la barra visible abans de corregir-la.
- 7 proves de recorregut superades després: fletxa/sistema, scroll, teclat, Agenda/Configuració, resposta tardana, fi de sessió i inscripció des de la recomanació.
- Suite completa: 530 proves superades; `flutter analyze` sense incidències.
- Format: 243 fitxers, cap canvi; `git diff --check` correcte.
- Captures reals amb Flutter, fonts Roboto i dades Demo a `PES/output/frontend/task-261-{assistent,conversa,retorn-inici}.png`; script de renderitzat superat.
- Revisió tècnica independent del codi, proves i documentació sense bloquejos; captures revisades visualment. La revisió humana i la prova al dispositiu continuen pendents.
- Cap commit/push. L’usuari vol executar aquests passos personalment amb els comandos que se li facilitaran.

## Pendents / següents passos

1. Validació humana, commit de #261, PR a develop i CI. Sense publicació automàtica.
2. Repassar el xat al dispositiu Android i validar DP-048.
3. La resta de funcionalitats i contractes pendents es conserven a les seves guies/DP.
