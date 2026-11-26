# ADR-0016 — Bandeau de rappel : 30 s, accusé par bouton, sans carrés

- Statut : accepté
- Date : 2026-11-26
- Décideurs : propriétaire du projet
- Drivers : lisibilité du message, accusé rapide, cohérence vibration/affichage

## Contexte

Le bandeau des rappels affichait sept carrés d'habitude et restait 25 s. Sur
la FR955, l'utilisateur ne voyait pas le bandeau aux créneaux réels et
souhaitait : un message plus long, une vibration, un accusé par n'importe quel
bouton et toute la place disponible pour le texte.

## Options écartées

- Bandeau persistant jusqu'à accretion : change trop le comportement et
  réclamerait une file d'attente de rappels.
- Vibration depuis la watch face : `Toybox.Attention` est interdit dans une
  watch face.
- Accusé tactile : la FR955 n'a pas d'écran tactile ; `onTap` reste utilisable
  pour les autres devices mais est `notMeasured` ici.

## Décision

- Durée d'affichage : **30 secondes** (`TIMING_POPUP_MS = 30000`).
- N'importe quel bouton masque immédiatement le bandeau.
- **START/ENTER uniquement** appelle `markDone()` et coche l'habitude.
- `onTap` a le même effet sur un device tactile ; non mesurable sur FR955.
- La vibration est émise par l'app compagnon (`doBuzz()`), pas par la face.
- Les sept carrés et les lettres LMMJVSD ne sont plus dessinés.
- Le rectangle est calculé à partir de `dc.getWidth()` / `dc.getHeight()`,
  centré avec une marge de 10 %, et le texte occupe toute la surface :
  titre en haut, message multiligne au centre, contexte en bas.
- L'historique d'habitude reste stocké mais n'est plus affiché sur le cadran.

## Conséquences

- Positives : message plus lisible, accusé immédiat, pas de carrés parasites.
- Négatives acceptées : l'historique d'habitude n'est plus visible sur le
  cadran ; la vibration dépend du compagnon.
- À surveiller : le nombre de rappels réellement affichés (`notif.count`).

## Preuves

- `shared/Timing.mc` — `TIMING_POPUP_MS = 30000`.
- `source/BigDigitsView.mc` — `drawPopup()` sans carrés, boutons d'accusé,
  dessin en mise à jour partielle.
- Suite de tests et captures à jour dans `docs/screens/`.

## Révision

Toute nouvelle durée ou tout retour des carrés exige un nouvel ADR.
