# Mapa — Taiga #21 «Veure un mapa amb els esdeveniments»

> Des de la #273 (DP-060) el mapa té la seva pestanya, «Mapa», i Inici mostra Descobreix. On aquest
> document diu «Inici», s'ha d'entendre la pestanya Mapa.

## Comportament

- A Inici, el selector «Mapa / Llista» canvia entre les dues vistes del **mateix conjunt d'activitats**. La
  llista és la vista inicial (DP-022). El selector sempre funciona: si Google Maps falla, la llista continua
  disponible (CA3).
- Cada activitat amb ubicació (`Activity.location`) té un marcador (CA1):
  - verd fosc amb un punt: activitat de l'Agenda Cultural;
  - coral amb una persona: publicada per un usuari;
  - coral amb el distintiu groc: publicada per una amistat (`creator.isFriend`).
- Els marcadors propers s'agrupen amb un número (`ClusterManager` de `google_maps_flutter`); en ampliar el mapa
  se separen.
- En tocar un grup, el mapa s'hi apropa fins que hi caben tots els marcadors (`newLatLngBounds`), que així es
  van separant. Si són tots al mateix lloc (menys d'uns 30 m), apropar-s'hi no els separaria mai: es mostra la
  llista d'activitats d'aquell lloc ordenades per data, i en tocar-ne una s'obre la fitxa (DP-034). Tocar un
  marcador que en té d'altres al mateix lloc també mostra la llista: molt a prop, Google ja no els agrupa i
  quedarien l'un sobre l'altre.
- En tocar un marcador surt una targeta a sota (CA2) amb la fotografia, la categoria, el títol, el municipi,
  l'horari i la procedència («Publicat per …» amb «Amiga» o «Font: Agenda Cultural · Generalitat»).
  «Veure activitat» obre la fitxa (#75) dins d'Inici. La creu o tocar el mapa la tanquen.
- «Llegenda» explica els marcadors i diu quantes activitats no tenen ubicació (només surten a la llista).

## On ets (Taiga #266)

- **Punt «ets aquí»**: un punt blau amb el cercle de precisió, com a Google Maps. El dibuixa l'app, perquè a la
  web Google no ho fa, i així es veu igual a la web i al mòbil. La llegenda l'explica («On ets tu»).
- **Botó «La meva ubicació»**, rodó, a baix a la dreta, per sobre d'«Assistent» (també puja amb la targeta).
  En prémer-lo, el mapa va on és la persona amb zoom 14 com a mínim, i es carreguen les activitats d'aquella zona.
- **Permís**: només es demana en prémer el botó, mai en obrir el mapa. Si ja s'havia donat, el punt surt sol.
  Si no es pot, un avís diu per què:
  - permís denegat: cal permetre-ho;
  - denegat per sempre: botó «Configuració» al mòbil; a la web, s'explica que es fa des de la icona del costat de
    l'adreça;
  - ubicació del dispositiu desactivada: botó «Activar».
- **Bateria**: la posició només s'escolta mentre el mapa és visible, i cada 10 m. En tornar a l'app (p. ex. de
  donar el permís a la configuració), es torna a mirar.
- Plataformes: `ACCESS_FINE_LOCATION` i `ACCESS_COARSE_LOCATION` a Android (la persona pot triar ubicació
  aproximada) i `NSLocationWhenInUseUsageDescription` a iOS. La web necessita HTTPS o `localhost`.
- Decisions provisionals a DP-057.

## Amb el backend

Si l'app s'executa amb `API_BASE_URL`, el mapa carrega les activitats del backend per zona visible. La llista
continua amb les dades de demostració (DP-029).

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

- **En obrir el mapa i cada cop que s'acaba de moure**, demana `GET /events/map?minLat=…&maxLat=…&minLng=…&maxLng=…`
  amb la zona visible i un 50 % de marge. Si la zona nova cap dins de la ja carregada, no torna a demanar res.
- **Mentre carrega**, surt una barra de progrés a dalt i es mantenen els marcadors anteriors. Si falla, surt un
  avís amb «Tornar-ho a provar».
- **«Veure activitat»** obre la fitxa amb `GET /events/{id}`.
- **Adaptació de les dades**: `HttpActivityMapRepository` converteix les etiquetes de municipi i categoria i
  posa la imatge per defecte. Les limitacions són a DP-029.
- **Requisits**:
  - `GET /events/map` és a la branca `feature/events-map` d'api-aprop (sense fusionar);
  - en depuració, Android permet HTTP sense xifrar (`android/app/src/debug/AndroidManifest.xml`).

## Fitxers

```text
features/activities/presentation/widgets/activities_map.dart     mapa, marcadors, targeta i llegenda
features/activities/presentation/screens/activities_screen.dart  selector Mapa / Llista; mapa per zona amb el backend
features/activities/presentation/view_models/activities_map_view_model.dart  càrrega per zona visible
features/activities/data/http_activity_map_repository.dart       GET /events/map i GET /events/{id}
features/activities/presentation/view_models/user_location_view_model.dart  on és la persona i el botó
features/activities/data/geolocator_user_location_repository.dart  permís i posició amb geolocator
features/activities/presentation/widgets/user_location_marker.dart  punt «ets aquí» i el seu color
features/activities/data/demo_activity_repository.dart          coordenades de les activitats de demostració
assets/icons/marker_official.png · marker_community.png · marker_friend.png
```

Els marcadors són imatges generades amb els colors del tema (`forest`, `coral` i el groc del distintiu
«Amiga»), a 144 × 184 px, i es dibuixen a 36 px d'amplada.

## Pendent

- **Clau de Google Maps**: sense clau el mapa surt en gris i no es veu cap marcador. Vegeu [Google Maps](google-maps.md).
- **Càrrega per zona visible (CA3, < 3 s)**: amb el backend ja es fa per zona (~140 ms per a tot Catalunya en
  local). Falta que `feature/events-map` es fusioni i que la llista faci servir la mateixa font (DP-022, DP-029).
- **Color dels grups**: el número dels grups el dibuixa Google amb el seu estil per defecte, no amb el verd del
  mockup (DP-022).
- Dates i Categories: implementats amb filtratge local a la tasca #87; vegeu [la guia](activity-filters.md). Zona/municipi i filtratge global amb servidor continuen pendents (DP-035).

## Proves

`test/features/activities/activities_map_test.dart`: selector Mapa / Llista, un marcador per activitat amb el
tipus i el grup correctes, targeta i «Veure activitat», tancar-la, tocar un grup (llista si són al mateix lloc,
apropar-s'hi si no), activitats sense ubicació i llegenda. Amb
el backend: marcadors de la zona, fitxa des del mapa, error i reintent.
`activities_map_view_model_test.dart`: càrrega amb marge, zona ja carregada, error amb reintent i respostes
antigues. `http_activity_map_repository_test.dart`: petició per zona, conversió del JSON, errors i fitxa.
On ets: `user_location_view_model_test.dart` (sense preguntar si ja hi ha permís, demanar-lo amb el botó, cada
motiu de no poder, temps esgotat, error i deixar d'escoltar) i el grup «La meva ubicació» de
`activities_map_test.dart` (punt i cercle, llegenda, permís i avisos amb «Configuració» o «Activar»).
A les proves, `test/flutter_test_config.dart` substitueix el mapa per un espai buit.
