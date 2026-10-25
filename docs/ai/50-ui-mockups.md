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

## Navegació

Barra inferior fixa amb 5 seccions: **Inici · Agenda · Descobreix · Avisos · Perfil**. Cada secció conserva
el seu historial; tornar d'una fitxa o perfil conserva els filtres, la cerca i la posició del desplaçament.
Accés amb Google; en el primer accés es completa el perfil i es fa el test d'interessos.

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
| Inici | Mapa (fig. 7) | Marcadors diferents per a oficials i d'usuaris, distintiu d'amistat, agrupació numerada. En tocar-ne un surt una targeta («Veure activitat»). Botó «Crear activitat». Filtres de zona, dates i categories amb «Aplicar» (si tanques el panell sense aplicar, es conserva la selecció anterior). Accés a «Assistent». |
| Inici | Llista (fig. 8) | Selector «Mapa / Llista» sobre el mateix conjunt de resultats, amb els mateixos filtres. |
| Inici | Fitxa (fig. 9) | Contingut desplaçable amb la franja de participació fixa. Bloc del creador («Veure perfil») o de la font oficial (enllaç a l'original). Després d'apuntar-se: «Apuntat» + «Xat de l'activitat». |
| Inici | Assistent (fig. 10) | Bombolles diferenciades. Interpreta tipus, municipi i interval de dates i les mostra a la resposta. Resultats amb la targeta estàndard. Enviar desactivat si el camp és buit. Es conserva la conversa en tornar de la fitxa. |
| Agenda | Calendari (fig. 11) | Mes amb un punt als dies que tenen plans propis, contorn al dia actual i fons verd al seleccionat. La llista del dia s'actualitza a l'instant. Fila «Recordatori» independent («No activat»). Missatge específic si el dia no té plans. |
| Agenda | Recordatori (fig. 12) | Panell inferior amb selecció única: Sense / 30 min / 1 h / 1 dia abans. Resum «Avís previst». «Desar» programa; «Cancel·lar», la creu o el fons descarten. Quan arriba l'hora, l'avís surt a Avisos › Recordatoris. |
| Agenda | Com va anar? (fig. 13) | Activitats acabades amb resposta pendent, sigui quin sigui el dia seleccionat. «Sí, hi vaig anar» / «No hi vaig anar» amb el mateix pes visual; «Més tard» l'amaga només durant la visita. No respondre = assistència desconeguda. «No» no és una valoració negativa. |
| Descobreix | Inici (fig. 14) | Seccions «Per a tu» (segons els interessos) i «Destacats», amb la mateixa targeta. Cercador a dalt. |
| Descobreix | Cerca (fig. 15–16) | Selector «Activitats / Persones», esborrar amb la creu, resum «N activitats/persones trobades». La fila de persona obre el perfil. En tornar es conserven la consulta i la selecció. |
| Avisos | Llista (fig. 17) | Filtres de selecció única: Tots / Social / Recordatoris / Recomanacions. Ordre del més recent al més antic, agrupat per data. Sense llegir: punt coral i fons verd suau; obrir-lo el marca com a llegit. Sol·licituds: «Acceptar» / «Rebutjar» i, en respondre, es mostra el resultat. Llegir-la no l'accepta. Obrir una recomanació no apunta l'usuari. |
| Perfil | Perfil (fig. 18) | Capçalera amb el nom d'usuari, cerca de persones i engranatge. Comptadors: plans fets, amics i valoració mitjana de les activitats creades. «Editar perfil», «Compartir perfil». Cinc insígnies de nivell (assolides en color, l'actual amb contorn verd, les pendents amb cadenat). Barra d'XP (p. ex. 340/500). Pestanyes «Plans fets» / «Creats per mi». |
| Perfil | Configuració (fig. 19) | Els canvis s'apliquen a l'instant. Preferències: idioma (**ca/es** al mockup; l'NFR diu ca/es/en, `TODO(confirmar)`) i tema. Privacitat: «Mostrar els meus plans», «Usuaris bloquejats». Notificacions: un interruptor per tipus. Compte: «Google Calendar», «Tornar a fer el test d'interessos», «Tancar sessió» (mostra el compte) i «Eliminar compte» (en coral, irreversible). |

## Estat actual vs mockups

Perfil propi i Configuració implementats a partir de `perfil_1_principal.png` i `perfil_2_configuracio.png` aportats per l'usuari. La identitat ve de la sessió; només Laia té estadístiques demo i els tres plans històrics resolubles. Edició de biografia/municipi i preferències per compte en memòria; compartir copia `@username`. Idioma/tema, serveis socials, Calendar, test i eliminació continuen pendents, amb Calendar «No connectat». Colors centralitzats, disposició adaptable i retorn a fitxes compartides. Taiga #230; DP-032/DP-033 i `docs/profile.md`.

Taiga #96 implementa Descobreix i la cerca d'activitats amb les targetes/inscripcions existents, el navegador de la secció i estats complets. La selecció demo no és personalitzada: subtítol «Una selecció per començar» i accés «Cerca activitats». «Persones» continua desactivat amb una explicació fins a tenir-ne l'abast/contracte. No s'inventen perfils ni recomanacions de producció (DP-024); detalls a `docs/discovery.md`.

Taiga #86 implementa Avisos amb repositori de demostració: filtres, ordre/agrupació per data, lectura confirmada, respostes a sol·licituds i ruta al detall. El perfil es mostra com a pendent fins que s'injecti un callback real. Les inicials substitueixen avatars no disponibles. En pantalles estretes o amb text ampliat, els quatre filtres es desplacen horitzontalment sense truncar. Lliurament de notificacions, recordatoris programats i amistats reals no estan integrats (DP-023); detalls a `docs/notifications.md`.

Accés real amb Firebase a Android i web (correu + contrasenya i Google, amb tria del nom d'usuari al primer accés; DP-025, DP-026; `docs/firebase-auth.md`). Implementat amb dades de demostració: llista
d'Inici amb capçalera, i fitxa (#75). Els controls pendents es mostren desactivats. Detall a `README.md`.
`TODO(confirmar)`: els criteris de Taiga #7 diuen «usuari o correu», però amb Firebase de moment només es pot
entrar amb el correu (DP-026).
