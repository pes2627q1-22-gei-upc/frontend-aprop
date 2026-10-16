---
name: revisar
description: "Comanda /revisar [branca|PR]: revisió tipus PR amb la checklist de l'equip en un context separat."
disable-model-invocation: true
metadata:
  repos: both
---

L'argument és la branca o el número de PR (per defecte, la branca actual contra `origin/develop`).

Delega-ho al subagent `revisor` (context net, sense l'historial d'implementació) i fes que apliqui la skill
`revisio-pr`. Si el canvi toca autenticació, dades personals, secrets o permisos, demana també una revisió al
subagent `seguretat-privacitat`. Torna només el veredicte i la llista de bloquejants.
