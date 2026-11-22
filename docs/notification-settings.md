# Preferències d’avisos · Taiga #132 / història #19

## Abast i comportament

La tasca amplia Configuració (figura 19) dins de `ProfileSettingsScreen` i `ProfileSettingsViewModel`.
L’usuari ha triat representar els quatre tipus reals: **Recordatoris, Avisos socials,
Recomanacions i Cancel·lacions**. Activitat dels amics i sol·licituds comparteixen Social; no es
mostren dos controls que aparentin ser independents. Els filtres de la bústia d’Avisos es conserven.

Cada switch representa el valor confirmat. Durant el guardat es conserva aquell valor, apareix
«Desant el canvi…» al mateix control i no es dupliquen escriptures. Si falla, hi ha error i reintent de
la mateixa intenció. Els estats i controls estan en ca/es/en, amb semàntica nativa i superfícies de 48 px.

La secció es carrega independentment de la privacitat. Un error no es presenta com si tots els
tipus estiguessin apagats; es pot reintentar i continuar utilitzant la resta de Configuració.
En refrescar es conserven valors confirmats si falla la consulta. Un tipus absent al catàleg no
s’inventa. Les preferències afecten la recepció; **els avisos ja rebuts no es borren ni s’amaguen**.

## Arquitectura i flux

- `ProfileSettings`: privacitat de plans i idioma. `NotificationPreferences`: snapshot immutable dels tipus
  configurables i valors confirmats, sense IDs HTTP ni widgets. No hi ha booleans duplicats a la UI.
- `ProfileSettingsRepository`: contracte de totes dues consultes i escriptures explícites.
- `ProfileSettingsViewModel`: snapshots, càrregues i errors separats; guard d’escriptura compartit
  amb idioma/privacitat, intenció fallida i reintent. Compte/dispose invaliden resultats de pantalles anteriors.
- `SettingsPreferenceTile`: representació reutilitzada de #199; no fa xarxa ni modifica la bústia.
- `notification_preferences_payload.dart`: validador del JSON i noms de tipus del protocol.

Consulta HTTP: `ProfileApi.own` captura bearer i valida la identitat real amb GET `/users/me`.
Amb les mateixes capçaleres consulta GET `/users/me/settings` i GET `/notificationtypes` en paral·lel.
Només `Social`, `Recordatori`, `Recomanacio` i `Cancelacio` tenen correspondència amb controls;
els IDs no estan fixats al codi. Es rebutgen JSON invàlid, IDs repetits, noms ambigus i catàlegs buits.

Escriptura: torna a llegir la llista completa abans de modificar un tipus, conserva els altres IDs
(inclosos els que aquesta versió no reconeix) i envia **només**
`{"allowed-notif-types": [ids...]}` a PATCH `/users/me`. Valida el UUID de la resposta i torna a
consultar Settings: mateix registre i conjunt desat. La resposta de PATCH és `UserProfile`, que no
conté la llista i, per tant, no confirma per si sola el canvi. Una confirmació fallida deixa error;
refrescar pot reconciliar una escriptura aplicada amb resposta perduda.

Demo conserva snapshots en memòria per compte. Ni Demo ni les proves HTTP simulen push,
permisos del dispositiu o la generació real de noves notificacions.

## Pendent concret del backend · DP-084

No s’ha modificat el backend. En `api-aprop@4f98835`, `UserRepository.UpdateSettings` retorna
abans d’actualitzar `AllowedNotifications` quan `settings.Language != ""`. Això impedeix
guardar els tipus permesos en aquell camí, encara que el PATCH respongui 200. El frontend ho
detecta amb la lectura de confirmació i no presenta el canvi com a desat.

Missatge per als companys:

> El frontend de #132 ja consumeix GET `/users/me/settings`, `/notificationtypes` i PATCH
> `/users/me` amb `allowed-notif-types`. A `UserRepository.UpdateSettings`, el camí
> `Language != ""` retorna abans d’actualitzar `AllowedNotifications`. Cal eliminar aquell
> retorn anticipat i executar totes dues actualitzacions amb el mateix `qtx` i `Commit`.
> Proveu-ho amb idioma `ca`, desactivant tots els tipus i canviant-ne un sense perdre la resta.

`NotificationRepository.Create` i els productors SQL de recordatoris, activitat dels amics i
cancel·lacions ja consulten els tipus permesos. Cal provar-ne el lliurament amb comptes reals
després de corregir la persistència. Aquesta tasca no resol el pendent de privacitat de DP-078.

## Verificació

Les proves cobreixen IDs variables, conjunt buit, preservació d’IDs desconeguts, PATCH parcial,
bearer fixat, canvi de compte, confirmació que no coincideix i la regressió del retorn anticipat.
ViewModel i widgets comproven càrrega/error separats, valors confirmats, reintents duplicats,
concurrència d’idioma/privacitat, dispose, ca/es/en i 320 px amb text ×2. El recorregut d’app
comprova persistència simulada en reobrir Configuració i que els avisos rebuts continuen visibles.
Les respostes HTTP són fixtures; no són una prova del backend desplegat.

Prova real pendent: després del fix de backend, alternar cada tipus amb una sessió real, reobrir
Configuració i comprovar una nova notificació permesa/desactivada i la conservació de l’historial.
CI i revisió humana continuen sent obligatòries abans de fusionar.

Resultat local (2026-11-21): **1041 proves superades**, amb 32 de noves per a #132; anàlisi sense
incidències, format de 396 fitxers correcte i APK debug compilada. Revisió independent aprovada
després de corregir l’error de càrrega residual en un guardat posterior confirmat. Captures de Flutter
amb Roboto i fixtures revisades a `PES/output/frontend/task-132-{configuracio,desactivats}.png`.
No s’han fet commit ni push. La correcció del backend i la prova real continuen pendents (DP-084).

Resolució de conflictes amb `origin/develop@bfff322` (2026-11-22): es conserven l'idioma inicial,
la sincronització pendent per compte, les millores d'Agenda, categories, assistent i test d'interessos,
juntament amb les preferències independents d'avisos. Les còpies de `ProfileSettings` mantenen
idioma i privacitat; una regressió comprova que els canvis de les tres preferències no se sobreescriuen
ni afecten altres comptes. La decisió d'aquesta tasca passa de DP-079 a DP-084 per preservar les
DP-079..083 incorporades per PR #80. **1101 proves superades**, anàlisi sense incidències, format
de 408 fitxers i APK debug correctes; revisió tècnica independent aprovada. Sense commit ni push
del merge. CI, revisió humana i prova amb comptes reals pendents.
