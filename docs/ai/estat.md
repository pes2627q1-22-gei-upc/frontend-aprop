# Estat viu

> Llegir a l’inici; detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 2 · només frontend. Tasca activa #262: contrast i color del logotip respecte al fons.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #185 | [FE] Valoració d'1–5 estrelles a la fitxa i a l'Agenda | `feature/valorar-esdeveniment` | Implementada amb Demo; sense assistència ni #184 (DP-048); pendent revisió |
| #203 | [FE] Valorar l'organitzador (esdeveniments comunitaris) i actualitzar-ne la fiabilitat | `feature/valorar-organitzador-203` | PR oberta #50 (Demo DP-049); apilada sobre #45; pendent CI i revisió humana |
| #262 | [FE] Ajustar contrast i color del logotip respecte al fons | `feature/fix-262-logo-contrast` | Implementada; preparació de PR autoritzada; pendent CI i revisió humana |

## Base i abast

- Frontend `origin/develop@a5e15f5`: #253 fusionada a la PR #41 i millores del mapa incorporades des de la PR #42 abans de publicar #262.
- Es conserva `assets/branding/aprop_logo.png` com a original aprovat.
- Nou `aprop_logo_transparent.png`: edició del recurs existent sense fons crema opac i amb menys marge.
- `APropLogo` a `core/widgets/`: mateixa imatge, proporcions i etiqueta «AProp!» per a Inici i Login.
- Alçades anteriors conservades: 80 a Inici i 96 a Login; cap canvi de navegació, autenticació o tema global.
- No s’afegeixen paquets ni endpoints; backend sense modificar.
- DP-047 documenta la derivació visual i la validació de marca per l’equip.
- Guia: `docs/branding.md`; arquitectura i resum de mockups actualitzats.

## Verificació (2026-11-16)

- Dues regressions fallaven abans del canvi: alfa 255 al fons del logo a Inici i Login.
- Després del canvi, alfa zero a les cantonades i contrast del color opac majoritari ≥7:1 sobre crema i fons de targeta.
- 16 proves de marca, accés i navegació superades.
- Captures renderitzades amb Flutter i fonts Roboto a `PES/output/frontend/task-262-{inici,login}.png`, amb dades Demo.
- Suite completa: 525 proves superades. `flutter analyze` sense incidències.
- `dart format --output=none --set-exit-if-changed lib test`: 244 fitxers, cap canvi; `git diff --check` correcte.
- Revisió independent del diff i les captures sense bloquejos; afegit `TODO(DP-047)` al recurs com suggeria la revisió. La validació humana de marca queda pendent.
- Publicació de la branca autoritzada per l’usuari el 2026-11-16.

## Pendents

1. PR de #262 a develop, CI i revisió humana, inclosa la validació visual de marca.
2. Repassar Inici i Login al dispositiu Android; mode fosc fora d’aquesta tasca.
3. Els pendents de funcionalitats i contractes de #253 i la resta es conserven a les seves guies/DP.
