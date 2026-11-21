# Eliminar una amistat · Taiga #195

Història #53. Base `origin/develop@112d2f8`, backend contrastat a `4f98835`. Només frontend;
cap endpoint ni paquet nou. L’acció funciona amb l’adaptador HTTP i amb Demo.

## Entrades i confirmació

- Perfil propi → comptador **Amics** → llista pròpia: icona d’eliminar amb etiqueta accessible que
  identifica la persona, diferenciada de la fila que obre el perfil.
- Perfil d’una altra persona amb amistat confirmada → menú superior → **Eliminar amistat**.
- Mateix diàleg: títol, nom de la persona, **Cancel·lar** i **Eliminar amistat**. Cancel·lar,
  tornar o tocar fora no envia cap petició. El botó destructiu usa els colors del tema.
- Durant l’escriptura hi ha progrés; un error conserva la relació i permet tornar a confirmar.
  L’èxit es comunica amb un avís breu. El perfil continua obert i recupera l’acció d’afegir amistat.
- Les llistes d’altres persones continuen sent de consulta. El perfil propi no mostra cap acció
  per eliminar-se: la gestió d’una relació correspon al perfil aliè (DP-076).

## Flux de codi

1. `FriendRemovalAction` i `confirmFriendRemoval` són presentació. Les pantalles només envien
   una acció al seu ViewModel després de confirmar i comprovar-ne la vigència.
2. `FriendsListViewModel.removeFriend` / `PublicProfileViewModel.removeFriend` validen estat i
   disponibilitat, exposen progrés i errors i deleguen al contracte compartit `FriendshipRepository`.
3. `CachedFriendshipRepository` agrupa operacions duplicades, serialitza escriptures de la mateixa
   relació i publica `FriendshipRemoval` només després de confirmar amb la font de dades.
4. Llista i perfils escolten el mateix repositori injectat per `AuthGate`/`MainShell`. La fila s’elimina,
   la relació passa a no ser amistat i el perfil propi i l’aliè tornen a consultar els seus recomptes.

Les resolucions de sol·licituds són historial, no l’estat actual de la relació. Es conserven perquè
Avisos no torni a oferir Acceptar/Rebutjar sobre peticions resoltes, però no poden reconstruir una
amistat eliminada. `confirmedFriendship` i les revisions dels ViewModels reconcilien lectures antigues.
Una lectura de plans iniciada abans d’eliminar no els pot tornar a mostrar després.
Les lectures noves i autoritatives poden reconèixer que s’ha restablert l’amistat, sense convertir
la memòria d’eliminacions en una prohibició permanent. També es consulten les noves peticions rebudes
de la mateixa persona; eliminar-ne una altra no esborra el feedback de la petició sortint.
Un `is-friend: false` explícit d’una lectura nova preval sobre una acceptació històrica; no es
guarden lectures positives com a amistats permanents. Només quan el camp és absent es conserva
la confirmació local com a alternativa.

## Contracte real

`HttpFriendshipRepository` valida el compte amb `GET /users/me` i congela les capçaleres autenticades.
Envia **`POST /users/{uuid}/unfriend`**, sense cos, i comprova la resposta HTTP mitjançant `ApiClient`.
El servidor comprova que són persones diferents i amigues, elimina la relació en qualsevol sentit
i respon 200 amb un missatge. El frontend no interpreta aquest text com a estat de negoci.

Una fallada HTTP o de xarxa no es converteix en èxit local. En particular, un 400 pot tenir motius
diferents i no es tracta automàticament com «ja eliminat». Cal tornar a carregar o reintentar.
La notificació que pugui generar el servidor pertany a Avisos; aquesta tasca no en dedueix el subtipus.

El backend ja aporta l’acció necessària. No cal cap canvi de backend per integrar aquesta tasca.
L’execució autenticada amb dos comptes en Android/desplegament continua sent verificació manual pendent.

## Demo i verificació

Els adaptadors Demo de llista i perfils comparteixen les confirmacions per compte. Els recomptes
de base continuen sent els exemples dels mockups, sense inventar persones addicionals. Els canvis
persisteixen durant l’execució, no després de reiniciar. Els HTTP venen del servidor.

- Repositori: endpoint, bearer fix, compte, UUID propi/aliè, errors HTTP, reintent, duplicats,
  serialització amb acceptació, historial i dispose.
- ViewModels: error sense èxit simulat, sincronització entre pantalles, comptadors recarregats,
  llistes alienes, refrescos antics, plans en curs i dispose.
- Interfície: confirmació/cancel·lació, progrés i error/reintent, navegació separada, canvi de compte,
  tres idiomes, semàntica nativa i 320 px amb text ×2.
- App: eliminació des de la llista i des del perfil aliè, retorn i recompte propi actualitzat.

Abans de fusionar calen CI i revisió humana. No s’ha modificat ni executat el backend, ni s’han fet
escriptures a Render durant les proves automatitzades.

Verificació local (2026-11-21): **33 proves noves**, 168 al conjunt de perfils/recorreguts i
**933 a la suite completa**, totes superades. Anàlisi sense incidències, format de 373 fitxers,
`git diff --check` i APK debug correctes. Revisió tècnica independent aprovada després de corregir
els casos de noves peticions, eliminació d’una altra persona i canvis posteriors del servidor.
Les fixtures d’acceptació/rebuig antigues comparteixen ara el mateix repositori amb Demo, sense
eliminar assertions. Captures de la UI real amb fonts Roboto i Demo a
`PES/output/frontend/task-195-{llista-amics,confirmacio,perfil-amiga,perfil-eliminat,llista-actualitzada,comptador-actualitzat}.png`.
