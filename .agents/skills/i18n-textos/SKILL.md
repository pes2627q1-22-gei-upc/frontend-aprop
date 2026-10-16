---
name: i18n-textos
description: Redacta, revisa, extreu o tradueix textos de la interfície (català, castellà i anglès) amb el to de proximitat i neutralitat d'AProp!, sense vocabulari transaccional ni publicitat. Fes-la servir quan s'escriguin etiquetes, missatges d'error, avisos o traduccions de la UI.
---

# Textos i i18n

## Estat i decisió pendent

- La UI actual és **només en català**, amb cadenes dins de les pantalles i els ViewModels.
- NFR: textos centralitzats en fitxers de traducció i idiomes ca/es/en (el mockup de Configuració mostra només
  ca/es). Història «Canviar idioma» (5 SP).
- `TODO(confirmar)` amb l'equip abans d'implementar-ho: `flutter_localizations` + `intl` amb fitxers ARB
  (`lib/l10n/app_ca.arb` com a plantilla, `l10n.yaml`) i si l'anglès entra a l'abast. **No afegeixis els paquets
  sense aquesta decisió** (regla de `AGENTS.md`). Quan es decideixi, registra-ho amb un ADR.

## Guia d'estil (NFR «Style of the Product»)

| Evita | Fes servir |
|---|---|
| comprar, reservar, entrada, oferta, promoció | apuntar-s'hi, «M'hi apunto», «Apuntat», pla |
| «Error 500», «Exception» | «No hem pogut carregar l'activitat. Torna-ho a provar.» |
| imperatius bruscos («Introdueix!») | to proper i neutre («Escriu el teu nom d'usuari») |
| llenguatge sexista | formes inclusives: «Amiga/Amic», «Curiós/a», «Ambaixador/a cultural» |
| tecnicismes | paraules del dia a dia («Avisos», «Agenda», «Descobreix») |

- Frases curtes, en segona persona del singular (tu). Apòstrof tipogràfic (’) com al codi actual.
- Botons: verb + objecte («Desar», «Tornar a fer el test d'interessos»). Accions destructives explícites
  («Eliminar compte», en coral).
- Errors: què ha passat + què pot fer l'usuari. Mai culpar-lo.
- Indicar que no s'hi va assistir no és una valoració negativa: evita-hi qualsevol to de retret.

## Procediment

1. Textos nous: redacta'ls en català seguint la guia; si es repeteixen a la feature, posa'ls en una classe
   `<Feature>Strings` (constants) dins de `presentation/`.
2. Revisió: busca'n de transaccionals amb
   `rg -n -i "compr|reserv|entrad|oferta|promoci" lib` i revisa'n cada coincidència.
3. Traduccions (quan existeixin els ARB): ca és la font; es/en conserven el to i els placeholders
   (`{count}`, plurals ICU). No tradueixis noms propis ni «AProp!». Les dades de l'Agenda Cultural les
   tradueix el backend (Google Translate), no la UI.

## Sortida

Taula `clau | ca | es | en | nota`, o el diff dels fitxers. Màxim 1 línia de justificació per canvi.
