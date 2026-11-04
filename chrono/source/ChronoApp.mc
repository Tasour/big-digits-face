using Toybox.Application;
using Toybox.WatchUi;

class ChronoApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new ChronoView();
        return [view, new ChronoDelegate(view)];
    }
}
