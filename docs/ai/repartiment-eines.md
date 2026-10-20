# Repartiment d'eines i models

> **Quan llegir-ho:** quan dubtis quina eina o quin model fer servir per a una tasca, quan s'esgoti la quota
> d'una eina o quan hagis de passar la feina a una altra. Eines de l'equip: **Cursor Pro** i **Antigravity CLI** (`agy`).

## Quina eina per a què

| Eina | Fes-la servir per a | Evita-la per a |
|---|---|---|
| **Cursor · Tab i Inline Edit (Ctrl+K)** | canvis petits i localitzats, completar codi, renomenar dins d'un fitxer | canvis multi-fitxer |
| **Cursor · Agent** | ajustos de UI Flutter amb feedback visual, iterar sobre una pantalla, *debug* amb el codi obert, revisar un diff a l'editor | tasques llargues que no vols seguir pas a pas |
| **Antigravity CLI** (`agy`, a WSL) | planificació i arquitectura (Opus 5.5), històries multi-fitxer, tasques llargues o autònomes en segon pla, subagents en paral·lel, CI i DevOps, segones opinions i revisions creuades | retocs visuals ràpids |

Regla pràctica: **pensar i planificar a Antigravity amb un model fort; executar al lloc on es veu el resultat**
(Cursor per a UI, Antigravity per a backend i tasques llargues).

## Encaminament de models

`agy --model <id>` o `/model` a la sessió. A Cursor, el selector de models del xat (els subagents tenen el model fixat).

| Tasca | Subagent / skill | Antigravity | Cursor |
|---|---|---|---|
| Arquitectura, contractes d'API, ADR | `arquitecte` | `claude-opus-5-5-high` o `gemini-4-argon-high` | model fort al pare (`inherit`) |
| Planificar una història complexa | `/pla` | `claude-opus-5-5-high` | mode Plan + model fort |
| Depuració difícil (no reproduïble, concurrència) | — | `claude-opus-5-5-high` | model fort |
| Seguretat, privacitat, integritat (R1–R15) | `seguretat-privacitat` | `claude-opus-5-5-high` | model fort |
| Revisió de PR crítica (auth, dades, migracions) | `revisor` | `claude-opus-5-5-medium` | model fort |
| Revisió de PR normal | `revisor` | `claude-sonnet-5-5-high` / `gemini-4-argon-medium` | `inherit` |
| Implementar amb un pla | `implementador-*`, `/implementar` | `claude-sonnet-5-5-medium` / `gemini-4-argon-medium` | `inherit` (model mitjà) |
| CI, Docker, desplegament | `devops-ci` | `gemini-4-argon-medium` | `inherit` |
| Proves repetitives | `tester`, `/provar` | `gemini-3.8-flash-high` (tier `flash`) | `composer-2.5` |
| Cerca al codi | `explorador-codi` | `gemini-3.8-flash-medium` | `composer-2.5` o l'Explore integrat |
| Documentació, i18n, memòria | `documentador`, `traductor-i18n`, `/compactar-memoria` | `gemini-3.8-flash-medium` | `composer-2.5` |
| Vigilar decisions pendents després de cada canvi | `vigilant-decisions` | `gemini-3.8-flash-medium` | `composer-2.5` |
| Missatge de commit, `/estat` | `/pr`, `/estat` | `gemini-3.8-flash-low` | `composer-2.5` |

Tiers dels subagents d'Antigravity: `flash` (ràpid), `pro` (fort), `inherit` (el de la sessió). Per fer servir
Opus en un subagent `pro`, obre la sessió amb `--model claude-opus-5-5-high`. `TODO(verificar)`: a quin model
concret correspon cada tier.

## Quan **no** fer servir subagents

- La tasca toca 1–2 fitxers coneguts o es fa en < 5 minuts: fes-la directament (el subagent recarrega context).
- La sortida del subagent caldria llegir-la sencera igualment (p. ex. un diff petit).
- Treballs seqüencials que depenen l'un de l'altre: fes-los al fil principal.
- **Sí** que convé quan hi ha cerques àmplies (`explorador-codi`), feina paral·lelitzable (proves de diverses
  features) o quan cal un context net (`revisor` després d'implementar).

## Quotes: què fer quan se n'acaba una

| S'esgota… | Passa a… |
|---|---|
| Opus a Antigravity | `gemini-4-argon-high` per planificar; si la tasca és crítica, espera o fes servir el model fort de Cursor |
| Antigravity sencer | Cursor Agent amb `/pla` i `/implementar` (les mateixes skills) |
| Peticions ràpides de Cursor | Tab + `agy` amb `gemini-3.8-flash-*` per a tasques mecàniques |
| Tot | `docs/ai/prompts-utils.md` i feina manual; deixa l'estat a `estat.md` |

Reparteix la feina pesant (planificació, revisions crítiques) a l'inici de la setmana, quan hi ha més quota.

## Traspàs entre eines (sense copiar converses)

1. A l'eina que deixes: `/tancar-sessio` (actualitza `docs/ai/estat.md` i la memòria si cal).
2. A l'eina nova, primer missatge: «Llegeix `docs/ai/estat.md` i continua amb el proper pas.»
3. No hi enganxis la conversa anterior: si cal un pla, guarda'l en un fitxer temporal fora de git o a la PR.
