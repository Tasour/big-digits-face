# Comparatif avancé — critères de protocoles et architectures de données

Date : 2026-11-25. Cible : `/home/tasour/Work/big-digits-face` (cadran Connect IQ
Monkey C + app compagnon, Forerunner 955 Solar). **Lecture seule** : aucun code
applicatif n'a été modifié ; seuls `docs/veille/` et `docs/architecture/` sont
écrits. Skills appliqués : `benchmark-concurrentiel` (mode complet),
`audit-resilient` (3 tentatives max, repli local, rien d'inventé),
`architecture-forge` (mesures bornées, ≥ 2 options par décision, zero-réseau).

## 1. Fiche cible et critères de scoring

Besoin : produire des messages de protocole (**Sommeil, NSDR, Pas, Stimulants,
Écrans, Calme, Lumière**) dont le déclenchement est justifié par des critères
fiables, avec le moins de cloud possible et le plus de contrôle depuis la
montre. Contrainte matérielle : face 131 072 B, watch-app 786 432 B,
background 65 536 B ; storage propre à chaque app ID ; score de sommeil natif
absent sur `fr955` (`DATA-SOURCES.md`).

Cinq critères notés 1–5, pondérés : **S** similarité au besoin (30 %),
**F** fiabilité des critères /statistics (25 %), **T** compatibilité 100 % local
et contrainte montre (20 %), **M** maturité et testabilité (15 %),
**D** différenciation technique (10 %). Chaque note est adossée à une preuve
`fichier:ligne` collectée le 2026-11-25 ; une preuve absente donne `partiel`,
jamais une note inventée.

## 2. Candidats et scoring

12 candidats découverts via 3 requêtes web FR/EN + API GitHub, tous consultés
le 2026-11-25. Shortlist : 12 (9 à analyse approfondie par 4 agents en parallèle,
maximum 4 simultanés). Verdicts licence : 🟢 copie open source attribuée,
🟡 copyleft = validation humaine obligatoire, 🔴 licence absente/incertaine =
inspiration seule et réimplémentation originale.

| Candidat | Licence | S | F | T | M | D | Total | Verdict d'usage |
|---|---|---:|---:|---:|---:|---:|---:|---|
| `fiddur/aurboda` | AGPL-3.0 🟡 | 4 | 5 | 4 | 5 | 5 | **4,50** | Idées seulement, validation humaine |
| `DocStream-Oficial/vitals` | MIT 🟢 | 4 | 4 | 5 | 4 | 4 | **4,20** | Réutilisable avec attribution |
| `Zsadigzade/trainbud` | MIT 🟢 | 5 | 5 | 3 | 2 | 5 | **4,15** | Réutilisable avec attribution |
| `NomaDamas/healthmes-agent` | AGPL-3.0 🟡 | 5 | 4 | 4 | 3 | 4 | **4,15** | Idées seulement, validation humaine |
| `afkcodes/healthee` | absente 🔴 | 4 | 5 | 4 | 3 | 5 | **4,20** | Inspiration seule |
| `wintermute422/garminizer` | MIT 🟢 | 4 | 4 | 3 | 2 | 4 | **3,50** | Formules attribuées |
| `ferhat00/garmin_sleep_analysis` | MIT 🟢 | 3 | 3 | 4 | 1 | 3 | **2,90** | Seuils attribués |
| `earlyaidopters/health-os` | absente 🔴 | 4 | 2 | 2 | 3 | 3 | **2,85** | Format de restitution seulement |
| `KareemmSayed/Threshold` | MIT 🟢 | 2 | 4 | 1 | 4 | 4 | **2,80** | Idées hors cloud |
| `tintin305/GarminSleepAnalytics` | absente 🔴 | 3 | 2 | 4 | 2 | 3 | **2,80** | Inspiration seule |
| `thebyteio/openclaw-skill-garmin-connect` | absente 🔴 | 3 | 2 | 3 | 1 | 3 | **2,45** | Inspiration seule |
| `alecvdp/health-dashboard` | absente 🔴 | 2 | 1 | 5 | 1 | 1 | **2,10** | Réimplémentation originale |

Méthode de calcul : moyenne pondérée des cinq notes ; `partiel` exclu du total,
jamais remplacé par une estimation.

### Ce que le benchmark précédent apporte déjà

`docs/veille/2026-11-25-controle-total-garmin-open-source.md` couvrait 9 projets
de *contrôle sur la montre* (menus, complications, vibration, MTP). Ce rapport
le complète sur l'axe **fiabilité des critères et traitement de la donnée**, sans
le dupliquer. Le fait SDK vérifié reste : `AppBase.getSettingsView()` n'est
applicable qu'aux watch faces et data fields (`doc/Toybox/Application/AppBase.html:1647`,
SDK 9.3.0).

## 3. Synthèses des quatre angles d'analyse

### 3.1 Ponts Garmin et accès local (trainbud, Threshold, openclaw)

- **trainbud 🟢** (MIT, 0★, push 2026-11-16) : trois SQLite séparés —
  `app.db`/`cache.db`/`history.db` (`src/appDb.ts:9,36-52`, `src/garmin/cache.ts:34-53`,
  `src/history/store.ts:17-20,55`). Pont montre : `GET /api/watch` en HTTPS via
  **tunnel cloudflared**, Bearer token par appareil révocable
  (`ciq/README.md:5,14-16,124-126`, `ciq/source/TrainBudApp.mc:644-653`,
  `src/pairApi.ts:18-51`). Glance allégée avec `lite=1` sous 100 Ko
  (`ciq/README.md:158`, `GlanceData.mc:5-22`). **Cache TTL dégradé 60 s** contre
  les retry-storms (`src/garmin/cache.ts:27-30,174-193`) ; **backoff d'auth
  persistant 60 s → 30 min** (`src/garmin/client.ts:26-36,72-81`) ;
  **single-flight** (`client.ts:9-10,126`) ; détecteurs baseline 28 j + robust-Z
  + plancher MAD, fenêtre récente exclue (`src/detect/detectors.ts:15,41-68,84-107,180-223`).
  Limite : tunnel public ⇒ **pas 100 % local**.
- **Threshold 🟢** (MIT, 10★/12 forks, push 2026-11-15) : Cloudflare Worker,
  D1 + KV, cron `*/10` (`wrangler.jsonc:4-13`). **Aucune app Connect IQ**.
  Technique reine : **Personal API key échangée contre bearer 24 h**, clé jamais
  stockée, refresh sous 1 h, single-flight (`src/garmin/client.ts:4-5,13,97,119-175`) ;
  budget de sous-requêtes (`client.ts:49-57`) ; `fetchRange` découpe les plages
  et divise par 2 sur échec (`src/garmin/endpoints.ts:196-221`). Limite : cloud.
- **openclaw 🔴** (licence absente, 3★) : session garth dans `/tmp`, cache JSON
  journalier (`scripts/cache-daily.sh:5-23`), **seuils statiques**
  `body_battery_low:40`, `min_sleep_hours:6.5` (`SKILL.md:172-188`) et **nudge
  conditionné à la récupération** (`SKILL.md:94-103,136-146`). Deux scripts
  documentés absents de l'arborescence ⇒ `partiel`. Aucun code repris.

### 3.2 Agrégation multi-sources et corrélation (vitals, aurboda, health-dashboard)

- **vitals 🟢** (MIT, 5★, 85 commits, 1 661 tests annoncés) : fusion **sémantique
  par métrique** (`app/merge.py:1-70`) — moyenne pour grandeurs redondantes,
  **HRV canonique jamais moyennée** (RMSSD ≠ SDNN, `:21-31,87`), `max` pour
  cumulatifs (`:32-35,91`), nuit gagnante = plus grand `asleep` (`:36-43`),
  séances fusionnées champ par champ (`:44-60,507-550`). Moteur « Behavior
  Impact » : Spearman lag 1 pour recovery/HRV, lag 0 pour `sleep_perf`, portes
  ≥ 5 jours oui / ≥ 5 non / ≥ 15 paires, BH FDR α = 0,05
  (`app/journal.py:133,484`, `app/drivers.py:30-31,156,282-288`). Limite
  honnête : `_pvalue()` ne modélise pas l'autocorrélation (`drivers.py:130-134`).
  Timezone `notMeasured` (aucun `zoneinfo` dans `merge.py`).
- **aurboda 🟡** (AGPL-3.0, 38★, 4 013 commits, 2026-11-25) : idées seulement.
  `raw_records` dédup par ID externe, `time_series` clé `(time,metric,source)`,
  empreinte **de schéma** SHA-256 (`docs/data-storage.md`). Corrélations :
  **deltas vs baseline rolling 7/30 j**, bins 5 min, onset-collapsing, risque
  relatif + IC 95 %, BH (`apps/backend/src/services/correlations/impact.ts:8-12,121-125`,
  `apps/backend/src/db/time-weighted.ts:1-32`). Limite : pas de correction
  circadienne, p-values optimistes.
- **health-dashboard 🔴** (archivé, licence absente) : CSV date-key last-wins
  (`app.py:141-142,150`), scatter OLS avec `MIN_POINTS = 5`
  (`app.py:584,588-600`), aucun test de significativité, aucun lag, aucune
  baseline. Seul le principe d'upsert par date est transférable, à réimplémenter.

### 3.3 Entrepôts de sommeil Garmin (garminizer, GarminSleepAnalytics, garmin_sleep_analysis)

- **garminizer 🟢** (MIT, 0★, 75 commits, push 2026-11-23) : `dailySleepDTO`
  parsé verbatim (`backend/garminizer/sync/parsers/daily.py:125-171`) ;
  `sleepScores.overall.qualifierKey` conservé **tel quel**, non recalculé
  (`docs/metrics.md` §1). Régularité = écart-type de `bedtime_min`/`waketime_min`
  en minutes depuis midi local de la veille (`api/routers/sleep.py:3-5,26-30,146-148,193-194`).
  Dette 7 nuits = Σ `max(0, need − asleep)` (`:173-175,195`). Garde-fou :
  absence = `null`, jamais `0`. Incohérence documentée : backend utilise
  `duration_s`, front `asleep()` = deep+light+REM (`web/src/pages/sleep/options.ts:57-60`).
- **GarminSleepAnalytics 🔴** (licence absente, 8★, 2020) : export RGPD ZIP,
  filtre `UNCONFIRMED` (`ExtractData/ExtractGarminData.py:45-47`), correction
  de fuseau **codée en dur +2 h** (`AnalyseData.py:35-36`) ⇒ biais DST. Aucun
  score, aucune dette, aucune régularité. Aucun code repris.
- **garmin_sleep_analysis 🟢** (MIT, 1★) : 1 353 nuits sur 5 ans, conformité
  7–9 h, efficacité seuils 85/90 %, moyenne mobile 30 j centrée
  (`v3/Sleep_Analysis_Complete_EDA.ipynb:592-596,694-701,734`). Définition
  `totalSleepHours = deep+light` **REM exclu** (`:592`), en contradiction avec
  le README qui explique un deep ≈ 53 % par un regroupement deep+REM ⇒ ne pas
  reprendre cette formule telle quelle.

### 3.4 Moteurs de décision santé (healthee, healthmes-agent, health-os)

Le premier lancement de cet angle est revenu **sans texte** ; il a été relancé
une fois (tentative 2/3) et a retourné un rapport complet. Aucune analyse n'a
été inventée pour combler le premier échec.

- **healthee 🔴** (licence absente, 12★, push 2026-10-04) : référence
  statistique — baseline **médiane + MAD sur 30 j**, `z = (v − médiane) /
  (MAD × 1,4826)`, anomalie si `|z| ≥ 2` sur 14 j, baseline excluant le jour
  testé, gate ≥ 10 nuits, sentinelles par métrique (RHR = 0 ⇒ non mesuré)
  (`apps/server/src/healthee/analytics/baselines.py:56-60,68,114-124,157,165-172`,
  `analytics/anomalies.py:30,98-100`, `derive/robust.py:38`, `derive/illness.py:112`).
  Multi-signaux : RR ≥ +2 bpm **et** temp ≥ +0,5 °C, gate par membre
  (`derive/illness.py:118-142`). Limite : +0,5 °C est une heuristique non
  sourcée, fenêtres 14/42/30 j non fondées (`:48-55,125-133`). Aucun code repris.
- **healthmes-agent 🟡** (AGPL-3.0 + licence commerciale séparée, 14★,
  72 issues, push 2026-11-18) : **double seuil absolu ET relatif** — stress
  ≥ 70/100 **et** ≥ 1,3× la médiane de base ; base = médiane des moyennes
  quotidiennes sur 14 j, ≥ 3 j, fraîcheur ≤ 3 h
  (`healthmes/engine/rules.py:166-169,218-235`, `triggers.py:113-114,146-151`).
  Gating croisé recovery ≤ 40 **et** ≥ 180 min chargées 12 h–18 h ; signaux
  absents ⇒ `return None` ; `dedup_key` par jour local (`rules.py:171-175,260-275,279`).
  Apport : payload `evidence` minimal `{valeur, médiane, jours, ratio, source}`
  et idempotence quotidienne. Réécriture originale obligatoire (🟡).
- **health-os 🔴** (licence absente, 23★/17 forks, push 2026-06-27) : bandes
  absolues WHOOP — vert ≥ 67 %, jaune ≥ 34 %, rouge < 34 %, tendance 7 j si
  écart ≥ 5 pts et ≥ 3 nuits (`agent/scripts/state.py:179,256-264`). Gating :
  recovery/HRV/RHR/sommeil au **même timestamp**, sinon « no night synced yet »
  (`state.py:157-190`). Dépend Supabase + OpenAI + Gemini ⇒ pas 100 % local
  (`README.md:107,282`). Seul le format de restitution en une ligne est
  transférable (`README.md:29`).

## 4. Le livre comme référentiel de critères

Résumé de `docs/architecture/protocol-criteria-from-book.md` (passages relus
intégralement dans le corpus Synthetix local, 1 584 chunks) :

| Catégorie | Seuil du livre | Chunk | Écart actuel |
|---|---|---|---|
| Sommeil | 7–9 h ; placement régulier sur 24 h | `chunk_361`, `chunk_250`, `chunk_252` | `sleepTime < 420 min` conforme (`BuzzApp.mc:195-200`) |
| Lumière matinale | 5–10 min dans les 30–60 min après le lever | `chunk_101` | slot fixe 07:00 (`BuzzApp.mc:306`) |
| Caféine | 8–10 h avant le coucher, 12 h si sensible | `chunk_399`, `chunk_414` | `bed − 480` = 8 h, borne tardive (`BuzzApp.mc:308`) |
| Écrans | lumière vive à éviter de `lever − 8 h` à `lever − 2 h` | `chunk_209`, `chunk_211` | `bed − 60` = 22 h 24, **2 h trop tard** (`BuzzApp.mc:316`) |
| NSDR | 10–30 min, 1×/jour ; jamais substitut de sommeil | `chunk_982`, `chunk_366` | 30/20/10/10 dans la plage, libellé à corriger |
| Calme | 1–3 soupirs immédiats ; 5 min cycliques en prévention | `chunk_904`, `chunk_914` | slot 22:30 conditionné au stress (`BuzzApp.mc:312`) |
| Pas | 7 000 objectif basal, 10 000 optimal | `chunk_574`, `chunk_576`, `chunk_578` | objectif pondéré par fenêtre, heuristique locale (`BuzzApp.mc:214-229`) |
| Température chambre | 18–20 °C, max 21 °C | `chunk_298` | `notMeasured` (aucun capteur ambiant) |

Le livre **ne fournit aucun seuil** de score de sommeil, de Body Battery ni de
stress chiffré : toute valeur de ce type est une heuristique locale ou une
métrique constructeur, et doit être étiquetée comme telle.

## 5. Matrice des gaps par catégorie de message

| Catégorie | Critère fiable disponible | Ce qui manque | Technique candidate (source) |
|---|---|---|---|
| Sommeil | durée déduite des événements ; 3/7 nuits < 7 h | score global sur la face | verdict 3 états pré-calculé (garminizer) |
| NSDR | plage 10–30 min du livre ; nuit courte mesurée | ressenti, dette cumulée | dette 7 nuits + besoin réel (garminizer) |
| Pas | `SensorHistory.STEP_COUNT`, 7 000/10 000 | objectif pondéré non validé | objectif quotidien fixe du livre + delta (aurboda) |
| Stimulants | dodo moyen 23 h 24 mesuré | heure d'ingestion réelle | garder le rappel temporel, étiqueter `notMeasured` |
| Écrans | lever moyen 06 h 25 calculé | capteur de lumière absent | avancer à 20 h 25, garder 22 h 24 en rappel final |
| Calme | tendance stress 1 h, Body Battery | seuil de stress validé | double gate absolu + `z` médiane/MAD (healthmes-agent 🟡 + healthee 🔴, idées seules) |
| Lumière | heure de lever | capteur de lumière, météo fiable | rappel temporel + `Weather` quand disponible |

## 6. Techniques de déclenchement et de validation

- **Déclenchement** : le projet actuel utilise des créneaux (`slot` 700/1230/1500/
  1730/1830/2100/2200/2230, `BuzzApp.mc:306-313`) avec un seul `Moment`
  replanifié. Les projets comparés utilisent trois autres modèles : (a) **seuil
  sur événement** (trainbud, robust-Z), (b) **gating par récupération** (openclaw,
  dégradation d'une séance en Z2 si sommeil court), (c) **corrélation lagée**
  (vitals, aurboda) qui produit une *confiance* plutôt qu'un déclenchement.
  Le modèle (b) est le plus transférable : il ne demande qu'un booléen
  « récupéré / non récupéré » calculé hors montre.
- **Validation** : aucun des 12 projets ne prouve un déclenchement sur montre
  réelle ; ours a 7 tests unitaires (`scripts/run-watch-tests.sh`) et un gate
  `-l 3` vert sur trois cibles. C'est **notre avantage mesuré**, à conserver.
- **Pièges identifiés** : absence = `null`/`—`, jamais `0` (garminizer) ;
  garde de validité avant tout calcul (GarminSleepAnalytics, `partiel` licence) ;
  ne jamais moyenner HRV RMSSD et SDNN (vitals) ; ne pas corriger le fuseau en
  dur (GarminSleepAnalytics, +2 h codé en dur) ; déclarer explicitement que les
  corrélations sont associatives, non causales (vitals, aurboda).

## 7. Architectures d'accès aux données — comparatif

| Modèle | Projets | Point fort | Point faible pour nous |
|---|---|---|---|
| **A. Tout sur la montre** | notre état actuel | 100 % local, aucun transport | pas de score de sommeil, RAM limitée, pas de multi-sources |
| **B. Service externe local/cloud** | garminizer, Threshold, trainbud | données riches, SQL, statistiques | dépendance runtime ; trainbud = tunnel public, Threshold = Workers ⇒ hors « zéro cloud » |
| **C. Calcul hors montre + payload compact** | vitals, aurboda | règles complexes appliquées hors face ; cadran O(1) | nécessite un canal face↔app (spike non encore prouvé) |
| **D. Export fichier + analyse différée** | GarminSleepAnalytics, garmin_sleep_analysis | zéro réseau, reproductible | données non temps réel ; fuseau figé dans l'un |

**Recommandation d'architecture : C avec repli A**, documentée dans
`DECISIONS/ADR-0010-aggregation-hors-montre-payload-compact.md`. Le service
local `mon-suivi-running` est une **source à développement**, pas une
dépendance de la montre. Le payload compact : `verdict` (3 états), `need_min`,
`asleep_s`, `debt7_s`, `bedtime_sd_min`, `date_calcul`, `schemaVersion`.

## 8. Preuves et tests

Mesures déterministes relevées le 2026-11-25 (`tools.arch.*`) : 58 fichiers,
1 384 814 octets, `arch.verify` vert (8 ADR, 0 erreur, 0 avertissement),
`arch.budget` signale 4 fichiers de debug XML > 100 Ko (non embarqués).
`arch.scorecard` brut = 0/100, couverture 0 % : les outils JS/SQL **ne
comprennent pas le Monkey C** ; les dimensions sont `unknown`, pas des échecs.
Une dimension renseignée manuellement (`testabilite` = 4/5, 2 preuves) donne
80/100 avec couverture 10 %, confiance `low` : ce score n'est pas présenté
comme une mesure globale.

Gates du projet : `-l 3` à 0 erreur sur trois cibles, 7/7 tests unitaires,
`verify.sh` vert (G0–G4), `RELEASES.md` avec SHA-256. Aucun des projets comparés
n'expose de gate équivalent prouvé sur montre ⇒ `notMeasured` pour eux, pas
« absent ».

## 9. Idées priorisées (impact × (6 − effort))

| # | Idée (source) | Impact | Effort | Priorité |
|---|---|---:|---:|---:|
| 1 | Seuils du livre comme plancher documenté, jamais comme heuristique tacite (Protocols) | 5 | 1 | 25 |
| 2 | Verdict 3 états pré-calculé + `—` si donnée absente (garminizer 🟢) | 5 | 2 | 20 |
| 3 | Règles de fusion sémantique par métrique, HRV non moyennée (vitals 🟢) | 5 | 3 | 15 |
| 4 | Baseline robust-Z 28 j + plancher MAD, fenêtre récente exclue (trainbud 🟢) | 5 | 4 | 10 |
| 5 | Backoff d'auth persistant + single-flight, même sans cloud (trainbud 🟢) | 5 | 3 | 15 |
| 6 | Nudge conditionné à la récupération, pas à l'heure seule (openclaw 🔴, idée seule) | 5 | 2 | 20 |
| 7 | Délégation du calcul au compagnon, cadran lecteur O(1) (vitals/aurboda) | 5 | 3 | 15 |
| 8 | Dettes 7 nuits `Σ max(0, need − asleep)` (garminizer 🟢) | 4 | 2 | 16 |
| 9 | Écart-type du coucher comme mesure de régularité (garminizer 🟢) | 4 | 2 | 16 |
| 10 | Garde de validité avant calcul (GarminSleepAnalytics 🔴, réimplémenté) | 4 | 1 | 20 |
| 11 | Deltas vs baseline rolling 7/30 j + bins 5 min (aurboda 🟡, idée seule) | 4 | 3 | 12 |
| 12 | Cache TTL dégradé 60 s anti retry-storm (trainbud 🟢) | 4 | 2 | 16 |
| 13 | Token par appareil révocable pour le pont (trainbud 🟢) | 4 | 3 | 12 |
| 14 | `fetchRange` en fenêtres légales, division par 2 sur échec (Threshold 🟢) | 4 | 3 | 12 |
| 15 | Compaction du payload avant envoi (Threshold 🟢) | 3 | 2 | 12 |
| 16 | Upsert par date, dernière valeur gagnante (health-dashboard 🔴, réimplémenté) | 2 | 1 | 10 |
| 17 | Spearman lagé + BH avec portes dures (vitals 🟢) | 4 | 4 | 8 |
| 18 | Correction explicite « associatif, non causal » dans le libellé (vitals/aurboda) | 3 | 1 | 15 |
| 19 | Empreinte de schéma + `schemaVersion` dans le payload (aurboda 🟡, idée seule) | 3 | 2 | 12 |
| 20 | Badge de version visible dans le diagnostic (notre dette documentée) | 2 | 1 | 10 |
| 21 | `z` robuste médiane + MAD sur 30 j, gate ≥ 10 nuits (healthee 🔴, idée seule) | 5 | 3 | 15 |
| 22 | Double gate absolu + relatif et dédup journalier (healthmes-agent 🟡, idée seule) | 5 | 2 | 20 |
| 23 | Snapshot de session en une ligne lisible (health-os 🔴, format seul) | 2 | 1 | 10 |

## 10. Arbitrage et recommandation finale

**Meilleure architecture : C + repli A**, avec quatre couches :

1. **Référentiel de critères** (livre, `protocol-criteria-from-book.md`) —
   plancher non négociable, séparé du code.
2. **Source réelle** — événements sleep/wake + capteurs sur la montre, complétés
   par le cache Garmin local au moment du développement ; jamais de dépendance
   runtime à un service externe.
3. **Calcul hors face** — compagnon : fusion sémantique (vitals), verdict 3
   états et dette (garminizer), baseline robust-Z/MAD (trainbud + healthee,
   idée seule), double gate absolu/relatif et dédup journalier (healthmes-agent,
   idée seule) ; payload compact avec `schemaVersion` et absence explicite.
4. **Face lectrice** — 7 créneaux et popups inchangés dans leur forme, mais
   pilotés par le payload ; `repli A` si la complication est absente.

Arbitrage des conflits :
- **Livre vs baseline** : le livre gagne sur le plancher (ADR-0009) ; la baseline
  ne peut que *resserrer*, jamais abaisser sous 7 h.
- **Local vs richesse** : le local gagne ; Threshold et trainbud sont écartés
  comme dépendances runtime, conservés comme idées (token, cache, retry).
- **Copier vs s'inspirer** : rien n'est copié des dépôts 🔴 ; rien n'est copié
  tel quel des 🟡 sans validation humaine ; les extraits 🟢 sont cités avec
  leur chemin et leur licence.
- **Statistique vs simplicité** : les tests de significativité restent hors
  montre et sont présentés comme associatifs, pas causaux.

## 11. Limites et `notMeasured`

- L'angle « moteurs de décision santé » a échoué au premier lancement (réponse
  vide) et a été relancé une fois ; la tentative 2/3 est documentée. Aucun
  constat n'a été comblé par une supposition.
- Le spike `ComplicationProvider`/`ComplicationSubscriber` n'a pas été exécuté :
  la latence de publication sur `fr955` est `notMeasured`.
- Le score de sommeil natif n'est pas exposé par le device `fr955`
  (`simulator.json` ne déclare que `time`) : `notMeasured`.
- Aucune capture exploitable du diagnostic n'a été relue pour ces changements
  (`docs/screens/app-diagnostic-watch.png` illisible) : `notMeasured`.
- Les métriques sociales (★, forks, commits) sont des relevés API du
  2026-11-25, pas des preuves de qualité ; les tests annoncés par vitals
  (1 661) n'ont pas été exécutés ici.
- La recherche vectorielle initiale a été écartée : cosinus 0,545 en
  ré-encodant le texte exact d'un chunk ⇒ vecteurs stockés incompatibles avec
  le `all-minilm` local. Les critères du livre proviennent donc d'une recherche
  par phrases exactes et d'une relecture intégrale.
- `arch.scorecard` = 0/100 sur ce dépôt n'est **pas** une mesure de qualité :
  l'adaptateur Monkey C est absent. Cette dimension est `notMeasured`.

## 12. Sources

- Corpus local *Protocols* : `~/.opencode-poc/synthetix-poc/data/rag/6b86b242…/`
  (1 584 chunks, identifiants cités plus haut).
- Données réelles : `docs/architecture/watch-data-2026-11-25.md`.
- Critères : `docs/architecture/protocol-criteria-from-book.md`.
- Benchmark précédent : `docs/veille/2026-11-25-controle-total-garmin-open-source.md`.
- Décisions : `DECISIONS/ADR-0009…00010` créés dans cette passe.
- Dépôts analysés : URLs et `fichier:ligne` dans les sections 3.1–3.3 ;
  consultation API GitHub et `raw.githubusercontent.com` le 2026-11-25.
