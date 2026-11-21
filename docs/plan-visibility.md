# Visibilitat dels plans · Taiga #199 / història #55

## Comportament

Configuració (figura 19) ja té `ProfileSettingsScreen` i `ProfileSettingsViewModel`. La tasca completa
aquest flux: no crea una segona pantalla `SettingsScreen` ni una còpia de les preferències.

El control «Mostrar els meus plans» consulta el valor real en obrir Configuració. Mostra
«Compartició amb amics activada/desactivada», independentment del color. Canviar-lo envia el nou
valor immediatament, sense botó Desar. Durant l’escriptura es manté el valor confirmat, apareix
«Desant el canvi…» al mateix control i no es poden duplicar escriptures. Si falla, es conserva el valor
anterior i es mostra un error amb «Tornar-ho a provar». El reintent repeteix la intenció fallida.
Actualitzar les preferències torna a llegir el valor real i resol un resultat d’escriptura incert.

No es presenta una consulta fallida com si la compartició estigués desactivada. El valor false del
model no substitueix el booleà del servidor. La migració 000007 del backend té default true; el client
mostra aquell valor quan el rep. Demo continua sent un exemple en memòria, amb default false.

## Flux i contracte

1. `MainShell` injecta el contracte `ProfileSettingsRepository` a Configuració.
2. `ProfileSettingsViewModel.load()` obté el snapshot i el widget el representa.
3. El switch crida `updatePreference(showMyPlans, valor)`; el ViewModel conserva estat, intenció,
   errors i bloqueig d’accions. `SettingsPreferenceTile` només representa dades i callbacks.
4. L’adaptador HTTP captura la sessió amb `ProfileApi.own`: GET autenticat a `/users/me`, després
   PATCH a `/users/me` amb **només** `{"show-plans": valor}` i el mateix bearer capturat.
5. La resposta ha de pertànyer al mateix UUID real i confirmar el valor demanat. Un altre compte,
   un JSON invàlid o una resposta que ignora el canvi produeixen error, mai un èxit fictici.

Preferències i idioma no s’escriuen simultàniament des de Configuració, perquè comparteixen dades
de Settings al backend. Es mantenen els guards de càrrega, sessió, dispose i escriptures duplicades.
Els errors d’una preferència no es confonen amb els d’idioma, tancament de sessió o eliminació.
La interfície i els estats estan traduïts a ca/es/en i utilitzen el switch natiu, controls de 48 px i tema compartit.

## Privacitat i límits reals

`show-plans` és la preferència. `plans-visible` és el permís que el servidor dona a qui consulta un
perfil: per al propietari sempre és true, encara que no comparteixi; per a altres persones exigeix
amistat i compartició. No s’ha de confondre un camp amb l’altre.

El perfil públic només consulta plans si `plans-visible` ho permet i, en refrescar una resposta privada,
descarta la llista anterior. Això no modifica l’Agenda pròpia ni elimina activitats publicades. No hi ha
una subscripció en temps real entre dispositius. Els perfils públics de Demo continuen sent exemples sembrats.

**Pendent de backend, DP-078 (relacionada amb DP-011):** a `api-aprop@4f98835`, la ruta directa
`GET /users/{userId}/events` encara no comprova la identitat de qui consulta, amistat ni `show-plans`.
El frontend respecta el permís, però això no constitueix autorització de l’API. Missatge per a l’equip:

> A #199 ja desem `show-plans` i el perfil respecta `plans-visible`. Falta que
> `GET /users/{userId}/events` permeti el propietari o una amistat amb compartició activada i
> rebutgi la resta. Ara es pot consultar directament sense aplicar aquella privacitat.

No s’han modificat backend, BD, paquets o endpoints; no s’han fet escriptures a Render.

## Verificació

Proves HTTP amb fixtures: persistència en ambdós sentits, PATCH parcial, bearer fixat, propietat,
booleà invàlid, confirmació ignorada, errors i reintent. Proves del ViewModel: càrrega, estat confirmat,
error, reintent duplicat, respostes antigues, dispose i escriptures d’idioma/privacitat. Widgets: ca/es/en,
390 px i 320 px amb text ×2, semàntica nativa, càrrega fallida, reintent i canvi de compte.
Un recorregut de repositoris/ViewModels comprova compartició + amistat, invalidació de plans anteriors
i persistència després de recrear l’adaptador. Les respostes són simulades, no una prova d’autorització real.

Prova manual pendent: amb dues sessions reals, canviar la preferència en totes dues direccions,
reobrir Configuració, refrescar el perfil des del compte amic i repetir des d’un compte no amic.
L’equip backend també ha de provar la consulta directa d’inscripcions, sense passar per la UI.

Resultat local (2026-11-21): **972 proves superades**, amb 23 de noves per a #199; anàlisi sense
incidències, format de 381 fitxers correcte i APK debug compilada. Després de l’ajust final de
`liveRegion`, les 9 proves de widgets i el render tornen a passar. Revisió tècnica independent aprovada.
Captures Flutter amb Roboto a `PES/output/frontend/task-199-{comparticio-activada,error-reintent,comparticio-desactivada}.png`.
La implementació #199 es va publicar a `642bbd1`. La resolució local del merge amb
`origin/develop@d11d342` incorpora #179 (PR #77) i conserva el recompte, la llista i les accions
de bloqueig juntament amb aquest control de privacitat. La resolució encara no té commit ni push;
queden CI i revisió humana abans de fusionar.

Verificació del merge: **1009 proves superades**, anàlisi sense incidències, format de 390 fitxers
correcte, APK debug compilada i revisió independent aprovada. Backend intacte; el pendent
d’autorització de DP-078 es manté.
