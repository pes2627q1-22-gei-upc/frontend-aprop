# ADR-0002 · Fer l'app mòbil en Flutter i no en React Native

- **Estat:** acceptada
- **Data:** 2026-10-02 (Incepció 2) · **Autoria:** FiveGuys

## Context

Cal una sola base de codi per a Android i iOS. Hi ha funcionalitats exigents en rendiment visual: el mapa
interactiu amb molts marcadors i les animacions del «Tinder d'esdeveniments» (lliscar targetes al test d'interessos).

## Decisió

Flutter 3.47 (Dart) per a Android i iOS. L'app només es comunica amb l'API REST; no accedeix mai a la BD.

## Alternatives considerades

- **React Native:** una sola base de codi, però amb un pont cap als components natius; el rendiment de les
  animacions i del mapa amb molts marcadors seria inferior.
- **Natiu per plataforma:** dues bases de codi a mantenir.

## Conseqüències

- (+) Compilació a codi natiu, rendiment alt i un únic `ThemeData` per a tota la UI.
- (−) La web de Flutter només serveix com a eina de desenvolupament; cal provar sempre en mòbil (`README.md`).
