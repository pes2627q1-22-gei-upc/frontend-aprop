# Xat de l'activitat — Taiga #26 «Xatejar amb persones que s'han apuntat a l'esdeveniment»

## Comportament

- **Botó a la fitxa** (fig. 9, CA1): «Xat de l'activitat» només està actiu si la persona s'hi ha apuntat
  (R11). Si no, queda desactivat i diu «Apunta't a l'activitat per poder parlar al xat.». L'estat
  d'inscripció és el compartit (`EnrollmentViewModel`): en apuntar-s'hi, el botó s'activa sense recarregar.
- **Pantalla del xat** (CA2): a pantalla completa, per sobre de la barra inferior, com el de l'Assistent.
  Títol «Xat de l'activitat» i el nom de l'activitat.
  - Historial en ordre cronològic: el més antic a dalt i el més nou a baix.
  - Cada missatge mostra l'autor (el nom, una sola vegada per als missatges seguits d'una persona) i
    l'hora: «18.30 h» si és d'avui, «Ahir · 18.30 h» o la data si és més antic. Els propis van a la
    dreta i no repeteixen el nom.
  - En obrir-lo surten els 50 més recents; «Veure missatges anteriors» carrega els anteriors.
  - Enviar: el text no pot ser buit (el botó queda desactivat) i té un màxim de 1.000 caràcters. Si no
    s'envia, el text es conserva i surt un avís.
  - Estats: carregant, buit («Encara no hi ha missatges…»), error amb «Tornar-ho a provar» i sense
    inscripció (el backend respon 403).
- **Missatges nous**: el backend no avisa en temps real. Mentre el xat és obert, cada 5 s es tornen a demanar
  els més recents i s'hi afegeixen els nous sense repetir-ne cap (DP-061).

## Backend

```text
GET  /events/{id}/messages?pageNum=0&pageSize=50   del més nou al més antic, amb `total`
POST /events/{id}/messages   {"text": "…"}         201 amb el missatge desat
```

La persona s'identifica amb el token. Cada missatge porta `user-id`, `username`, `name`, `text` i
`date-sent`. Errors: 403 si no s'hi està apuntat, 404 si l'activitat no existeix, 409 si s'envien dos
missatges al mateix instant.

## Fitxers

```text
features/activity_chat/models/activity_message.dart                         missatge i pàgina
features/activity_chat/repositories/activity_chat_repository.dart           contracte, límits i R11
features/activity_chat/data/http_activity_chat_repository.dart              backend
features/activity_chat/data/demo_activity_chat_repository.dart              xat en memòria sense backend
features/activity_chat/presentation/view_models/activity_chat_view_model.dart  historial, refresc i enviament
features/activity_chat/presentation/screens/activity_chat_screen.dart       pantalla, bombolles i camp de text
features/activity_chat/presentation/formatters/activity_message_formatter.dart  hora del missatge
```

El botó és a `ActivityDetailsScreen` (`onOpenChat`) i el xat l'obre `MainShell._openActivityChat`.

## Proves

- `test/features/activity_chat/`: repositori HTTP (pàgina, autor, enviament, 403 i errors), ViewModel
  (ordre, buit, R11, reintent, enviament, text buit, error d'enviament, missatges nous sense repetir,
  pàgines anteriors i un sol enviament alhora) i pantalla (autor i hora, buit, sense inscripció, enviar i
  error d'enviament).
- `test/features/activities/activity_details_screen_test.dart`: el botó només s'activa amb la inscripció i
  obre el xat de l'activitat.
