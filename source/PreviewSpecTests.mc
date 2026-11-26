// Tests de l'apercu des rappels : ordre, numerotation, absence de donnee.
using Toybox.Lang;
using Toybox.Graphics;
using Toybox.Test;

function previewLabels() as Lang.Array {
    return [
        ["Reveil", "Lever de soleil"],
        ["Repas", "Marche apres repas"],
        ["Stimulants", "Pas de cafeine"],
        ["Soleil", "Coucher solaire"],
        ["Pas", "Marche 5 min"],
        ["NSDR", "Repos 10-30 min"],
        ["Ecrans", "Ecrans off"],
        ["Calme", "Soupirs"]
    ] as Lang.Array;
}

function previewConditions() as Lang.Array {
    return [
        "lever 07:00", "12:30", "coucher 22:00 - 8h", "coucher 20:30",
        "pas 3000/7000", "stress 62", "coucher 22:00 - 1h", "stress 62"
    ] as Lang.Array;
}

(:test)
function previewHasEightSteps(logger as Test.Logger) as Lang.Boolean {
    return previewCount() == 8;
}

(:test)
function previewFirstIsApercu(logger as Test.Logger) as Lang.Boolean {
    var p = previewSpec(0, previewLabels(), previewConditions());
    return (p.get(:title) as Lang.String).find("APERCU") != null &&
           (p.get(:ctx) as Lang.String).find("1/8") != null;
}

(:test)
function previewLastIsNumbered(logger as Test.Logger) as Lang.Boolean {
    var p = previewSpec(7, previewLabels(), previewConditions());
    return (p.get(:ctx) as Lang.String).find("8/8") != null;
}

(:test)
function previewKeepsMessage(logger as Test.Logger) as Lang.Boolean {
    var p = previewSpec(7, previewLabels(), previewConditions());
    return (p.get(:msg) as Lang.String).equals("Soupirs");
}

(:test)
function previewMarksNotMeasured(logger as Test.Logger) as Lang.Boolean {
    var conds = previewConditions();
    conds[3] = "notMeasured";
    var p = previewSpec(3, previewLabels(), conds);
    return (p.get(:ctx) as Lang.String).find("notMeasured") != null;
}

(:test)
function previewHasColor(logger as Test.Logger) as Lang.Boolean {
    var p = previewSpec(0, previewLabels(), previewConditions());
    return (p.get(:color) as Lang.Number) == Graphics.COLOR_ORANGE;
}
