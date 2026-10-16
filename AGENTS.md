# Instruccions per als assistents de codi

- Llegeix `README.md` i `docs/architecture.md` abans d’editar el projecte.
- L’usuari aprèn Flutter implementant el projecte per blocs. Respecta el límit d’acció del torn: quan demani explicacions o codi per copiar, no modifiquis fitxers; quan autoritzi canvis, aplica només l’abast autoritzat.
- Organitza les funcionalitats sota `lib/features/` amb models, contractes de repositori, implementacions a `data/` i presentació amb screens, view_models i widgets.
- Injecta els contractes de repositori per constructor; no posis dades de demostració ni peticions HTTP als widgets.
- Mantén models i contractes independents de Flutter. Els ViewModels no depenen de BuildContext ni construeixen widgets.
- `core/` només conté elements compartits i no depèn de `features/` ni d’`app/`.
- No dupliquis estat de negoci entre pantalles. Llista, detall i agenda hauran de compartir la font d’inscripcions.
- Segueix els mockups aprovats i utilitza català en la interfície.
- No incorporis paquets, endpoints, credencials ni funcionalitats fora de l’abast sense una necessitat concreta.
- Crea carpetes de funcionalitats quan es comenci el seu desenvolupament. Conserva les carpetes inicials buides amb `.gitkeep` fins que tinguin fitxers reals.
- The current task is Taiga #75, event details; #77 covers the list foundation. Use real task IDs and do not present pending backend integration as complete.
- Per a canvis de codi Dart, comprova format, `flutter analyze` i les proves pertinents. Per a canvis només de carpetes o documentació, comprova l’estructura i que el codi existent es conserva; no afegeixis proves que no verifiquen comportament.
- Indica sempre què has modificat i què has pogut verificar. Respecta el flux de branques, revisió i publicació autoritzat per l’usuari.
