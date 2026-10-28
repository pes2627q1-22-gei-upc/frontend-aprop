# Avisos: traspàs al backend

Contracte revisat el 26 d’octubre de 2026 a `origin/develop@d01f231`. Frontend basat en #86;
no s’ha modificat ni executat el backend. Aquest text està preparat perquè Adam el revisi i el comuniqui.

## Missatge per a l’equip

He connectat la bústia d’Avisos del frontend amb `/users/me`, `/notifications/user/{uuid}`,
`/notificationtypes`, `GET /notifications/{id}` i `POST /notifications/{id}/read`.
Utilitzo el UUID real del perfil, no un ID numèric o derivat. Per completar la prova conjunta:

1. **Disponibilitat i accés web:** `/notificationtypes` no ha retornat resposta HTTP en 15 segons.
   Confirmeu la URL desplegada i que respon. Per web, cal que CORS/OPTIONS permeti el frontend i les
   capçaleres d’autenticació. No cal compartir tokens ni credencials per missatgeria.
2. **Destinatari autenticat:** als handlers revisats, la consulta per usuari i les operacions GET/read
   només fan servir l’ID del path. Cal resoldre la identitat autenticada a UUID i comprovar que l’avís
   és seu. Un altre usuari no ha de poder consultar ni marcar aquests avisos. El frontend ho comprova
   com a defensa d’ús, però l’autorització ha d’estar al servidor. Incloure proves entre dos comptes i
   una resposta 404/403 per avisos aliens o inexistents, sense una confirmació d’UPDATE de zero files.
3. **Hora de recepció:** `notification-date` és `pgtype.Timestamp`. Confirmeu la zona horària i retorneu
   preferiblement RFC 3339 amb offset/Z per agrupar Avui/Ahir i mostrar l’hora correcta. No s’ha inventat
   una hora de recepció si el camp és absent o invàlid.
4. **Creació real dels avisos:** he trobat `POST /notifications`, però cap servei que creï automàticament
   recordatoris en arribar l’hora o recomanacions per usuari. Confirmeu si això entra a l’Sprint 1 i,
   si hi entra, connecteu els productors amb la bústia i les preferències/inscripcions reals. El client
   consumeix avisos rebuts; no crea una recomanació o un recordatori al dispositiu per simular backend.
5. **Prova conjunta:** preparar al servidor de desenvolupament un recordatori i una recomanació d’un
   compte de prova, amb activitat vàlida, i comprovar lectura → recàrrega → segueix llegit. El frontend
   ja prova aquest recorregut amb transport simulat; encara no s’ha validat contra producció.

**Social queda fora d’aquest sprint**, segons l’acord d’Adam. Per a un sprint posterior caldran subtipus
de notificació i identificador/estat de la sol·licitud, així com endpoints per acceptar/rebutjar amb
amistat mútua atòmica. Amb el contracte actual no es dedueix una sol·licitud a partir de «Social».

Optimització futura: retornar un resum de l’activitat i la persona dins de l’avís, o un endpoint batch,
per reduir consultes. Ara el client deduplica per ID i limita conjuntament a quatre les consultes de
context; no consulta una vegada per cada targeta ni descarta avisos quan un context desapareix.
