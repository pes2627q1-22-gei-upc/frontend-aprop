---
name: nova-historia-usuari
description: Prepara l'inici d'una història d'usuari o tasca de Taiga - llegeix els criteris d'acceptació, crea la branca feature/ des de develop, descompon la feina en tasques amb hores i deixa la checklist de la DoD. Fes-la servir quan l'usuari digui que comença una història, una tasca o un número de Taiga.
metadata:
  repos: both
---

# Nova història d'usuari

Entrada: ID de Taiga (`#<n>`) i, si en té, el títol. Si no tens els criteris d'acceptació, **demana'ls**
(enganxats de Taiga). No te'ls inventis.

## 1. Context mínim

1. Llegeix `docs/ai/estat.md`.
2. Busca la història a `docs/ai/10-requisits.md` (èpica i SP; 1 SP ≈ 2 h).
3. Segons el tipus, carrega **només** el que calgui: UI → `50-ui-mockups.md`; dades o regles → `20-model-domini.md`;
   API → `40-api-i-serveis.md`. Per a decisions prèvies, `memoria.md`.

## 2. Abast

Escriu-lo en ≤ 8 línies:

- Criteris d'acceptació numerats (`CA1…CAn`), copiats de Taiga.
- **Dins** de l'abast / **fora** de l'abast (controls que es mostraran desactivats).
- Dependències: contracte del backend existent o pendent, altres històries, serveis externs.
- Restriccions del UML afectades (`R<n>`).

Si un criteri és ambigu, pregunta abans de planificar.

## 3. Branca

```bash
git fetch origin && git switch develop && git pull --ff-only
git switch -c feature/<nom-curt-en-kebab-case>
```

Executa-ho només si l'usuari ho autoritza (la regla de límit d'acció de `AGENTS.md`). Nom: verb o substantiu
de la funcionalitat (p. ex. `feature/agenda-calendari`), sense el número.

## 4. Pla de tasques

Taula per crear a Taiga (l'usuari les crea; tu no tens accés a Taiga):

| # | Tasca | Repo | Hores est. | Criteri cobert | Prova |
|---|---|---|---|---|---|

- Les hores totals han de ser ≈ SP × 2. Si te'n surten > 1,5×, avisa'n (cal reestimar-la o partir-la).
- Les proves van dins de cada tasca, no en una tasca separada al final.
- Ordre: model i contracte → dades (demo o backend) → ViewModel i proves → pantalla i proves de widget →
  navegació → documentació.

## 5. Checklist DoD (copia-la a la descripció de la PR)

- [ ] CA1…CAn comprovats manualment
- [ ] Proves noves superades i suite completa en verd
- [ ] `dart format`, `flutter analyze` (o `go test`, `golangci-lint`, `govulncheck`)
- [ ] Revisió d'una persona que no l'ha implementada
- [ ] Documentació afectada actualitzada (`README.md`, `docs/architecture.md`, `docs/ai/*`)
- [ ] Taiga: estat i hores reals

## 6. Tancament del pas

Actualitza `docs/ai/estat.md` (fila «En curs»: Taiga, història, repo, branca, responsable, estat).
Sortida a l'usuari: abast + taula de tasques + ordres de branca, en ≤ 40 línies.
