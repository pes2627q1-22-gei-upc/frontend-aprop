# Bloquejar usuaris · Taiga #179 / història #45

## Abast i branca

Bloqueig des del perfil aliè i gestió a Configuració (figura 19). Només frontend, amb endpoints
existents; backend `4f98835` consultat sense modificar-lo. `feature/block-users-179` parteix de
`fd95352` de #195. Aquella PR ha d’estar integrada abans de fusionar #179 a develop. La comparació
amb `feature/remove-friend-195` mostra només aquesta tasca, sense els canvis de #195.

## Interfície

- El menú del perfil ofereix **Bloquejar** o **Desbloquejar** segons el bloqueig propi consultat.
  El nom i l’efecte apareixen al diàleg; Cancel·lar/tornar no envia res. Progrés i errors amb reintent.
- Bloquejar elimina l’amistat, amaga els plans anteriors i impedeix respondre peticions pendents.
  Els comptadors es recarreguen de la font. Desbloquejar no recupera amistat ni peticions antigues.
- **Configuració → Usuaris bloquejats** té un accés actiu i recompte quan es coneix. La pantalla
  mostra persones, accés al perfil i Desbloquejar amb confirmació. Inclou càrrega, buit i error/reintent;
  durant l’escriptura la fila continua visible fins a confirmar. Es pot actualitzar arrossegant.
- Una fallada de consulta no es presenta com una llista buida ni com una persona no bloquejada.
  El perfil continua disponible amb error de consulta i reintent.
- ca/es/en, botons natius amb nom accessible, zones de 48 px i disposició a 320 px amb text ×2.
  La ubicació dels controls i els textos de confirmació són la proposta de DP-077.

## Arquitectura i contracte

`BlockedUser` és un model pur (persona i data). `UserBlockingRepository` separa el contracte del
bloqueig personal; `FriendshipRepository` l’amplia perquè la font compartida coordini totes les
mutacions d’una relació. Els ViewModels i widgets depenen de contractes, no d’implementacions.

`CachedFriendshipRepository` manté snapshots per compte, agrupa consultes/escriptures duplicades,
serialitza bloqueig/desbloqueig/acceptació/eliminació per persona i publica només canvis confirmats.
Una llista pendent es reconcilia amb les mutacions que han passat durant la lectura. Una lectura de
peticions anterior a un canvi de bloqueig es torna a consultar per no recuperar peticions invalides.

L’adaptador HTTP fixa compte i bearer amb `ProfileApi.own`, valida UUID propi/aliè, propietat del
resultat, noms, dates i duplicats. Usa:

| Acció | Endpoint | Confirmació |
|---|---|---|
| Consultar | `GET /users/me/blocked` | Llista completa de les persones bloquejades pel compte |
| Bloquejar | `POST /users/{id}/block` | 201 amb persona i `date-blocked` |
| Desbloquejar | `DELETE /users/{id}/block` | 204 |

Un 409 de bloqueig només es confirma si una nova llista autenticada conté aquella persona; un 404
de desbloqueig només es confirma si ja no hi és. Altres errors conserven l’estat i permeten reintentar.
No s’interpreta text lliure d’errors o avisos per modificar l’estat de negoci.

`PublicProfileViewModel` gestiona l’acció i reacciona a canvis de bloqueig. `BlockedUsersViewModel`
gestiona càrrega i desbloqueigs. `ProfileSettingsViewModel` observa el recompte sense duplicar la
llista de negoci. `MainShell` connecta les pantalles amb el repositori compartit de `AuthGate`.
Avisos conserva les targetes rebudes però deixa d’oferir accions d’amistat sobre persones bloquejades.

## Límits i verificació

El bloqueig no amaga esdeveniments, xats o notificacions: el backend encara no aplica aquesta
política. Tampoc permet gestionar bloquejos de l’altra persona. No es promet cap d’aquests efectes
als diàlegs. Demo manté els canvis durant l’execució i els perfils reutilitzen la mateixa font.

Les proves cobreixen contracte HTTP, sessions, errors, respostes antigues, operacions concurrents,
privacitat dels plans, peticions resoltes, llista/comptadors, disposició i navegació. Les peticions
HTTP de les proves són simulades; queda pendent provar-ho amb dos comptes reals i en Android.
No s’executen migracions ni escriptures a Render. CI i revisió humana continuen sent obligatòries.

Verificació local del 21 de novembre de 2026: **970 proves superades**, 37 de noves per a #179;
anàlisi sense incidències, format i comprovació del diff correctes, i APK debug compilada.
Després de la neteja final, les proves focals i el render tornen a passar (38 proves).
Revisió tècnica independent aprovada. Les regressions comproven que un avís d’una persona
bloquejada continua sent llegible i que un bloqueig conegut no desapareix quan falla el refresc.
Captures amb Flutter, Roboto i repositoris Demo revisades a `PES/output/frontend/task-179-*.png`.
Canvis preparats sense commit ni push; #195 ha d’estar integrada abans de fusionar #179 a develop.
