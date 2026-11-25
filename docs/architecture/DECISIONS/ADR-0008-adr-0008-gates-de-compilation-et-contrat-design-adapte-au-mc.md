# ADR-0008 — Gates de compilation et contrat design adapté au .mc

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : qualité, traçabilité

## Contexte

0 test unitaire ; 85 erreurs -l 3 rapportées (non rejouées) ; checkStorage in-band (BuzzApp.mc:256-262) ; gate HTML inapplicable au .mc.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A. B/C rejetés. Contraste et débordement à recalculer avant P0 avéré.

## Conséquences

- Positives : vérifiabilité ; non-régression
- Négatives acceptées : blocage temporaire releases
- À surveiller : captures non reproductibles

## Preuves

- `companion/source/BuzzApp.mc:256-262`
- `build.sh:28`
- `monkey.jungle:1-7`
- `source/BigDigitsView.mc:62-65,69-75`

## Révision

Si -l 3 retombe à 0 erreur et 20 tests passent.
