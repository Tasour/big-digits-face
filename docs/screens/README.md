# Captures des rappels Protocoles — Forerunner 955

Douze captures prises sur le simulateur Connect IQ `fr955` avec le cadran de
test forçant le créneau (le champ « Time Simulation » n'entre pas 17:30 de
façon fiable). Deux recadrages par variante :

- `*-watch.png` — cadran complet, 520 × 520 px ;
- `*-popup.png` — rectangle seul, 466 × 194 px (232 × 96 px CIQ × 2).

Rendu final : fond noir, texte blanc centré horizontalement et verticalement,
bordure pleine de 3 px colorée par catégorie, interligne de 23 px CIQ, barre de
7 carrés (vides si non fait, pleins si fait). Chaque image a été relue : titre
en Title Case, message complet sur deux lignes, accents `é è °`.

## Les huit messages

| Fichier | Heure | Titre | Message | Bordure |
|---|---|---|---|---|
| `0700-reveil` | 07:00 | Réveil | 10-30 min de lumière au réveil | orange |
| `1230-repas` | 12:30 | Repas | Marche 5-10 min après le repas | bleu |
| `1500-stimulants` | 15:00 | Stimulants | Plus de caféine ni d'alcool ce soir | violet |
| `1730-soleil` | 17:30 | Soleil | Va voir le coucher de soleil | violet |
| `1830-pas` | 18:30 | Pas | Marche 5 min, pas assez | bleu |
| `2100-nsdr` | 21:00 | NSDR | 20 min de repos si stress élevé | violet |
| `2200-ecrans` | 22:00 | Écrans | Écrans off 1 h avant le coucher | violet |
| `2230-calme` | 22:30 | Calme | 1-3 soupirs physiologiques | violet |

## Variantes

| Fichier | Variante | Message affiché |
|---|---|---|
| `1830-pas-ok` | `Pup18Ok` | Objectif pas atteint |
| `2100-nsdr-matin` | contexte `Matin` | identique à `2100-nsdr` |
| `2100-nsdr-seance` | contexte `Avant séance` | identique à `2100-nsdr` |
| `2100-nsdr-soir` | contexte `Soir` | identique à `2100-nsdr` |

Les trois variantes NSDR sont **visuellement identiques** : le contexte n'est
affiché par `drawPopup` que lorsque le message tient sur une seule ligne, ce
qui n'arrive avec aucun message v2. Le choix du moment par les données reste
donc interne au cadran (`notMeasured` dans les captures).

## Méthode et limites

- Cadran de test compilé depuis une copie non versionnée de `source/`, avec
  appel direct à `setPopup()` utilisant les vraies chaînes de `strings.xml`.
- Binaire livré compilé séparément depuis le source non modifié.
- Capture d'écran `grim` (2880 × 1800), recadrage sur la fenêtre du simulateur
  puis sur le cadran et le popup. Aucun OCR, aucun texte recomposé.
- Ces images prouvent le **rendu**, pas le déclenchement réel sur la montre ni
  l'appui du bouton haut droit (simulateur uniquement).
- `docs/popup-design-v2.png` conserve l'ancien rendu tronqué, avant correction
  de `wrapText`, agrandissement du rectangle à 96 px et espacement du titre.
