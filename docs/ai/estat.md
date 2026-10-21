# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #86 | Frontend pantalla notificacions | frontend-aprop | `feature/notifications` | Adam | commit `c84a138` publicat i PR oberta; integració local de `develop` verificada (196 proves i APK debug), sense commit de fusió |
| — | Configuració d'IA per a l'equip | frontend-aprop | `feature/ai-setup` | Wenqiang | sense scripts/hooks; pendent PR |
| — | Configuració d'IA per a l'equip | api-aprop | `feature/ai-setup` | Wenqiang | pendent de revisió humana |

## Fet recentment (només l'últim sprint)

- #7 Accés demo (PR #2) i verificació de correu (PR #5).
- Backend: estructura handler/service/repository i `gencat_client` (PR #6).
- #75 Detall d'activitat (PR #3) i #82 inscripció (PR #6).
- #84 / #39 Agenda (PR #7) i #91 / #14 Assistent (PR #8), fusionades.
- #93 / #31 Creació d'activitats (PR #9 i #10) i #79 / #21 Mapa d'Inici (PR #14), fusionades a `develop`.

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada pendent; agenda demo connectada (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).
- Creació i mapa: contracte backend i decisions provisionals pendents (DP-017 a DP-022).
- Avisos: API, amistats reals, perfils i enviament pendents (DP-023; abans DP-017 a la branca).

## Propers passos

1. Adam revisa la resolució preparada, fa el commit de fusió i actualitza la mateixa PR de #86.
2. Revisió humana de la PR de la tasca #86 i acord dels contractes d'API pendents.

## Traspàs entre eines

Última eina: Codex (2026-10-21) · Context mínim: aquest fitxer + `docs/notifications.md` + DP-023. Fusió local en curs; cap commit de fusió ni push fet per l'assistent.
