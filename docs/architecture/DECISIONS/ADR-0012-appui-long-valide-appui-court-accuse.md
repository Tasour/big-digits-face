# ADR-0012 — Appui long valide, appui court accuse, expiration à 1 h

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : interaction fiable sur FR955, intégrité des 7 cases, autonomie

## Contexte

Le porteur veut : un appui rapide fait disparaître la notification, un appui
long coche la journée, et la notification disparaît au bout d'une heure sans
appui. Le FR955 **est tactile** : `~/.Garmin/ConnectIQ/Devices/fr955/simulator.json`
déclare `display.isTouch = true` et `tap → onSelect` (avec `hold`, `release` et
les swipes). Le SDK 9.3.0 documente cependant `WatchFaceDelegate.onTap()` comme
« Only available in WatchFace config mode », tandis que `onPress()` est
« called when user does a touch and hold ». Un spike graphique n'a pas permis
d'observer un `tap` en mode normal ; le geste long reste donc la voie prouvée.
La watch-app, elle, distingue `BehaviorDelegate.onPress()` (court) de `onMenu()`
(long). Correction apportée le 2026-11-25 : l'affirmation précédente selon
laquelle la 955 n'était pas tactile était fausse.

Le popup du cadran expire après 25 s (`POP_MS = 25000`, avant modification) ;
celui de l'app après 25 s par Timer. Les 7 cases d'habitude vivent dans le
Storage du cadran ; l'app ne peut pas les écrire.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| **A. Deux gestes sur le cadran** | correspondrait littéralement à la demande | `onTap` limité au mode config par le SDK 9.3.0 ; spike normal non concluant | 2 | différée |
| **B. Appui long sur le cadran = valide ; accusé par l'app ou expiration** | respecte le matériel ; validation au bon endroit (Storage des cases) | l'accusé rapide nécessite d'ouvrir l'app compagnon | 2 | immédiate |
| **C. Tout piloter depuis l'app avec pont de complications** | deux gestes au même endroit | pont non prouvé ; latence `notMeasured` | 4 | moyenne |

## Décision

Retenir **B**, avec **C comme évolution conditionnelle**. Sur le cadran :
- appui long (`onButtonPress` → `markDone()`) coche la case du jour et ferme
  le popup, une seule fois par jour local (`habit.day.<slot>`) ;
- le popup protocole reste **3 600 000 ms**, le popup de test reste 10 000 ms ;
  l'expiration est vérifiée dans `onPartialUpdate()` sans Timer, car la watch
  face est redessinée par le système (`BigDigitsView.mc:217-228`) ;
- une notification par catégorie et par jour (`face.notif.<slot>`), donc pas de
  réapparition après expiration.

Sur l'app compagnon :
- `PopupDelegate.onPress()` accuse **sans cocher** et enregistre l'issue
  `dismissed` (décalage +15 min) ;
- `PopupView.closePopup()` enregistre `none` (inchangé) ;
- l'appui long sur le cadran enregistre `done` (décalage −15 min) via le
  `recordOutcome()` partagé ;
- la vibration est limitée à un buzz par slot et par jour.

**A est différée** jusqu'à la preuve d'un `onTap` en mode normal : le tactile
existe, mais le SDK limite ce callback au mode configuration. **C est différée**
jusqu'à la preuve du pont.

## Conséquences

- Positives : geste de validation au seul endroit qui possède les cases ;
  accusé possible sans valider ; expiration honorée ; apprentissage du timing.
- Négatives acceptées : l'utilisateur doit ouvrir l'app pour un accusé rapide ;
  l'expiration à 1 h peut consommer un peu plus d'énergie sur écran MIP
  (`notMeasured`).
- À surveiller : parité entre `recordOutcome()` de l'app et `markDone()` de la
  face ; affichage du temps restant dans un espace de 220×138 px.

## Preuves

- `source/BigDigitsView.mc:88` — `POP_MS = TIMING_POPUP_MS` (3 600 000 ms).
- `source/BigDigitsView.mc:217-228` — expiration dans `onPartialUpdate()`.
- `source/BigDigitsView.mc:265-300` — `markDone()` et `onButtonPress()`.
- `companion/source/BuzzApp.mc:551-570` — `PopupDelegate.onPress()` sans
  écriture de case.
- `shared/Timing.mc:99-103` — `timingHysteresis()`.
- `doc/Toybox/WatchUi/WatchFaceDelegate.html` — « touch and hold ».

## Révision

Si le pont de complications est prouvé, évaluer le passage à C ; ne jamais
réintroduire un appui court sur le cadran sans changement de matériel.
