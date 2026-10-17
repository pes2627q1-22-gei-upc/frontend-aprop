# 60 · Metodologia i qualitat

> **Quan llegir-ho:** en començar o tancar una història, preparar una PR, fer una release, gestionar un bug o
> revisar un requisit no funcional. Les regles imprescindibles ja són a `AGENTS.md`; aquí hi ha el detall.
> **Font:** `memoria.pdf` §2.

## Scrum i Taiga

- 2 incepcions + 3 sprints de desenvolupament. Taiga: backlog, històries i tasques amb hores estimades.
- **Inici de sprint:** a la planning es trien històries per prioritat i es descomponen en tasques amb hores.
  La planificació s'envia al professor el mateix dia.
- **Inici d'història:** revisar els criteris d'acceptació i crear `feature/<nom>` des de `develop`.
- **Inici de tasca:** autoassignar-la a Taiga i marcar-la com a iniciada.
- **Fi de tasca:** commits que referencien la tasca, PR cap a `develop`, CI, revisió i tancament amb les hores reals.
- **Fi de sprint:** review i retrospectiva → merge de `develop` a `master` → tag → desplegament automàtic.
- **PRT:** cada membre hi registra l'activitat i l'sprint master ho verifica. Error conegut: tasques de
  gestió del projecte amb Taiga marcades com a «Documentació» (vegeu la skill `sprint-report`).
- **Comunicació:** WhatsApp (dia a dia), Discord (reunions en línia), classe (seguiment 2×/setmana),
  Google Drive (documents).

## Gitflow

- `master` (producció) i `develop` (integració): **protegides**. Sense commits directes, PR amb ≥ 1 aprovació i CI verd.
- `feature/<nom>` des de `develop` → PR a `develop`, revisada per algú que **no** l'ha implementada.
- `hotfix/<nom>` des de `master` → merge a `master` **i** a `develop`.

## Commits

```
Tasca #<ID> <Títol de la tasca>: <descripció concisa dels canvis>
```

Exemple: `Tasca #42 Autenticació Google: Implementació de la validació de tokens JWT en el backend`.

## Versionat (SemVer sobre `master`)

`vMAJOR.MINOR.PATCH`. **MAJOR:** canvis estructurals d'alt impacte, fites (MVP), migracions de components
crítics o redisseny significatiu de la UI Flutter. **MINOR:** funcionalitat nova retrocompatible o
actualització de llibreries *deprecated*. **PATCH:** només correccions de bugs, sense funcionalitat nova.

## CI (GitHub Actions a cada PR; cal que passi tot)

| Repo | Passos |
|---|---|
| Frontend | `dart format --output=none --set-exit-if-changed lib test` · `flutter analyze` · `flutter test` · `flutter build apk --debug` |
| Backend | `go test ./...` (cobertura) · `golangci-lint run` · `govulncheck ./...` · `docker build` |

Estat: el frontend encara **no té workflow** i el `go.yml` del backend és incomplet (`TODO`, agent `devops-ci`).
Desplegament: release a `master` → imatge → GHCR → EC2.

## Definition of Done

Implementada · compleix els criteris d'acceptació (comprovats manualment) · proves escrites amb la
funcionalitat i superades · revisada per algú altre · fusionada a `develop` · documentació afectada
actualitzada · estat i hores reals a Taiga.

## Proves

- **Prioritat:** restriccions d'integritat del UML (`20-model-domini.md`, R1–R15).
- **Backend:** paquet `testing` (unitàries de la lògica) i proves d'integració dels endpoints. **Cobertura ≥ 80 %.**
- **Frontend:** `flutter_test` (unitàries i de widgets de les pantalles principals) i proves d'integració del recorregut principal.
- Els serveis externs es proven amb *fakes* darrere d'interfícies (sense xarxa ni quotes).

## Revisió de codi (checklist comuna)

Llegibilitat i coherència amb l'arquitectura · gestió d'errors · proves adequades · cap credencial ni dada
sensible · compliment dels criteris d'acceptació. Skill: `revisio-pr`.

## Bugs

Issue a Taiga amb descripció, passos per reproduir-lo, severitat i història relacionada → assignació →
branca pròpia + prova que el reprodueix. Bug crític d'un sprint anterior → `hotfix/`; si no és crític,
es prioritza a la planning següent. Skill-comanda: `/bug`.

## Configuració i secrets

`.env` local (ignorat) + `.env.example` versionat. Secrets de GitHub a CI. A EC2, `.env` injectat al
contenidor. Mai no es posen claus al client.

## NFR (Volere) amb mètriques

| Requisit | Objectiu i mesura |
|---|---|
| Aparença | Un `ThemeData` amb tokens; components compartits; mode clar i fosc WCAG 2.1 AA; revisió contra els mockups a les PR de UI |
| Estil | To de proximitat i neutralitat; sense termes transaccionals ni publicitat; textos centralitzats en fitxers de traducció |
| Facilitat d'ús | Etiquetes clares a camps i botons; interfície neta |
| Personalització i i18n | ca/es/en (en estudi); mode clar i fosc; notificacions; antelació dels recordatoris |
| Rapidesa | Mapa < 3 s · cerca/filtres < 2 s · assistent < 10 s · servidor < 0,5 s en la majoria de peticions · càrrega per zona visible · paginació |
| Disponibilitat | ≥ 99 %; reinici automàtic en pocs minuts; fallada aïllada dels serveis externs |
| Integritat | Validació al servidor; transaccions; restriccions de BD; concurrència en inscripcions; còpia de seguretat diària |
| Privacitat | Dades mínimes (nom d'usuari, nom, correu; foto i bio opcionals); activitat visible només als amics i només amb «Mostrar els meus plans»; sense contrasenyes pròpies (Firebase); esborrat en eliminar el compte (RGPD) |
| Immunitat | `golangci-lint` + `govulncheck` a cada PR; `net/http` sense framework; Docker aïllat; validació de totes les entrades; claus només al backend; denúncies |
| Legal | RGPD + LOPDGDD (informar abans del registre, consultar, modificar i esborrar dades); citar la font de les dades obertes; termes de Google, Firebase i Gemini; polítiques de les botigues; LSSI-CE (retirada de contingut); sense pagaments |

## Ús d'assistents d'IA (memòria §2.10)

Ús previst: proves, deute tècnic, documentació i suport a la implementació. **Tot el que generi la IA ho revisa i
valida una persona abans d'incorporar-ho. Cap commit sense verificació prèvia.**
