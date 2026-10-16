# Política d'estalvi de tokens

> **Quan llegir-ho:** en configurar una eina o quan una sessió es fa llarga, lenta o cara. Regles accionables;
> les eines i els models són a `repartiment-eines.md`.

## Context base mínim

- Sempre carregat: `AGENTS.md` (< 150 línies) + l'índex de skills, subagents i regles (només nom i descripció).
  Mesura-ho amb `bash scripts/ai/context-size.sh`.
- Tota la resta es carrega **sota demanda**: `docs/ai/*`, el cos de les skills, les regles `glob`.
- **No llegeixis mai els PDFs** de `docs/source/`; si canvien, `bash scripts/ai/pdf-to-md.sh` i actualitza
  només la secció afectada.
- Prefix estable: no editis `AGENTS.md` en cada sessió (trenca la memòria cau de prompts). L'estat va a `estat.md`.

## Una sessió = una història

- Comença amb `/estat` o «llegeix `docs/ai/estat.md`». Acaba amb `/tancar-sessio`.
- Entre històries: sessió nova (Cursor: xat nou; `agy`: surt i torna a entrar, o `/clear` si n'hi ha).
- Quan el context arribi al ~60 %: compacta indicant què cal conservar («conserva el pla, els fitxers tocats i
  els errors pendents; descarta els logs»), o tanca i obre una sessió nova des d'`estat.md`.

## Pla abans del codi

- Tasca de > 2 fitxers o amb decisions: `/pla` amb un model fort i, després, `/implementar` amb un model mitjà.
- No barregis planificar i implementar en el mateix torn amb el model car.

## Lectura i sortides

- Delega les cerques àmplies a `explorador-codi` (en torna conclusions, no fitxers).
- Llegeix rangs de línies, no fitxers sencers, quan el fitxer fa > 300 línies.
- Executa les proves, l'anàlisi i el build amb `bash scripts/ai/run-quiet.sh …`: només errors i resum.
- No enganxis logs sencers al xat: enganxa'n l'error i 5 línies de context.
- Demana sortides acotades: «torna només el diff», «taula de ≤ 10 files», «≤ 15 línies».

## Prompts específics

Inclou-hi sempre: fitxer o funció, criteri d'acceptació, què **no** s'ha de tocar i el format de sortida.
Exemples a `prompts-utils.md`. Un prompt ambigu costa més iteracions que un prompt llarg.

## Models

Fes servir el model més barat que pugui fer bé la tasca (taula a `repartiment-eines.md`). Opus i Argon High
només per a l'arquitectura, la planificació complexa, la seguretat i la integritat, i la depuració difícil.
