# Estat viu

> **Quan llegir-ho:** sempre a l'inici d'una sessió (és curt) i en passar la feina d'una eina a una altra.
> S'actualitza en tancar la sessió amb `/tancar-sessio`. Màxim ~40 línies: només el present.

## Sprint

- Fase: Sprint 1 `TODO(confirmar dates)`
- Objectiu del sprint: `TODO(confirmar)`

## En curs

| Taiga | Història / tasca | Repo | Branca | Responsable | Estat |
|---|---|---|---|---|---|
| #87 | Filtres d’Inici al servidor (ampliació) | frontend-aprop | `feature/inici-server-filters` | Adam | 417 proves i APK correctes; revisió feta; verificació amb Render/mapa pendent; sense commit |
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
- Grups del mapa (PR #22), filtres #87 (PR #24) i client HTTP #231 (PR #23), fusionats a `develop`.
- #77 llista real publicada a `9c35672`; encara no era a `origin/develop` en començar aquesta ampliació.

## Bloquejos

- Contractes amb Talaia i Mobilicat sense concretar (`40-api-i-serveis.md`).
- Inscripcions: API autenticada pendent; agenda demo connectada (DP-010).
- Assistent (xatbot): contracte d'API amb el backend i Gemini pendent (DP-016).
- Creació i mapa: contracte backend i decisions provisionals pendents (DP-017 a DP-022).
- Avisos: API, amistats reals, perfils i enviament pendents (DP-023; abans DP-017 a la branca).
- Descobreix/cerca: API, interessos i cerca de persones/perfils pendents (DP-024).
- Filtres: llista connectada amb dates/IDs reals; mapa sense filtres/categories del servidor (DP-029/DP-035/DP-038).
- Firebase local d’Adam: Android/web configurats, SHA-1 registrada; no versionar fitxers locals.
- Perfil/Configuració: contractes i integracions pendents (DP-032/DP-033); només perfil propi demo.

## Propers passos

1. Integrar la PR de #77 abans de portar aquesta ampliació de #87 a `develop`; revisió humana obligatòria.
2. Coordinar backend: categories/filtres del mapa, multiselecció/ordre estable, disponibilitat i CORS.
3. Verificar login → filtrar → detall → inscripció → agenda → recàrrega; API només de lectura aquí.

## Traspàs entre eines

2026-10-26 · Context: `docs/inici-server-filters.md`, DP-038/DP-035/DP-037.
Branca `feature/inici-server-filters` des de `9c35672`. Només frontend; sense commit ni push.
