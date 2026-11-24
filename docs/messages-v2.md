# Messages v2 — Titre en Title Case, message en phrase

Source : `docs/rag-messages.md` (RAG Synthetix / EPUB Huberman), relu le 2026-11-24.
Règles appliquées : U01 (1 sens), U03 (hiérarchie), U18 (vocabulaire stable),
U19 (tokens), U41 (catégorie portée par le texte + bordure), U73 (pas de coupe
au milieu d'un mot), U35 dérogation (18 caractères/ligne max, 2 lignes max). Mesure sur `FONT_TINY`
fr955 : 10,9 px CIQ par caractère, soit 196 px pour 18 caractères dans 216 px
de largeur utile.

| Heure | Catégorie / Token | Titre | Message complet (source RAG) |
|---|---|---|---|
| 07:00 | Lumière — ORANGE | `Réveil` | `10-30 min de lumière au réveil` |
| 08:00 | Programme — VERT | `Programme` | `Jour 1 : cardio 45-75 min doux` (varie selon le jour) |
| 12:30 | Marche — BLEU | `Repas` | `Marche 5-10 min après le repas` |
| 15:00 | Stimulants — VIOLET | `Stimulants` | `Plus de caféine ni d'alcool ce soir` |
| 17:30 | Soleil — VIOLET | `Soleil` | `Va voir le coucher de soleil` |
| 18:30 | Pas — BLEU | `Pas` | `Marche 5 min, pas assez` / `Objectif pas atteint` |
| 20:30 | Mobilité — VERT | `Mobilité` | `4 mouvements, 2-4 fois par semaine` |
| 21:00 | NSDR — VIOLET | `NSDR` | `20 min si sommeil insuffisant` |
| 21:30 | Température — BLEU | `Chambre` | `18-20 °C, extrémités chaudes` |
| 22:00 | Écrans — VIOLET | `Écrans` | `Écrans off 1 h avant le coucher` |
| 22:30 | Calme — VIOLET | `Calme` | `1-3 soupirs physiologiques` |

## Variantes du programme du jour (08:00)

| Jour | Message |
|---|---|
| Lundi | `Jour 1 : cardio 45-75 min doux` |
| Mardi | `Jour 2 : bas du corps, 4-9 séries` |
| Mercredi | `Jour 3 : repos, 7000 pas` |
| Jeudi | `Jour 4 : torse, 4-9 séries` |
| Vendredi | `Jour 5 : cardio 25-30 min modéré` |
| Samedi | `Jour 6 : cardio 6-17 min intense` |
| Dimanche | `Jour 7 : épaules, bras, core` |

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
- `Objectif pas` / `atteint`

Les lignes de contexte (`Pup07Ctx`, `Pup17Ctx`, …) ne sont affichées que lorsque
le message tient sur une seule ligne. Avec le jeu de messages v2, tous les
messages occupent deux lignes : le contexte est donc masqué par construction
(comportement confirmé par les captures).
