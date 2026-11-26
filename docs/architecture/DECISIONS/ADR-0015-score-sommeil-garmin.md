# ADR-0015 — Score de sommeil Garmin comme entrée du repos NSDR

- Statut : accepté
- Date : 2026-11-26
- Décideurs : propriétaire du projet
- Drivers : manque de score de sommeil natif exposé par `ActivityMonitor` sur `fr955`, disponibilité d'une complication système
- Contrat lié : `docs/architecture/DATA-SOURCES.md`

## Contexte

`ActivityMonitor` sur `fr955` n'expose pas le score de sommeil Garmin (0–100). Le SDK fournit en revanche `Complications.COMPLICATION_TYPE_SLEEP_SCORE` (valeur documentée `42`, API 6.0.2). Seules les **watch faces** peuvent s'abonner aux complications : une watch-app comme le compagnon ne peut pas les lire. Le score doit donc être lu et appliqué par le cadran.

La règle du livre ne donne pas de seuil pour ce score propriétaire. La décision produit est : un score strictement inférieur à 70 ajoute **l'équivalent d'un pas de stress**, soit 10 points sur l'échelle de stressused par le cadran, plafonné au score NSDR maximal. Score absent = `-1`, aucun effet.

## Options écartées

- Lire le score depuis le compagnon : impossible, `ComplicationSubscriber` est refusé pour `watch-app`.
- Inventer un seuil « médical » : refusé, aucune source dans le corpus.
- Remplacer les signaux existants : refusé, le score n'est qu'un appoint d'un cran.

## Décision

- Le cadran lit la complication de type `42` et conserve `gSleepScore` dans `0..100`, ou `-1` si absente.
- `sleepScoreBonus(score)` renvoie `10` si `0 <= score < 70`, sinon `0`.
- `effectiveStress(stress, score) = stress + sleepScoreBonus(score)`.
- Le déclencheur NSDR et le choix de durée utilisent `effectiveStress`, pas le stress brut.
- Le score est affiché dans le contexte du rappel NSDR quand il est disponible.
- Le compagnon n'expose pas le score : `notMeasured` de son côté, sans valeur de substitution.

## Conséquences

- Positives : le signal manquant est récupéré sans cloud ni application téléphone ; la règle est bornée à un cran ; l'absence ne change pas le comportement.
- Négatives acceptées : le score dépend de la présence d'un fournisseur de complication sur la montre ; la valeur `42` est codée en dur car la constante n'est pas livrée sur `fr955`.
- À surveiller : si Garmin fournit un score different de 0–100, la plage est rejetée et le score reste `-1`.

## Preuves

- `source/SleepScore.mc` — fonctions pures `sleepScoreBonus()` et `effectiveStress()`.
- `source/SleepScoreTests.mc` — 4 tests : 69, 70, absent, ajout d'un pas.
- `source/BigDigitsView.mc` — lecture de la complication et application au rappel NSDR.
- Suite : 87 tests verts.

## Révision

Toute modification du seuil 70 ou du pas 10 exige un nouvel ADR. Le passage à une lecture côté compagnon exigerait une application watch-app autorisée à s'abonner, ce que le SDK refuse actuellement.
