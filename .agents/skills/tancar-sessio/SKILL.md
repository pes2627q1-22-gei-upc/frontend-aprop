---
name: tancar-sessio
description: "Comanda /tancar-sessio: actualitza docs/ai/estat.md i, si cal, docs/ai/memoria.md abans de tancar la sessió o canviar d'eina."
disable-model-invocation: true
metadata:
  repos: both
---

Aplica la secció «Tancar la sessió» de la skill `actualitzar-memoria`. Si `docs/ai/memoria.md` supera 200 línies,
avisa i proposa `/compactar-memoria`. Acaba amb el diff dels dos fitxers i una línia de traspàs per a la propera eina.
