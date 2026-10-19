# Crear activitat no oficial — Taiga #31 (tasca #93)

## Comportament

- A Inici hi ha el botó flotant «Crear activitat» (CA1). Obre el formulari «Crea una activitat» dins de la mateixa secció; la navegació inferior continua visible.
- Camps: títol (obligatori, màxim 80 caràcters), descripció (obligatòria, màxim 1.000), categoria (obligatòria, una sola, amb un desplegable), data i hora d'inici (obligatòria i posterior al moment de crear-la), municipi (obligatori), preu (opcional; buit vol dir gratuïta) i imatge (obligatòria, una de les plantilles).
- No hi ha hora de final: és opcional al CA1 i l'equip ha decidit no demanar-la de moment.
- En publicar, la fitxa de l'activitat nova substitueix el formulari. La persona creadora hi queda apuntada automàticament. En tornar enrere, l'activitat surt a la llista amb les oficials, ordenada per data i amb «Publicat per» i el nom de qui l'ha creat (CA2).
- La fitxa mostra el preu: «Gratuït» o l'import («12,50 €»). Les activitats oficials de demostració no en tenen i no el mostren.
- El CA1 permet diverses categories i la fotografia és opcional. De moment l'equip ha decidit una sola categoria i imatge obligatòria, perquè el model `Activity` no canviï i les altres pantalles (com l'agenda) no s'hagin d'adaptar.

## Fitxers

```text
features/activities/models/activity.dart                 price i avatar opcionals
features/activities/models/new_activity.dart             dades del formulari
features/activities/models/activity_options.dart         categories i plantilles provisionals
features/activities/repositories/activity_repository.dart  createActivity(NewActivity)
features/activities/data/demo_activity_repository.dart   afegeix l'activitat al catàleg en memòria
features/activities/presentation/view_models/create_activity_view_model.dart
features/activities/presentation/screens/create_activity_screen.dart
features/activities/presentation/formatters/activity_price_formatter.dart
app/navigation/main_shell.dart                           botó, ruta i què passa en publicar
```

`CreateActivityViewModel` valida i publica; no sap res de navegació ni d'inscripcions. `MainShell` rep l'activitat creada, apunta la persona creadora amb l'`EnrollmentViewModel` compartit, recarrega la llista i substitueix el formulari per la fitxa.

## Canvis al model compartit

Només dos canvis compatibles amb el codi existent: s'afegeix `price` (opcional, en euros; `0` és gratuïta i nul vol dir que no se sap) i `ActivityCreator.avatarAsset` passa a ser opcional, perquè qui crea una activitat no té foto; la targeta i la fitxa hi mostren una icona. `category` i `imageAsset` no canvien.

El formatador de dates escriu «d’octubre», «d’abril» i «d’agost» en lloc de «de octubre».

## Dades de demostració i pendent

- Les activitats creades es guarden en memòria i es perden en tancar l'aplicació.
- Categories provisionals: Música, Teatre i Exposicions. L'equip encara ha de tancar la llista; es canvia a `activity_options.dart`.
- Imatges: de moment, les tres fotografies de demostració fan de plantilla i se n'ha de triar una. Pujar fotos pròpies és la tasca #94; llavors es podrà decidir si la imatge torna a ser opcional.
- Ubicació: només el municipi. Per sortir al mapa (CA2 i història #21) caldrà demanar el punt o les coordenades.
- Quan el backend apunti la persona creadora en crear l'activitat, la crida a `enroll` de `MainShell` sobrarà (`TODO(backend)`).
- Els selectors de data i hora tenen els botons en català, però els noms dels mesos i dels dies del calendari surten en anglès fins que l'app configuri `flutter_localizations` per a català i castellà.
- Editar i esborrar les activitats pròpies queda per a una altra història.

## Proves

- `test/features/activities/create_activity_view_model_test.dart`: validacions (també categoria i imatge obligatòries), data posterior a ara, preu, errors, doble enviament i repositori de demostració.
- `test/features/activities/create_activity_screen_test.dart`: omplir el formulari amb el desplegable de categoria i els selectors de data i hora i publicar; errors si falten camps.
- `test/app/create_activity_flow_test.dart`: des d'Inici fins a la fitxa (amb «Apuntat») i la llista.
