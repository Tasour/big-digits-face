# Captures des rappels Protocoles — Forerunner 955

Douze captures prises sur le simulateur Connect IQ `fr955` avec un cadran de
test forçant le créneau (le champ « Time Simulation » n'entre pas 17:30 de
façon fiable). Deux recadrages par variante :

- `*-watch.png` — cadran complet, 520 × 520 px ;
- `*-popup.png` — rectangle seul, 466 × 194 px (232 × 96 px CIQ × 2).

Rendu final : fond noir, titre `FONT_SMALL` et message `FONT_XTINY` en blanc
centrés horizontalement et verticalement, bordure pleine de 3 px colorée par
catégorie, interligne de 23 px CIQ, barre de 7 carrés de 10 px (vides = contour
blanc, pleins = couleur de bordure). Chaque image a été relue : accents
`é è °`, message complet, aucun chevauchement.

## Les huit messages et leur algorithme de déclenchement

| Fichier | Heure | Message | Algorithme (`updatePopup`) |
|---|---|---|---|
| `0700-reveil` | 07:00 | 10-30 min de lumière au réveil | `wakeWindow()` : profil `upcomingWakeTime`, `now ∈ [wake, wake+30]` et sommeil < 420 min |
| `1230-repas` | 12:30 | Marche 5-10 min après le repas | `hour == 12 && 30 ≤ min < 31` — créneau fixe, non mesuré |
| `1500-stimulants` | 15:00 | Plus de caféine ni d'alcool ce soir | `nearBed(480)` : `upcomingSleepTime` (ou 23:00 − `sleepTime`) à `now + 480 min ± 2` |
| `1730-soleil` | 17:30 | Va voir le coucher de soleil | NOAA en cache : `now ∈ [sunset, sunset+2]` ; repli `nearBed(120)` → « Coucher approx. » |
| `1830-pas` | 18:30 | Marche 5 min, pas assez | `hour == 18 && 30 ≤ min < 31 && steps < 0,85 × stepGoal` (ou < 7 000 si objectif nul) |
| `2100-nsdr` | 21:00 | 20 min de repos si stress élevé | `stress > 50` **ou** (`sleep < 420` et `10 ≤ hour ≤ 16`) ; contexte par `nsdrContext(hour)` |
| `2200-ecrans` | 22:00 | Écrans off 1 h avant le coucher | `nearBed(60)` : coucher − 1 h ± 2 |
| `2230-calme` | 22:30 | 1-3 soupirs physiologiques | `hour == 22 && 30 ≤ min < 31 && stress > 40` |

La durée NSDR retenue est **20 min** : les extraits RAG archivés donnent
« ten- to thirty-minute NSDR session » et « 20 to 30 minutes if you slept
poorly » ; 20 min est la seule valeur commune aux deux plages.

## Variantes

| Fichier | Variante | Ce que la capture prouve |
|---|---|---|
| `habit-partiel` | `activeBits = 0x05` | 3 carrés remplis de la couleur de bordure, 4 vides — état « fait » |
| `2100-nsdr-matin` | `nsdrContext(9)` | sélection du contexte « Matin » par le vrai helper |
| `2100-nsdr-seance` | `nsdrContext(17)` | sélection du contexte « Avant séance » par le vrai helper |
| `2100-nsdr-soir` | `nsdrContext(21)` | sélection du contexte « Soir » par le vrai helper |

Les trois variantes NSDR restent **visuellement identiques** : le contexte
n'est dessiné par `drawPopup` que si le message tient sur une seule ligne, ce
qui n'arrive avec aucun message v2. Le helper de sélection est bien exercé, mais
la distinction à l'écran est `notMeasured`.

## Méthode et limites

- Cadran de test compilé depuis une copie non versionnée de `source/`, avec
  appel à `setPopup()` utilisant les vraies chaînes de `strings.xml` ; pour
  NSDR, le contexte vient du vrai `nsdrContext(hour)` extrait de la prod.
- Binaire livré compilé séparément depuis le source non modifié.
- Capture d'écran `grim` (2880 × 1800), recadrage sur la fenêtre du simulateur
  puis sur le cadran et le popup. Aucun OCR, aucun texte recomposé.
- Ces images prouvent le **rendu**, pas le déclenchement réel sur la montre ni
  l'appui du bouton haut droit (simulateur uniquement).
- `docs/popup-design-v2.png` conserve l'ancien rendu tronqué, avant correction
  de `wrapText`, agrandissement du rectangle à 96 px et espacement du titre.
