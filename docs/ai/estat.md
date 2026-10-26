# Estat viu

> Llegir a l’inici i en passar feina entre eines. Només estat actual; detalls a les guies.

## Sprint

Sprint 1 · dates/objectiu del frontend pendents de contrastar amb la planificació de l’equip.

## En curs

| Taiga | Tasca | Branca | Responsable | Estat |
|---|---|---|---|---|
| #86 | Bústia i lectura d’Avisos HTTP | `feature/notifications-backend` | Adam | Implementada; validació real amb Render pendent; sense commit |
| — | Configuració d’IA de l’equip | `feature/ai-setup` | Wenqiang | PR/revisió pendent als dos repositoris |

## Fet recentment

- Accés #7, detall #75, inscripcions #82, Agenda #84/#39, Assistent #91/#14 i creació #93/#31 tenen frontend.
- Avisos #86 (PR #15), Descobreix #96 (PR #16), Perfil #230 (PR #20), mapa (PR #21/#22), filtres #87 (PR #24) i client HTTP #231 (PR #23) són a develop; la integració real es verifica per secció.
- Llista real #77 fusionada (PR #25). Filtres HTTP #87 publicats a `8aee081`, base de la branca actual.
- Avisos: UUID real autenticat, catàleg de tipus, lectura confirmada i context absent conservat; accions socials fora de l’Sprint 1 per acord de l’usuari (DP-039).

## Bloquejos i límits

- Render sense resposta en 15 s a `/notificationtypes`; sessió real/persistència encara no verificades. Firebase Android/web local configurat i ignorat per Git.
- Backend d’Avisos: autoritzar destinatari, concretar zona horària i confirmar generació automàtica de recordatoris/recomanacions. Traspàs a `docs/notifications-backend-handoff.md`.
- Mapa: categories/filtres del servidor i ordre estable pendents (DP-029/DP-035/DP-037/DP-038).
- Agenda/inscripcions, creació i Assistent: adaptadors existents; revisar identitat i recorregut real (DP-010/DP-016/DP-017/DP-036).
- Descobreix/cerca i Perfil/Configuració són les integracions següents; contrastar contractes i criteris (DP-024/DP-032/DP-033).
- Talaia/Mobilicat sense concretar (DP-006); CI frontend pendent a develop revisat.

## Propers passos

1. Revisió humana i PR d’Avisos després d’integrar #87; cap commit/push automàtic.
2. Comunicar el traspàs al backend; social no bloqueja aquest sprint.
3. Integrar el que falti de Descobreix/Perfil i provar login → filtrar → detall → inscripció → Agenda → recàrrega.

## Traspàs

2026-10-27 · `docs/notifications-backend.md`, DP-039/DP-023. Branca des de `8aee081`; només frontend.
