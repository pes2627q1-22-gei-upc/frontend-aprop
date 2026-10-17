---
name: bug
description: "Comanda /bug <descripció>: redacta la issue de Taiga, proposa la branca i escriu una prova que reprodueixi el bug abans de corregir-lo."
disable-model-invocation: true
metadata:
  repos: both
---

# /bug

Procés de la memòria §2.8. L'argument és la descripció del bug.

1. **Issue de Taiga** (l'usuari la crea; tu redactes el text amb la plantilla `.github/ISSUE_TEMPLATE/bug.md`):
   títol curt; passos per reproduir-lo; resultat esperat i real; severitat (crítica | alta | mitjana | baixa);
   història relacionada (#ID); entorn (dispositiu o versió).
   Severitat crítica = afecta producció o la integritat de les dades (R1–R15) → `hotfix/` des de `master`.
   La resta es prioritza a la planning següent, si no és de l'sprint en curs.
2. **Branca** (proposa-la): `hotfix/<nom>` (crític a `master`) o `feature/fix-<nom>` des de `develop`.
3. **Prova que el reprodueix:** escriu-la primer i comprova que **falla** pel motiu esperat
   (`flutter test <fitxer>`).
4. **Correcció mínima** només si l'usuari ho autoritza; després, la prova ha de passar i la suite també.
5. Commit proposat: `Tasca #<ID de la issue> <Títol>: Corregeix <efecte> i afegeix-ne la prova`.

Sortida: el text de la issue, la branca, la prova (fitxer i nom) i el seu resultat abans i després.
