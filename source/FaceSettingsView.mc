// Réglages sur la montre, accessibles via UP/MENU → Cadran → Personnaliser.
using Toybox.Application;
using Toybox.Lang;
using Toybox.WatchUi as Ui;

// P1 : le bridge de complications remplacera ce stub par Complications.exitTo().
function handleComplicationPress() as Lang.Boolean {
    return false;
}

class BigDigitsSettingsView extends Ui.Menu2 {
    function initialize() {
        Menu2.initialize(null);
        setTitle("Réglages");
        addItem(new Ui.ToggleMenuItem("Secondes", null, :seconds,
                settingFlag("face.showSeconds") != 0, null));
        addItem(new Ui.ToggleMenuItem("Rappels", null, :popups,
                settingFlag("face.showPopups") != 0, null));
    }
}

class BigDigitsSettingsDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId();
        if (id == :seconds) {
            Application.Storage.setValue("face.showSeconds",
                                         (item as Ui.ToggleMenuItem).isEnabled() ? 1 : 0);
        } else if (id == :popups) {
            Application.Storage.setValue("face.showPopups",
                                         (item as Ui.ToggleMenuItem).isEnabled() ? 1 : 0);
        }
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }
}
