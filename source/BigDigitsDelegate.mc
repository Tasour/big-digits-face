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
}
