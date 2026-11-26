// Le bandeau ne doit pas recouvrir les secondes du cadran.
using Toybox.Lang;
using Toybox.Test;

(:test)
function popupTopOn955(logger as Test.Logger) as Lang.Boolean {
    return popupTop(260) == 71;
}

(:test)
function popupHeightOn955(logger as Test.Logger) as Lang.Boolean {
    return popupHeight(260) == 117;
}

(:test)
function popupDoesNotCoverSeconds(logger as Test.Logger) as Lang.Boolean {
    return !popupCoversSeconds(260, 232);
}

(:test)
function popupFitsSmallScreen(logger as Test.Logger) as Lang.Boolean {
    var secondsY = (240 * 232) / 260;
    return !popupCoversSeconds(240, secondsY) && popupTop(240) + popupHeight(240) < 240;
}
