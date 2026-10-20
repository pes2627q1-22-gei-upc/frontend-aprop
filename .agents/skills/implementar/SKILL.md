---
name: implementar
description: "Comanda /implementar: executa un pla aprovat amb canvis mínims i verificats, sense fer-ne commit."
disable-model-invocation: true
metadata:
  repos: both
---

# /implementar

Requisit: un pla aprovat (de `/pla` o enganxat per l'usuari). Si no n'hi ha cap i la tasca toca més de 2 fitxers,
proposa fer `/pla` primer.

1. Confirma la branca (`git branch --show-current`): ha de ser `feature/…` o `hotfix/…`.
2. Aplica la skill que correspongui: `pantalla-flutter` (UI), o les del backend (`endpoint-go`,
   `migracio-bd`, `integracio-externa`) al repo `api-aprop`.
3. Implementa pas a pas. Després de cada pas, executa la verificació del pla amb
   l'ordre directament (p. ex. `flutter test`) i corregeix el que falli abans de continuar.
4. Respecta l'abast: si cal un canvi fora del pla, atura't i pregunta. Si un pas depèn d'un supòsit, registra'l
   a `docs/decisions-pendents.md` i marca el codi amb `TODO(DP-NNN)` (regla de `AGENTS.md`).
5. Al final: `dart format lib test`, `flutter analyze` i `flutter test` (o els equivalents de Go).
6. Delega al subagent `vigilant-decisions` la revisió del diff.
7. Sortida (≤ 15 línies): fitxers modificats, verificacions i resultat, decisions pendents (DP obertes o
   afectades), i el missatge de commit proposat. **No en facis commit.**
