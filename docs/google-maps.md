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

## Pendent

- **iOS** encara no està configurat: caldrà activar *Maps SDK for iOS* i donar la clau a `AppDelegate`
  sense versionar-la.
- Si les claus han d'anar al client o al backend és la decisió DP-004; el paquet de mapes i la ubicació
  exacta, la DP-020.
