# ADR-0013 — NSDR piloté par cinq signaux réels

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : pertinence du repos, honnêteté scientifique, 100 % local

## Contexte

Le livre donne une plage de durée (10–30 min, `chunk_982`) et refuse d'en faire
un substitut de sommeil (`chunk_366`), mais aucun score de décision. Le code
précédent choisissait la durée depuis la seule dette et le stress
(`companion/source/BuzzApp.mc:481`). Les données réelles disponibles sont :
durée de la dernière nuit, dette 7 nuits, écart-type du coucher sur 7 jours,
stress robuste (médiane + MAD) et Body Battery (`watch-data-2026-11-25.md`).
Un réveil programmé au milieu de la nuit est interprété comme un réveil pour
un match de football, avec sommeil différé ou besoin de repos — hypothèse du
porteur, pas mesure.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| **A. Durée fixe 20 min** | simple | ignore l'état réel ; contredit la demande | 0 | immédiate |
| **B. Dette seule** | déjà implémenté | ignore stress, Battery et régularité ; faux positifs après une bonne nuit stressée | 1 | immédiate |
| **C. Score pondéré à cinq signaux** | conforme au livre par la plage 10–30 ; tient compte de la nuit, de la semaine et de la régularité | deux cibles à maintenir ; constantes à calibrer | 3 | élevée |

## Décision

Retenir **C**. `timingNsdrScore()` combine, sur une échelle 0–5 :

- dette 7 nuits : poids 0,30 (plafond 420 min) ;
- nuit courte (< 420 min) : poids 0,20 ;
- régularité du coucher (`timingCircularSD`) : poids 0,15 (plafond 60 min) ;
- stress robuste `z` : poids 0,20 (plafond 3) ;
- Body Battery : poids 0,15 (référence basse 22 observée).

Décision : **score ≥ 3 → 30 min**, ≥ 2 → 20 min, ≥ 1 → 10 min, < 1 → aucun
NSDR. Le créneau dépend de la cause dominante : stress/Battery basse ⇒
immédiat, dette ⇒ lever + 30 min, réveil de nuit ⇒ 14 h 00, coucher
irrégulier ⇒ une heure avant le coucher calculé. **A et B sont rejetés** car
ils ne répondent pas à la demande. La durée reste dans la plage du livre et le
message dit « repos », jamais « rattrapage de sommeil ».

## Conséquences

- Positives : décision traçable par cinq signaux mesurés ; 8 tests dédiés ;
  message de contexte affiché (cause + durée).
- Négatives acceptées : poids choisis par design, pas par régression
  statistique ; `bedtimeSD()` exige au moins deux couchers enregistrés, sinon 0
  (`notMeasured`) ; la face ne lit pas les événements de l'app et utilise un
  proxy stress/nuit courte.
- À surveiller : calibration des poids sur ≥ 14 nuits ; dérive entre le score
  compagnon et le proxy face.

## Preuves

- `shared/Timing.mc:171-215` — `timingCircularSD`, `timingNsdrScore`,
  `timingNsdrDurationFromScore`, `timingNsdrCause`, `timingNsdrTime`.
- `companion/source/BuzzApp.mc` — `bedtimeSD()`, `nightAlarm()`, `buildContext()`.
- `docs/architecture/watch-data-2026-11-25.md` — dodo 23 h 24, BB bas 22.
- `source/TimingTests.mc` — `timingScoreLow`, `timingScoreHigh`,
  `timingNsdrTable`, `timingNsdrCauseMatch` ; 30 tests verts au total.

## Révision

Si une régression locale sur 14 nuits montre qu'un poids est trompeur, le
modifier ici et dans `shared/Timing.mc` en même temps ; ne jamais dépasser
30 min ni présenter le NSDR comme un substitut de sommeil.
