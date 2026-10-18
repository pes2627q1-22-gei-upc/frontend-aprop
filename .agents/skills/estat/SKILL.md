---
name: estat
description: "Comanda /estat: resum en 10 línies de l'estat actual (sprint, història, branca, canvis locals i propers passos)."
disable-model-invocation: true
metadata:
  repos: both
---

Fes servir un model ràpid. Sense modificar cap fitxer:

1. Llegeix `docs/ai/estat.md`.
2. Executa `git branch --show-current`, `git status --short | head -20` i `git log --oneline -5`.
3. Respon en ≤ 10 línies: sprint · història activa (Taiga) · branca · canvis sense commit (nombre de fitxers) ·
   divergència respecte d'`origin/develop` si es pot saber · bloquejos · el proper pas recomanat.
4. Si `estat.md` contradiu git (p. ex. una altra branca), indica-ho i proposa `/tancar-sessio`.
