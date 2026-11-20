# Cerca de persones — Taiga #162

## Abast i ús

El cercador de les figures 15–16 manté una única entrada i el selector «Activitats / Persones».
S’hi entra des d’Inici o des de la barra del Mapa (#273/#274). La consulta visible es comparteix
en canviar de mode; cada mode conserva el seu propi resultat si la consulta no ha canviat.

«Persones» permet cercar per nom o nom d’usuari, veure avatar/inicials, nom i `@username`, i
obrir el perfil públic existent. No hi ha comptadors, amistats ni verificacions deduïdes del resum.
Tornar del perfil conserva el text, la selecció, les pàgines carregades i el desplaçament.
El propi resultat obre Perfil; en tornar a la pestanya d’origen, el cercador continua igual.

## Contracte real consultat

Backend `api-aprop@454e22b`, només llegit. Font: `internal/handlers/user_handler/search_users.go`,
`internal/services/user_service/search_users.go` i `internal/models/user_model/user_model.go`.

- `GET /users?q=<text>&pageNum=0&pageSize=20`, autenticat amb Bearer Firebase; sense `X-User-ID`.
- Resposta: `query`, `total`, `page-num`, `page-size` i `users`.
- Cada persona: `id` UUID, `username`, `name` i `profile-picture`. Cap correu ni altre camp privat.
- Consulta retallada als extrems; màxim 100 punts de codi Unicode. Pàgines des de zero, mida màxima 50.
- Una consulta buida no enumera persones ni fa una petició des del frontend.
- El servidor filtra comptes no disponibles i bloquejos; el frontend no intenta reconstruir aquest filtre.

L’adaptador valida que consulta/pàgina/mida corresponguin a la petició i comprova estructura, total,
UUID, identitats duplicades i camps del resum. JSON invàlid i errors HTTP són errors, no resultats buits.
Una imatge no utilitzable es representa amb inicials. Un nom buit utilitza el nom d’usuari.
La continuació i el total provenen del servidor; el client no afirma haver carregat tots els resultats.

## Responsabilitats i estat

`profile/models` conté els snapshots immutables i `profile/repositories` el contracte.
`HttpUserSearchRepository` utilitza `ApiClient`; `DemoUserSearchRepository` cerca les identitats
canòniques del perfil Demo, sense àlies duplicats ni informació real.

`UserSearchViewModel`, dins de la presentació del cercador existent, depèn només del contracte.
Aplica 350 ms d’espera en escriure, enviament immediat, invalidació per revisió, continuacions
serialitzades, deduplicació per ID i protecció després de `dispose`. La pantalla gestiona el mode i
el camp, crea/allibera els dos ViewModels i rep callbacks de navegació des d’`app/`.

La primera càrrega, buit, error/reintent i error de continuació tenen estats diferents.
Refrescar o editar invalida les peticions anteriors. Un error de continuació conserva les files.
Els missatges i plurals són als ARB ca/es/en; noms i usernames no es tradueixen.

## Comprovacions

- Repositori HTTP/Demo: autenticació, UTF-8, paràmetres, límits, paginació, validació i errors.
- ViewModel: debounce, cerca immediata, concurrència, neteja, reintent, continuació, refresc i dispose.
- Interfície: prompt/càrrega/contingut/buit/error, canvi de mode, paginació, ca/es/en i 320 px amb text ×2.
- Flux HTTP simulat: dues pàgines → perfil privat → retorn → canvi de pestanya, sense repetir la cerca.
- Fluxos Demo: accés des de Mapa i propi resultat cap a Perfil.

Les proves HTTP utilitzen un transport simulat amb el contracte real, sense connectar a Render.
Queden la comprovació autenticada al desplegament, la prova manual en Android i la revisió humana.
No s’ha modificat ni executat el backend.
