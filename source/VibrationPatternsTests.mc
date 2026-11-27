// Tests des signatures vibration (module pur, sans materiel).
using Toybox.Lang;
using Toybox.Test;

(:test)
function vibeHasFivePatterns(logger as Test.Logger) as Lang.Boolean {
    return VibrationPatterns.COUNT == 5 && VibrationPatterns.names().size() == 5;
}

(:test)
function vibeAllPatternsValid(logger as Test.Logger) as Lang.Boolean {
    for (var i = 0; i < VibrationPatterns.COUNT; i++) {
        if (!VibrationPatterns.valid(i)) { return false; }
    }
    return true;
}

(:test)
function vibeRejectsOutOfRange(logger as Test.Logger) as Lang.Boolean {
    return !VibrationPatterns.valid(-1) && !VibrationPatterns.valid(5);
}

(:test)
function vibeHasSilences(logger as Test.Logger) as Lang.Boolean {
    var steps = VibrationPatterns.pattern(0);
    var silent = 0;
    for (var i = 0; i < steps.size(); i++) {
        if (((steps[i] as Lang.Array)[0] as Lang.Number) == 0) { silent++; }
    }
    return silent == 2;
}

(:test)
function vibeUnderBudget(logger as Test.Logger) as Lang.Boolean {
    return VibrationPatterns.totalMs(1) <= 1200 &&
           VibrationPatterns.totalMs(4) <= 1200;
}

(:test)
function vibeLongUniqueHasOneStep(logger as Test.Logger) as Lang.Boolean {
    return VibrationPatterns.pattern(3).size() == 1;
}

(:test)
function vibeDefaultIsCourtCourtLong(logger as Test.Logger) as Lang.Boolean {
    return VibrationPatterns.VIBRATION_DEFAULT == 0 &&
           (VibrationPatterns.names()[0] as Lang.String).equals("Court-court-long");
}
