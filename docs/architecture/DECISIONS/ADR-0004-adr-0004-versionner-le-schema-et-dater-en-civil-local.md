# ADR-0004 — Versionner le schéma et dater en civil local

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : intégrité des habitudes, lisibilité MIP

## Contexte

dayIndex() = epoch/86400 (BigDigitsView.mc:218-220) alors que l'étiquette jour est locale (:494) ; habit.app.day écrit sans lecture (BuzzApp.mc:465) ; aucun schemaVersion.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A. B/C rejetés. Plainte UI étiquette = partiel : Moment.html:123,131 donne 1=dimanche, fixture requise.

## Conséquences

- Positives : source de vérité unique ; migration testable
- Négatives acceptées : migration des clés
- À surveiller : changement d'heure

## Preuves

- `source/BigDigitsView.mc:218-220,491-500`
- `companion/source/BuzzApp.mc:317-327,465`
- `doc/Toybox/Time/Moment.html:123,131`

## Révision

Au premier test de fixture weekday.
