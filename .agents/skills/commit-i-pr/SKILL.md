---
name: commit-i-pr
description: "Prepara el missatge de commit amb el format «Tasca #ID Títol: descripció», comprova la branca i els fitxers en stage, i redacta la descripció de la PR enllaçada a Taiga amb la checklist de la DoD. Fes-la servir quan l'usuari vulgui fer commit, publicar la branca o obrir una PR."
metadata:
  repos: both
---

# Commit i PR

**Cap commit ni push sense una confirmació explícita de l'usuari en aquest torn.** Segueix també la regla `git-commits`.

## 1. Comprovacions

```bash
git branch --show-current          # no ha de ser master/develop
git status --short
git diff --stat                    # què canvia
```

- Proposa quins fitxers entren al commit (llista). Exclou `.env`, `build/`, fitxers generats i canvis aliens a la tasca.
- Si hi ha codi Dart, comprova `dart format --output=none --set-exit-if-changed lib test` i `flutter analyze`.

## 2. Missatge

```
Tasca #<ID> <Títol exacte de la tasca a Taiga>: <què canvia, en català, ≤ 1 línia>
```

- Demana l'ID i el títol si no són a `docs/ai/estat.md`.
- La descripció diu **què** canvia de cara a qui revisa (no «canvis», ni «fix»).
- Comprova que segueix el format `Tasca #<ID> <Títol>: <descripció>`.

Mostra a l'usuari:

```
Fitxers: a, b, c
Missatge: Tasca #75 Frontend pantalla d'esdeveniment: Afegeix l'estat d'error amb reintent
Ordres: git add a b c && git commit -m "…"
```

i espera'n la confirmació.

## 3. PR

Base: `develop` (o `master` per a `hotfix/`). Títol = el mateix format que el commit principal.
Cos: omple `.github/pull_request_template.md`:

- Enllaç a Taiga: `https://tree.taiga.io/project/wenqiange-aprop/` + l'ID de la història o la tasca (`TODO(confirmar)` la ruta exacta).
- Resum (3–5 punts), criteris d'acceptació amb ✓, proves executades, què és de demostració o queda pendent,
  captures si hi ha UI.
- Checklist de la DoD.

Si l'usuari ho autoritza i té `gh` (a WSL): `gh pr create --base develop --title "…" --body-file <fitxer>`.
Si no, dona-li el text per enganxar-lo.

## 4. Després

Actualitza `docs/ai/estat.md` (estat: «PR oberta #n»).
