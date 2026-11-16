# Estat viu

> Llegir a l’inici; només el present. Detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · canvis només al frontend. Backend consultat com a contracte.
- L’usuari ha concretat #253: les categories no apareixen a Mapa i Inici.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #253 | [FE] Corregir que no es mostren les categories | `feature/fix-253-categories` | Implementada; 532 proves, analyze i revisió correctes; pendent de prova autenticada i PR; sense commit/push |

## Base i abast

- Frontend `origin/develop@5b0c95c`; backend `develop@6f4979e`, PR #54 fusionada; contracte revisat el 2026-11-16.
- La base ja incorpora Descobreix HTTP, test d’interessos i millores de l’assistent i de creació.
- `/categories`: una fila amb ID vàlid i nom sense etiqueta visible no bloqueja les altres opcions.
- Es conserven els noms/IDs del servidor; estructura, ID o tipus invàlids continuen generant error.
- Catàleg no buit en memòria i peticions simultànies compartides; catàleg buit amb reintent.
- Mateix panell i selecció provisional per Mapa/Llista; sense paquets, endpoints ni dades demo nous.
- No es modifica el formulari de creació ni la seva política de categories de DP-018.
- El mapa ja retorna categories: el mapper compartit descarta noms sense etiqueta visible abans d’escollir el distintiu.
- Es filtren totes les categories rebudes de cada marcador a la zona carregada; no hi ha peticions de detall addicionals.
- DP-045 documenta noms buits i recuperació; actualitza els límits de categories del mapa de DP-038.

## Verificació (2026-11-16)

- 5 regressions reproduïdes abans de corregir: catàleg invàlid per nom buit, opcions ocultes a Mapa/Llista i resposta buida sense recuperació.
- 3 regressions addicionals reproduïdes abans de corregir etiquetes sense nom en activitats del mapa.
- 41 proves de repositoris de mapa/filtres i panells superades; inclou el recorregut llista → mapa → targeta → categoria secundària → llista → mapa.
- Format de 246 fitxers sense canvis pendents; analitzador sense incidències; suite completa: 532 proves superades (524 de base i 8 regressions noves).
- Revisió tècnica independent i de decisions sense bloquejos; corregida la petició de categories del mapa que havia quedat obsoleta a la guia. Cap commit/push.
- Render sense sessió respon 401; encara no es confirma la causa amb el catàleg de producció.
- Backend només llegit; no s’ha iniciat servidor, BD, migracions ni cap operació d’escriptura.

## Pendents / següents passos

1. Revisió humana, commit de #253, PR a develop i CI; cap publicació automàtica.
2. Provar «Categories» amb una sessió real a Inici i Mapa.
3. Confirmar que Render inclou la PR #54. Per activitats sense categoria usable es manté l’avís i «Veure llista».
4. Guia: `docs/inici-server-filters.md`, DP-038/045. Filtratge global del mapa i font compartida fora d’aquesta correcció.
