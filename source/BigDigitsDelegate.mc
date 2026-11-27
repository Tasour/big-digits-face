using Toybox.Lang;
using Toybox.WatchUi;

// Accuse de reception d'un rappel : bouton START/ENTER (KEY_ENTER).
class BigDigitsDelegate extends WatchUi.WatchFaceDelegate {

    function initialize() {
        WatchFaceDelegate.initialize();
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        if (gBigDigitsView == null) { return false; }
        if ((gBigDigitsView as BigDigitsView).hasActivePopup()) {
            return (gBigDigitsView as BigDigitsView).dismissWithButton(WatchUi.KEY_ESC);
        }
        return (gBigDigitsView as BigDigitsView).onButtonPress();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        if (gBigDigitsView == null) { return false; }
        if ((gBigDigitsView as BigDigitsView).hasActivePopup()) {
            return (gBigDigitsView as BigDigitsView).dismissWithButton(keyEvent.getKey());
        }
        return false;
    }

    // Le SDK 9.3.0 documente onTap comme disponible uniquement en mode
    // configuration du cadran. On le garde comme accuse quand il est livré,
    // sans en faire la voie principale (ADR-0012 révisé).
    function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
        if (gBigDigitsView != null) {
            if (gBigDigitsView.isPreviewMode()) {
                (gBigDigitsView as BigDigitsView).nextPreview();
                return true;
            }
            if ((gBigDigitsView as BigDigitsView).hasActivePopup()) {
                // Appui court : on efface sans cocher d'habitude.
                return (gBigDigitsView as BigDigitsView).dismissWithButton(WatchUi.KEY_ESC);
            }
            return false;
        }
        return false;
    }
}
