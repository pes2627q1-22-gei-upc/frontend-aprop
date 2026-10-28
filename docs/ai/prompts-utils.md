# Prompts útils

> **Quan llegir-ho:** quan vulguis demanar una tasca recurrent sense haver de pensar el prompt. Substitueix el
> que hi ha entre `<>`. Els pots escriure en castellà o en català; la sortida del codi i de la UI segueix `AGENTS.md`.

1. **Començar una història**
   `/iniciar-historia #<ID> <títol>` — i enganxa-hi els criteris d'acceptació de Taiga.

2. **Planificar sense tocar res**
   `/pla Taiga #<ID>: <què>. Només <carpeta/feature>. No toquis <X>. Pla de ≤ 30 línies amb la verificació de cada pas.`

3. **Implementar un pla**
   `/implementar Segueix aquest pla: <enganxa'l>. Skill pantalla-flutter. No afegeixis paquets. Torna només la llista de fitxers, el resultat de les proves i un resum de 5 línies.`

4. **Pantalla des del mockup**
   `Implementa la pantalla <secció> segons docs/ai/50-ui-mockups.md (fila <pantalla>) amb la skill pantalla-flutter i dades de demostració a data/. Controls fora de l'abast, desactivats. Proves de ViewModel i de widget.`

5. **Proves d'una restricció**
   `/provar Escriu proves per a R<n> (docs/ai/20-model-domini.md) a <fitxer o capa>. Un cas vàlid i un cas invàlid per condició. Torna només el resultat.`

6. **Entendre codi sense gastar context**
   `Fes servir explorador-codi: on i com es gestiona <X>? Torna fitxer:línia i el patró a seguir, ≤ 10 línies.`

7. **Corregir una fallada de la CI**
   `Fes servir devops-ci: la CI falla a <job>. Error: <enganxa 10 línies>. Troba'n la causa arrel i proposa el canvi mínim. No toquis el codi de l'app.`

8. **Revisar abans de demanar la revisió humana**
   `/revisar` — o, per a un canvi crític: `/revisar` i, a més, `Fes servir seguretat-privacitat sobre el diff de origin/develop...HEAD.`

9. **Commit i PR**
   `/pr Tasca #<ID> <títol de Taiga>.` (Proposa el missatge i la descripció; tu confirmes.)

10. **Bug**
    `/bug <què passa> a <pantalla o endpoint>. Passos: <1, 2, 3>. Esperat: <…>. Història: #<ID>.`

11. **Revisar els textos de la UI**
    `Fes servir traductor-i18n sobre lib/features/<f>/: revisa el to (proximitat, sense vocabulari transaccional). Taula clau | actual | proposta.`

12. **Tancar el dia**
    `/tancar-sessio`
