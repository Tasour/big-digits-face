using Toybox.Lang;
using Toybox.Graphics;

// Specification pure de l'aperçu des huit rappels du cadran.
// Aucune horloge, aucun Stockage, aucun test de seuil : les valeurs mesurées
// sont fournies par la vue sous forme de textes, ou "notMeasured".

function previewColor(index as Lang.Number) as Lang.Number {
    if (index == 0) { return Graphics.COLOR_ORANGE; }
    if (index == 1 || index == 4) { return Graphics.COLOR_BLUE; }
    if (index == 3 || index == 5 || index == 6 || index == 7) {
        return Graphics.COLOR_PURPLE;
    }
    return Graphics.COLOR_PURPLE;
}

function previewSpec(index as Lang.Number, labels as Lang.Array,
                     conditions as Lang.Array) as Lang.Dictionary {
    var pair = labels[index] as Lang.Array;
    var title = "APERCU " + (pair[0] as Lang.String);
    var cond = conditions[index] as Lang.String;
    return {
        :index => index,
        :title => title,
        :msg => pair[1] as Lang.String,
        :ctx => (index + 1).format("%d") + "/8 " + cond,
        :color => previewColor(index)
    } as Lang.Dictionary;
}

function previewCount() as Lang.Number {
    return 8;
}
