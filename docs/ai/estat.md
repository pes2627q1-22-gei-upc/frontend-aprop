# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #91 / #14 | Frontend xat (Demanar recomanacions al xatbot) | frontend-aprop | `feature/assistant` | Wenqiang | PR oberta cap a `develop` |
| #79 / #21 | Frontend mapa d'Inici (Veure un mapa amb els esdeveniments) | frontend-aprop | `feature/mapa-inici` | Sukhjeet | pendent de PR (DP-022) |
| #93 / #31 | Frontend pantalla creació (Crear esdeveniment no oficial) | frontend-aprop | `feature/crear-esdeveniment` | Sukhjeet | pendent de PR (DP-017 a DP-021) |
| #84 / #39 | Frontend pantalla calendari (Agenda) | frontend-aprop | `feature/calendar` | — | PR oberta [#7](https://github.com/pes2627q1-22-gei-upc/frontend-aprop/pull/7) |
| — | Configuració d'IA per a l'equip | frontend-aprop | `feature/ai-setup` | Wenqiang | sense scripts/hooks; pendent PR |
| — | Configuració d'IA per a l'equip | api-aprop | `feature/ai-setup` | Wenqiang | pendent de revisió humana |

## Fet recentment (només l'últim sprint)

- #7 Login/Register/Logout amb comptes de demostració (frontend, PR #2).
- #75 Pantalla de detall d'esdeveniment (frontend, PR #3).
- Verificació de correu abans d'entrar a l'app (frontend, PR #5).
- Backend: estructura handler/service/repository i `gencat_client` (PR #6).
- #82 Frontend apuntar-se a un esdeveniment (frontend, PR #6).

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada i connexió de l'agenda pendents (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).

## Propers passos

1. Revisar `feature/assistant` i `feature/calendar`, i concretar a Taiga l'ID de la tasca de l'assistent.
2. Acordar el contracte d'API del xatbot amb el backend (DP-016).

## Traspàs entre eines

Última eina: Antigravity (2026-10-19) · Context mínim: aquest fitxer + `lib/features/assistant/` + DP-016. Branca `feature/assistant` creada des de `develop` sense commit; pendent de revisió humana.
