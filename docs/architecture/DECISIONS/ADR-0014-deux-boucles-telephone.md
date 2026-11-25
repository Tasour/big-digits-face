# ADR-0014 — Deux boucles : la montre décide, le téléphone corrige

- Statut : accepté
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : autonomie de la montre, honnêteté des données, budget de transfert, zéro cloud
- Contrat : `docs/architecture/PHONE-CONTRACT.md`

## Contexte

Le rappel Protocoles doit sortir à l'heure même si le téléphone est loin, éteint
ou sans réseau. Or la montre ne voit pas tout : le score de sommeil Garmin, le
besoin de sommeil `sleepNeed`, une dette consolidée et une baseline HRV ne sont
accessibles que côté téléphone, avec du retard. La version précédente du lien
téléphone envoyait une trame par créneau (huit par jour) et recevait des seuils
complets : plus de BLE que nécessaire, et un risque qu'un verdict périmé pilote
un rappel.

## Options envisagées

| Option | Avantages | Inconvénients | Coût |
|---|---|---|---|
| **A. Téléphone maître** — la montre attend le verdict du téléphone | un seul endroit décide | aucun rappel si le téléphone est absent ; latence ; dépendance à une app à écrire | 4 |
| **B. Montre seule** — aucun lien | simple, autonome | n'accède jamais au score de sommeil ni au besoin réel ; ignore la dette consolidée | 1 |
| **C. Deux boucles** — la montre décide, le téléphone corrige une fois par jour | rappel garanti hors ligne ; corrections lentes mais bornées ; 62 octets | deux sources à tenir cohérentes ; app téléphone encore à écrire | 3 |

## Décision

Retenir **C**.

- **Boucle rapide (montre, toujours active)** : événements sommeil, pas, stress,
  Body Battery, réveil programmé, lever et coucher du soleil. C'est elle, et
  elle seule, qui déclenche une notification. Aucun appel BLE sur ce chemin.
- **Boucle lente (téléphone, une fois par jour)** : à la première ouverture au premier plan, la montre envoie
  un instantané de 62 octets ; le téléphone renvoie au plus 40 octets de
  corrections (`needMin`, `debt7`, `bedSD`, `verdict`, `nsdrMin`, `exp`).
- **Fraîcheur** : une correction n'est appliquée que si `exp > maintenant` ;
  sinon le calcul local reprend, sans message d'erreur.
- **Transport** : `Communications.transmit` (BLE) vers l'app téléphone, et
  `registerForPhoneAppMessages` pour la réponse. Aucune URL, aucun cloud.
- **Une requête en vol** : une seule trame à la fois, profondeur de file 1. En
  cas d'échec, nouvelle tentative à la prochaine ouverture, trois fois par jour
  au plus — une minuterie de fond sous 5 minutes est interdite par le SDK.
- **La face reste autonome** : elle ne reçoit rien du téléphone. Le pont de
  complications reste hors du chemin critique.

**A et B sont rejetés** : A casse le rappel quand le téléphone manque, B prive
la décision des seules grandeurs que la montre ne peut pas mesurer.

## Conséquences

- Positives : rappel garanti hors ligne ; 62 + 40 octets au lieu de ~800 ;
  1 envoi par jour au lieu de 8 ; format testable sans téléphone (19 tests) ;
  un verdict périmé ne peut pas piloter un rappel.
- Négatives acceptées : deux sources de vérité, arbitrées par l'expiration ;
  les poids du score restent locaux, seules les entrées sont corrigées ; l'app
  téléphone n'existe pas encore, donc la moitié descendante est `notMeasured`.
- À surveiller : dérive entre `debt7` local et consolidé, et le nombre de
  rejets CRC en usage réel (compteur `diag.ble.reject`).

## Preuves

- `shared/Timing.mc` — `timingCrc16`, `timingSnapshotBytes`,
  `timingSnapshotDecode`, `timingCorrectionsBytes`, `timingParseCorrections`.
- `source/PhoneContractTests.mc` — 19 tests : taille 62, CRC, aller-retour,
  absence `-1`, zéro distinct de l'absence, 9 rejets de corrections.
- `companion/source/BuzzApp.mc` — `sendSnapshot`, `PhoneListener`,
  `handlePhoneMessage`, `loadCorrections`, `correctionSource`.
- `scripts/check-timing-parity.sh` — parité face/compagnon du moteur.
- Suite complète : 50 tests, `failed=0, errors=0`.

## Révision

Si une app téléphone est livrée, la seule modification autorisée sans nouvelle
version est l'ajout de champs dans `reserved`. Toute autre évolution passe à
`schemaVersion = 2`, avec les deux versions acceptées pendant une transition.
