# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #86 | Frontend pantalla notificacions | frontend-aprop | `feature/notifications` | Adam | demo local verificada; pendent revisió humana i PR |
| — | Configuració d'IA per a l'equip | frontend-aprop | `feature/ai-setup` | Wenqiang | sense scripts/hooks; pendent PR |
| — | Configuració d'IA per a l'equip | api-aprop | `feature/ai-setup` | Wenqiang | pendent de revisió humana |

## Fet recentment (només l'últim sprint)

- #7 Accés demo (PR #2) i verificació de correu (PR #5).
- Backend: estructura handler/service/repository i `gencat_client` (PR #6).
- #75 Detall d'activitat (PR #3) i #82 inscripció (PR #6).
- #84 / #39 Agenda (PR #7) i #91 / #14 Assistent (PR #8), fusionades.

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada pendent; agenda demo connectada (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).
- Avisos: API, amistats reals, perfils i enviament pendents (DP-017).

## Propers passos

1. Revisar #86, validar criteris de Taiga i preparar PR quan Adam ho autoritzi.
2. Acordar els contractes d'API pendents (DP-010, DP-016 i DP-017).

## Traspàs entre eines

Última eina: Codex (2026-10-19) · Context mínim: aquest fitxer + `docs/notifications.md` + DP-017. #86 sense commit ni push; implementació autoritzada, publicació pendent.
