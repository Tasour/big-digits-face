# ADR-0006 — Remplacer le planning background illégal

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : conformité SDK, fiabilité haptique

## Contexte

wait<1 -> 1 minute puis Duration(wait*60) (BuzzApp.mc:184-190) ; auto-test Duration(10) (:489) ; SDK interdit <5 min (Background.html:1707).

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A ; supprimer l'auto-test background. B/C rejetés.

## Conséquences

- Positives : conformité ; créneau exact
- Négatives acceptées : test 10 s supprimé du background
- À surveiller : chevauchement minuit

## Preuves

- `companion/source/BuzzApp.mc:184-190,489`
- `doc/Toybox/Background.html:1707`

## Révision

Si un créneau tombe à moins de 5 min d'un event précédent.
