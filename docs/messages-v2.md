# Messages v2 — Titre en Title Case, message en phrase

Source : `docs/rag-messages.md` (RAG Synthetix / EPUB Huberman), relu le 2026-11-24.
Règles appliquées : U01 (1 sens), U03 (hiérarchie), U18 (vocabulaire stable),
U19 (tokens), U41 (catégorie portée par le texte + bordure), U73 (pas de coupe
au milieu d'un mot).

Le message est dessiné en `FONT_SYSTEM_XTINY` dans un popup de 244 px, avec un
wrap à 30 caractères : les phrases longues passent sur deux lignes, les autres
tiennent sur une seule. Le titre reste en `FONT_SMALL`. Les durées NSDR sont
30 / 20 / 10 / 10 min selon le moment : le livre donne « ten- to thirty-minute
NSDR session » et « 20 to 30 minutes if you slept poorly » ; le 10 min avant
séance est un choix de design, pas une donnée source.

| Heure | Catégorie | Titre | Message compilé | Algorithme de déclenchement |
|---|---|---|---|---|
| 07:00 | Lumière — ORANGE | `Réveil` | `Part regarder le lever de soleil` | `wakeWindow()` : `upcomingWakeTime`, `now ∈ [wake, wake+30]`, sommeil < 420 min |
| 12:30 | Marche — BLEU | `Repas` | `Marche 5-10 min après le repas` | `hour == 12 && 30 ≤ min < 31` (créneau fixe, non mesuré) |
| 15:00 | Stimulants — VIOLET | `Stimulants` | `Plus de caféine ni d'alcool ce soir` | `nearBed(480)` : coucher − 8 h ± 2 |
| 17:30 | Soleil — VIOLET | `Soleil` | `Part regarder le coucher de soleil` | NOAA en cache : `now ∈ [sunset, sunset+2]` ; repli `nearBed(120)` |
| 18:30 | Pas — BLEU | `Pas` | `Marche 5 min, pas assez` | `hour == 18 && 30 ≤ min < 31 && steps < 0,85 × stepGoal` |
| 21:00 | NSDR — VIOLET | `NSDR` | `30 min de repos au réveil` / `20 min de repos après-midi` / `10 min de repos avant séance` / `10 min de repos le soir` | `stress > 50` ou (`sleep < 420` et `10 ≤ hour ≤ 16`) ; `nsdrMessage(hour)` |
| 22:00 | Écrans — VIOLET | `Écrans` | `Écrans off 1 h avant le coucher` | `nearBed(60)` : coucher − 1 h ± 2 |
| 22:30 | Calme — VIOLET | `Calme` | `1-3 soupirs physiologiques` | `hour == 22 && 30 ≤ min < 31 && stress > 40` |

Les rappels `Programme`, `Mobilité` et `Température chambre` ont été retirés à
la demande de l'utilisateur : ils dépendaient de données non mesurables depuis
une watch face. Le contexte n'est plus dessiné dans le popup : avec la nouvelle
mise en page, les lignes de contexte trop longues se chevauchaient avec les
carrés. Les chaînes sont conservées mais non utilisées.

L'app compagnon `companion/` réévalue les mêmes créneaux avec des données
réservées aux watch-apps (`Weather.getSunset()`, `SensorHistory`) et déclenche
un buzz court. Elle n'a pas d'app ID partagé avec le cadran : les deux peuvent
diverger sur une condition limite, et le score d'habitude reste dans le cadran.
