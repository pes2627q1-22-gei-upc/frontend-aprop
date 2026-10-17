---
trigger: model_decision
description: "Aplica-la quan preparis, validis o proposis un commit, una branca o una PR."
---

# Commits i branques

1. `git branch --show-current`: si és `master` o `develop`, **atura't** i proposa crear `feature/<nom>`.
2. Afegeix els fitxers un per un (`git add <fitxer>`), mai `git add -A` ni `git add .`. Revisa
   `git diff --cached --stat`: cap `.env`, clau, `build/` ni fitxer generat.
3. Comprova que el missatge segueix `Tasca #<ID> <Títol>: <descripció>` (títol exacte de Taiga, descripció en català).
4. **Mostra el missatge i la llista de fitxers i espera una confirmació explícita.** Sense confirmació no
   facis ni `commit` ni `push`.
5. Una tasca de Taiga, un o pocs commits coherents. No barregis feina de tasques diferents.
6. Per a la PR, fes servir la skill `commit-i-pr`.
