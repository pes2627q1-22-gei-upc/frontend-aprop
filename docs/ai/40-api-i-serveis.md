# 40 · API i serveis

> **Quan llegir-ho:** en crear o consumir un endpoint, en integrar un servei extern o en tractar amb
> Talaia/Mobilicat. El contracte real és el codi del backend: si hi ha discrepància, mana el codi
> (`api-aprop/internal/router/router.go`) i cal actualitzar aquest fitxer.
> **Font:** `incepcio-2.pdf` §9.5 i §11, i l'estat de `api-aprop@develop`.

## Endpoints existents (backend `develop`)

| Mètode i ruta | Handler | Estat |
|---|---|---|
| `GET /events` | `EventHandler.ListEvents` | repositori en memòria |
| `GET /events/{id}` | `EventHandler.GetEvent` | repositori en memòria |
| `POST /events` | `EventHandler.CreateEvent` | repositori en memòria |

- JSON en **kebab-case** (`start-date`, `tickets-url`, `postal-code`…), definit pels tags de `event_model.Event`.
- `Event.Code` ve de la Generalitat i **no és únic** (es reutilitza si l'esdeveniment es repeteix o es fa a
  diversos llocs). La clau UML d'Oficial és `codi`: `TODO(confirmar)` com es reconcilia.
- Configuració per `.env`: `PORT`, `APP_TOKEN`, `GENCAT_EVENTS_URL`, `GENCAT_PAGE_SIZE` (tots obligatoris).

## Serveis produïts (per a altres equips; Mobilicat en particular)

| Servei | Paràmetres | Retorna | Ruta prevista |
|---|---|---|---|
| Llistat d'esdeveniments (oficials + no oficials) | filtres: data, categoria, municipi, preu | llista paginada | `GET /events` + query `TODO(confirmar)` |
| Detall d'un esdeveniment | id | títol, descripció, data i hora, lloc, coordenades, preu, categoria, imatge, /nombreInscrits, /valoracióMitjana | `GET /events/{id}` |
| Esdeveniments propers | coordenades + radi | llista ordenada per distància | `TODO(confirmar)` |
| Estimació d'afluència | zona + franja horària | estimació segons les inscripcions als esdeveniments de la zona | `TODO(confirmar)` (dissenyat per a Mobilicat) |

`TODO(confirmar)`: versionat de l'API (`/v1`?), format d'errors, autenticació dels equips externs i
documentació del contracte (OpenAPI a `api-aprop/api/`?).

## Serveis consumits (sempre des del backend, excepte on s'indica)

| Servei | Ús | Si falla |
|---|---|---|
| Firebase Auth (OIDC, Google) | identitat; el backend valida el token | sense sessió nova |
| Google Maps | mapa i marcadors | el llistat continua |
| Google Calendar API | exportació unidireccional amb consentiment explícit | el calendari intern és autònom |
| Gemini | xatbot: consulta + context → recomanacions del catàleg | missatge d'error clar; resta de l'app OK |
| Google Translate | traduir títols i descripcions (originals en català) | es mostra l'original |
| Dades Obertes de Catalunya | importació d'esdeveniments oficials (dataset `rhpv-yr4f`) | es manté el darrer catàleg |
| Talaia (PES) | esdeveniments astronòmics (pluges d'estels, eclipsis, observacions) → `Extern` | es mostren només els propis |

- **Condicions:** citar la font de les dades obertes; complir els termes de Google, Firebase i Gemini.
- **Contractes amb Talaia i Mobilicat:** acordats en una reunió a classe; l'intercanvi es fa per WhatsApp i
  correu. Rutes, formats i autenticació: `TODO(confirmar)`. Quan es concretin, documenta'ls aquí.
- **Abstracció:** cada servei té una interfície a `internal/clients/<x>_client/interface.go` (patró de
  `gencat_client`) i un *fake* per a proves. Vegeu la skill `integracio-externa`.

## Frontend

Client HTTP centralitzat: [`ApiClient`](../../lib/core/network/api_client.dart) sobre `package:http` i configurat a [`ApiConfig`](../../lib/core/config/api_config.dart).
- **URL Base per defecte (Render):** `https://api-aprop.onrender.com` (es pot sobreescriure amb `--dart-define=API_BASE_URL=http://10.0.2.2:8080`).
- **Cold Start (Render Free):** `connectTimeout = Duration(seconds: 60)`.
- **Capçaleres comunes:** `Accept: application/json`, `Content-Type: application/json`, `Authorization: Bearer <firebase_id_token>` i `X-User-ID: <firebase_uid>`.
- **Format JSON i d'errors:** Claus en `kebab-case` traduïdes a `camelCase` als repositoris HTTP; errors `{"error": "..."}` descodificats en `ApiException`.

| Endpoint | Ús al frontend | Estat |
|---|---|---|
| `POST /auth/sync` | `HttpUserSyncRepository`: token de Firebase + `X-User-ID`; cos `{"username"}` opcional | Connectat a Render (`develop`) |
| `GET /users/me`, `PATCH /users/me`, `GET /users/me/created-events` | `HttpProfileRepository`, `HttpProfileSettingsRepository`, `HttpUserSyncRepository` | Connectat a Render (`develop`) |
| `GET /events`, `GET /events/{id}`, `POST /events`, `GET /categories` | `HttpActivityRepository` | Connectat a Render (`develop`) |
| `GET /events/map` | `HttpActivityMapRepository` | Connectat a Render (`develop`) |
| `GET /events/search` | `HttpDiscoveryRepository` | Connectat a Render (`develop`) |
| `POST /events/{id}/signup`, `DELETE /events/{id}/signup`, `GET /users/{userId}/events` | `HttpEnrollmentRepository` | Connectat a Render (`develop`) |
| `POST /assistant/messages`, `GET /assistant/conversation` | `HttpAssistantRepository` | Connectat a Render (`develop`) |
| `GET /notifications/user/{id}`, `POST /notifications/{id}/read` | `HttpNotificationRepository` | Connectat a Render (`develop`) |
