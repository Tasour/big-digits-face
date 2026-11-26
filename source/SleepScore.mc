// Regle du score de sommeil Garmin (ADR-0015) : un score strictement inferieur
// a 70 ajoute l'equivalent d'un pas de stress (10 points) au score NSDR du
// cadran. Score absent = -1 : aucun effet, jamais de valeur inventee.
using Toybox.Lang;

const SLEEP_SCORE_THRESHOLD = 70;
const SLEEP_SCORE_STEP = 10;

function sleepScoreBonus(score as Lang.Number) as Lang.Number {
    if (score >= 0 && score < SLEEP_SCORE_THRESHOLD) { return SLEEP_SCORE_STEP; }
    return 0;
}

function effectiveStress(stress as Lang.Number, score as Lang.Number) as Lang.Number {
    return stress + sleepScoreBonus(score);
}
