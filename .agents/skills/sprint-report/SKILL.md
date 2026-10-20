---
name: sprint-report
description: Genera la base de l'informe de l'Sprint Master (feina feta, coordinació, problemes i millores) i revisa la coherència de les hores del PRT per membre i categoria. Fes-la servir en acabar un sprint o una fase, o quan es preparin el lliurament, el PRT o la retrospectiva.
disable-model-invocation: true
metadata:
  repos: both
---

# Informe de sprint i revisió del PRT

L'informe es lliura en **català**, en el to del «Sprint master report» de la Incepció 2 (prosa, primera
persona de l'Sprint Master, 2–4 paràgrafs).

## Entrades (demana-les; no les inventis)

- Exportació del PRT (CSV o taula enganxada): membre, data, tasca, categoria, hores.
- Històries i tasques de l'sprint a Taiga (estat, hores estimades i reals).
- Nom de l'Sprint Master i dates de l'sprint.
- Opcional: `git log --since=<inici> --until=<fi> --oneline` dels dos repos.

## 1. Revisió del PRT

Calcula les hores per membre i categoria i comprova:

1. **Categoria correcta.** Error conegut: tasques de gestió de projecte amb Taiga (crear o estimar històries,
   planificació) marcades com a «Documentació». Senyals: paraules com «Taiga», «backlog», «planificació»,
   «estimació», «sprint» en una tasca de «Documentació» → proposa «Gestió de projecte».
2. **Coherència amb Taiga:** les hores reals de les tasques tancades ≈ les hores del PRT (±15 %).
3. **Desequilibri:** algun membre amb > 1,5× o < 0,5× la mitjana. Pot ser legítim: indica-ho, no ho jutgis.
4. **Forats:** dies o tasques sense registre, entrades duplicades, hores > 10 en un dia.
5. **Codi vs PRT:** les tasques d'implementació tenen commits `Tasca #ID` coherents.

Sortida: taula `membre | categoria | hores | incidència | proposta`. Cap canvi directe al PRT.

## 2. Informe (esborrany)

Estructura:

1. Objectiu de l'sprint i què s'ha lliurat (històries en «Done», SP completats vs planificats).
2. Organització: reunions (classe, Discord), canals (WhatsApp) i repartiment frontend/backend.
3. Valoració de l'Sprint Master: què ha funcionat i complicacions (temps, coordinació, PRT).
4. Accions de millora per al proper sprint (≤ 3, concretes).

Velocitat: `SP completats / SP planificats`; inclou-la amb 1 decimal.

## 3. Coherència

Comprova que l'informe no contradigui `docs/ai/estat.md` ni el backlog. Al final, actualitza «Fet recentment» a `estat.md`.
