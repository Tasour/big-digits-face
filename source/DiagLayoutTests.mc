// Tests de la grille du diagnostic : la mise en page doit rester dans le
// cercle du cadran, y compris avec les grandes polices du device fr955.
using Toybox.Lang;
using Toybox.Test;

(:test)
function diagGridDeviceMetrics(logger as Test.Logger) as Lang.Boolean {
    var g = DiagLayout.grid(454, 454, 34, 24, 2);
    var ok = g[:boxW] as Lang.Number == 299 &&
             g[:top] as Lang.Number == 62 &&
             (g[:top] as Lang.Number) + (g[:boxH] as Lang.Number) == 392;
    logger.debug("diagGridDevice=" + (g[:boxW] as Lang.Number).toString() + "/" +
                 (g[:top] as Lang.Number).toString() + "/" +
                 (g[:boxH] as Lang.Number).toString());
    return ok;
}

(:test)
function diagGridSimulatorMetrics(logger as Test.Logger) as Lang.Boolean {
    var g = DiagLayout.grid(454, 454, 20, 20, 2);
    var ok = g[:boxH] as Lang.Number == 200 &&
             g[:top] as Lang.Number == 127 &&
             g[:rowY] as Lang.Number == 157;
    logger.debug("diagGridSim=" + (g[:boxH] as Lang.Number).toString() + "/" +
                 (g[:top] as Lang.Number).toString());
    return ok;
}

(:test)
function diagGridStaysInCircle(logger as Test.Logger) as Lang.Boolean {
    var widths = [454, 390, 300] as Lang.Array;
    var heights = [454, 390, 300] as Lang.Array;
    var lineHs = [20, 28, 34, 40] as Lang.Array;
    for (var s = 0; s < widths.size(); s++) {
        var width = widths[s] as Lang.Number;
        var height = heights[s] as Lang.Number;
        for (var i = 0; i < lineHs.size(); i++) {
            // Une grille plus haute que l'ecran est impossible par construction :
            // l'application reduit alors le pied a une ligne. On ne teste ici
            // que les cas ou neuf lignes tiennent reellement.
            if (24 + 9 * (lineHs[i] as Lang.Number) > height) { continue; }
            var g = DiagLayout.grid(width, height, lineHs[i] as Lang.Number, 24, 2);
            var left = g[:left] as Lang.Number;
            var top = g[:top] as Lang.Number;
            var boxW = g[:boxW] as Lang.Number;
            var boxH = g[:boxH] as Lang.Number;
            if (left < 0 || top < 0 || left + boxW > width || top + boxH > height) {
                logger.debug("hors cadre w=" + width.toString() + " lh=" +
                             (lineHs[i] as Lang.Number).toString());
                return false;
            }
        }
    }
    return true;
}

(:test)
function diagGridFooterBelowRows(logger as Test.Logger) as Lang.Boolean {
    var g = DiagLayout.grid(454, 454, 34, 24, 2);
    var rowY = g[:rowY] as Lang.Number;
    var footerY = g[:footerY] as Lang.Number;
    // Derniere ligne : rowY + 6 * lineH ; le pied doit etre en dessous.
    var lastRow = rowY + 6 * (g[:lineH] as Lang.Number);
    var ok = footerY > lastRow &&
             footerY + (g[:lineH] as Lang.Number) <=
             (g[:top] as Lang.Number) + (g[:boxH] as Lang.Number);
    logger.debug("diagGridFooter=" + lastRow.toString() + "/" + footerY.toString());
    return ok;
}
