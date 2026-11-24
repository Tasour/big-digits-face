# Messages v2 — Titre en Title Case, message en phrase

Source : `docs/rag-messages.md` (RAG Synthetix / EPUB Huberman), relu le 2026-11-24.
Règles appliquées : U01 (1 sens), U03 (hiérarchie), U18 (vocabulaire stable),
U19 (tokens), U41 (catégorie portée par le texte + bordure), U73 (pas de coupe
au milieu d'un mot).

Le message est dessiné en `FONT_XTINY` : mesure sur `fr955`, ~7,5 px CIQ par
caractère, soit ~135 px pour 18 caractères dans 216 px de largeur utile. Le
titre reste en `FONT_SMALL`. La durée NSDR retenue est 20 min : les extraits RAG
donnent « ten- to thirty-minute NSDR session » et « 20 to 30 minutes if you
slept poorly » ; 20 min est la seule valeur commune.

| Heure | Catégorie | Titre | Message compilé | Algorithme de déclenchement |
|---|---|---|---|---|
| 07:00 | Lumière — ORANGE | `Réveil` | `10-30 min de lumière au réveil` | `wakeWindow()` : `upcomingWakeTime`, `now ∈ [wake, wake+30]`, sommeil < 420 min |
| 12:30 | Marche — BLEU | `Repas` | `Marche 5-10 min après le repas` | `hour == 12 && 30 ≤ min < 31` (créneau fixe, non mesuré) |
| 15:00 | Stimulants — VIOLET | `Stimulants` | `Plus de caféine ni d'alcool ce soir` | `nearBed(480)` : coucher − 8 h ± 2 |
| 17:30 | Soleil — VIOLET | `Soleil` | `Va voir le coucher de soleil` | NOAA en cache : `now ∈ [sunset, sunset+2]` ; repli `nearBed(120)` |
| 18:30 | Pas — BLEU | `Pas` | `Marche 5 min, pas assez` | `hour == 18 && 30 ≤ min < 31 && steps < 0,85 × stepGoal` |
| 21:00 | NSDR — VIOLET | `NSDR` | `20 min de repos si stress élevé` | `stress > 50` ou (`sleep < 420` et `10 ≤ hour ≤ 16`) ; contexte = `nsdrContext(hour)` |
| 22:00 | Écrans — VIOLET | `Écrans` | `Écrans off 1 h avant le coucher` | `nearBed(60)` : coucher − 1 h ± 2 |
| 22:30 | Calme — VIOLET | `Calme` | `1-3 soupirs physiologiques` | `hour == 22 && 30 ≤ min < 31 && stress > 40` |

Les rappels `Programme` (08:00), `Mobilité` (20:30) et `Température chambre`
(21:30) ont été retirés à la demande de l'utilisateur : leurs variantes
dépendaient de données ou de règles non mesurables depuis une watch face.

## Découpage réel en 2 lignes × 18 caractères (wrap sur espace)

Relevé sur les captures du simulateur `fr955`, après correction de `wrapText`
(le tableau démarrait avec une entrée vide, ce qui masquait la première ligne) :

- `10-30 min de` / `lumière au réveil`
- `Va voir le coucher` / `de soleil`
- `1-3 soupirs` / `physiologiques`
- `Plus de caféine ni` / `d'alcool ce soir`
- `Marche 5-10 min` / `après le repas`
- `Marche 5 min,` / `pas assez`
- `Écrans off 1 h` / `avant le coucher`
- `20 min de repos si` / `stress élevé`

Les lignes de contexte (`Pup07Ctx`, `Pup17Ctx`, …) ne sont affichées que lorsque
le message tient sur une seule ligne. Avec le jeu de messages v2, tous les
messages occupent deux lignes : le contexte est donc masqué par construction.
Le helper `nsdrContext(hour)` est néanmoins exercé par les captures
`2100-nsdr-*` ; la distinction à l'écran reste `notMeasured`.
