---
name: release-semver
description: Decideix el número de versió SemVer (MAJOR, MINOR o PATCH) d'una release a main, prepara el tag i el changelog i comprova el pipeline de desplegament (GitHub Actions, GHCR, EC2). Fes-la servir al final d'un sprint o quan es vulgui publicar una versió o un hotfix.
disable-model-invocation: true
metadata:
  repos: both
---

# Release SemVer

Criteris complets a `docs/ai/60-metodologia-i-qualitat.md` § Versionat. **Cap tag ni push sense confirmació.**

## 1. Punt de partida

```bash
git fetch --tags origin
git describe --tags --abbrev=0 origin/main 2>/dev/null || echo "sense tags"
git log --oneline <darrer-tag>..origin/develop      # o ..origin/hotfix/<x>
```

Si no hi ha cap tag, la primera release és `v0.1.0` (`TODO(confirmar)` amb l'equip si el MVP serà `v1.0.0`).

## 2. Decisió

| Si entre els commits hi ha… | Increment |
|---|---|
| MVP, migració d'un component crític, canvi estructural o redisseny significatiu de la UI | MAJOR |
| Funcionalitat nova retrocompatible o actualització de llibreries *deprecated* | MINOR |
| Només correccions de bugs, de lògica o visuals | PATCH |

Agrupa els commits per tipus a partir del títol de la tasca. En cas de dubte entre dos nivells, tria el més alt
i justifica-ho en una línia.

## 3. Comprovacions abans del merge a `main`

- [ ] CI verda a `develop` (frontend i backend)
- [ ] Review i retrospectiva fetes; històries de l'sprint en «Done» a Taiga
- [ ] Migracions de BD noves revisades (backend)
- [ ] `.env.example` al dia amb les variables noves
- [ ] Frontend: `version:` a `pubspec.yaml` = `X.Y.Z+<build>` (build +1)

## 4. Ordres (proposa-les; les executa l'usuari)

```bash
# PR develop → main revisada i fusionada; després:
git switch main && git pull --ff-only
git tag -a vX.Y.Z -m "vX.Y.Z: <resum en una línia>"
git push origin vX.Y.Z
```

Hotfix: `hotfix/<x>` → PR a `main` → tag PATCH → **merge també a `develop`**.

## 5. Desplegament (backend)

El tag o release a `main` dispara GitHub Actions → imatge Docker → GHCR → EC2. Comprova-ho:

```bash
gh run list --branch main --limit 3          # a WSL
gh run view <id> --log-failed                # només si falla
```

Estat actual: el workflow `go.yml` és incomplet (`TODO`, subagent `devops-ci`).

## Sortida

Versió proposada i motiu, changelog agrupat (≤ 15 línies), checklist i ordres.
