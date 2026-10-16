# Configuració d'IA del projecte

> **Quan llegir-ho:** en configurar una eina d'IA, en afegir o modificar skills, subagents, regles o hooks, o si
> alguna cosa de la IA no es carrega. No cal per programar.

## Mapa: quina eina llegeix cada fitxer

| Fitxer | Cursor | Antigravity CLI | Tipus |
|---|---|---|---|
| `AGENTS.md` | ✓ sempre | ✓ sempre | **font** |
| `docs/ai/*.md` | sota demanda | sota demanda | **font** |
| `docs/decisions-pendents.md` | sota demanda; el hook `stop` hi avisa | sota demanda; el hook `Stop` hi avisa | **font** (registre DP-NNN) |
| `.agents/skills/*/SKILL.md` | ✓ (`/nom`) | ✓ (`/nom`) | **font** |
| `.agents/rules/*.md` | — | ✓ (`trigger`) | **font** |
| `.cursor/rules/*.mdc` | ✓ | — | generat des de `.agents/rules/` |
| `docs/ai/agents/*.md` | — | — | **font** dels subagents |
| `.cursor/agents/*.md` | ✓ | — | generat |
| `.agents/agents/*/agent.md` | — | ✓ | generat |
| `.cursor/hooks.json` | ✓ | — | font (crida `scripts/ai/hooks/`) |
| `.agents/hooks.json` | — | ✓ | font (crida `scripts/ai/hooks/`) |
| `.cursorignore` | ✓ | — | font (instal·lació manual, vegeu més avall) |
| `scripts/ai/` | via hooks | via hooks | **font** |
| `docs/source/*.pdf` | ignorat | no el llegeix (regla de `AGENTS.md`) | original |

**Regla:** edita només les fonts i després executa `python3 scripts/ai/sync-ai-config.py`. Amb `--check`
comprova que no hi hagi res desincronitzat (útil a la CI).

## Posada en marxa (una vegada per persona)

1. Requisits: WSL amb `python3` i `git` (a Windows, Cursor executa els hooks amb `bash` = WSL).
2. `cp scripts/ai/templates/cursorignore .cursorignore` (Cursor no deixa que l'agent creï aquest fitxer).
3. Cursor: Settings › Agents › Hooks: comprova que `.cursor/hooks.json` hi aparegui. Settings › Rules: hi
   han de sortir 4 regles i `AGENTS.md`.
4. Antigravity: obre `agy` **des de l'arrel del repo** (`cd frontend-aprop && agy`). Comprova amb `/hooks`,
   `/agents` i escrivint `/` que es vegin els hooks, els subagents i les skills.
5. Permisos d'Antigravity (només es poden posar a la configuració global): afegeix a
   `~/.gemini/antigravity-cli/settings.json`:

   ```json
   {
     "permissions": {
       "allow": ["command(flutter analyze)", "command(flutter test)", "command(dart format)", "command(git status)",
                 "command(git diff)", "command(git log)", "command(go test)", "command(go vet)", "command(bash scripts/ai/)"],
       "deny":  ["command(rm -rf)", "command(git push --force)", "command(git push -f)", "read_file(.env)"],
       "ask":   ["command(git commit)", "command(git push)"]
     }
   }
   ```
   El hook `guard` aplica les mateixes regles encara que no ho facis.
6. Opcional: `bash scripts/ai/install-git-hooks.sh` (valida el format dels commits que fas tu).

## Backend (`api-aprop`)

La documentació del projecte és **només aquí**. El backend té el seu `AGENTS.md` i les seves skills de Go, i rep
còpies generades de les skills compartides, els subagents, els scripts i els hooks:

```bash
python3 scripts/ai/sync-ai-config.py --backend ../api-aprop
```

Cal que els dos repos estiguin clonats a la mateixa carpeta. Les skills compartides citen `docs/ai/…`: des del
backend, aquesta ruta és `../frontend-aprop/docs/ai/…` (ho indica el seu `AGENTS.md`).

## Afegir…

- **Una skill:** `.agents/skills/<nom>/SKILL.md` amb `name` (igual que la carpeta) i `description` (què fa i
  **quan** activar-la). Si és una comanda, `disable-model-invocation: true`. Si també és per al backend,
  `metadata: { repos: both }`. ≤ 120 línies; el material llarg va a `references/`.
- **Un subagent:** `docs/ai/agents/<nom>.md` (copia'n un d'existent) i executa la sincronització.
- **Una regla:** `.agents/rules/<nom>.md` amb `trigger: glob | model_decision | always_on | manual`. Prefereix
  `glob` o `model_decision`; `always_on` costa context a cada torn.
- **Proves dels hooks:** `python3 -m unittest discover -s scripts/ai/tests`.

## Afegir un altre agent (eina)

«Argon» no és una altra eina: és el model **Gemini 4 Argon** d'Antigravity CLI (`agy --model gemini-4-argon-high`).
Per a una eina nova (p. ex. Codex, Gemini CLI, Claude Code):

1. Comprova si llegeix `AGENTS.md` i `.agents/skills/` (estàndard Agent Skills). Si ho fa, no cal res més.
2. Si té un format propi de regles, subagents o hooks, afegeix-ne el generador a `scripts/ai/sync-ai-config.py`
   en lloc de copiar contingut a mà.
3. Afegeix-la a la taula «Mapa» i a `repartiment-eines.md`, i registra la decisió a `memoria.md`.
4. Claude Code en concret: llegeix `AGENTS.md` sense `CLAUDE.md`, però les skills les busca a `.claude/skills/`
   (caldria generar-les) i Cursor també carrega `.claude/skills/` i `.claude/agents/`: genera-les **o** per a
   una eina **o** per a l'altra, per no tenir-les duplicades.

## Pendent de verificar manualment

- Comprovat (2026-10-16, `agy -p`): Antigravity carrega els 9 subagents, `AGENTS.md`, les regles i les skills
  automàtiques, i treu de l'índex del model les que tenen `disable-model-invocation: true`.
  `TODO(verificar)`: que aquestes surtin igualment al menú `/` en mode interactiu.
- `TODO(verificar)`: si Antigravity té un fitxer d'ignore propi; ara depèn de `.gitignore` i de la regla de `AGENTS.md`.
- `TODO(verificar)`: el model real dels tiers `flash` i `pro` dels subagents d'Antigravity.
- `TODO(verificar)`: que l'identificador `composer-2.5` estigui disponible al teu pla de Cursor (si no, posa
  `inherit` a `docs/ai/agents/*.md` i sincronitza).