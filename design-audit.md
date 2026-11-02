# Audit UX/UI — Big Digits (Forerunner 955 Solar)

Audit externe avec une grille type Apple HIG : hiérarchie, lisibilité, composition,
typographie, couleur, architecture de l’information, états, accessibilité.
Mesures indicatives issues des rendus 560/260 px et du code ; à revalider sur MIP réelle.

## Verdict — 5,5/10

- **Temps : 8,5/10.** Les 94 px, le trait 18 et le 1 custom fonctionnent ; 10:49 se lit en moins d’une seconde.
- **Data : 3,5/10.** 10 px, icônes de 3–5 px, trois accents invisibles, aucune étiquette.
- **Composition : 5/10.** Grille 4 px / 8 px, badge qui déborde, date collée aux chiffres, blocs posés à 2–8 px des axes.

**Diagnostic central : ce n’est pas la taille des chiffres. C’est 4 px, 10 px et 5 %.**
4 px de badge en trop, 10 px de data trop petits, 5 % d’écart de gris entre date et data.

## Les 5 problèmes majeurs

### 1. Le badge des secondes casse la cellule haut-gauche et la grille — P0
- Cellule haut-gauche 94 px ; chiffre 78 px ; badge 20 px : **78 + 20 = 98**, pas 94.
- Le badge déborde de 4 px, fusionne avec le 1 et devient l’objet le plus blanc du cadran.
- Chiffres non centrés : 27 px de blanc à gauche, 3 px à droite.
- La cellule haut-gauche est courte **14 h/24** (00–09 et 20–23) : le 0/2/8/6/9 comprimé est l’état moyen, pas l’exception.
- 3 px de trait laissent des compteurs de 4 px : 0/8 se bouchent à distance.

### 2. La date est un linteau qui touche les chiffres et sort de l’anneau — P0
- Encre ~122,5 × 13 px, de y=17 à y=30 ; le haut des chiffres est à y=30 : **aucun pixel de respiration**.
- « Lun 2 Nov » fusionne avec le 1/le badge ; « 2026 » avec le 0.
- 10,8 px de la date sont hors de l’anneau r=126 ; « Juin »/« Juil » aggravent.
- 85 % de blanc, contraste 14,7:1 : elle lit comme une seconde headline, pas une donnée secondaire.
- L’année coûte ~38 px pour une information inutile au poignet.

### 3. Les data sont sous le seuil de lecture — P0/P1
- Valeurs FONT_XTINY ~10 px, icônes 3–5 px : à 60 cm, ~7,3 arcmin pour les valeurs, 2–4 arcmin pour les icônes.
- Batterie « 5J » / « 0H » : les deux lignes se touchent ; l’icône 10×6 est un tiret.
- Groupe bas centré à 122,5 au lieu de 130 (7,5 px à gauche) ; 5 chiffres de pas passent à 5 px de l’icône calories ; 6 chiffres collisionnent.
- Format brut sans séparateur ; la micro-police 4×6 du code n’est jamais utilisée.

### 4. La grille n’est pas une grille — P1
- Colonnes à 34/132, lignes à 30/132 : gouttières **4 px / 8 px**, bloc 192×196.
- Bas de colonne gauche à 128, 0 à 124, rangée basse à 132 : plus de ligne d’assise.
- Badge à 9 h 30, batterie à 2 h 20, bas à 122,5 : les quatre « points cardinaux » sont posés à l’œil.

### 5. Rognage et anneau se contredisent — P1
- Bloc 192 px > carré sûr 178 px (r=126) : coins du 0/9/7/4 rognés de 5–8 px, asymétriquement.
- Le 0 n’a qu’un coin chanfreiné, les trois autres carrés : il lit comme abîmé.
- Anneau 1 px #555 (2,8:1) qui traverse les chiffres et disparaît au soleil ; les ticks ne cadrent rien.

## Trois directions

### A. Conservatrice — « Badge réparé, grille exacte »
**Garder** : 94/18, 2×2, badge horizontal blanc, 1 custom, noir/blanc, quatre data, 24 h.
**Enlever** : anneau et ticks, année, « 0H » quand ≥ 1 jour, icônes < 10 px, trait 3 px des secondes.
**Changements** :
- Badge **56×16** à x=52→108, y=108→124 ; chiffres 14×15, trait 2 px, centrés.
- Cellule haut-gauche 78 + 16 = 94 ; plus de débordement.
- Date « LUN 2 NOV » sans année, 13 px, y=9, centrée ; 4 px avant les chiffres.
- Data 14 px, icônes 12 px, interligne 14, groupe centré à 130.
- Batterie à 3 h, pas « 5J/0H » ; une ligne « 5j » + jauge.
- Blanc pur temps, #AAA date, #888 data, un seul accent.
**Risque** : le 0/2/8/6/9 haut-gauche reste comprimé ; le badge reste fusionné. Effort M.

### B. Raffinée — « Rail + grille cardinale » (recommandée si la data compte)
**Garder** : quatre chiffres 7 segments, noir/blanc, badge blanc, 1 custom, 24 h.
**Enlever** : badge horizontal sous le 1, année, troisième accent, anneau continu, FONT_XTINY.
**Changements** :
- Grille : 12 px marge | rail 24 px | 2 px | bloc 184 px (4×90 + 2×2) | 2 px | batterie 24 px | 12 px.
- Bloc à x=38→222, y=38→222 : coins à r=130,1 ; aucun rognage réel ; chiffres 90/18.
- Rail secondes **24×40** à x=12, y=110 : deux 16×16 empilés, trait 2 px, blanc sur noir.
- Date 13 px sans année, y=11 ; data 14 px centrées à 130, y=226→240 ; batterie 14 px + jauge 5×20 à 3 h.
- Anneau **segmenté** : quatre arcs de 60° à r=126, 2 px #777, trous de 30° aux diagonales ; les coins des chiffres tombent dans les trous.
- Micro-police 5×7 à l’échelle 2 (10×14, trait 2) pour date et data ; un accent (vert batterie).
- Drapeau du 1 à ~32 px (34 % de la cellule) au lieu de 20 %.
**Risque** : temps décalé de 2–4 px, secondes verticales plus lentes, identité qui passe du badge à un rail. Effort H.

### C. Audacieuse — « Plein cadre, une data à la fois »
**Garder** : quatre chiffres 100/20, noir/blanc, 1 custom, date.
**Enlever** : anneau, badge horizontal, simultanéité des quatre data, icônes, petits gris.
**Changements** :
- Chiffres 100 px à x=28/132, y=28/132 ; bloc 204, coins à r=144 : pieds du 4/7 rognés de ~20 px, à assumer.
- Secondes : arc 3 px à r=120 dans la baie de 9 h (8→10), segment de la seconde courante en blanc.
- Batterie : arc 4 px à 3 h, vert, longueur = %.
- Date 13 px ; **une seule ligne data 18 px** en bas qui permute toutes les 6 s : « PAS 8 214 » → « KCAL 642 » → « AUT 5j ».
**Risque** : data non simultanée, arcs à la limite, perte du badge signature. Effort H, risque H.

## Priorités

| Prio | Problème | Recommandation | Impact | Effort | Risque |
|---|---|---|---|---|---|
| P0 | Badge 78+20=98 > 94, fusion avec le 1 | Badge 56×16, chiffres centrés 14×15/2 px ; ou rail | Très haut | M | M |
| P0 | Haut-gauche comprimé 14 h/24 | 90/94 plein (B) ; sinon mid=30 et assumer | Très haut | M | H |
| P0 | Date 122,5 px, touche 1 et 0, hors anneau | Sans année, 13 px, y=9, « LUN 2 NOV » | Très haut | S | L |
| P0 | Data 10 px, icônes 3–5 px | 14 px, icônes 12 px, interligne 14 | Haut | M | M |
| P1 | Grille 4/8, axes décalés | Gouttières 8/8, tout aligner sur 130 | Haut | S | L |
| P1 | Batterie à 2 h 20, lignes collées | 3 h (y=107→145), 12/14 px ou « 5j » + jauge | Moyen | S | L |
| P1 | Rognage 0/9/7/4, anneau 2,8:1 | 90 contenu ou 94 plein cadre sans anneau | Moyen | M | M |
| P1 | Trois accents 15–42 px², date/data à 5 % | Un accent ≥ 100 px², quatre gris séparés | Moyen | S | L |
| P1 | 12 h sans AM/PM, FR only, charge/null | AM/PM, table fr/en, fallback « -- » | Moyen | M | M |
| P2 | 1 flag à 20 % au lieu de ~35 % | Allonger le drapeau à 30–32 px | Bas | S | L |
| P2 | Date minuscules, « 5J/0H », accents | Capitales, « 5j/12h », Fév/Aoû/Déc | Bas | S | L |
| P2 | Flash badge 1 280 px² chaque seconde | Badge 56×16, trait 2, tester partial update | Moyen | S | M |

## À ne pas changer

1. Les quatre chiffres comme seule architecture ; pas de cadres, widgets, jauges multiples.
2. L’échelle : ne pas descendre sous 90 px ; 94 est bon, 100 est un choix plein cadre.
3. Le trait 18/94, les extrémités carrées, les compteurs larges ; pas d’arrondis ni d’ombres.
4. Le 1 custom : drapeau + hampe ; l’allonger, pas le supprimer.
5. Le noir profond et le blanc pur du temps : contraste 21:1.
6. Le badge blanc à chiffres noirs : l’inversion est la signature ; le réduire/déplacer, pas le remplacer.
7. La mise à jour minute + `onPartialUpdate` secondes : bonne architecture ; réduire le flash.
8. Les data dans les zones cardinales : le principe est bon, l’exécution est fausse.
9. L’absence de tactile/chrome : le cadran reste une image, pas une app.
10. Le 24 h français par défaut ; le 12 h et l’anglais doivent être vrais, pas des promesses.

## Validation à faire

- 1:1 réels : 00:00, 07:07, 08:08, 10:49, 11:11, 12:34, 17:47, 20:02, 22:22, 23:59.
- Data : 0, 999, 9 999, 12 345, 123 456 pas ; 0, 99, 642, 1 234 kcal ; batterie 100/50/10/5/0 %, charge, null.
- 12/24 h, FR/EN, plein soleil, 40/60 cm, photo MIP réelle.
- Test des 5 secondes : heure < 1 s ; chaque data < 2 s ; tout < 5 s.

## Recommandation

La **A** corrige 80 % des problèmes sans changer l’identité (badge, date, data, grille, batterie).
La **B** est la seule qui règle aussi la compression 14 h/24 et la lisibilité des data ; c’est la direction recommandée si la data compte autant que le poster.
La **C** est la plus belle mais la plus éloignée du brief « toutes les data, tout le temps ».
