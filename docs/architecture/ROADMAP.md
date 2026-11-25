# Roadmap de migration — big-digits-face

> Chaque étape est réversible. Aucune phase ne commence avant la validation de la précédente. Règle de tri : `impact × (6 − effort)`.

## P0 — Fondations (avant toute nouvelle release)

| # | Action | Fichiers concernés | Effort | Impact | Critère de sortie | Rollback |
|---|---|---|---:|---:|---|---|
| 1 | Corriger `habitBits()` sans effacement | `source/BigDigitsView.mc:222-234` | 1 | 5 | test 7 j avec un jour manqué : 0 perte | revert du hunk, `.prg` `.prev` |
| 2 | Remplacer le planning par `Moment` ≥ 5 min, retirer `Duration(10)` | `companion/source/BuzzApp.mc:184-190,489` | 1 | 5 | aucun `Duration < 300 s` ; journal d'un cycle complet | `.prg` `.prev` |
| 3 | Ajouter `getSettingsView()` + `Menu2` sur la face | `source/BigDigitsApp.mc`, `resources/` | 2 | 5 | menu visible sur `fr955`, ≤ 7 items, capturé | retirer l'override |
| 4 | Prioriser `onPress` (accuse → complication → indice) | `source/BigDigitsView.mc:256-264`, `source/BigDigitsDelegate.mc:11-13` | 1 | 4 | 3 cas exercés en simulateur | revert du delegate |
| 5 | Trier les 85 erreurs `-l 3` puis activer le gate | `monkey.jungle`, `build.sh:28`, sources | 2 | 5 | 0 erreur, build vert | désactiver le gate (release non certifiée) |
| 6 | Test de fixture `weekdayLetters` | suite `:test`, `source/BigDigitsView.mc:491-500` | 1 | 3 | dimanche→D, lundi→L prouvés ; correctif seulement si échec | revert du test |
| 7 | Scripts release/verify/deploy + `.prev` + SHA-256 | `bin/` (hors git), scripts locaux | 2 | 4 | tag + SHA + restauration `.prev` réussie | suppression des scripts |
| 8 | Recapturer le diagnostic invalide sur `fr955` | `docs/screens/` | 1 | 3 | capture relue, page web écartée | garder l'ancienne comme témoin invalide |

Sortie P0 : 8 actions vertes, `arch.verify` vert après écriture des livrables, release à 0 erreur `-l 3`.

## P1 — Extraction contrôlée

| # | Action | Fichiers concernés | Effort | Impact | Critère de sortie | Rollback |
|---|---|---|---:|---:|---|---|
| 9 | Module `Keys` + `schemaVersion=1`, neutraliser `habit.app.day` | `shared/Keys.mc`, face, app | 2 | 4 | lecture v0 et v1 dans la suite `:test` | lecture v0 seule |
| 10 | Log append-only + double lecture | `shared/Habits.mc`, `source/BigDigitsView.mc` | 2 | 5 | historique 7 j reconstruit après 2 jours manqués | bascule lecture v0 |
| 11 | `DataManager` TTL + `profile` injecté + `Theme` indexé | `shared/*`, face, app | 3 | 4 | 1 seul `getProfile()` par cycle mesuré | ancien chemin conservé |
| 12 | Spike `ComplicationSubscriber`, puis id0/id1 typés | app, face | 3 | 4 | spike prouvé sur 9.3.0 ; repli `ComplicationNotFoundException` | désactiver l'abonnement |
| 13 | Suite `:test` 20 cas + oracle de stockage hors bande | suite `:test` | 3 | 4 | 20/20 verts, sonde en lecture seule | revert de la suite |
| 14 | Layout fractions + `getFontHeight()`, contraste recalculé | `source/BigDigitsView.mc`, `companion/source/BuzzApp.mc` | 2 | 3 | 0 pixel de texte dans la bordure, ≥ 4,5:1 mesuré | géométrie constantes d'origine |
| 15 | Notification locale à la place du réveil background | `companion/source/BuzzApp.mc:549` | 2 | 3 | disponibilité sonde sur `fr955` | réveil explicite restauré |

## P2 — Consolidation

| # | Action | Fichiers concernés | Effort | Impact | Critère de sortie | Rollback |
|---|---|---|---:|---:|---|---|
| 16 | Widget glance + `System.exitTo` (conditionnel) | `widget/` | 2 | 3 | besoin mesuré documenté ; confirmation acceptée | suppression du widget |
| 17 | Instrumentation `System.Stats` CPU/heap/courant | face, app | 2 | 3 | relevés archivés dans `docs/architecture/` | désactiver la sonde |
| 18 | Cache différencié par type de donnée | `shared/DataManager.mc` | 2 | 3 | TTL par type consignés, 0 appel redondant | TTL uniforme |

## Jalon de validation humaine

- [ ] P0 validé par le propriétaire du projet le 2026-11-25
- [ ] P1 validé par le propriétaire du projet le <date>
- [ ] P2 validé par le propriétaire du projet le <date>

## État d'exécution au 2026-11-25

- P0-1 à P0-4 et P0-6 : modifiés dans le code, compilation `-r` verte, **tests non exécutés** (simulateur indisponible).
- P0-5 : **vert** — 0 erreur `-l 3` sur les trois cibles ; gate activé dans les trois `build.sh`.
- P0-7 : **livré** — `release.sh`, `verify.sh`, `deploy.sh`, `RELEASES.md` ; `verify.sh` vert sauf G2 partiel.
- P0-8 : **bloqué** — simulateur indisponible.

Aucune phase n'est déclarée terminée tant que ces points restent ouverts. Cause simulator et commandes de rejeu dans `CURRENT-STATE.md` §5. Décision JDK alternatif (A7) en attente de validation humaine.
