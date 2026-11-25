# ADR-0011 — Moteur de timing déterministe partagé

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : timing fiable, parité face/app, testabilité, 100 % local

## Contexte

Le projet utilisait huit créneaux codés en dur dans la watch-app
(`companion/source/BuzzApp.mc:306-313`) et dans la face
(`source/BigDigitsView.mc:450-512`), avec des heures configurées `UserProfile`
comme repli. Les critères du livre (`protocol-criteria-from-book.md`) et les
données réelles (`watch-data-2026-11-25.md`) montrent que ces créneaux sont
décalés : rappel écrans à 22 h 24 au lieu de 20 h 25, seuil de pas à 85 % du
goal à 18 h 30 au lieu d'un rythme requis, NSDR sans dette cumulée. Le FR955
n'expose ni score de sommeil natif, ni capteur de lumière, ni caféine ingérée.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| **A. Créneaux fixes maintenus** | simple, aucun calcul | ignore les données réelles, contradictoire avec le livre | 0 | immédiate |
| **B. Calcul uniquement dans la watch-app** | données capteurs complètes, vibration | la face ne peut pas lire le Storage de l'app ; pont non prouvé | 2 | moyenne |
| **C. Module pur partagé + calcul dans chaque cible** | une seule source de seuils, testable, repli autonome | deux cibles à compiler, dérive possible si le module diverge | 3 | élevée |

## Décision

Retenir **C**. `shared/Timing.mc` contient les constantes du livre et des
fonctions pures (`timingCircularMean`, `timingTempMin`, `timingScreenStart`,
`timingCaffeine`, `timingDebt7`, `timingRobustZ`, `timingStepRate`,
`timingNsdrMinutes`, `timingHysteresis`, `timingExpired`, `timingChooseSlot`).
Il est compilé dans la face et les tests via `monkey.jungle:3`
(`base.sourcePath = source;shared`). La watch-app utilise une copie annotée
`(:background)` (`companion/source/Timing.mc`) car le module partagé annoté
exigerait la permission `Background` dans le manifest du cadran (observé :
`ERROR: The 'Background' permission is required...` au build de test).
`scripts/check-timing-parity.sh` garantit l'égalité des deux fichiers après
retrait des annotations. **A est rejeté** car il
conserve un décalage mesuré de 2 h ; **B seul est rejeté** car le pont par
complications n'est pas prouvé sous CIQ 9.3.0.

La watch-app utilise les événements réels quand `bedEventCount() >= 3`, sinon
les heures `UserProfile` (`eventConfidence()`). La face, qui ne peut pas lire
ces événements, utilise `UserProfile` et le documente comme repli.

## Conséquences

- Positives : 22 tests unitaires verts, seuils sourcés, un seul fichier de
  constantes, dédup par jour local, hystérésis apprise (−15 min si validé
  tard, +15 min si accusé, inchangé si expiration).
- Négatives acceptées : la face et l'app peuvent différer de quelques minutes
  tant que le pont de complications n'est pas prouvé ; `stressZ()` exige
  ≥ 10 échantillons sinon renvoie 0 (`notMeasured`).
- À surveiller : dérive entre `shared/Timing.mc` et les libellés de messages ;
  dérive des heures `UserProfile` entre les deux cibles.

## Preuves

- `shared/Timing.mc:1-28` — constantes et sources `chunk_XXX`.
- `source/TimingTests.mc` — 15 tests du moteur, 22 au total avec les tests
  d'habitude, `PASSED (passed=22, failed=0, errors=0)`.
- `companion/source/BuzzApp.mc:338-352` — créneaux calculés au lieu de fixes.
- `source/BigDigitsView.mc:336-380,443-512` — repli `UserProfile` sur la face.
- `docs/architecture/watch-data-2026-11-25.md` — dodo 23 h 24, lever 06 h 25.

## Révision

Si le spike `ComplicationProvider`/`ComplicationSubscriber` réussit, remplacer
le calcul face par la consommation du payload et conserver le module partagé
comme repli.
