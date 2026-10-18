# Memòria tècnica (append-only)

> **Quan llegir-ho:** a l'inici d'una sessió de treball no trivial, i abans de proposar una decisió que potser
> ja s'ha pres o descartat. Actualització: skill `actualitzar-memoria`.

## Regles

- **Sí:** decisions acordades que no surten als PDFs ni al codi, convencions noves, errors recurrents amb la
  seva solució i coses que no han funcionat (perquè no es tornin a provar).
- **No:** res que ja sigui a `AGENTS.md`, `docs/ai/` o `docs/architecture.md` (enllaça-ho), l'estat del
  sprint (va a `estat.md`), resums de sessió, logs, secrets o dades personals.
- **Format:** una línia per entrada, `AAAA-MM-DD · [tipus] text (ref)`. Tipus: `decisió`, `convenció`,
  `error`, `descartat`. Afegeix-ho al final de la secció «Entrades». No editis les entrades antigues: si una
  queda obsoleta, n'afegeixes una de nova que la substitueixi.
- **Compactació:** quan el fitxer superi **200 línies**, resumeix les entrades de més de dos sprints a
  «Històric» (≤ 15 línies, només el que encara és vigent) i esborra-les d'«Entrades». Comanda: `/compactar-memoria`.

## Històric

(buit)

## Entrades

2026-10-16 · [decisió] Eines d'IA de l'equip: Cursor Pro i Antigravity CLI (`agy`). Sense subscripció a Claude Code; no es manté `.claude/` (ref. `docs/ai/README.md`).
2026-10-16 · [decisió] Font única de skills: `.agents/skills/`, que llegeixen Cursor i Antigravity. Els subagents es mantenen a `docs/ai/agents/` i es copien a mà als miralls Cursor/Antigravity.
2026-10-16 · [decisió] Documentació del projecte només a `frontend-aprop/docs/ai/`; el backend hi enllaça amb `../frontend-aprop/` (repos clonats l'un al costat de l'altre).
2026-10-16 · [decisió] Idioma de `AGENTS.md` i `docs/ai/`: català, com la resta de documentació de l'equip.
2026-10-16 · [descartat] Hooks en bash/python (`scripts/ai/`, `.cursor/hooks.json`): fallaven a Windows (encoding, dart.BAT, cache d'on_stop, forats al guard). Eliminats el 2026-10-17.
2026-10-16 · [error] `git fetch` per SSH falla des de PowerShell (la clau només és a WSL). Solució: git des de WSL.
2026-10-16 · [error] Contrast: `AppTheme.muted` sobre `cream` ≈ 4,4:1 (< AA 4,5:1 en text normal); sobre `cardBackground` ≈ 4,9:1 (decisió a DP-007).
2026-10-16 · [convenció] Dubtes i supòsits es registren a `docs/decisions-pendents.md` (DP-NNN) i es marquen al codi amb `TODO(DP-NNN)`; el subagent `vigilant-decisions` els revisa sota demanda.
2026-10-17 · [decisió] Sense capa `scripts/ai/` ni hooks d'IDE: agents, skills, rules i `docs/ai/` es mantenen a mà. Branca estable de producció: `master` (no `main`).
2026-10-16 · [descartat] Workflows d'Antigravity (`.agents/workflows/`): deixen de funcionar el 2026-10-19. Es fan servir skills amb `disable-model-invocation`.
