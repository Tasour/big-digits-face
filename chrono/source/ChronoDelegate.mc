using Toybox.Lang;
using Toybox.WatchUi;

class ChronoDelegate extends WatchUi.InputDelegate {

    hidden var _view;

    function initialize(view as ChronoView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            _view.toggle();
            return true;
        } else if (key == WatchUi.KEY_LIGHT || key == WatchUi.KEY_LAP) {
            _view.lap();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            _view.exit();
            return true;
        }
        return false;
    }

    // Bouton BACK (bas droite) : remise a zero.
    function onBack() as Lang.Boolean {
        _view.reset();
        return true;
    }
}
