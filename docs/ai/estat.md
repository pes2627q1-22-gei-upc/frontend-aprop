# Estat viu

> Llegir a l’inici; només el present (~40 línies). Detalls a les guies de cada funcionalitat.

## Sprint

- Sprint 1 · només frontend. Social fora d’aquest sprint segons l’usuari.
- Prioritat: integrar Descobreix i després revisar el recorregut real de l’MVP.

## En curs

| Taiga | Tasca | Branca | Estat |
|---|---|---|---|
| #96 | Descobreix HTTP i cerca paginada | `feature/discovery-backend` | Implementada; 497 proves, analyze, APK/web i revisió correctes; sense commit/push |

## Base i abast

- Frontend `origin/develop@60fbebc`; Perfil (PR #32), Avisos (#31), creació (#30) i verificació web (#33) fusionats.
- Backend actualitzat a `develop@be6c25e`, sense canvis locals ni execució del servidor/BD.
- «Per a tu» → `/events/recommended`; «Destacats» → `/events/popular`; preferències → `/preferences`.
- Cerca → `/events/search`, pàgina 0, total real, continuació/reintent i deduplicació per ID.
- Preferències absents són un estat propi; un error de secció no amaga la resta ni elimina dades confirmades.
- Mateixes targetes, detall, navegadors i inscripcions compartides; sense paquets nous ni dades demo en HTTP.
- Models/contractes purs i ViewModels sense transport; Demo adapta el mateix contracte paginat.
- Límits de ranking/dates/cerca: DP-041 actualitza DP-024; guia `docs/discovery-backend.md`.

## Verificació (2026-10-27)

- Format: 237 fitxers, cap canvi pendent; analitzador sense incidències; 497 proves (base: 481).
- Flux HTTP provat: feed → apuntar-se → cerca → pàgina 1 → detall → retorn → Apuntat a Inici.
- APK debug i web compilats; revisió tècnica sense bloquejos.
- Captures reals de Flutter revisades: `PES/output/frontend/discovery-backend-{feed,search,page-1}.png`.
- Cap commit/push ni canvi al backend; Firebase local ignorat, no versionar credencials/configuració.

## Pendents / següents passos

1. Revisió humana, commit #96, PR a develop i CI; no fusionar automàticament.
2. Provar Render amb comptes amb/sense gustos i persistència; contrastar desplegament dels endpoints nous.
3. Frontend del test d’interessos i accés per repetir-lo: història separada, endpoints disponibles.
4. Repàs global de les 5 seccions, dades/inscripcions/avisos/imatges i errors amb la versió real del servidor.
5. Backend: ranking global, pesos incomplets, activitats futures i ordre estable (DP-041); revisar DP-039/040.
