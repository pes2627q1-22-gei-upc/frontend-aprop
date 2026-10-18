# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #82 | Frontend apuntar-se a un esdeveniment | frontend-aprop | `feature/event-enrollment` | Adam | demo validada localment; preparació de PR i revisió humana pendents |
| — | Configuració d'IA per a l'equip | frontend-aprop | `feature/ai-setup` | Wenqiang | sense scripts/hooks; pendent PR |
| — | Configuració d'IA per a l'equip | api-aprop | `feature/ai-setup` | Wenqiang | pendent de revisió humana |

## Fet recentment (només l'últim sprint)

- #7 Login/Register/Logout amb comptes de demostració (frontend, PR #2).
- #75 Pantalla de detall d'esdeveniment (frontend, PR #3).
- Verificació de correu abans d'entrar a l'app (frontend, PR #5).
- Backend: estructura handler/service/repository i `gencat_client` (PR #6).

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada i connexió de l'agenda pendents (DP-010).

## Propers passos

1. Revisar `feature/ai-setup` (ja sense `scripts/ai/` ni hooks) i obrir/actualitzar la PR.
2. Concretar a Taiga les històries de l'Sprint 1 i omplir la taula «En curs».

## Traspàs entre eines

Última eina: Codex (2026-10-18) · Context mínim: aquest fitxer + `docs/event-enrollment.md` + DP-010. Publicació de #82 autoritzada per Adam; cap merge autoritzat.
