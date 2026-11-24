# Notificacions push (#265)

> Tasca #276 (front). Backend: #275 (Arnau), fusionat a `develop` d’`api-aprop` (PR #77). Decisions a DP-072.

## Criteris d'acceptació proposats

La història no en té a Taiga. Proposta:

- **CA1:** en entrar a l'app (Android), es demana permís de notificacions i el mòbil es registra al backend (`PUT /users/me/devices`); si l'identificador del mòbil canvia, es torna a registrar.
- **CA2:** amb l'app tancada o en segon pla, cada avís nou arriba com a notificació del sistema; en tocar-la s'obre Avisos i, si parla d'una activitat, la seva fitxa.
- **CA3:** amb l'app oberta, el push no es perd: surt un avís a baix amb «Veure» i Avisos es torna a carregar.
- **CA4:** en tancar la sessió, el mòbil es dona de baixa (`DELETE /users/me/devices/{token}`) i deixa de rebre els pushes d'aquell compte.
- **CA5:** si la persona no dona permís o el registre falla, l'app funciona igual i els avisos continuen a Avisos.

## Com funciona

- `PushMessaging` és el servei del mòbil (`FirebasePushMessaging`, amb `firebase_messaging`); `PushDeviceRepository` és el backend (`HttpPushDeviceRepository`).
- `MainShell` crea `PushViewModel` després del primer frame si l'app té tots dos (només Android i amb backend). El ViewModel registra el mòbil a cada `onRegistered`, informa dels pushes rebuts (`onForeground`) i tocats (`onOpened`) i el dona de baixa abans de tancar la sessió.
- Amb l'app oberta, `MainShell` mostra el text del push en un avís a baix i fa que Avisos torni a llegir la safata (`NotificationsScreen.reload`).

## Proves

- `test/features/push/push_test.dart`: dades del push, `PUT`/`DELETE` del backend i `PushViewModel` (registre i canvi d'identificador, permís denegat, registre fallit, pushes rebuts i tocats, baixa).
- `test/app/push_flow_test.dart`: registre en entrar, push amb l'app oberta i «Veure», tocar un push d'activitat i baixa en tancar la sessió.

## Pendent

Prova en un dispositiu amb el backend de la #275 i les credencials de Firebase del servidor; interruptor de push a Configuració (#19); iOS i web (DP-072).
