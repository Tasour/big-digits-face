using Toybox.Application;
using Toybox.WatchUi;

class BigDigitsApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new BigDigitsView() ];
    }
}
