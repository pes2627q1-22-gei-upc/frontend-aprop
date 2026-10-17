---
name: pr
description: "Comanda /pr: prepara el commit amb el format de l'equip i la descripció de la PR cap a develop."
disable-model-invocation: true
metadata:
  repos: both
---

Aplica la skill `commit-i-pr`. Primer executa la verificació completa (format, anàlisi i proves) amb
les ordres de verificació, i passa el diff al subagent `vigilant-decisions`. Si alguna cosa falla, atura't i
informa'n. Llista a la descripció de la PR les DP que la PR obre o de què depèn. **No facis commit, push ni PR sense
confirmació explícita.**
