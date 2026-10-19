# Crear activitat no oficial — Taiga #31 (tasca #93)

## Comportament

- A Inici hi ha el botó flotant «Crear activitat» (CA1). Obre el formulari «Crea una activitat» dins de la mateixa secció; la navegació inferior continua visible.
- Camps: títol (obligatori, màxim 80 caràcters), descripció (obligatòria, màxim 1.000), categoria (obligatòria, una sola, en una fila horitzontal que es pot desplaçar), data i hora d'inici (obligatòria i posterior al moment de crear-la), municipi (obligatori), indicacions per arribar-hi (opcionals, màxim 200 caràcters), preu (opcional; buit vol dir gratuïta) i imatge de portada.
- La portada surt a dalt del formulari, gran, amb la primera plantilla per defecte. El botó del llapis obre un panell amb «Puja una foto» (desactivat fins a la tasca #94) i les plantilles per triar-ne una altra.
- La data i l'hora es trien en un panell inferior amb rodes (dia, mes i any, i l'hora cada 15 minuts), amb un resum a dalt. Per defecte proposa demà a les 19.00 i no deixa acceptar un moment que ja ha passat. Els mesos surten en català i l'hora en format de 24 hores.
- No hi ha hora de final: és opcional al CA1 i l'equip ha decidit no demanar-la de moment.
- En publicar, la fitxa de l'activitat nova substitueix el formulari. La persona creadora hi queda apuntada automàticament. En tornar enrere, l'activitat surt a la llista amb les oficials, ordenada per data i amb «Publicat per» i el nom de qui l'ha creat (CA2).
- La fitxa mostra les indicacions, si n'hi ha, sota el municipi, i el preu: «Gratuït» o l'import («12,50 €»). Les activitats oficials de demostració no en tenen i no el mostren.
- El CA1 permet diverses categories i la fotografia és opcional. De moment hi ha una sola categoria i sempre una imatge (la plantilla per defecte), perquè el model `Activity` no canviï i les altres pantalles (com l'agenda) no s'hagin d'adaptar. Decisions pendents: DP-017 (contracte del backend), DP-018 (categories), DP-019 (imatge), DP-020 (ubicació i mapa) i DP-021 (disseny sense mockup).

## Fitxers

```text
features/activities/models/activity.dart                 price i avatar opcionals
features/activities/models/new_activity.dart             dades del formulari
features/activities/models/activity_options.dart         categories i plantilles provisionals
features/activities/repositories/activity_repository.dart  createActivity(NewActivity)
features/activities/data/demo_activity_repository.dart   afegeix l'activitat al catàleg en memòria
features/activities/presentation/view_models/create_activity_view_model.dart
features/activities/presentation/screens/create_activity_screen.dart
features/activities/presentation/widgets/start_date_time_sheet.dart   panell de data i hora
features/activities/presentation/formatters/activity_price_formatter.dart
app/navigation/main_shell.dart                           botó, ruta i què passa en publicar
```

`CreateActivityViewModel` valida i publica; no sap res de navegació ni d'inscripcions. `MainShell` rep l'activitat creada, apunta la persona creadora amb l'`EnrollmentViewModel` compartit, recarrega la llista i substitueix el formulari per la fitxa.

## Canvis al model compartit

Només canvis compatibles amb el codi existent: s'afegeixen `price` (opcional, en euros; `0` és gratuïta i nul vol dir que no se sap) i `directions` (opcional), i `ActivityCreator.avatarAsset` passa a ser opcional, perquè qui crea una activitat no té foto; la targeta i la fitxa hi mostren una icona. `category` i `imageAsset` no canvien.

El formatador de dates escriu «d’octubre», «d’abril» i «d’agost» en lloc de «de octubre».

## Dades de demostració i pendent

- Les activitats creades es guarden en memòria i es perden en tancar l'aplicació.
- Categories provisionals: Música, Teatre i Exposicions. L'equip encara ha de tancar la llista; es canvia a `activity_options.dart`.
- Imatges: de moment, les tres fotografies de demostració fan de plantilla. Pujar fotos pròpies és la tasca #94: caldrà un paquet per obrir la galeria (com `image_picker`) i que el backend guardi la foto (S3, segons el CA1). El botó «Puja una foto» ja és al panell, desactivat.
- Ubicació: el municipi i, opcionalment, indicacions en text. Per sortir al mapa (CA2 i història #21) caldrà un punt amb coordenades: la proposta és centrar el mapa al municipi i deixar ajustar el marcador. Està pendent que l'equip triï el paquet de mapes, que també farà servir la història #21.
- Quan el backend apunti la persona creadora en crear l'activitat, la crida a `enroll` de `MainShell` sobrarà (`TODO(DP-017)`).
- Editar i esborrar les activitats pròpies queda per a una altra història.

## Proves

- `test/features/activities/create_activity_view_model_test.dart`: validacions, portada per defecte, data posterior a ara, indicacions, preu, errors, doble enviament i repositori de demostració.
- `test/features/activities/create_activity_screen_test.dart`: omplir el formulari (portada, categoria, rodes de data i hora) i publicar; panell de la portada; rodes, moment passat i cancel·lar; errors si falten camps.
- `test/app/create_activity_flow_test.dart`: des d'Inici fins a la fitxa (amb «Apuntat») i la llista.
