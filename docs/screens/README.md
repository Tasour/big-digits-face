# Captures des rappels Protocoles — Forerunner 955

Douze captures prises sur le simulateur Connect IQ `fr955` avec un cadran de
test forçant le créneau (le champ « Time Simulation » n'entre pas 17:30 de
façon fiable). Deux recadrages par variante :

- `*-watch.png` — cadran complet, 520 × 520 px ;
- `*-popup.png` — rectangle seul, 492 × 228 px (244 × 112 px CIQ × 2 + marge).

Rendu final : fond noir, titre `FONT_SMALL` et message `FONT_SYSTEM_XTINY` en
blanc centrés, bordure pleine de 3 px colorée par catégorie, wrap à 30
caractères (deux lignes maximum), barre de 7 carrés de 30 px portant les lettres
`LMMJVSD`. Plein = couleur de bordure et lettre noire ; vide = contour blanc et
lettre blanche. Chaque image a été relue : accents `é è °`, aucune coupure de
mot, aucun chevauchement. Le contexte n'est plus dessiné (il chevauchait les
carrés).

## Les huit messages et leur algorithme de déclenchement

| Fichier | Heure | Message | Algorithme (`updatePopup`) |
|---|---|---|---|
| `0700-reveil` | 07:00 | Part regarder le lever de soleil | `wakeWindow()` : profil `upcomingWakeTime`, `now ∈ [wake, wake+30]`, sommeil < 420 min |
| `1230-repas` | 12:30 | Marche 5-10 min après le repas | `hour == 12 && 30 ≤ min < 31` — créneau fixe, non mesuré |
| `1500-stimulants` | 15:00 | Plus de caféine ni d'alcool ce soir | `nearBed(480)` : coucher − 8 h ± 2 |
| `1730-soleil` | 17:30 | Part regarder le coucher de soleil | NOAA en cache : `now ∈ [sunset, sunset+2]` ; repli `nearBed(120)` |
| `1830-pas` | 18:30 | Marche 5 min, pas assez | `hour == 18 && 30 ≤ min < 31 && steps < 0,85 × stepGoal` |
| `2100-nsdr` | 21:00 | 20 min de repos après-midi | `stress > 50` ou (`sleep < 420` et `10 ≤ hour ≤ 16`) ; durée par `nsdrMessage(hour)` |
| `2200-ecrans` | 22:00 | Écrans off 1 h avant le coucher | `nearBed(60)` : coucher − 1 h ± 2 |
| `2230-calme` | 22:30 | 1-3 soupirs physiologiques | `hour == 22 && 30 ≤ min < 31 && stress > 40` |

Durées NSDR : **30 min le matin, 20 min l'après-midi, 10 min avant séance,
10 min le soir**. Les 10–30 min sont sourcés dans le livre ; le 10 min avant
séance est un choix de design.

## Variantes

| Fichier | Variante | Ce que la capture prouve |
|---|---|---|
| `habit-partiel` | `activeBits = 0x05` | 3 carrés remplis (lettres noires), 4 vides (lettres blanches) |
| `2100-nsdr-matin` | `nsdrMessage(9)` | 30 min au réveil |
| `2100-nsdr-seance` | `nsdrMessage(17)` | 10 min avant séance |
| `2100-nsdr-soir` | `nsdrMessage(21)` | 10 min le soir |

Les lettres `LMMJVSD` sont calculées depuis `day_of_week` en remontant de 0 à 6
jours (bit 0 = aujourd'hui). Le harnais appelle les vrais helpers de sélection
`nsdrContext(hour)` et `nsdrMessage(hour)`.

## Méthode et limites

- Cadran de test compilé depuis une copie non versionnée de `source/`, avec
  appel à `setPopup()` utilisant les vraies chaînes de `strings.xml`.
- Binaire livré compilé séparément depuis le source non modifié.
- Capture `grim` (2880 × 1800), recadrage par détection de la bordure colorée,
  puis sur le cadran et le popup. Aucun OCR, aucun texte recomposé.
- Ces images prouvent le **rendu**, pas le déclenchement réel sur la montre ni
  l'appui du bouton (simulateur uniquement).
- Le buzz est fourni par l'app compagnon `companion/` (watch-app) : non
  vérifiable sur simulateur, `notMeasured`. Les algorithmes améliorés de
  l'app (`Weather.getSunset()`, `SensorHistory`) ne modifient pas les captures.
- `docs/popup-design-v2.png` conserve l'ancien rendu tronqué avant corrections.
