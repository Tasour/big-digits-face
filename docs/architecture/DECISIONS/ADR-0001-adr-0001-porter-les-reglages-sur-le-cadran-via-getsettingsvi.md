# ADR-0001 — Porter les réglages sur le cadran via getSettingsView + Menu2

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : contrôle depuis la montre, 100% local

## Contexte

Contrôle total depuis la montre ; aucun réglage aujourd'hui (source/BigDigitsView.mc:256-264) ; AppBase.html:1647 limite getSettingsView aux faces/data fields ; une face ne peut pas pushView.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A en P0 ; l'app garde son Menu2 interne. B rejeté (contraire au driver P0).

## Conséquences

- Positives : accès direct ; zéro téléphone
- Négatives acceptées : deux menus à maintenir ; ouverture non programmatique
- À surveiller : 7 items max par écran ; clés append-only

## Preuves

- `doc/Toybox/Application/AppBase.html:1647`
- `README.md:88-89,168-170`

## Révision

Si le SDK offre un lancement programmatique de Customize depuis une face.
