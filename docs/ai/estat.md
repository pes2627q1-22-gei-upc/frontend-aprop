# Estat viu

> Llegir a l’inici; només el present (~40 línies). Detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 1. Dates i criteris detallats de Taiga pendents de confirmar.
- Prioritat actual: integrar l’MVP amb els endpoints reals; només es modifica el frontend.
- Social fora d’aquest sprint segons l’usuari.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #230 | Integració HTTP de Perfil | `feature/profile-backend` | Implementada; 440 proves, analyze, APK/web i revisió tècnica correctes; sense commit/push |
| #86 | Integració HTTP d’Avisos | `feature/notifications-backend` | Publicada a `8089a9d`; PR separada, pendent adaptar al bearer-only del nou develop |

## Base i abast actual

- Perfil parteix d’`origin/develop@70ccb27` (inclou PR #25/#27, CI #26/#28 i inscripcions #29).
- Backend consultat fins a `origin/develop@a67ae9e`; checkout/fitxers conservats sense canvis.
- Perfil: GET/PATCH propi, avatar de galeria, creades amb error separat i `show-plans` persistent.
- Sense dades Auth/Demo substituint errors, UUID inventats, assistències deduïdes o nivells ficticis.
- Demo conserva els exemples; les funcionalitats sense contracte s’indiquen pendents en HTTP.
- Arquitectura i flux: `docs/profile-backend.md`; adaptacions registrades a DP-040.

## Verificació (2026-10-27)

- Format correcte i `flutter analyze` sense incidències; 440 proves superades (base: 419).
- `flutter build apk --debug` i `flutter build web` correctes.
- Captures reals revisades: `PES/output/frontend/profile-backend-{principal,edicio,configuracio}.png`.
- Revisió vigilant-decisions sense bloquejos; cap commit, push ni canvi al backend.
- Firebase configurat localment; fitxers ignorats, no versionar credencials/configuració local.

## Pendents / següents passos

1. Prova autenticada real de Perfil: persistència, errors, S3 i galeria en Android físic; iOS Auth continua Demo.
2. Revisió humana, commit amb ID real, PR cap a develop i CI; no fusionar automàticament.
3. Backend: historial confirmat/valoracions, nivells, municipi i preferències d’avisos (DP-040).
4. Continuar Descobreix/test d’interessos en tasques separades; mapa/filtres encara tenen límits DP-038.
5. Auth, assistent, creació i serveis externs: contrastar les DP obertes abans de donar l’MVP per complet.
