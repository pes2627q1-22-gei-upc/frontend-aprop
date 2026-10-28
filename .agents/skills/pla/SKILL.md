---
name: pla
description: "Comanda /pla <tasca>: genera un pla d'implementació verificable abans d'escriure codi, sense modificar fitxers."
disable-model-invocation: true
metadata:
  repos: both
---

# /pla

Fes servir el model més potent disponible (vegeu `docs/ai/repartiment-eines.md`) i el mode Plan si l'eina en té.
**No modifiquis cap fitxer.**

1. Llegeix `docs/ai/estat.md` i només els documents de `docs/ai/` que la tasca necessiti.
2. Localitza el codi afectat. Si cal cercar per més de 3 carpetes, delega-ho al subagent `explorador-codi`
   i demana-li només conclusions (fitxers i línies).
3. Escriu el pla amb aquest format (≤ 40 línies):

```
Objectiu: <1 línia> · Taiga #<ID> · CA coberts: CA1..n
Fitxers: (nou|mod) camí — per què
Passos:
1. … (verificació: <prova o ordre>)
Riscos / preguntes obertes:
- …
Fora de l'abast:
- …
Model recomanat per implementar-ho: <ràpid|potent> — motiu
```

4. Si hi ha preguntes obertes que bloquegen la feina, fes-les ara (≤ 3) i atura't.
5. Si l'eina en té, guarda el pla com a artefacte; si no, l'usuari l'enganxarà a `/implementar`.
