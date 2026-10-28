# Configuració d'IA del projecte

> **Quan llegir-ho:** en configurar una eina d'IA, en afegir o modificar skills, subagents o regles, o si
> alguna cosa de la IA no es carrega. No cal per programar.

## Mapa: quina eina llegeix cada fitxer

| Fitxer | Cursor | Antigravity CLI | Tipus |
|---|---|---|---|
| `AGENTS.md` | ✓ sempre | ✓ sempre | **font** |
| `docs/ai/*.md` | sota demanda | sota demanda | **font** |
| `docs/decisions-pendents.md` | sota demanda | sota demanda | **font** (registre DP-NNN) |
| `.agents/skills/*/SKILL.md` | ✓ (`/nom`) | ✓ (`/nom`) | **font** |
| `.agents/rules/*.md` | — | ✓ (`trigger`) | **font** |
| `.cursor/rules/*.mdc` | ✓ | — | mirall de `.agents/rules/` (edita les dues o copia a mà) |
| `docs/ai/agents/*.md` | — | — | **font** dels subagents |
| `.cursor/agents/*.md` | ✓ | — | mirall (edita la font i copia) |
| `.agents/agents/*/agent.md` | — | ✓ | mirall (edita la font i copia) |
| `.cursorignore` | ✓ | — | font (creació manual) |
| `docs/source/*.pdf` | ignorat | no el llegeix (regla de `AGENTS.md`) | original |

**Regla:** no hi ha scripts ni hooks d'automatització en aquest repo. Edita les fonts i mantén els miralls
(`.cursor/…` i `.agents/agents/…`) alineats a mà quan canviïs un subagent o una regla.

## Posada en marxa (una vegada per persona)

1. Cursor: Settings › Rules: hi han de sortir les regles i `AGENTS.md`. Skills a `.agents/skills/`.
2. Antigravity: obre `agy` **des de l'arrel del repo** (`cd frontend-aprop && agy`). Comprova amb `/agents`
   i escrivint `/` que es vegin els subagents i les skills.
3. Permisos d'Antigravity (configuració global), a `~/.gemini/antigravity-cli/settings.json`:

   ```json
   {
     "permissions": {
       "allow": ["command(flutter analyze)", "command(flutter test)", "command(dart format)", "command(git status)",
                 "command(git diff)", "command(git log)", "command(go test)", "command(go vet)"],
       "deny":  ["command(rm -rf)", "command(git push --force)", "command(git push -f)", "read_file(.env)"],
       "ask":   ["command(git commit)", "command(git push)"]
     }
   }
   ```

## Backend (`api-aprop`)

La documentació del projecte és **només aquí**. El backend té el seu `AGENTS.md` i les seves skills de Go.
Les skills compartides citen `docs/ai/…`: des del backend, aquesta ruta és `../frontend-aprop/docs/ai/…`
(ho indica el seu `AGENTS.md`).

## Afegir…

- **Una skill:** `.agents/skills/<nom>/SKILL.md` amb `name` (igual que la carpeta) i `description` (què fa i
  **quan** activar-la). Si és una comanda, `disable-model-invocation: true`. Si també és per al backend,
  `metadata: { repos: both }`. ≤ 120 línies; el material llarg va a `references/`.
- **Un subagent:** `docs/ai/agents/<nom>.md` (copia'n un d'existent) i actualitza els miralls
  `.cursor/agents/<nom>.md` i `.agents/agents/<nom>/agent.md`.
- **Una regla:** `.agents/rules/<nom>.md` amb `trigger: glob | model_decision | always_on | manual`, i el
  mirall `.cursor/rules/<nom>.mdc` per a Cursor. Prefereix `glob` o `model_decision`; `always_on` costa
  context a cada torn.

## Afegir un altre agent (eina)

«Argon» no és una altra eina: és el model **Gemini 4 Argon** d'Antigravity CLI (`agy --model gemini-4-argon-high`).
Per a una eina nova (p. ex. Codex, Gemini CLI, Claude Code):

1. Comprova si llegeix `AGENTS.md` i `.agents/skills/` (estàndard Agent Skills). Si ho fa, no cal res més.
2. Si té un format propi, afegeix miralls manuals (no automatitzats) i documenta'ls a la taula «Mapa».
3. Afegeix-la a `repartiment-eines.md` i registra la decisió a `memoria.md`.
4. Claude Code: llegeix `AGENTS.md` sense `CLAUDE.md`, però les skills les busca a `.claude/skills/`.

## Pendent de verificar manualment

- Comprovat (2026-10-16, `agy -p`): Antigravity carrega els subagents, `AGENTS.md`, les regles i les skills
  automàtiques, i treu de l'índex del model les que tenen `disable-model-invocation: true`.
  `TODO(verificar)`: que aquestes surtin igualment al menú `/` en mode interactiu.
- `TODO(verificar)`: si Antigravity té un fitxer d'ignore propi; ara depèn de `.gitignore` i de la regla de `AGENTS.md`.
- `TODO(verificar)`: el model real dels tiers `flash` i `pro` dels subagents d'Antigravity.
- `TODO(verificar)`: que l'identificador `composer-2.5` estigui disponible al teu pla de Cursor (si no, posa
  `inherit` a `docs/ai/agents/*.md` i als miralls).
