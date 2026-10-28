---
name: provar
description: "Comanda /provar [camí]: escriu les proves que falten per al canvi actual i les executa, informant només de fallades i cobertura."
disable-model-invocation: true
metadata:
  repos: both
---

# /provar

Si l'eina permet subagents, delega-ho al subagent `tester` amb el camí o el diff com a context.

1. Àmbit: l'argument (fitxer o carpeta) o, si no n'hi ha, `git diff --name-only origin/develop...HEAD`.
2. Per a cada comportament nou, comprova que hi hagi una prova (regla `tests`). Prioritza:
   restriccions R1–R15 afectades (`docs/ai/20-model-domini.md`) → estats d'error i buit → camí feliç → casos límit.
3. Escriu les proves que faltin, seguint els *fakes* i noms existents.
4. Executa:

```bash
flutter test <camins>
flutter test --coverage   # només si es demana cobertura
```

5. Si una prova falla per un bug del codi (no de la prova), **no canviïs el codi de producció** sense dir-ho:
   informa'n i proposa la correcció.

Sortida (≤ 12 línies): proves afegides (nom), resultat `N passen / M fallen`, fallades amb fitxer:línia i
causa probable, i la cobertura si s'ha calculat.
