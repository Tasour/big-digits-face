# ADR-0010 — Agrégation hors montre, payload compact vers le cadran

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : 100 % local, contraintes FR955 (131 072 B face / 786 432 B app / 65 536 B background), fiabilité des seuils

## Contexte

La face connect IQ ne peut pas lire le stockage de l'app compagnon
(`DATA-SOURCES.md`), et le score de sommeil natif n'est pas exposé sur `fr955`.
Les projets comparés (`docs/veille/2026-11-25-comparatif-protocoles-architecture.md`)
montrent trois façons de traiter la donnée : tout calculer sur la montre
(notre état actuel), tout déporter vers un service local externe (garminizer,
Threshold, trainbud), ou calculer côté téléphone/compagnon puis n'envoyer que
le résultat (vitals, aurboda). Le cache Garmin local contient déjà
`sleepScores.overall.qualifierKey`, `sleepNeed.actual`, Body Battery et stress.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| **A. Tout calculer dans la watch-app** | 100 % sur la montre, aucun transport | pas de score de sommeil Garmin ; RAM/budget background 65 536 B ; pas de corrélation multi-sources | 1 | immédiate |
| **B. Service local externe (PostgreSQL + MCP)** | données riches, statistiques complètes, tests faciles | dépendance à un service, à un tunnel ou au cloud ; contraire au « zéro cloud » si distant | 4 | moyenne |
| **C. Compagnon = calculateur, cadran = lecteur** | règles du livre appliquées sur des données réelles ; charge hors face ; payload de quelques entiers | nécessite un canal face↔app (spike `ComplicationProvider`) ; échec du canal ⇒ repli A | 3 | élevée (repli A) |

## Décision

Retenir **C** comme architecture cible, avec **A comme repli obligatoire** si le
spike de complication échoue. **B est rejeté** comme dépendance runtime : les
projets qui l'utilisent (Threshold sur Cloudflare Workers, trainbud derrière
cloudflared) ne sont pas 100 % locaux. Le service local existant
(`mon-suivi-running`, port 47822) reste une **source de données au moment du
développement**, pas une dépendance de la montre.

Le payload compact est : `verdict` (3 états), `need_min`, `asleep_s`, `debt7_s`,
`bedtime_sd_min`, `date_calcul`, `schemaVersion`. Une donnée absente est `—`,
jamais `0` (piège documenté dans garminizer).

## Conséquences

- Positives : le cadran reste O(1) en lecture ; les règles du livre sont
  appliquées sur des valeurs mesurées ; le repli A garantit une face autonome.
- Négatives acceptées : deux chemins de lecture à maintenir ; latence du pont
  à mesurer (`notMeasured` avant spike).
- À surveiller : cohérence du `schemaVersion` entre compagnon et face ; dérive
  entre payload et libellés de messages.

## Preuves

- `docs/architecture/DATA-SOURCES.md` — Storage propre à un app ID ; pas de
  score de sommeil sur `fr955` ; budget background 65 536 B.
- `docs/veille/2026-11-25-comparatif-protocoles-architecture.md` — scoring des
  12 candidats et recommandation d'agrégation sémantique côté serveur.
- `docs/architecture/watch-data-2026-11-25.md` — disponibilité réelle des
  champs `sleepScores`, `sleepNeed`, Body Battery dans le cache local.
- `companion/source/BuzzApp.mc:195-229` — calculs locaux actuels.

## Révision

Si le spike `ComplicationProvider`/`ComplicationSubscriber` échoue sous CIQ
9.3.0, rester en A et documenter l'absence de score de sommeil comme limite
définitive ; ne pas basculer en B sans accord explicite du propriétaire.
