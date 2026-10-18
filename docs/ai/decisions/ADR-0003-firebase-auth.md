# ADR-0003 · Delegar l'autenticació a Firebase Authentication

- **Estat:** acceptada
- **Data:** 2026-10-02 (Incepció 2) · **Autoria:** FiveGuys

## Context

L'app gestiona dades personals sensibles (on serà una persona i quan). Els NFR de privacitat i compliment
legal (RGPD/LOPDGDD) demanen dades mínimes i no emmagatzemar contrasenyes. L'equip no vol implementar un
sistema d'autenticació propi.

## Decisió

Firebase Authentication amb OIDC i Google. Les contrasenyes no s'emmagatzemen al nostre sistema. El backend
valida el token de Firebase a cada petició autenticada i hi associa el perfil propi (nom d'usuari únic).

## Alternatives considerades

- **Autenticació pròpia (hash de contrasenyes + JWT):** més codi crític de seguretat i més responsabilitat
  legal sobre les credencials.
- **Només Google OAuth sense Firebase:** caldria gestionar sessions i el correu per separat.

## Conseqüències

- (+) Menys superfície de risc; inici de sessió amb Google senzill.
- (−) Dependència d'un proveïdor extern. Pendent (`docs/architecture.md` § «Accés i sessió»):
  `FirebaseAuthRepository`, alta al backend, obtenir el correu a partir del nom d'usuari i el primer accés
  amb Google.
- `TODO(confirmar)`: com es protegeixen les claus de configuració de Firebase al client (no són secretes,
  però s'han de restringir) i si el backend usa l'Admin SDK o verifica el JWT directament.
