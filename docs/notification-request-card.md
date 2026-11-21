# Targeta de sol·licitud rebuda · Taiga #168

## Abast

Història #37: renderitzar la petició rebuda a `NotificationsScreen` amb «Acceptar» i «Rebutjar».
#164 i #193 ja aporten els contractes HTTP i la sincronització amb el perfil. #168 no duplica aquesta
lògica: separa la presentació i en verifica els estats visibles i accessibles.

Base independent: `origin/develop@550d9a9`, amb #164 (PR #66) i #193 (PR #68) integrades.

## Flux

`NotificationsScreen` observa el seu `NotificationsViewModel` i passa el snapshot de cada avís a
`NotificationCard`. Només el tipus `friendRequest` renderitza `FriendRequestNotificationActions`.
El nou widget rep estat, disponibilitat, nom de la persona i callback; no carrega dades ni modifica
cap amistat. Les pulsacions tornen al ViewModel, que espera la confirmació del repositori compartit.

| Estat | Presentació | Accions |
|---|---|---|
| Pendent, llegida o no llegida | Persona, data, tipus Social, Acceptar/Rebutjar | Responen a aquella petició |
| Enviant resposta | Barra de progrés i «Enviant la resposta» | Totes dues desactivades; altres peticions disponibles |
| Llegint o refrescant | Indicador de lectura/refresc del contenidor | Desactivades; no es presenta com un enviament de resposta |
| Error de resposta | Missatge d’error al costat de la petició pendent | Es poden tornar a intentar |
| Acceptada | Icona i «Sol·licitud acceptada» en una regió viva | Sense botons pendents |
| Rebutjada | Icona i «Sol·licitud rebutjada» en una regió viva | Sense botons pendents |

Obrir el cos de la targeta només confirma la lectura i obre el perfil si hi ha destinació.
Prémer les accions no navega al perfil. Llegir no resol la petició. L’acceptació/rebuig i la lectura
continuen sent escriptures independents: un error de lectura conserva el resultat confirmat.
Un avís Social genèric o una acceptació rebuda d’un altre usuari no reben botons per respondre.

## Accessibilitat i adaptació

- Cada botó identifica també qui ha enviat la petició al lector de pantalla, amb textos ca/es/en i
  placeholder `{name}`. Les etiquetes visibles continuen sent «Acceptar» i «Rebutjar».
- Superfícies d’almenys 48 px d’alt. En una targeta estreta o amb text ampliat, els botons s’apilen
  i ocupen l’amplada disponible; en la vista habitual comparteixen fila.
- Estat confirmat amb text i icona, sense dependre del color. Progrés i resultat amb anunci accessible;
  els botons desactivats no exposen una acció semàntica de pulsació.
- Colors del tema existent; estat desactivat també visualment atenuat en totes dues accions. Sense paquets, assets ni estils globals nous.

## Contracte i límits

Es reutilitzen `NotificationRepository` i `FriendshipRepository`. Cap endpoint nou ni canvi al backend.
Les targetes provenen de la bústia i de les peticions rebudes autoritatives ja integrades a #164.
Quan no hi ha avís persistent, la targeta no inventa una lectura pendent ni fa un POST de lectura.
La falta d’una destinació de perfil no impedeix respondre la petició.

L’enviament d’una sol·licitud continua sense crear automàticament un avís al backend `fb266a7`.
La consulta de rebudes cobreix la presentació dins d’Avisos; no s’implementen notificacions push ni
un nou sistema d’actualització en temps real. Continuen les dependències i política de dates de
DP-039/DP-066. Vegeu [el flux compartit d’amistat](friend-requests.md).

## Proves

- `friend_request_notification_actions_test.dart`: estats, callbacks, semàntica per persona,
  mida tàctil, disposició a 390 px i a 320 px amb text ×2 en ca/es/en, focus natiu i activació amb Tab/Enter/espai.
- `friend_request_card_screen_test.dart`: lectura independent, resposta de les dues accions,
  error/reintent, disponibilitat d’altres peticions, filtre conservat i perfil no disponible.
- La suite existent de #164/#193 conserva la verificació HTTP, propietari, data exacta, respostes
  tardanes, concurrència i sincronització amb els perfils.

Abans del merge cal CI i revisió humana. Verificar amb comptes reals continua pendent; les proves
automatitzades utilitzen contractes falsos, HTTP simulat i Demo, sense escriptures a Render.
