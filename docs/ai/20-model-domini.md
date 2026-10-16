# 20 · Model de domini (UML)

> **Quan llegir-ho:** en dissenyar taules, migracions, models, endpoints o proves d'integritat, i quan una regla
> de negoci afecti diverses entitats. Per a canvis només de UI, normalment n'hi ha prou amb `70-glossari.md`.
> **Font:** `docs/source/incepcio-2.pdf` §10. El diagrama és una imatge: els atributs que només surten al dibuix
> estan marcats `TODO(confirmar)`. Els noms en cursiva s'han deduït de les restriccions textuals.

## Entitats

| Entitat | Descripció | Atributs coneguts |
|---|---|---|
| Usuari | Compte amb perfil i estat | *nomUsuari* (únic), *email* (únic), nom, foto?, biografia?, *estatCompte* |
| Administrador | Usuari que modera; resol denúncies | (hereta d'Usuari? `TODO(confirmar)`) |
| Configuració | Preferències d'un Usuari (1–1) | idioma, tema, notificacions per tipus, visibilitat d'inscripcions |
| Sol·licitudAmistat | Emissor → receptor | *estat*, *dataEnviament*, *dataResposta*? |
| Notificació *(abstracta)* | Avís a un Usuari (receptor) | text, *dataCreació*, llegida |
| · NotificacióSocial | Sobre una Sol·licitudAmistat rebuda o acceptada | → Sol·licitudAmistat |
| · NotificacióEsdeveniment | Recordatori, cancel·lació, recordatori per valorar, recomanació, amic inscrit | *tipus*, → Esdeveniment, *amic*? |
| · NotificacióNivell | Pujada de nivell | nivell `TODO(confirmar)` |
| Denúncia *(abstracta)* | Queixa d'un Usuari (denunciant) | motiu, *estat*, *data*, *dataResolució*?, → Administrador? |
| · DenúnciaUsuari | Contra un Usuari (denunciat) | → Usuari |
| · DenúnciaEsdeveniment | Sobre un NoOficial | → NoOficial |
| Esdeveniment *(abstracta)* | Activitat mostrada | *id*, títol, descripció, *dataInici*, *dataFi*?, preu |
| · Oficial | De Dades Obertes; conserva el codi original | *codi* |
| · NoOficial | Creat per un Usuari; denunciable; es valora l'organitzador | *dataCreació*, *estat*, → creador |
| · Extern | Importat d'un altre equip PES (Talaia) | *codiExtern* |
| Espai | Lloc de l'esdeveniment | nom, adreça, municipi, coordenades |
| Categoria | Tipus d'activitat (teatre, dansa…) | nom (únic). Cada Esdeveniment en té ≥ 1 |
| Inscripció | Usuari apuntat a un Esdeveniment | exportadaGoogle, *assistència*? (bool) |
| Valoració | Puntuació 1–5 d'un esdeveniment assistit | *puntuació* |
| Missatge | Xat d'un Esdeveniment | text, *dataEnviament*, → autor, → Esdeveniment |
| Interès | Grau d'interès Usuari–Categoria | /pes |
| TestInteressos | Test inicial de 25 Esdeveniments (1 per Usuari) | |
| RespostaTest | M'agrada / no m'agrada per Esdeveniment del test | valor |
| ConversaXatbot | Conversa amb l'assistent | *dataInici* |
| MissatgeXatbot | Missatge de la conversa | *emissor* (Usuari/Xatbot), *perVeu*, *dataEnviament*, → recomanats* |
| GuanyExperiència | Punts guanyats | *acció*, *data*, *punts* |
| (bloqueig) | Usuari bloqueja Usuari | associació reflexiva |

## Enumeracions (valors coneguts)

| Enum | Valors | Pendent |
|---|---|---|
| Sol·licitudAmistat.estat | Pendent, Acceptada, *Rebutjada* | confirmar el nom de l'estat rebutjat |
| Usuari.estatCompte | Desactivat, … | `TODO(confirmar)` valor actiu |
| NoOficial.estat | Retirat, … | `TODO(confirmar)` (cancel·lat? actiu?) |
| Denúncia.estat | Pendent, Acceptada, … | `TODO(confirmar)` (rebutjada?) |
| NotificacióEsdeveniment.tipus | Recordatori, Cancel·lació, RecordatoriValorar, Recomanació, InscripcióAmic | noms exactes al diagrama |
| MissatgeXatbot.emissor | Usuari, Xatbot | |
| Nivell | Curiós/a → Explorador/a → Aventurer/a cultural → Descobridor/a cultural → Ambaixador/a cultural | llindars d'XP `TODO(confirmar)` (mockup: 340/500) |
| Configuració.idioma | ca, es (+ en?) | mockup diu ca/es; NFR diu ca/es/en |

## Informació derivada

- **/ésAmicDe:** existeix una Sol·licitudAmistat entre els dos amb estat = Acceptada.
- **/nombreAmics:** nombre d'Usuaris amb qui l'Usuari ésAmicDe.
- **/experiència:** suma dels punts dels GuanyExperiència de l'Usuari.
- **/nivell:** funció de /experiència (5 nivells).
- **/fiabilitat:** mitjana de les Valoracions dels NoOficials creats per l'Usuari; nul·la si no n'hi ha.
- **/nombreInscrits:** nombre d'Inscripcions de l'Esdeveniment.
- **/valoracióMitjana:** mitjana de les Valoracions de l'Esdeveniment; nul·la si no n'hi ha.
- **Interès./pes:** a partir de les RespostaTest, Inscripcions i Valoracions de l'Usuari a Esdeveniments de la Categoria.

## Restriccions textuals com a regles verificables

Cada regla té un identificador `R<n>` per referenciar-la als noms de les proves (p. ex. `TestR3_...`).

- **R1 · Claus (unicitat).** No poden existir dos registres amb la mateixa clau:
  Usuari(nomUsuari) · Usuari(email) · Esdeveniment(id) · Oficial(codi) · Extern(codiExtern) ·
  Espai(nom+municipi) · Categoria(nom) · Configuració(Usuari) · TestInteressos(Usuari) ·
  ConversaXatbot(Usuari+dataInici) · MissatgeXatbot(Conversa+dataEnviament) ·
  Missatge(autor+Esdeveniment+dataEnviament) · Sol·licitudAmistat(emissor+receptor+dataEnviament) ·
  GuanyExperiència(Usuari+acció+data) · Notificació(receptor+dataCreació) · Denúncia(denunciant+data).
  *Atenció:* el `Code` de l'API de la Generalitat **no és únic** (vegeu `40-api-i-serveis.md`).
- **R2 · Sense autoreferència.** emissor ≠ receptor en una Sol·licitudAmistat; un Usuari no es pot bloquejar a si mateix.
- **R3 · Una relació activa.** Entre A i B hi ha com a màxim una Sol·licitudAmistat amb estat ∈ {Pendent, Acceptada}
  en qualsevol sentit; i cap si A ha bloquejat B o B ha bloquejat A.
- **R4 · Resposta coherent.** dataResposta existeix ⇔ estat ≠ Pendent; i dataResposta ≥ dataEnviament.
- **R5 · Dates d'esdeveniment.** Si hi ha dataFi, dataFi ≥ dataInici. En un NoOficial, dataInici ≥ dataCreació.
- **R6 · Desactivació justificada.** estatCompte = Desactivat ⇒ l'Usuari és denunciat en ≥ 1 DenúnciaUsuari Acceptada.
- **R7 · Retirada justificada.** NoOficial.estat = Retirat ⇒ ≥ 1 DenúnciaEsdeveniment Acceptada sobre ell **o** creador
  Desactivat. Oficial i Extern mai no poden estar Retirats.
- **R8 · Assistència a posteriori.** Inscripció.assistència només té valor si dataInici de l'Esdeveniment < ara.
- **R9 · Rangs.** Valoració.puntuació ∈ [1, 5]; GuanyExperiència.punts > 0.
- **R10 · Valorar exigeix assistir.** Una Valoració d'U sobre E exigeix una Inscripció d'U a E amb assistència = cert.
- **R11 · Xat exigeix inscripció.** L'autor d'un Missatge té una Inscripció a l'Esdeveniment del Missatge.
- **R12 · Missatges del xatbot.** Només recomana Esdeveniments si emissor = Xatbot; perVeu = cert només si emissor = Usuari.
- **R13 · Notificacions.** NotificacióEsdeveniment té amic ⇔ tipus = InscripcióAmic. El receptor d'una
  NotificacióSocial és el receptor de la Sol·licitudAmistat, o l'emissor si estat = Acceptada.
- **R14 · Sense conflicte d'interessos.** Ningú no es denuncia a si mateix ni denuncia un NoOficial propi.
  Un Administrador no resol una DenúnciaUsuari on és el denunciat ni una DenúnciaEsdeveniment sobre un NoOficial seu.
- **R15 · Resolució coherent.** Administrador i dataResolució existeixen ⇔ estat ≠ Pendent; i dataResolució ≥ data.

On aplicar-les: **validació al servidor + restriccions de BD** quan siguin expressables (UNIQUE, CHECK, FK);
la resta, al servei dins d'una transacció. El client només fa validació d'usabilitat.
Proves: skill `test-restriccions-uml`.
