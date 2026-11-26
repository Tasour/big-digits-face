// Tests de la regle ADR-0015.
using Toybox.Lang;
using Toybox.Test;

(:test)
function sleepBonusBelowThreshold(logger as Test.Logger) as Lang.Boolean {
    return sleepScoreBonus(69) == 10;
}

(:test)
function sleepBonusAtThreshold(logger as Test.Logger) as Lang.Boolean {
    return sleepScoreBonus(70) == 0;
}

(:test)
function sleepBonusWhenAbsent(logger as Test.Logger) as Lang.Boolean {
    return sleepScoreBonus(-1) == 0 && sleepScoreBonus(100) == 0;
}

(:test)
function effectiveStressAddsOneStep(logger as Test.Logger) as Lang.Boolean {
    return effectiveStress(45, 69) == 55 && effectiveStress(45, 85) == 45;
}
