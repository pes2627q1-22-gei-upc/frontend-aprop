# Acceptar una sol·licitud d’amistat · #164

## Abast

Sprint 2, història #35. Acceptar des de la targeta social d’Avisos o del perfil aliè.
Ambdues entrades comparteixen la mateixa font de confirmacions i actualitzen la bústia, el distintiu
«Amiga/Amic» i els comptadors dels perfils. Sense canvis al backend, paquets nous ni persistència local
per substituir la confirmació del servidor. L’enviament de #160 es conserva quan no hi ha petició rebuda.

## Contracte comprovat

Backend `api-aprop@454e22b` (lectura de handlers, servei, repositori i SQL):

| Operació | Endpoint | Resultat |
|---|---|---|
| Sol·licituds rebudes pendents | `GET /users/me/friend-requests` | Array: `sender-id`, `receiver-id`, `date-sent`, `state: Pending` |
| Acceptar | `POST /users/{sender}/friend-requests/{date}/accept` | Mateixa sol·licitud amb `state: Accepted` |
| Rebutjar (acció ja present a Avisos) | `POST /users/{sender}/friend-requests/{date}/deny` | Mateixa sol·licitud amb `state: Rejected` |
| Recarregar comptadors i privacitat | `GET /users/me`, `GET /users/{id}` | `friends-count`, `is-friend`, `plans-visible` |

L’adaptador fixa les capçaleres Bearer de l’operació i contrasta el Firebase UID/UUID del compte amb
`/users/me`. Només es poden respondre sol·licituds rebudes d’una altra persona. La identitat és la
parella remitent/destinatari més la data exacta en microsegons. La ruta envia UTC amb `Z`; no perd
microsegons ni reutilitza la data de l’avís. Es valida també el remitent, destinatari, data i estat de
la resposta. El backend fa l’acceptació i l’amistat recíproca en una transacció.

## Flux i responsabilitats

1. El ViewModel consulta el perfil i les sol·licituds rebudes. Si n’hi ha una d’aquella persona,
   mostra «Acceptar». Un error de consulta ofereix reintent, no «Afegeix com a amic».
2. Prémer «Acceptar» mostra «Acceptant…» i bloqueja pulsacions repetides. El repositori comparteix
   la petició en curs entre pantalles; només publica després d’una resposta vàlida.
3. La confirmació actualitza les targetes existents i el distintiu del perfil. Perfil propi i aliè
   tornen a consultar els comptadors: no se’ls suma un amic manualment. Si hi havia una càrrega o
   edició en curs, s’executa després un refresc pendent. S’ignoren respostes de pantalles alliberades.
4. Els plans no es fan públics per una acceptació: només es consulten quan el servidor autoritza
   `plans-visible`. La consulta, la navegació, el filtre i el scroll existents es conserven.
5. A Avisos, la lectura és independent. Després de respondre s’intenta marcar l’avís real com a llegit.
   Si això falla, la targeta continua acceptada i mostra l’error de lectura; es pot tornar a obrir.

## Límit del servidor i DP-066

Actualment enviar una sol·licitud **no crea una notificació**. Per això, la bústia incorpora les
sol·licituds rebudes autoritatives com a targetes socials. Si ja hi ha un avís Social amb el mateix
`friend-id` i `request-date`, s’utilitza aquella targeta. Mateix remitent amb altra data no coincideix.
No es dedueixen permisos del text, del tipus numèric ni del nom de la persona.

Les targetes sense registre de notificació tenen ID de presentació `friend-request:<requestId>` i
no porten punt de no llegit ni fan POST de lectura: l’API de sol·licituds no ofereix estat de lectura.
Les confirmacions pròpies es conserven durant l’execució per reconciliar refrescos; en reiniciar no
s’inventa un historial resolt que el servidor no exposa. No s’implementen push ni detecció en temps real
de sol·licituds noves; s’obtenen carregant/refrescant les pantalles.

`request-date` pot arribar sense zona des de PostgreSQL, mentre `date-sent` arriba serialitzat en UTC.
Per correlacionar es comparen els components UTC; les mutacions sempre usen `date-sent`. Es necessita
que backend confirmi aquesta política o enviï tots dos camps amb offset. No es canvia la política de
la data general dels avisos (DP-039).

## Proves i comprovació manual

Tests: `http_friendship_repository_test.dart`, `friendship_reactivity_test.dart`,
`friendship_screen_test.dart`, `friend_request_notifications_test.dart` i el recorregut
`test/app/public_profile_flow_test.dart`. Inclouen contracte, propietari, microsegons, doble pulsació,
respostes falses/tardanes, error/reintent, compte diferent, dispose, privacitat, comptadors, text ×2 a
320 px i acceptació des de les dues entrades.

Abans de fusionar: CI, revisió humana i prova amb dos comptes reals. Enviar des d’un compte, acceptar
amb l’altre, comprovar comptadors, distintiu, retorn a Avisos i privacitat. Les proves automatitzades
fan servir HTTP simulat i dades Demo; no s’han fet escriptures reals a Render.

## Compatibilitat amb la llista d’amics #197

En integrar `develop@8b4b5dd` es conserven el comptador que obre la llista i la navegació al perfil.
La font HTTP consulta la llista real en obrir-la/refrescar-la. La llista Demo de #197 conserva els seus
exemples fixos (DP-065): no és una representació completa del graf després d’acceptar una petició.
L’estat i els comptadors Demo de #164 sí comparteixen la confirmació. Aquest límit no afecta la
consulta HTTP de les amistats. La decisió de #164 s’ha renumerat a DP-066 per evitar la col·lisió.
