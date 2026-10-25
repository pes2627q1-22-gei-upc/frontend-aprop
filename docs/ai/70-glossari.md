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
| Persona creadora | Creador/a | `ActivityCreator` | `TODO` | `userId` opcional per autoria; `isFriend` → distintiu «Amiga/Amic» |
| Espai | Espacio | — (`municipality`) | `Place`, `Address`, `Latitude`, `Longitude` | |
| Municipi | Municipio | `municipality` | `TODO` | |
| Categoria | Categoría | `category` (String) | `TODO` | ≥ 1 per esdeveniment |
| Data d'inici / fi | Fecha inicio / fin | `startsAt` | `StartDate` / `EndDate` | |
| Inscripció («M'hi apunto» / «Apuntat») | Inscripción | `EnrollmentRepository`, `EnrollmentViewModel`, `enrolledActivityIds` | `TODO` | Intenció d'assistir; no és una compra ni una reserva. Contracte backend pendent (DP-010) |
| Desapuntar-se | Desapuntarse | `TODO` (unenroll) | `TODO` | |
| Assistència («Com va anar?») | Asistencia | `TODO` (attendance) | `TODO` | `null` = desconeguda |
| Agenda / Calendari | Agenda / Calendario | `TODO` (agenda) | `TODO` | Secció «Agenda» |
| Recordatori | Recordatorio | `TODO` (reminder) | `TODO` | Sense / 30 min / 1 h / 1 dia |
| Valoració | Valoración | `CompletedPlan.rating` | `TODO` | 1–5; projecció de plans fets, no implica implementar valoracions reals |
| Fiabilitat (organitzador) | Fiabilidad | `UserProfile.organizerRating` | `TODO` | Valoració rebuda; projecció demo pendent de dades reals (DP-025) |
| Usuari | Usuario | `AppUser` | `TODO` | `username` pot ser nul (primer accés amb Google) |
| Nom d'usuari | Nombre de usuario | `username` | `TODO` | Únic |
| Sol·licitud d'amistat | Solicitud de amistad | `FriendRequestStatus` a la projecció d'Avisos | `TODO` | Resposta demo: `pending` / `accepted` / `rejected`; contracte i graf real pendents (DP-023) |
| Amic / Amiga | Amigo / Amiga | `isFriend` | `TODO` | Derivat |
| Bloquejar | Bloquear | `TODO` (block) | `TODO` | |
| Avís / Notificació | Aviso / Notificación | `AppNotification`, `NotificationType`, `NotificationCategory`, `NotificationRepository`, `NotificationsViewModel` | `TODO` | Projecció de la bústia d'Avisos; no són enums del backend (DP-023) |
| Persona d'un avís | Persona de un aviso | `NotificationPerson` | `TODO` | Context visual; perfil i identitat de servidor pendents (DP-023) |
| Denúncia | Denuncia | `TODO` (report) | `TODO` | Usuari / Esdeveniment |
| Administrador | Administrador | — | `TODO` (admin) | Web d'administració |
| Xatbot / Assistent | Chatbot / Asistente | `AssistantRepository`, `AssistantViewModel`, `AssistantMessage`, `AssistantScreen` | `TODO` (gemini_client) | La UI diu «Assistent». Contracte backend pendent (DP-016) |
| Xat de l'activitat | Chat del evento | `TODO` (eventChat) | `TODO` | Cal inscripció |
| Test d'interessos | Test de intereses | `TODO` (interestTest) | `TODO` | 25 esdeveniments |
| Interès | Interés | `TODO` | `TODO` | /pes derivat |
| Experiència (XP) | Experiencia | `ProfileProgress.experience` | `TODO` | Projecció de GuanyExperiència; no s’atorguen XP en aquesta tasca |
| Nivell | Nivel | `ProfileLevel`, `ProfileProgress` | `TODO` | Curiós/a … Ambaixador/a cultural; llindars pendents (DP-025) |
| Configuració | Configuración | `ProfileSettings`, `ProfilePreference`, `ProfileSettingsRepository` | `TODO` | Preferències demo per compte (DP-026) |
| «Mostrar els meus plans» | Mostrar mis planes | `ProfileSettings.showMyPlans` | `TODO` | Privacitat; valor inicial fals; aplicació al servidor pendent |
| Descobreix | Descubre | secció 2 de `MainShell` | — | |
| Inici | Inicio | secció 0 de `MainShell` | — | Mapa / Llista |
| Perfil | Perfil | `UserProfile`, `ProfileRepository`, `ProfileViewModel`, secció 4 de `MainShell` | `TODO` | Perfil propi; perfils aliens pendents |
| Fallada d'accés | Error de acceso | `AuthFailure` | — | |

Quan creïs un nom nou, substitueix el `TODO` d'aquesta taula en el mateix canvi.
