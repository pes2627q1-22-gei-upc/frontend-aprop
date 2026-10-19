# 70 · Glossari català ↔ codi

> **Quan llegir-ho:** quan hagis de posar nom a un model, camp, endpoint o clau de traducció, o quan
> trobis un terme del domini i no sàpigues com es diu al codi. La UI és en català; el codi, en anglès.
> Si el terme ja existeix al codi, **mana el codi** (columnes «Frontend» i «Backend»).

| Domini (ca) | Castellà | Frontend (Dart) | Backend (Go) | Notes |
|---|---|---|---|---|
| Activitat / Esdeveniment | Actividad / Evento | `Activity` | `event_model.Event` | La UI diu «activitat»; el UML, «Esdeveniment» |
| Oficial (Agenda Cultural) | Oficial | `ActivitySource.culturalAgenda` | `TODO` | Dades Obertes; `Code` no és únic |
| No oficial (d'usuari) | No oficial | `ActivitySource.community` | `TODO` | Creat per un usuari; denunciable |
| Extern (Talaia) | Externo | `TODO` | `TODO` | Altres equips PES |
| Persona creadora | Creador/a | `ActivityCreator` | `TODO` | `isFriend` → distintiu «Amiga/Amic» |
| Espai | Espacio | — (`municipality`) | `Place`, `Address`, `Latitude`, `Longitude` | |
| Municipi | Municipio | `municipality` | `TODO` | |
| Categoria | Categoría | `category` (String) | `TODO` | ≥ 1 per esdeveniment |
| Data d'inici / fi | Fecha inicio / fin | `startsAt` | `StartDate` / `EndDate` | |
| Inscripció («M'hi apunto» / «Apuntat») | Inscripción | `EnrollmentRepository`, `EnrollmentViewModel`, `enrolledActivityIds` | `TODO` | Intenció d'assistir; no és una compra ni una reserva. Contracte backend pendent (DP-010) |
| Desapuntar-se | Desapuntarse | `TODO` (unenroll) | `TODO` | |
| Assistència («Com va anar?») | Asistencia | `TODO` (attendance) | `TODO` | `null` = desconeguda |
| Agenda / Calendari | Agenda / Calendario | `TODO` (agenda) | `TODO` | Secció «Agenda» |
| Recordatori | Recordatorio | `TODO` (reminder) | `TODO` | Sense / 30 min / 1 h / 1 dia |
| Valoració | Valoración | `TODO` (rating) | `TODO` | 1–5 |
| Fiabilitat (organitzador) | Fiabilidad | `TODO` (reliability) | `TODO` | Derivada |
| Usuari | Usuario | `AppUser` | `TODO` | `username` pot ser nul (primer accés amb Google) |
| Nom d'usuari | Nombre de usuario | `username` | `TODO` | Únic |
| Sol·licitud d'amistat | Solicitud de amistad | `TODO` (friendRequest) | `TODO` | Pendent / Acceptada / Rebutjada |
| Amic / Amiga | Amigo / Amiga | `isFriend` | `TODO` | Derivat |
| Bloquejar | Bloquear | `TODO` (block) | `TODO` | |
| Avís / Notificació | Aviso / Notificación | `TODO` (notification) | `TODO` | Secció «Avisos» |
| Denúncia | Denuncia | `TODO` (report) | `TODO` | Usuari / Esdeveniment |
| Administrador | Administrador | — | `TODO` (admin) | Web d'administració |
| Xatbot / Assistent | Chatbot / Asistente | `AssistantRepository`, `AssistantViewModel`, `AssistantMessage`, `AssistantScreen` | `TODO` (gemini_client) | La UI diu «Assistent». Contracte backend pendent (DP-016) |
| Xat de l'activitat | Chat del evento | `TODO` (eventChat) | `TODO` | Cal inscripció |
| Test d'interessos | Test de intereses | `TODO` (interestTest) | `TODO` | 25 esdeveniments |
| Interès | Interés | `TODO` | `TODO` | /pes derivat |
| Experiència (XP) | Experiencia | `TODO` (xp) | `TODO` | GuanyExperiència |
| Nivell | Nivel | `TODO` (level) | `TODO` | Curiós/a … Ambaixador/a cultural |
| Configuració | Configuración | `TODO` (settings) | `TODO` | |
| «Mostrar els meus plans» | Mostrar mis planes | `TODO` (showMyPlans) | `TODO` | Privacitat |
| Descobreix | Descubre | secció 2 de `MainShell` | — | |
| Inici | Inicio | secció 0 de `MainShell` | — | Mapa / Llista |
| Perfil | Perfil | secció 4 de `MainShell` | — | |
| Fallada d'accés | Error de acceso | `AuthFailure` | — | |

Quan creïs un nom nou, substitueix el `TODO` d'aquesta taula en el mateix canvi.
