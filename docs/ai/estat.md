# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| pendent | Frontend Perfil propi i Configuració | frontend-aprop | `feature/profile` | Adam | implementat; analyze i 258 proves correctes; APK debug compilat; revisió humana/ID pendents; sense commit ni push |
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

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- El frontend no té workflow de CI.
- Inscripcions: API autenticada pendent; agenda demo connectada (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).
- Creació i mapa: contracte backend i decisions provisionals pendents (DP-017 a DP-022).
- Avisos: API, amistats reals, perfils i enviament pendents (DP-023; abans DP-017 a la branca).
- Descobreix/cerca: API, interessos i cerca de persones/perfils pendents (DP-024).
- Perfil/Configuració: contractes i integracions pendents (DP-025/DP-026); només perfil propi demo.

## Propers passos

1. Revisar Perfil/Configuració amb Adam en Android i incorporar l'ID/criteris de Taiga quan es creï la tasca.
2. Revisió humana abans de commit/PR i acord dels contractes d'API pendents.

## Traspàs entre eines

Última eina: Codex (2026-10-22) · Context mínim: aquest fitxer + `docs/profile.md` + DP-025/DP-026. Branca creada des de `origin/develop` (`3808c1d`); Perfil sense commit ni push.
