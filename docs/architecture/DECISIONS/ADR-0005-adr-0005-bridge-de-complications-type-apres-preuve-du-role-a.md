# ADR-0005 — Bridge de complications typé après preuve du rôle abonné

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : contrôle depuis la montre, intégrité des habitudes

## Contexte

Aucun canal app->face (README.md:168-170) ; benchmark:122,151 ; SDK <=4 publications, ids 0-255, value String/Number, ComplicationNotFoundException.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A en P1, conditionné au spike. B/C rejetés.

## Conséquences

- Positives : état partagé ; repli local
- Négatives acceptées : rôle face non prouvé
- À surveiller : parité face/app non testée

## Preuves

- `docs/veille/2026-11-25-controle-total-garmin-open-source.md:122,151,246-247`
- `doc/Toybox/Complications.html`

## Révision

Si le spike échoue sous CIQ 9.3.0.
