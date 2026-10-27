# Estat viu

> Llegir a l’inici; només el present (~40 línies). Detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 1 · només frontend. Social fora d’aquest sprint segons l’usuari.
- Prioritat: resoldre la revisió i els conflictes de la PR #31 abans de continuar Descobreix.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #86 | Integració HTTP d’Avisos, PR #31 | `feature/notifications-backend` | Conflictes resolts; 481 proves, analyze, APK/web i revisió correctes; merge preparat sense commit/push |

## Base i canvis

- HEAD publicat `8089a9d`; s’integra `origin/develop@572612a` amb `git merge --no-commit`.
- El company aprova implementació/tests i demana sincronitzar develop (comentari copiat per l’usuari).
- Conflictes: estat viu, decisions pendents i prova multi-repositori; es conserva la feina de les dues branques.
- Autenticació d’Avisos adaptada a bearer-only; no es restaura `X-User-ID` ni UUID sintètics.
- DP-039 i DP-040 preservades; DP-036 continua resolta; DP-031 conserva la verificació per enllaç web.
- Perfil HTTP ja fusionat a develop (PR #32); creació backend (PR #30) i verificació web (PR #33) també.
- Cap canvi al backend, credencials, desplegament ni branca protegida.

## Verificació

- Format correcte (234 fitxers); analitzador sense incidències; 72 proves dirigides i 481 globals superades.
- APK debug i web compilats; revisió sense bloquejos. Cap entrada U ni marcador de conflicte.
- No es pot certificar la CI remota sense accés autenticat a GitHub; reproduïm els passos locals.
- Firebase local configurat i ignorat: no versionar configuracions ni secrets.

## Pendents / següents passos

1. Usuari revisa, fa el commit del merge i el push a la mateixa branca: actualitza la PR #31 existent.
2. Esperar CI verda i aprovació humana; no crear una PR duplicada ni fusionar automàticament.
3. Prova real d’Avisos: identitat/destinatari, lectura persistent, disponibilitat i zona horària (DP-039).
4. Prova real de Perfil, galeria i S3; límits de contracte a DP-040.
5. Descobreix: cerca i populars disponibles; recomanacions personalitzades/test en tasques separades (DP-024).
