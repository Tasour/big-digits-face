# ADR-0003 — Rendre la persistance d'habitude non destructive

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : intégrité des habitudes

## Contexte

habitBits() remet bits à 0 si last < today - 1 (BigDigitsView.mc:222-234) ; un jour manqué efface 7 jours.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A en deux temps. B et C rejetés.

## Conséquences

- Positives : historique conservé ; UI historique préparée
- Négatives acceptées : lecture double transitoire
- À surveiller : log < 8 Ko/clé

## Preuves

- `source/BigDigitsView.mc:222-234,239-247`

## Révision

Si le log dépasse 8 Ko ou si un test 7 j avec trou échoue.
