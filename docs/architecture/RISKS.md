# Risques et angles morts — big-digits-face

| Risque | Probabilité | Impact | Mitigation | Preuve |
|---|---|---|---|---|
| Perte d'historique d'habitude | Certain aujourd'hui | Élevé | P0-1 + test 7 j | `source/BigDigitsView.mc:228-229` |
| Événement background rejeté par le SDK | Certain aujourd'hui | Élevé | `Moment` + garde 5 min | `companion/source/BuzzApp.mc:189,489`; `doc/Toybox/Background.html:1707` |
| Permissions/storage divergents face ↔ app | Élevé | Moyen | `Keys` unique, parité testée | `README.md:168-170` |
| Rôle `ComplicationSubscriber` non prouvé | Moyen | Moyen | spike P1-12, repli local | `docs/veille/2026-11-25-controle-total-garmin-open-source.md:246-247` |
| Confirmation utilisateur sur réveil / `exitTo` | Certain | Moyen | notification locale, test assumé | `companion/source/BuzzApp.mc:549`; `doc/Toybox/System.html:1352` |
| Régression visuelle MIP non détectée | Moyen | Moyen | captures `fr955` relues, contraste calculé | `source/BigDigitsView.mc:62-75` |
| Release non traçable / irréversible | Élevé | Moyen | tag + SHA + `.prev` | 0 tag, `build.sh:28` |
| Faux positifs du gate HTML sur `.mc` | Certain | Faible | contrat design mesuré à part | rapport QUALITÉ |
| Benchmark non applicable (SDK 9.2, AMOLED, cloud) | Moyen | Moyen | réimplémentation originale, aucun copiage | `docs/veille/...:89,100-101,188,245` |
| Confiance globale limitée | Certain | Moyen | scorecard `partial`, mesures manquantes listées | `docs/architecture/scorecard.json` |

## Hypothèses à valider

- L'étiquette `LMMJVSD` décalée d'un jour est `partiel` : le SDK donne `day_of_week = 1` pour dimanche (`Moment.html:123,131`), ce qui rend le calcul actuel cohérent à première lecture. Un test de fixture est obligatoire avant tout correctif.
- Aucun chemin programmatique n'existe pour ouvrir *Customize* depuis une face sous 9.3.0 : à confirmer avant de renoncer définitivement à l'ouverture par bouton.
- `Notifications.showNotification()` est disponible sur `fr955` : non sondé.
- Le besoin du widget n'est pas mesuré : il reste conditionnel en P2.
- Les 85 erreurs `-l 3` et les mesures de contraste/débordement proviennent d'un seul rapport, non rejoué par l'arbitre.

## Mesures manquantes

1. CPU p50/p95 de `onUpdate`, `onPartialUpdate`, `drawPopup`.
2. Heap réel au repos, pendant popup, pendant background (`System.Stats`).
3. Courant batterie et Δ d'autonomie.
4. Durée réelle d'un `onTemporalEvent` vs 30 s.
5. Nombre d'events/jour et taux d'`InvalidBackgroundTimeException`.
6. Latence `Weather.getSunset()` et `Position.getInfo()` sur le 955.
7. Précision NOAA local vs Weather sur deux semaines.
8. Résultat du build avec `typecheck = 3`.
9. Purge du pool graphique si `BufferedBitmap` est retenu.
10. Contrôle MIP sur device (simulateur ≠ 955).
