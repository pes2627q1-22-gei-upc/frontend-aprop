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

## Fitxers

```text
features/activities/presentation/widgets/activities_map.dart     mapa, marcadors, targeta i llegenda
features/activities/presentation/screens/activities_screen.dart  selector Mapa / Llista
features/activities/data/demo_activity_repository.dart          coordenades de les activitats de demostració
assets/icons/marker_official.png · marker_community.png · marker_friend.png
```

Els marcadors són imatges generades amb els colors del tema (`forest`, `coral` i el groc del distintiu
«Amiga»), a 144 × 184 px, i es dibuixen a 36 px d'amplada.

## Pendent

- **Clau de Google Maps**: sense clau el mapa surt en gris i no es veu cap marcador. Vegeu [Google Maps](google-maps.md).
- **Càrrega per zona visible (CA3, < 3 s)**: ara es mostren totes les activitats carregades; caldrà un endpoint
  que retorni les activitats d'una zona (DP-022).
- **Color dels grups**: el número dels grups el dibuixa Google amb el seu estil per defecte, no amb el verd del
  mockup (DP-022).
- Filtres de zona, dates i categories: història #25, fora d'aquesta.
- El botó de la meva ubicació del mockup no hi és: necessitaria permisos de localització.

## Proves

`test/features/activities/activities_map_test.dart`: selector Mapa / Llista, un marcador per activitat amb el
tipus i el grup correctes, targeta i «Veure activitat», tancar-la, activitats sense ubicació i llegenda.
A les proves, `test/flutter_test_config.dart` substitueix el mapa per un espai buit.
