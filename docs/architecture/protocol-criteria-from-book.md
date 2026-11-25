# Critères « assez / pas assez » tirés du livre *Protocols*

Date : 2026-11-25. Source : corpus EPUB local indexé dans Synthetix
(`~/.opencode-poc/synthetix-poc/data/rag/6b86b242…/`, **1 584 chunks**,
modèle `all-minilm` 384 dims). Aucun appel réseau externe.

## Méthode

1. Extraction des chunks par **phrase exacte** (recherche mot pour mot), puis
   relecture intégrale du chunk : la recherche vectorielle locale a été écartée
   parce que les vecteurs stockés ne correspondent pas au modèle `all-minilm`
   installé (cosinus **0,545** mesuré en ré-encodant le texte exact d'un chunk).
2. Chaque seuil ci-dessous est cité tel quel, avec son `chunk_XXX` et, quand le
   texte porte une référence, la source scientifique du livre.
3. Les chapitres sont déduits des marqueurs de citation (`#ch01en_` = sommeil,
   `ch02en_` = exercice, `ch03en_` = stress, `ch04en_` = nutrition,
   `ch05en_` = lumière, `ch06en_` = focus).

## Référentiel par catégorie de message

| Catégorie | Critère du livre (citation courte) | Chunk | Seuil retenu | Mesurable sur FR955 ? |
|---|---|---|---|---|
| **Sommeil** | « a full seven to nine hours of sleep » | `chunk_361` | **7 h – 9 h** = assez ; < 7 h = pas assez | Oui, via événements sleep/wake de l'app |
| **Sommeil (architecture)** | « Cycling through N1, N2, N3, to REM takes about ninety minutes… 7.5 hours gets five cycles » | `chunk_252` | 7,5 h ≈ 5 cycles, référence de qualité | Non (pas de stades sur l'app) ; score global dans le cache Garmin |
| **Sommeil (placement)** | « six to eight hours of sleep in each twenty-four-hour cycle, and the consistency of that placement » | `chunk_250` | Régularité du coucher = critère à part entière | Oui (moyenne circulaire sur 7 nuits) |
| **Lumière matinale** | « look in the direction of the sun for at least five to ten minutes… within the first thirty to sixty minutes of waking up » | `chunk_101` | **5–10 min**, fenêtre **+30 à +60 min** après le lever | Non (pas de capteur de lumière) → rappel temporel |
| **Caféine** | « Avoid caffeine in the eight to ten hours before bed… sensitive may have to avoid in the twelve hours » | `chunk_399` | **8–10 h** avant le coucher ; **12 h** si sensible | Non (pas d'ingestion mesurée) → rappel temporel |
| **Caféine (auto-test)** | « waking after seven to eight hours of sleep and still not feeling alert, you may try avoiding caffeine in the eight to ten or even twelve hours prior to sleep » | `chunk_414` | Le seuil doit être **ajusté si réveil non reposé** | Partiel (durée oui, ressenti non) |
| **Écrans / lumière du soir** | « avoid viewing bright artificial light in the full six-hour period prior to [temperature minimum] » ; « minimum… two hours before you typically wake up » | `chunk_211`, `chunk_209` | Temp. mini = **lever moyen − 2 h** ; éviter lumière vive de **tempMin − 8 h** (= lever − 10 h) à **tempMin** | Non (capteur lumière absent) → rappel temporel |
| **Écrans (filtre)** | « glasses that block both blue and green light… better » | `chunk_464` | Bleu **et** vert, pas bleu seul | Non → contenu du message seulement |
| **NSDR** | « Do a non-sleep deep rest session for 10 to 30 minutes… Ideally once per day » | `chunk_982`, `chunk_1028` | **10–30 min**, 1×/jour idéal | Déclenchement oui (durée de nuit), séance non mesurée |
| **NSDR (limite)** | « NSDR won't necessarily reduce the amount of nighttime sleep you need, but it may very well improve the quality » | `chunk_366` | **Jamais présenter comme substitut de sommeil** | Règle de rédaction |
| **Calme / stress** | « doing one to three physiological sighs is a great tool when stress hits and doing five minutes on repeat can buffer us » | `chunk_904`, `chunk_914` | **1–3 soupirs** immédiats ; **5 min** cycliques en prévention | Stress mesuré par tendance, soupir non mesuré |
| **Pas** | « Seven thousand steps per day is a good goal, and ten thousand is even better » | `chunk_574` | **7 000** = seuil basal ; **10 000** = optimal | Oui (`SensorHistory.STEP_COUNT`) |
| **Pas (épidémiologie)** | « at least seven thousand steps per day… significantly lower mortality risk » (JAMA Network Open 2021, n = 2 110) | `chunk_576` | Confirme 7 000 | — |
| **Pas (démence)** | « optimal dose… just shy of 10,000 steps per day » (n = 78 340) | `chunk_578` | Confirme ~10 000 | — |
| **Pas (micro-pauses)** | « walk five to ten minutes after meals… at least five minutes for every thirty minutes of sitting » | `chunk_574` | 5 min / 30 min assis | Partiel (position non mesurée) |
| **Température** | « Keep your bedroom between 65 and 68 degrees Fahrenheit, and a maximum of 70 » ; « warm your extremities » | `chunk_298` | 18–20 °C, max 21 °C | **Non** (capteur ambiant absent) → `notMeasured` |

## Confrontation aux données réelles (archivées dans `watch-data-2026-11-25.md`)

- **Sommeil** : 3 nuits sur 7 sous le seuil de 7 h (6 h 44, 4 h 19, 6 h 44) ;
  moyenne 6 h 52. Le message « sommeil insuffisant » est donc justifié par le
  livre sur **43 % des nuits observées**, pas par une supposition.
- **Dodo** : moyenne circulaire **23 h 24**. Le déclenchement actuel du message
  « Stimulants » est `dodo − 8 h = 15 h 24`. Le livre dit **8 à 10 h** : 15 h 24
  est la **borne la plus tardive** ; 13 h 24 (10 h) serait plus protecteur.
  Décision : garder 8 h par défaut, proposer 10/12 h quand le réveil est
  signalé non reposé (`chunk_414`), mais ce ressenti n'est pas mesurable sur la
  montre → reste une option de réglage, pas une mesure.
- **Écrans** : le déclenchement actuel `dodo − 60 min = 22 h 24` est **cohérent
  mais tardif** au regard du livre. Le lever moyen calculé est **06 h 25**,
  donc température minimale **04 h 25** et fenêtre « lumière vive à éviter »
  **20 h 25 → 04 h 25**. Recommandation : avancer le rappel à **20 h 25**
  (lever − 10 h) et garder 22 h 24 comme rappel de dernier recours.
- **NSDR** : la durée dynamique actuelle 30 / 20 / 10 / 10 min reste **dans la
  plage 10–30 min** du livre. Le libellé doit cependant préciser « meilleure
  qualité de sommeil », pas « rattraper une nuit » (`chunk_366`).
- **Pas** : l'objectif pondéré par la fenêtre lever/coucher est **notre choix de
  design**, pas une règle du livre. Le livre donne un objectif **quotidien fixe**
  (7 000 / 10 000). À conserver comme objectif de référence et à afficher
  clairement comme tel ; la pondération doit être documentée comme heuristique.
- **Calme** : le seuil de tendance de stress est un proxy. Le livre recommande
  une action (1–3 soupirs), pas un seuil chiffré de stress : ne pas présenter le
  proxy comme une mesure validée.

## Ce que le livre NE fournit PAS

- Pas de seuil chiffré de **score de sommeil** (le livre parle de durée,
  d'architecture et de régularité ; le score Garmin est une invention
  constructeur, non un protocole).
- Pas de seuil de **Body Battery** : c'est une métrique Garmin. Un seuil à 30
  est une heuristique locale cohérente avec les valeurs observées (bas moyen
  22), **pas** une recommandation de *Protocols*.
- Pas de mesure de **lumière ambiente**, d'**ingestion de caféine**, de
  **température de chambre** ni de **ressenti au réveil** sur le FR955 :
  ces catégories restent des rappels temporels ou `notMeasured`.
