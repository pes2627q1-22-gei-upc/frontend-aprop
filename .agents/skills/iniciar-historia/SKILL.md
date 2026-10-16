---
name: iniciar-historia
description: "Comanda /iniciar-historia <ID de Taiga>: comença una història d'usuari (criteris, branca, pla d'hores i DoD)."
disable-model-invocation: true
metadata:
  repos: both
---

L'argument de la comanda és l'ID de Taiga (i opcionalment el títol). Si falta, demana'l.

Aplica la skill `nova-historia-usuari` (`.agents/skills/nova-historia-usuari/SKILL.md`) pas a pas amb aquest ID.
No escriguis codi en aquesta comanda: acaba amb l'abast, el pla de tasques i la proposta de branca.
