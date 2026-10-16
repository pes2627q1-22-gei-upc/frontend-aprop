---
name: actualitzar-memoria
description: Protocol per actualitzar docs/ai/estat.md i docs/ai/memoria.md en tancar una sessió o en canviar d'eina, i per compactar la memòria quan supera 200 línies. Fes-la servir en acabar una sessió de treball, en prendre una decisió tècnica o en passar la feina a una altra eina.
metadata:
  repos: both
---

# Actualitzar estat i memòria

## Què va a cada lloc

| Informació | On |
|---|---|
| Sprint, història activa, branca, bloquejos, propers passos | `docs/ai/estat.md` (es reescriu) |
| Dubte o supòsit sense confirmar | `docs/decisions-pendents.md` (DP-NNN; en resoldre's, passa a memòria o ADR) |
| Decisió tècnica, convenció nova, error recurrent i solució, intent descartat | `docs/ai/memoria.md` (s'hi afegeix) |
| Decisió d'arquitectura amb alternatives | `docs/ai/decisions/ADR-XXXX-*.md` (+ 1 línia a la memòria que hi enllaci) |
| Fets del producte (requisits, model, UI) | el fitxer `docs/ai/NN-*.md` corresponent |
| El que ja diu el codi, resums de sessió, logs, secrets | enlloc |

## Tancar la sessió (`/tancar-sessio`)

1. `git branch --show-current` i `git status --short` (per saber la branca i si queda feina sense commit).
2. Reescriu `estat.md` (≤ 40 línies): actualitza la taula «En curs», «Fet recentment» (només l'últim sprint),
   «Bloquejos», «Propers passos» (≤ 3, accionables) i «Traspàs entre eines» (eina actual + què cal llegir).
3. Revisa la sessió: hi ha hagut alguna decisió, error repetit o intent fallit que una altra sessió hauria de
   saber? Si n'hi ha, afegeix **una línia per element** al final de `memoria.md`:
   `AAAA-MM-DD · [decisió|convenció|error|descartat] text (ref)`.
4. Si no n'hi ha cap, no hi escriguis res. Els dubtes que queden oberts no van a la memòria: comprova (o delega
   al subagent `vigilant-decisions`) que siguin a `docs/decisions-pendents.md` i esmenta'n els números a `estat.md`.
5. Mostra el diff dels dos fitxers. No en facis commit (regla de revisió humana).

## Compactar (`/compactar-memoria`)

Quan `wc -l docs/ai/memoria.md` > 200:

1. Agafa les entrades de més de dos sprints d'antiguitat.
2. Esborra'n les obsoletes (substituïdes per una entrada posterior o ja reflectides en el codi o la documentació).
3. Resumeix les vigents a «Històric» en ≤ 15 línies, agrupades per tema.
4. Elimina-les d'«Entrades». Comprova que el fitxer queda < 150 línies.
5. Mostra el diff i espera la revisió.

## Criteri de qualitat

Una entrada de memòria ha d'estalviar com a mínim una investigació o un error futurs. Si no, no hi va.
