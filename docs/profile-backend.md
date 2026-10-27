# Perfil propi connectat al backend — #230

## Abast

Integració autoritzada el 2026-10-27, només a `frontend-aprop`. Branca `feature/profile-backend`, creada des d’`origin/develop@70ccb27`. Contracte contrastat amb `api-aprop origin/develop@a67ae9e`; el checkout i els fitxers del backend es conserven. La integració d’Avisos de `feature/notifications-backend@8089a9d` és una PR separada i no s’ha barrejat amb aquests canvis. No s’ha creat cap commit ni fet push.

`main.dart` ja injecta els adaptadors HTTP amb l’API configurada. `ProfileRepository` i `ProfileSettingsRepository` continuen sent contractes en Dart pur: cap widget ni ViewModel coneix URL, JSON o transport. Demo continua disponible per a proves i disseny; HTTP no substitueix un error amb dades de mostra.

| Acció de la UI | Petició real | Què confirma |
|---|---|---|
| Obrir/refrescar Perfil | `GET /users/me` | Identitat, foto, biografia, plans, amics, valoració i XP del compte |
| Editar nom, username o biografia | `PATCH /users/me` | Perfil retornat després de desar; 409 indica username ocupat |
| Canviar foto | `POST /users/me/avatar`, camp multipart `avatar` | URL de la foto retornada pel servidor |
| «Creats per mi» | `GET /users/me/created-events` | Col·lecció creada pel compte, amb portades remotes i navegació al detall compartit |
| «Mostrar els meus plans» | `PATCH /users/me` amb `show-plans` | Valor persistent retornat pel servidor |

Cada operació captura el bearer actual i valida `/users/me` contra el compte del ViewModel: UUID real no nul i coincidència amb `firebase-uid` o UUID del compte. Les peticions posteriors d’aquella operació retenen les mateixes capçaleres. No s’inventen UUID, no s’usen noms per decidir autoria i no s’envien tokens al host de les imatges. Un resultat d’un altre compte és un error.

## Recorregut del codi per entendre’l

1. [MainShell](../lib/app/navigation/main_shell.dart) crea el `ProfileViewModel` del compte, injecta el repositori i, si suporta foto, `GalleryProfileImagePicker`; crida `load()`. Destrueix l’estat en canviar de compte.
2. [ProfileViewModel](../lib/features/profile/presentation/view_models/profile_view_model.dart) demana `getProfile(user)` a la interfície. [HttpProfileRepository](../lib/features/profile/data/http_profile_repository.dart) delega autenticació a [ProfileApi](../lib/features/profile/data/profile_api.dart), consulta el backend i converteix el JSON amb [profile_json_mapper](../lib/features/profile/data/profile_json_mapper.dart).
3. La resposta és un [UserProfile](../lib/features/profile/models/user_profile.dart) immutable. `notifyListeners()` fa reconstruir el `ListenableBuilder` de [ProfileScreen](../lib/features/profile/presentation/screens/profile_screen.dart). La pantalla dibuixa les dades; no les consulta.
4. A continuació es carrega `getCreatedActivities` de manera independent. Si falla, el perfil continua visible i es pot reintentar. Si ja hi havia creades, es conserven amb un avís. Una resposta buida vàlida sí que mostra l’estat buit; una resposta invàlida no.
5. [EditProfileSheet](../lib/features/profile/presentation/widgets/edit_profile_sheet.dart) manté només els textos provisionals. El ViewModel valida, crida `updateDetails` i espera la resposta. Fins llavors el perfil anterior continua confirmat; si falla, el formulari conserva el text. Tancar sense desar descarta l’esborrany. Nom ≤100 bytes UTF-8, biografia ≤500 bytes UTF-8 i username entre 3–30 caràcters ASCII alfanumèrics/guió baix, segons el servei real.
6. Canviar foto demana un fitxer a [ProfileImagePicker](../lib/features/profile/repositories/profile_image_picker.dart). Cancel·lar no fa cap escriptura. El repositori puja bytes immutables i substitueix l’avatar només amb una resposta vàlida; l’error conserva la foto anterior. El ViewModel serialitza edició/foto i ignora callbacks després de `dispose`.
7. [ProfileSettingsViewModel](../lib/features/profile/presentation/view_models/profile_settings_view_model.dart) consulta el contracte de configuració. [HttpProfileSettingsRepository](../lib/features/profile/data/http_profile_settings_repository.dart) declara que només `showMyPlans` és persistent. S’utilitza `show-plans`, mai `plans-visible` (aquest últim és un permís de lectura). La UI mostra la resta com a pendent, sense guardar-los en memòria com si fossin reals.
8. Compartir i la capçalera llegeixen el username confirmat; crear activitats llegeix el nom confirmat. Auth continua sent la font de la sessió i dels seus identificadors. Editar Perfil no crea una altra sessió ni canvia credencials.

## Dades del servidor i adaptacions dels mockups

- `plans-count` compta inscripcions: es mostra com a «Plans». `completed-plans-count` compta inscripcions d’esdeveniments acabats; no prova assistència. Per això HTTP no fabrica miniatures/valoracions de «Plans fets» i n’explica la disponibilitat pendent. La pestanya inicial és «Creats per mi».
- `level` és un FK nullable, sense etiquetes ni llindars. Es conserva a `ProfileProgress.serverLevel`, però no es força una equivalència amb les cinc insígnies de la figura 18. Es mostra únicament l’XP informat. `rating`/`reliability` absents o zero mostren «—».
- El backend no té municipi del perfil. L’edició d’aquest camp s’indica pendent; no s’escriu en un mapa local que es perdria en reiniciar.
- El compte Demo conserva biografia/municipi, preferències en memòria i nivells/assistències d’exemple. `ProfileCapabilities` evita condicionar widgets al tipus concret de repositori.
- Les fotos reutilitzen [ContentImage](../lib/core/widgets/content_image.dart), compartit amb les portades d’activitats. Si una URL no es pot carregar, queda un placeholder accessible; no s’hi posa la foto d’una altra persona.

## Galeria i dependència

S’utilitza el plugin oficial [image_picker](https://pub.dev/packages/image_picker), encapsulat a `data/gallery_profile_image_picker.dart`; el contracte i el ViewModel no l’importen. La necessitat és seleccionar una foto per a l’endpoint existent. No s’afegeix cap gestor d’estat ni client de xarxa addicional.

El backend accepta JPG/JPEG, PNG i WebP, amb un màxim de 5 MiB sobre **tot** el multipart. Primer es comprova la mida del fitxer abans de llegir-lo i després `ApiClient` comprova `MultipartRequest.contentLength` abans d’enviar, incloent boundary/capçaleres. HEIC/GIF s’expliquen com a format no admès. El selector no demana metadades completes ni usa càmera. `ios/Runner/Info.plist` inclou l’explicació d’accés a la galeria; no s’afegeixen permisos de càmera ni micròfon.

En Android es consulta `retrieveLostData` al començar. Si el sistema havia destruït l’activitat mentre es triava la foto, s’avisa de triar-la novament; mai s’envia el fitxer recuperat automàticament perquè la sessió podria haver canviat. Cal provar permisos, cancel·lació, recuperació i pujada en un telèfon físic. iOS Auth encara és Demo a `main.dart`; aquesta tasca no converteix l’accés iOS a Firebase.

## Què falta demanar al backend o implementar en una altra història

| Necessitat del mockup | Estat / petició concreta |
|---|---|
| «Plans fets» amb valoracions | Contracte d’assistència confirmada i col·lecció amb les activitats i valoracions de l’usuari; no basta comptar activitats passades |
| Cinc insígnies i progrés | Metadades dels nivells (ID, etiqueta, ordre i XP de pas) i regles de guanyar XP |
| Municipi del perfil | Camp real en model, consulta i PATCH, amb la seva validació |
| Interruptors d’avisos | Consulta i modificació persistent de preferències per tipus; relació amb generació/lliurament d’avisos |
| Foto visible en producció | Confirmar que S3 està configurat, guarda el fitxer i la URL retornada és accessible des d’Android/web; l’endpoint per si sol no prova l’emmagatzematge |
| Amics/perfils aliens/bloquejos | Fora de Sprint 1 segons l’usuari; no s’implementen aquí |
| Test d’interessos | Té endpoints propis de preferències al backend; integració i pantalla corresponen a una història separada |
| Calendar, idioma/tema, eliminar compte | Històries/contractes propis pendents; els controls no simulen èxit |

## Verificació i prova manual

Les proves HTTP utilitzen fixtures amb el JSON real: bearer, propietat del compte, JSON invàlid, errors, 409, PATCH parcial, `show-plans`, multipart i portades. ViewModels/widgets cobreixen càrregues independents, reintents, preservació de dades, cancel·lació de foto, límits, escriptures confirmades i `dispose`. El flux d’app comprova nom/username confirmats, compartir, privacitat persistent i composició de creació. UI a 320 px amb text al doble.

Resultat local (2026-10-27): format correcte, analitzador sense incidències i **440 proves superades** (base: 419). APK debug i web compilats. Revisió tècnica sense bloquejos després de corregir el nom d’autoria i el límit del multipart complet. Les captures reals de Flutter a `PES/output/frontend/profile-backend-{principal,edicio,configuracio,configuracio-compte}.png` mostren la integració amb fixtures, no dades de producció. Android manté l’avís preexistent de migració de Kotlin dels plugins Firebase; la compilació acaba correctament. Web avisa de la font Cupertino absent; cal revisar les icones d’aquella família en una tasca separada.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

Amb una sessió Firebase i API real: obrir Perfil, modificar nom/username/biografia, canviar foto i tancar/reobrir l’app; comprovar persistència. Provar un username ocupat, cancel·lar foto, arxiu massa gran i tall de connexió. Canviar `show-plans`, reobrir Configuració i contrastar el valor. Crear una activitat a Inici i consultar-la a «Creats per mi». Tancar sessió i entrar amb un altre compte: cap dada pendent del primer no ha d’aparèixer al segon. Les proves amb fixtures i la compilació no substitueixen aquesta comprovació autenticada en producció.
