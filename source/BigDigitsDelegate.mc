using Toybox.Lang;
using Toybox.WatchUi;

// Accuse de reception d'un rappel : bouton START/ENTER (KEY_ENTER).
class BigDigitsDelegate extends WatchUi.WatchFaceDelegate {

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        if (gBigDigitsView != null) {
            return gBigDigitsView.onButtonPress();
        }
        return false;
    }

    // Le SDK 9.3.0 documente onTap comme disponible uniquement en mode
    // configuration du cadran. On le garde comme accuse quand il est livré,
    // sans en faire la voie principale (ADR-0012 révisé).
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        if (gBigDigitsView != null) {
            gBigDigitsView.dismissPopup();
            return true;
        }
        return false;
    }
}
