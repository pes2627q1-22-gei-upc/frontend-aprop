# 10 · Requisits: èpiques i històries d'usuari

> **Quan llegir-ho:** en planificar un sprint, en començar una història (per saber-ne l'èpica i els SP) o en
> calcular hores. Els **criteris d'acceptació** són a Taiga: aquí només hi ha els que ja s'han aplicat al codi.
> **Font:** `docs/source/incepcio-2.pdf` §7. Backlog: <https://tree.taiga.io/project/wenqiange-aprop/backlog>

Equivalència: **1 SP ≈ 2 h**. Total del projecte: **193 SP** (≈ 386 h).
Columna «Sprint (entra, acaba)»: format de la memòria §1.4. `TODO(confirmar)` fins que es planifiqui a Taiga.

## Gestió d'usuaris — 31,5 SP

| Història | SP | Ref. Taiga |
|---|---|---|
| Iniciar sessió / Registre / Tancar sessió | 7 | #7 (tasca) |
| Eliminar compte | 1,5 | |
| Recuperar contrasenya | 2,5 | fora de l'Sprint 1 |
| Editar dades del compte | 1,5 | |
| Enviar sol·licitud d'amistat | 1,5 | |
| Cercar usuari | 3 | |
| Acceptar sol·licitud d'amistat | 3 | |
| Veure perfil d'usuari | 2,5 | |
| Bloquejar usuari | 4 | |
| Rebutjar sol·licitud d'amistat | 1,5 | |
| Eliminar un amic | 2 | |
| Veure la meva llista d'amistats | 1,5 | |

## Xatbot — 11,5 SP

| Història | SP |
|---|---|
| Demanar recomanacions al xatbot | 6 |
| Parlar amb el xatbot per veu | 5,5 |

## Notificacions — 26,5 SP

| Història | SP |
|---|---|
| Rebre notificacions quan s'acosten esdeveniments | 6 |
| Rebre notificacions quan un amic s'apunta a algun esdeveniment | 2,5 |
| Rebre notificacions amb recomanacions d'esdeveniments | 5,5 |
| Configurar les notificacions | 3 |
| Filtratge de notificacions | 2 |
| Rebre una notificació quan rebo una sol·licitud d'amistat | 1,5 |
| Rebre notificació quan una sol·licitud d'amistat s'accepta | 2 |
| Rebre notificacions quan es cancel·la un esdeveniment | 2 |
| Rebre notificació en pujar de nivell | 2 |

## Gestió d'esdeveniments — 60,5 SP

| Història | SP | Ref. Taiga |
|---|---|---|
| Veure un mapa amb els esdeveniments | 5 | |
| Clicar un esdeveniment per veure els detalls | 6 | #75 (tasca frontend) |
| Apuntar-se a un esdeveniment | 1 | #82 (tasca frontend) |
| Llista d'esdeveniments | 4 | #77 (tasca frontend) |
| Filtrar esdeveniments | 2 | |
| Xatejar amb persones que s'han apuntat a l'esdeveniment | 6 | |
| Fer test d'interessos | 8 | |
| Crear esdeveniment no oficial | 8 | |
| Buscar esdeveniment | 6 | |
| Cancel·lar esdeveniment no oficial | 5 | |
| Valorar esdeveniment | 5 | |
| Desapuntar-se d'un esdeveniment | 1,5 | |
| Editar esdeveniment no oficial | 2 | |
| Llista d'esdeveniments recomanats | 1 | |

## Configuració — 10,5 SP

| Història | SP |
|---|---|
| Canviar idioma | 5 |
| Canviar a mode fosc/clar | 2 |
| Repetir el test d'interessos | 0,5 |
| Configurar la visibilitat dels meus esdeveniments | 3 |

## Calendari — 11,5 SP

| Història | SP |
|---|---|
| Visualitzar calendari | 6 |
| Exportar al calendari de Google | 5,5 |

## Administració — 11 SP

| Història | SP |
|---|---|
| Denunciar | 3 |
| Desactivar compte | 4 |
| Retirar esdeveniment no oficial | 2 |
| Consultar denúncia | 2 |

## Gamificació — 30 SP

| Història | SP |
|---|---|
| Valorar l'organitzador d'un esdeveniment | 4 |
| Veure la puntuació de fiabilitat d'un organitzador | 1 |
| Modificar o eliminar la meva valoració | 1,5 |
| Rebre un recordatori per valorar un esdeveniment | 1,5 |
| Guanyar experiència en fer servir l'aplicació | 8 |
| Confirmar l'assistència a una activitat | 2 |
| Veure el meu nivell i el progrés d'experiència | 5 |
| Personalitzar el perfil segons el nivell | 4 |
| Consultar l'historial d'experiència | 3 |

## Criteris d'acceptació coneguts

- **#7 Accés:** vegeu `docs/architecture.md` § «Accés i sessió» (contrasenya ≥ 8 amb majúscula, minúscula,
  número i caràcter especial; confirmació; nom d'usuari únic; accés per nom o correu).
- **#75 Detall:** vegeu `docs/activity-details.md`.
- **#82 Inscripció:** llista i detall comparteixen estat; confirmació abans de «Apuntat», prevenció de duplicats, errors amb reintent i aïllament per compte. Implementació de demostració i contracte per a l'agenda a `docs/event-enrollment.md` (DP-010). Aquest comportament prové dels mockups aprovats i de la petició de l'usuari; falta contrastar els criteris complets a Taiga i integrar el backend.
- **Resta:** `TODO(confirmar)` — consulta Taiga. El comportament dels mockups (`50-ui-mockups.md`) en dona
  pistes, però no substitueix els criteris.
