# Données réelles de la montre — relevé du 2026-11-25

Source : cache local du service **Mon suivi running V2** (`http://127.0.0.1:47822`,
connecté au compte Garmin `e95a9033…`, 339 activités). Fichier :
`/home/tasour/.local/share/mon-suivi-running-v2/v2.db`, table `garmin_raw`
(payloads JSON non chiffrés). Aucune donnée n'est inventée ci-dessous.

## Sommeil — 7 dernières nuits (clé `graphql.sleepSummariesScalar`)

| Date | Dodo | Lever | Durée | Profond | REM | Stress nuit | Qualification globale |
|---|---|---|---:|---:|---:|---:|---|
| 2026-11-18 | 23:24 | 07:04 | 7 h 28 | 1 h 09 | 1 h 19 | 8 | GOOD |
| 2026-11-19 | 23:14 | 06:55 | 7 h 30 | 0 h 46 | 2 h 06 | 16 | GOOD |
| 2026-11-20 | 23:05 | 07:30 | 8 h 11 | 2 h 04 | 1 h 21 | 23 | GOOD |
| 2026-11-21 | 00:39 | 07:32 | 6 h 44 | 1 h 11 | 1 h 20 | 8 | GOOD |
| 2026-11-22 | 23:50 | 06:50 | 7 h 00 | 1 h 01 | 1 h 15 | 9 | GOOD |
| 2026-11-23 | 23:53 | 04:30 | 4 h 19 | 1 h 11 | 0 h 26 | 29 | POOR |
| 2026-11-24 | 21:46 | 04:31 | 6 h 44 | 1 h 29 | 1 h 04 | 8 | GOOD |

- **Heure moyenne de dodo (moyenne circulaire) : 23 h 24.**
- Durée moyenne : **6 h 52**. Une nuit POOR (4 h 19) sur sept.
- La nuit du 2026-11-24 porte `bodyBatteryChange = 80`, `restingHeartRate = 52`,
  `avgOvernightHrv = 77` (`BALANCED`), `avgSleepStress = 8`.
- `sleepScores.overall.qualifierKey` est la source de qualité réelle : `GOOD`×6,
  `POOR`×1. Le cadran Forerunner 955 n'expose pas ce champ via l'API Connect IQ.

## Body Battery — 7 derniers jours (clé `get_body_battery`)

| Date | Bas | Haut |
|---|---:|---:|
| 2026-11-18 | 29 | 100 |
| 2026-11-19 | 13 | 100 |
| 2026-11-20 | 19 | 75 |
| 2026-11-21 | 27 | 98 |
| 2026-11-22 | 11 | 100 |
| 2026-11-23 | 11 | 50 |
| 2026-11-24 | 43 | 92 |

Bas moyen : **22,0** ; minimum observé **11** ; deux jours sous 15 les 22/23.

## Conséquence pour les algorithmes

- Les messages « Stimulants » et « Écrans » doivent utiliser **23 h 24** comme
  référence, pas l'heure configurée dans `UserProfile` : déclenches à
  **15 h 24** (dodo − 8 h) et **22 h 24** (dodo − 60 min).
- La nuit POOR du 23 justifie un NSDR 30 min le 24 ; le score global réel est
  disponible dans le cache Garmin mais **pas dans l'app Connect IQ**. Le pont
  possible est le téléphone via `Communications`, ou une déduction locale par
  durée < 6 h + stress de sommeil > 20 (ici : 4 h 19 / 29).
- Le Body Battery bas moyen (22) confirme qu'un seuil fixe à 30 est pertinent,
  mais la valeur doit être lue dans `SensorHistory`, pas supposée.

## Limites

- Cache récolté le 2026-11-24 ; pas de lecture directe depuis la montre pendant
  cette session (les données proviennent de Garmin Connect via le service local).
- `sleepStartTimestampLocal` est interprété en UTC machine : les heures sont
  cohérentes entre elles mais le fuseau affiché peut différer du réglage watch.
- Aucun appel réseau externe n'a été fait pour produire ce relevé.
