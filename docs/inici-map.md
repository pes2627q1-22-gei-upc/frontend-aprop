# Mapa d'Inici — Taiga #21 «Veure un mapa amb els esdeveniments»

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
- En tocar un marcador surt una targeta a sota (CA2) amb la fotografia, la categoria, el títol, el municipi,
  l'horari i la procedència («Publicat per …» amb «Amiga» o «Font: Agenda Cultural · Generalitat»).
  «Veure activitat» obre la fitxa (#75) dins d'Inici. La creu o tocar el mapa la tanquen.
- «Llegenda» explica els marcadors i diu quantes activitats no tenen ubicació (només surten a la llista).

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
- Filtres de zona, dates i categories: història #25, fora d'aquesta.
- El botó de la meva ubicació del mockup no hi és: necessitaria permisos de localització.

## Proves

`test/features/activities/activities_map_test.dart`: selector Mapa / Llista, un marcador per activitat amb el
tipus i el grup correctes, targeta i «Veure activitat», tancar-la, activitats sense ubicació i llegenda. Amb
el backend: marcadors de la zona, fitxa des del mapa, error i reintent.
`activities_map_view_model_test.dart`: càrrega amb marge, zona ja carregada, error amb reintent i respostes
antigues. `http_activity_map_repository_test.dart`: petició per zona, conversió del JSON, errors i fitxa.
A les proves, `test/flutter_test_config.dart` substitueix el mapa per un espai buit.
