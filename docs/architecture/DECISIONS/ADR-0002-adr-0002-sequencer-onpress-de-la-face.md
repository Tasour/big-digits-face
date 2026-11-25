# ADR-0002 — Séquencer onPress de la face

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : contrôle depuis la montre, conformité SDK

## Contexte

WatchFaceDelegate.onPress est un appui maintenu (README.md:203-206) ; un seul handler sert accuse et test (BigDigitsView.mc:256-264) ; conflit avec Complications.exitTo.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A. B et C rejetés pour faisabilité SDK.

## Conséquences

- Positives : interaction déterministe ; compatible complication
- Négatives acceptées : geste système à connaître
- À surveiller : collision popup + complication

## Preuves

- `source/BigDigitsView.mc:256-264`
- `source/BigDigitsDelegate.mc:11-13`

## Révision

Dès qu'une complication est observée avec un popup sur le device.
