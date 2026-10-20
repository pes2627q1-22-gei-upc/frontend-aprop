# Google Maps: clau d'API

El formulari «Crea una activitat» mostra un mapa de Google per marcar el lloc exacte. El paquet és
`google_maps_flutter`. **Sense clau l'app funciona igual, però el mapa surt en gris.**

La clau **no es versiona**: cada persona la posa al seu `android/local.properties`, que és a
`android/.gitignore`. `android/app/build.gradle.kts` la llegeix d'allà i l'`AndroidManifest.xml` la rep
com a `${mapsApiKey}`. No l'enganxeu mai al codi, a una PR, a Taiga ni a un xat.

## Crear la clau (una sola vegada, per a tot l'equip)

1. A [Google Cloud Console](https://console.cloud.google.com/), crea (o tria) el projecte de l'equip. Google
   demana un compte de facturació per fer servir Maps; consulteu-ne els preus actuals abans d'activar-lo.
2. *APIs i serveis → Biblioteca*: activa **Maps SDK for Android**.
3. *APIs i serveis → Credencials → Crea credencials → Clau d'API*.
4. Restringeix la clau:
   - **Restriccions d'aplicació:** aplicacions Android. Afegeix el paquet `cat.fiveguys.aprop` amb l'empremta
     **SHA-1** de cada membre de l'equip (vegeu a sota).
   - **Restriccions d'API:** només *Maps SDK for Android*.
5. Passa la clau a l'equip per un canal privat.

### Empremta SHA-1 de cada ordinador

Cada ordinador signa l'app de depuració amb una clau diferent; si la seva SHA-1 no és a la llista, a aquell
ordinador el mapa surt en gris. Des de l'arrel del repo:

```bash
cd android
./gradlew signingReport
```

Copia el valor `SHA1` de la variant `debug` i afegeix-lo a la clau de Google Cloud.

## Fer servir la clau

Afegeix aquesta línia a `android/local.properties` (el fitxer ja existeix, el crea Flutter):

```properties
MAPS_API_KEY=la_clau_de_l_equip
```

Després atura l'app i torna a fer `flutter run`: amb *hot reload* no n'hi ha prou, perquè la clau entra en
compilar l'app.

## Web (Chrome)

La web carrega *Maps JavaScript API* amb una **altra clau**: cada clau només admet un tipus de restricció
d'aplicació, i la de la web es restringeix per adreça.

1. A Google Cloud, activa **Maps JavaScript API** i crea una clau nova.
2. Restriccions d'aplicació: **Llocs web**, amb `http://localhost:5000/*`. Restriccions d'API: només
   *Maps JavaScript API*.
3. Copia `web/maps_key.example.js` com a `web/maps_key.js` (no es versiona; és a `.gitignore`) i posa-hi la
   clau:

   ```js
   window.APROP_MAPS_WEB_KEY = 'la_clau_web';
   ```

4. Executa sempre amb el mateix port, perquè coincideixi amb la restricció:

   ```bash
   flutter run -d chrome --web-port 5000
   ```

`web/index.html` també carrega la llibreria `@googlemaps/markerclusterer` 2.5.3 (la versió que demana `google_maps_flutter_web`) per agrupar els marcadors; sense ella el mapa d'Inici falla amb `MarkerClusterer`.

Sense `web/maps_key.js` la web funciona igual, però el mapa no es pot dibuixar. Una clau de web sempre
acaba visible al navegador: per això la restricció d'adreça és imprescindible.

## Pendent

- **iOS** encara no està configurat: caldrà activar *Maps SDK for iOS* i donar la clau a `AppDelegate`
  sense versionar-la.
- Si les claus han d'anar al client o al backend és la decisió DP-004; el paquet de mapes i la ubicació
  exacta, la DP-020.
