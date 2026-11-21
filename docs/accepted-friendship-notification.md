# Avís d’amistat acceptada · Taiga #170

## Abast

Història #38: qui va enviar una sol·licitud rep un avís quan l’altra persona l’accepta i pot obrir-ne
el perfil. Base `origin/develop@c7f4895`, amb #164, #193 i #168 integrades. Només frontend.

El model `AppNotification.friendRequestAccepted`, el missatge i la navegació genèrica al perfil ja
existien. #170 afegeix l’accés explícit «Veure perfil» i comprova el recorregut i els casos límit.
La integració HTTP d’aquest subtipus **no està completada**: depèn del contracte indicat a DP-069.

## Flux i responsabilitats

1. El repositori aporta un `AppNotification` tipat. El formatador resol el text d’acceptació en ca/es/en.
2. `NotificationCard` mostra persona/avatar, data, etiqueta Social, missatge i estat de lectura.
   Per a `friendRequestAccepted` incorpora un botó «Veure perfil», amb el nom de la persona a la
   semàntica. No presenta Acceptar/Rebutjar: la sol·licitud ja ha estat acceptada per l’altra persona.
3. Cos i botó reutilitzen `_open` de `NotificationsScreen`: crida `markAsRead`, espera la confirmació
   i comprova que el mateix compte, ViewModel i ruta continuen actius abans d’invocar el callback.
4. `MainShell` connecta `onPersonSelected` amb el navegador de la secció i el perfil públic existent.
   El retorn conserva filtre, posició i lectura d’Avisos. No es modifica cap comptador des d’aquesta
   targeta: la informació d’amistat/perfil continua sent responsabilitat dels repositoris compartits.

| Situació | Comportament |
|---|---|
| No llegit | Punt, missatge i botó; la lectura es confirma abans d’obrir el perfil |
| Ja llegit | Obre el perfil sense repetir l’escriptura de lectura |
| Llegint | Indicador de progrés; cos i botó desactivats per evitar duplicats |
| Error de lectura | Es conserva no llegit, es mostra l’error i es permet reintentar |
| Sense callback de perfil | Sense botó ni enllaç mort; avís de perfil no disponible i cos per llegir |
| Canvi de compte, ruta o dispose | Una resposta tardana no obre el perfil de la pantalla anterior |

No es creen pantalles, ViewModels, repositoris, paquets ni endpoints nous. Textos als ARB ca/es/en;
colors del tema, botó natiu accessible d’almenys 48 px i disposició comprovada a 320 px amb text ×2.

## Contracte que falta

A `api-aprop@fb266a7`, el servei d’acceptació crea un avís amb tipus **Social**, `friend-id`,
`request-date` i text lliure. El DTO de notificació no distingeix l’acceptació d’altres accions socials.
La consulta de sol·licituds només retorna les rebudes Pending, de manera que tampoc demostra
l’acceptació d’una petició enviada. L’usuari confirma que no hi ha una altra branca disponible.

`HttpNotificationRepository` conserva aquests avisos com a `socialUpdate`; continuen sent llegibles
i poden obrir el perfil si hi ha una persona resolta. No mostren el missatge específic d’acceptació
ni el nou botó propi d’aquest subtipus. Cap cerca de paraules o traducció decideix un estat de negoci.

Missatge per traslladar al backend:

> Per completar la tasca #170 / història #38 necessitem que la resposta de notificacions identifiqui
> l’acceptació d’amistat amb un camp estructurat, sense interpretar el text de Social. Ha d’indicar
> destinatari, persona que ha acceptat, data i referència de la sol·licitud. Podeu acordar i publicar
> el discriminador i un exemple JSON? Amb aquest contracte adaptarem el mapper del frontend i
> comprovarem el recorregut amb dos comptes reals.

L’acció d’acceptar de #164 continua funcionant amb HTTP. Aquesta dependència afecta l’avís específic
que rep l’altre compte. No canvia els límits de generació inicial, dates o autorització de DP-039/DP-066.

## Proves

- `accepted_friend_notification_card_test.dart`: text, persona, hora, lectura, absència d’accions de
  resposta, callback, superfície tàctil i semàntica nativa en ca/es/en a 390 px i 320 px/text ×2.
- `accepted_friend_notifications_screen_test.dart`: lectura confirmada, duplicats, ja llegit,
  error/reintent, destinació opcional, canvi de compte i dispose.
- `accepted_friend_notification_flow_test.dart`: Avisos → perfil real de Demo → retorn i canvi
  de pestanya, conservant filtre Social, desplaçament i lectura, sense alterar cap amistat.
- `http_notification_repository_test.dart`: un avís Social amb el text real d’acceptació continua
  genèric sense un discriminador autoritatiu; no s’inventa l’estat de la sol·licitud.

Les proves fan servir fakes, Demo i HTTP simulat. Calen contracte backend, verificació autenticada
amb dos comptes, CI i revisió humana abans de donar per completada tota la història #38.

Verificació local (2026-11-21): 14 proves noves, conjunt focal de 28 i suite completa de 870 superades;
anàlisi sense incidències, format de 362 fitxers i APK debug correctes. Revisió tècnica independent
aprovada. Un test anterior de rebuig ara torna a fer visible el missatge abans de prémer-lo després
del canvi d’alçada de la targeta, mantenint les comprovacions de navegació i comptadors.
Captures Flutter amb fonts Roboto i Demo a `PES/output/frontend/task-170-{avisos-acceptacio,perfil-amiga,retorn-avisos}.png`.
Backend intacte; sense escriptures a Render ni commit/push.
