---
name: revisio-pr
description: Revisa una PR o un conjunt de canvis amb la checklist comuna de l'equip (llegibilitat i arquitectura, errors, proves, secrets, criteris d'acceptació, UI i NFR). Fes-la servir quan et demanin revisar codi, una branca, un diff o una PR abans de fusionar-la.
metadata:
  repos: both
---

# Revisió de PR

Revisa-ho en un context **net**: si has implementat tu el canvi en aquesta sessió, delega la revisió al
subagent `revisor` (o obre una sessió nova). La revisió humana continua sent obligatòria; aquesta en prepara la base.

## Entrada

- Diff: `git diff --stat origin/develop...HEAD` i després `git diff origin/develop...HEAD -- <fitxers>` per
  blocs. No carreguis el diff sencer si supera ~800 línies: revisa per carpetes.
- Criteris d'acceptació (de la PR o de Taiga). Si no n'hi ha, demana'ls.

## Checklist (memòria §2.4.4 + NFR)

1. **Abast:** compleix cada criteri d'acceptació (CA1…n)? Hi ha canvis fora de l'abast?
2. **Arquitectura:** regles de `docs/architecture.md` (capes, dependències, injecció per constructor, cap
   import d'`app/` des de `features/`). Al backend: handler → service → repository, sense framework.
3. **Errors:** fallades de xarxa i de repositori gestionades; missatges en català; sense `catch` buit que
   amagui bugs; al backend, codis HTTP correctes i validació al servidor.
4. **Proves:** n'hi ha per al comportament nou i per als casos límit; les restriccions R1–R15 afectades
   estan cobertes; cap prova trivial ni dependent de la xarxa.
5. **Secrets i privacitat:** cap clau, token, `.env`, correu real ni dada personal; dades mínimes;
   «Mostrar els meus plans» respectat.
6. **UI:** fidel al mockup, tema únic, accessibilitat AA, estats de càrrega, buit i error, sense
   vocabulari transaccional.
7. **Rendiment:** paginació, sense treball pesat a `build`, sense peticions duplicades.
8. **Qualitat:** noms segons el glossari, sense codi mort ni `print`, format i anàlisi nets.
9. **Traçabilitat:** branca `feature/…`, missatges `Tasca #ID …`, documentació actualitzada.
10. **Decisions pendents:** cada `TODO(DP-NNN)` del diff existeix a `docs/decisions-pendents.md`; cap supòsit
    sense registrar; el canvi no contradiu cap DP oberta. Si hi ha dubtes, crida el subagent `vigilant-decisions`.

Executa (o demana els resultats de la CI):

```bash
bash scripts/ai/run-quiet.sh flutter analyze
bash scripts/ai/run-quiet.sh flutter test
```

## Sortida (format fix, ≤ 30 línies)

```
Veredicte: Aprovar | Aprovar amb canvis menors | Cal canviar-ho
Bloquejants:
- <fitxer>:<línia> — problema → proposta
Millores (no bloquejants):
- …
CA: CA1 ✓ · CA2 ✗ (motiu) · …
Proves executades: <ordre> → <resultat resumit>
```

No reescriguis el codi a la revisió; proposa el canvi en una línia o en un diff curt.
