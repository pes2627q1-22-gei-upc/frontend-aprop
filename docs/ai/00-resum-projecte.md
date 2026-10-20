# 00 · Resum del projecte

> **Quan llegir-ho:** a l'inici d'una tasca nova si no coneixes AProp!, o quan dubtis si una funcionalitat
> entra a l'abast (llista IS / IS NOT / MAYBE). No cal per a canvis locals de codi.
> **Font:** `docs/source/incepcio-2.pdf` §2–§6 (no el rellegeixis; aquest resum el substitueix).

## Visió

- **Producte:** AProp! — «La cultura, més a prop.» App mòbil (Android + iOS) per descobrir i planificar
  activitats culturals a Catalunya a partir de les Dades Obertes de la Generalitat.
- **Equip:** FiveGuys (Wenqiang He, Lluc Paez, Arnau Serra, Sukhjeet Singh, Adam Ziani). PES, FIB–UPC.
  Professor i product owner: Víctor Asenjo Carvajal.
- **Problema:** l'oferta cultural és dispersa entre webs i apps; costa passar de *descobrir* a *organitzar-se*.
- **Proposta:** una sola app per descobrir (mapa i llista), decidir (fitxa, recomanacions, xatbot) i recordar
  (agenda amb recordatoris), amb una capa social (amistats, xat per activitat, activitats d'usuaris).
- **Competidor directe:** Vibra (mateixes dades obertes). Ens diferenciem per l'experiència: calendari amb
  recordatoris, test d'interessos, xatbot i part social. Altres referents: Agenda Cultural (web), Eventbrite,
  Time Out, Fever, Meetup.
- **To:** proximitat i neutralitat. Apuntar-se = intenció d'assistir, **no** una compra. Sense publicitat.
- **Usuari amb més potencial:** qui ja consumeix cultura de manera activa però dispersa.
- **Dataset:** Agenda cultural de Catalunya per localitzacions (`rhpv-yr4f`) a analisi.transparenciacatalunya.cat.

## IS (l'aplicació farà)

1. Descobrir i planificar activitats culturals a Catalunya a partir de dades obertes.
2. Mapa interactiu amb les activitats geolocalitzades.
3. Llistat amb cerca per paraules clau i filtres per ubicació, data i horari.
4. Fitxa de cada activitat (descripció, ubicació, dates…).
5. Calendari personal amb les activitats guardades.
6. Recordatoris quan s'apropa la data.
7. Recomanacions segons les activitats guardades i un test d'interessos inicial.
8. Xatbot per trobar activitats en llenguatge natural, per text o per veu.
9. Comptador visible de persones apuntades (senyal de popularitat).
10. Amistats: compartir plans, veure les activitats que els amics fan visibles, xat entre assistents.
11. Qualsevol usuari (també entitats) pot publicar activitats pròpies, mostrades amb les oficials.
12. Valoracions de les activitats a què s'ha assistit; en les no oficials, es guarden al perfil de l'organitzador.
13. Exportació del calendari personal a Google Calendar.
14. Esdeveniments astronòmics del servei de Talaia al mapa, llistat i calendari.
15. Moderació: denúncies d'usuaris i d'activitats no oficials; els administradors desactiven comptes i retiren activitats.
16. Bloquejar altres usuaris.
17. Nivells d'experiència que premien la participació.

## IS NOT

1. Venda d'entrades o pagaments (la compra es fa fora de l'app).
2. Navegació GPS o càlcul de rutes en temps real.
3. Reserves o gestió d'aforament.

## MAYBE

1. Expansió a activitats de fora de Catalunya.

## Stakeholders (resum)

Usuaris finals · organitzadors i espais (via dades obertes) · Generalitat (proveïdora de dades) ·
competidors · proveïdors tecnològics (Google, AWS, Firebase, GitHub) · FiveGuys · equips PES Talaia
(ens proveeix) i Mobilicat (ens consumeix) · F-Droid (distribució) · professor (PO i client).

## On seguir

Requisits → `10-requisits.md` · Model → `20-model-domini.md` · Pantalles → `50-ui-mockups.md`.
