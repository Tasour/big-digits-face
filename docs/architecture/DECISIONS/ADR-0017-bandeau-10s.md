# ADR-0017 — Durée du bandeau réduite à 10 secondes

- Statut : accepté
- Date : 2026-11-26
- Remplace : durée de l'ADR-0016 (30 s)
- Drivers : bandeau trop long sur le cadran, absence d'accusé par bouton

## Contexte

L'ADR-0016 fixait 30 s. L'utilisateur a confirmé que les boutons physiques ne
peuvent pas être reçus par une watch face (`WatchFaceDelegate` n'expose que
`onPress`, `onTap` et la configuration). L'accusé par bouton est donc
`notMeasured` et le bandeau ne peut disparaître qu'à l'expiration.

## Décision

- `TIMING_POPUP_MS = 10000` dans le moteur partagé et sa copie compagnon.
- Le popup du compagnon passe aussi à 10 s.
- Le bandeau reste centré et surimposé sur le cadran, sans carrés de semaine.
- La vibration reste dans l'app compagnon : la watch face ne peut pas vibrer.

## Conséquences

- Positive : attente maximale réduite à 10 s sans interaction impossible.
- Négative : la fenêtre de lecture est courte ; le message doit rester court.
- À surveiller : le compteur `notif.count` pour savoir si les rappels réels
  sont bien déclenchés.

## Preuves

- `shared/Timing.mc` et `companion/source/Timing.mc` : constante à 10 000.
- Tests de durée et de zone mis à jour.
- Capture du bandeau centré archivée dans `docs/screens/`.
