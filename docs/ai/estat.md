# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #87 | Frontend filtrar esdeveniments | frontend-aprop | `feature/activity-filters` | Adam | 366 proves; conflicte amb PR #22 resolt; commit de merge/push i revisió humana pendents |
| — | Configuració d'IA per a l'equip | frontend-aprop | `feature/ai-setup` | Wenqiang | sense scripts/hooks; pendent PR |
| — | Configuració d'IA per a l'equip | api-aprop | `feature/ai-setup` | Wenqiang | pendent de revisió humana |

## Fet recentment (només l'últim sprint)

- #7 Accés demo (PR #2) i verificació de correu (PR #5).
- Backend: estructura handler/service/repository i `gencat_client` (PR #6).
- #75 Detall d'activitat (PR #3) i #82 inscripció (PR #6).
- #84 / #39 Agenda (PR #7) i #91 / #14 Assistent (PR #8), fusionades.
- #93 / #31 Creació d'activitats (PR #9 i #10) i #79 / #21 Mapa d'Inici (PR #14), fusionades a `develop`.
- #86 Avisos fusionats a `develop` (PR #15); conflictes resolts preservant les DP anteriors.
- #96 Descobreix i cerca fusionades a `develop` (PR #16).
- #230 Perfil (PR #20) i mapa connectat al backend (PR #21), fusionats a `develop`.
- Grups del mapa: zoom i llista al mateix lloc, fusionats a `develop` (PR #22).

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada pendent; agenda demo connectada (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).
- Creació i mapa: contracte backend i decisions provisionals pendents (DP-017 a DP-022).
- Avisos: API, amistats reals, perfils i enviament pendents (DP-023; abans DP-017 a la branca).
- Descobreix/cerca: API, interessos i cerca de persones/perfils pendents (DP-024).
- Filtres: contracte, categories i catàleg compartit pendents (DP-035/DP-029).
- Firebase local: sessió iniciada, però sense permisos del projecte; configuració absent.
- Perfil/Configuració: contractes i integracions pendents (DP-032/DP-033); només perfil propi demo.

## Propers passos

1. Revisar i publicar el merge de `develop` a #87 per actualitzar la PR; contrastar criteris de Taiga.
2. Generar Firebase quan el compte tingui accés al projecte (`docs/firebase-auth.md`).
3. Revisió humana abans de commit/PR i acord dels contractes d’API pendents.

## Traspàs entre eines

2026-10-25 · Context: aquest fitxer, `docs/activity-filters.md` i DP-035/DP-029.
Branca `feature/activity-filters`: codi publicat a `e7d7343`; merge de `c0815d9` resolt, sense finalitzar.
