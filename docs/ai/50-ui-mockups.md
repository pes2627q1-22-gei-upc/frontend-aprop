# 50 · Pantalles i mockups

> **Quan llegir-ho:** en implementar o revisar una pantalla. Resumeix el comportament aprovat a la Incepció 2
> (figures 7–19). Les imatges no s'han extret: si necessites el detall visual, demana a l'usuari la figura
> concreta en lloc de llegir el PDF sencer.
> **Font:** `incepcio-2.pdf` §3 i §8.

## Identitat visual

- **Paleta:** crema, verd bosc i coral, amb accents mostassa. Tokens actuals a `lib/app/theme/app_theme.dart`:
  `forest #143C32`, `coral #EF674F`, `cream #F6EFE2`, `cardBackground #FFFCF8`, `ink #10232D`, `muted #667078`,
  `border #E3DED5`, `selectedBackground #E6EEE7`. Mostassa i tema fosc: `TODO` (encara no existeixen).
- **NFR:** un únic `ThemeData` amb tokens de color, tipografia i espaiat; mode clar i fosc conforme a WCAG 2.1 AA.
- **Interfície en català.** No hi ha vocabulari transaccional («comprar», «reservar») ni publicitat.
- **Logotip (#262):** `APropLogo` compartit a Inici i Login, amb fons transparent i sense deformar-lo. Es conserva la composició Catalunya + tres marcadors + «AProp!», amb verd bosc, coral, mostassa i crema. Original conservat; detall i verificació a `docs/branding.md` (DP-047).

## Navegació

Barra inferior fixa amb 5 seccions: **Inici · Agenda · Mapa · Avisos · Perfil**. Des de la #273 (DP-060),
Inici mostra el contingut de Descobreix i el mapa té la seva pestanya; al mockup, Inici era el mapa. Cada secció conserva
el seu historial; tornar d'una fitxa o perfil conserva els filtres, la cerca i la posició del desplaçament.
Accés amb Google; en el primer accés es completa el perfil i es fa el test d'interessos.

**Actualització #261 (2026-11-16):** en obrir el xat de l’Assistent s’amaga la barra inferior. La fletxa,
el retorn del sistema i les dreceres recuperen la navegació habitual sense perdre l’estat de les seccions.
La conversa es conserva en tornar d’una fitxa o reobrir l’Assistent. Les fitxes obertes des del xat també
mantenen el flux sense barra, pendent de validar aquest detall de disseny a DP-048.

## Comportaments compartits

- **Targeta d'activitat:** fotografia, categoria, títol, municipi, horari i procedència («Agenda Cultural» o
  persona creadora, amb el distintiu «Amiga/Amic» si escau). Prémer la foto o el títol obre la fitxa; el nom o
  l'avatar obren el perfil.
- **«M'hi apunto» → «Apuntat» ✓:** afegeix el pla a l'agenda sense sortir de la pantalla. L'estat està
  **sincronitzat** entre llista, fitxa, agenda, Descobreix, cerca i assistent (una única font).
- Estats de càrrega, buit i error amb reintent a cada llista.

## Pantalles

| Secció | Pantalla | Comportament clau |
|---|---|---|
| Mapa | Mapa (fig. 7) | Marcadors diferents per a oficials i d'usuaris, distintiu d'amistat, agrupació numerada. En tocar-ne un surt una targeta («Veure activitat»). Botó «Crear activitat». Filtres de zona, dates i categories amb «Aplicar» (si tanques el panell sense aplicar, es conserva la selecció anterior). Accés a «Assistent». |
| Mapa | Llista (fig. 8) | Selector «Mapa / Llista» sobre el mateix conjunt de resultats, amb els mateixos filtres. |
| Inici | Fitxa (fig. 9) | Contingut desplaçable amb la franja de participació fixa. Bloc del creador («Veure perfil») o de la font oficial (enllaç a l'original). Després d'apuntar-se: «Apuntat» + «Xat de l'activitat». |
| Inici | Assistent (fig. 10) | Bombolles diferenciades. Interpreta tipus, municipi i interval de dates i les mostra a la resposta. Resultats amb la targeta estàndard. Enviar desactivat si el camp és buit. Es conserva la conversa en tornar de la fitxa. |
| Agenda | Calendari (fig. 11) | Mes amb un punt als dies que tenen plans propis, contorn al dia actual i fons verd al seleccionat. La llista del dia s'actualitza a l'instant. Fila «Recordatori» independent («No activat»). Missatge específic si el dia no té plans. |
| Agenda | Recordatori (fig. 12) | Panell inferior amb selecció única: Sense / 30 min / 1 h / 1 dia abans. Resum «Avís previst». «Desar» programa; «Cancel·lar», la creu o el fons descarten. Quan arriba l'hora, l'avís surt a Avisos › Recordatoris. |
| Agenda | Com va anar? (fig. 13) | Activitats acabades amb resposta pendent, sigui quin sigui el dia seleccionat. «Sí, hi vaig anar» / «No hi vaig anar» amb el mateix pes visual; «Més tard» l'amaga només durant la visita. No respondre = assistència desconeguda. «No» no és una valoració negativa. |
| Descobreix | Inici (fig. 14) | Seccions «Per a tu» (segons els interessos) i «Destacats», amb la mateixa targeta. Cercador a dalt. |
| Descobreix | Cerca (fig. 15–16) | Selector «Activitats / Persones», esborrar amb la creu, resum «N activitats/persones trobades». La fila de persona obre el perfil. En tornar es conserven la consulta i la selecció. |
| Avisos | Llista (fig. 17) | Filtres de selecció única: Tots / Social / Recordatoris / Recomanacions. Ordre del més recent al més antic, agrupat per data. Sense llegir: punt coral i fons verd suau; obrir-lo el marca com a llegit. Sol·licituds: «Acceptar» / «Rebutjar» i, en respondre, es mostra el resultat. Llegir-la no l'accepta. Obrir una recomanació no apunta l'usuari. |
| Perfil | Perfil (fig. 18) | Capçalera amb el nom d'usuari, cerca de persones i engranatge. Comptadors: plans fets, amics i valoració mitjana de les activitats creades. «Editar perfil», «Compartir perfil». Cinc insígnies de nivell (assolides en color, l'actual amb contorn verd, les pendents amb cadenat). Barra d'XP (p. ex. 340/500). Pestanyes «Plans fets» / «Creats per mi». |
| Perfil | Configuració (fig. 19) | Els canvis s'apliquen a l'instant. Preferències: idioma (**ca/es/en**: el mockup només mostrava ca/es; l'anglès s'hi afegeix per decisió de #28, vegeu DP-055) i tema. Privacitat: «Mostrar els meus plans», «Usuaris bloquejats». Notificacions: un interruptor per tipus. Compte: «Google Calendar», «Tornar a fer el test d'interessos», «Tancar sessió» (mostra el compte) i «Eliminar compte» (en coral, irreversible). |

## Estat actual vs mockups

Taiga #87 implementa els panells Dates/Categories aprovats: calendari inclusiu, dreceres, caselles, esborrany, Aplicar/Netejar i cancel·lació sense guardar. Les vuit caselles del mockup són l’exemple Demo; en HTTP les opcions venen de `/categories`, amb càrrega/error/reintent. La capçalera mostra selecció i resum; Mapa/Llista comparteixen els filtres. La llista consulta el servidor abans de paginar. #253 conserva les opcions vàlides si hi ha noms buits i permet reintentar un catàleg buit. Amb el contracte de mapa del backend `6f4979e`, es mostren les categories rebudes i es filtra localment per qualsevol categoria de l’activitat. Si genuïnament falta categoria es manté «Veure llista», sense confondre-ho amb absència d’esdeveniments. Font compartida i filtratge global pendents (DP-035/DP-038/DP-046). Zona/municipi continua pendent. Vegeu `docs/inici-server-filters.md`.

Perfil propi i Configuració segueixen `perfil_1_principal.png` i `perfil_2_configuracio.png`. En HTTP, la identitat, comptadors i XP venen de `/users/me`; s’editen nom/username/biografia, es puja la foto i es desa `show-plans`. «Creats per mi» és la pestanya inicial i carrega a part amb error/reintent; «Plans fets» indica historial pendent perquè plans passats no confirmen assistència. Sense metadades de nivells no es dibuixen insígnies/llindars inventats. Municipi i preferències d’avisos queden pendents; Demo conserva els exemples i canvis en memòria. Compartir copia el username confirmat. Colors centralitzats i disposició adaptable. Taiga #230; DP-032/DP-033/DP-040 i `docs/profile-backend.md`.

Taiga #96 conserva els mockups de Descobreix/cerca i els connecta amb recomanacions, populars i cerca paginada. «Per a tu» només mostra «Segons els teus interessos» amb dades personalitzades; sense gustos explica el test pendent. Errors de secció mantenen la resta visible i permeten reintentar. El total de cerca ve del servidor i «Carregar més activitats» continua des de la pàgina següent. Detall, inscripcions, retorn i scroll compartits. «Persones» continua pendent; Demo conserva les seleccions sense personalització real. Contracte i adaptacions a DP-041/DP-024 i `docs/discovery-backend.md`.

Ampliació HTTP de #86: les accions socials del mockup són del projecte final i queden fora de l’Sprint 1
(confirmat per l’usuari). El servidor actual només informa una categoria Social; es mostra un missatge
genèric sense inventar accions. Tipus desconeguts es conserven a «Tots» amb etiqueta «Avís». Activitat
eliminada: l’avís continua llegible sense un enllaç mort; error temporal del context: es pot intentar
obrir la fitxa. Capçalera, filtres, paleta i navegació es conserven. Vegeu DP-039 i `notifications-backend.md`.

Accés real amb Firebase a Android i web (correu + contrasenya i Google, amb tria del nom d'usuari al primer accés; DP-025, DP-026; `docs/firebase-auth.md`). Implementat amb dades de demostració: llista
d'Inici amb capçalera, i fitxa (#75). Els controls pendents es mostren desactivats. Detall a `README.md`.
`TODO(confirmar)`: els criteris de Taiga #7 diuen «usuari o correu», però amb Firebase de moment només es pot
entrar amb el correu (DP-026).

Llista real d’Inici (ampliació de #77): conserva la capçalera i les targetes; afegeix «Carregar més activitats», actualització arrossegant i reintents sense perdre el contingut. Portades HTTP o assets amb la mateixa geometria i alternativa coherent. Un filtre sense coincidències entre pàgines carregades es diferencia del catàleg complet buit (DP-037). Guia `docs/inici-list-backend.md`.
