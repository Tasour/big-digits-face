// App compagnon du cadran Big Digits : un buzz court et discret aux memes
// rappels Protocoles. Le cadran garde les popups et le score d'habitude ;
// cette app apporte la vibration et des donnees historiques (SensorHistory,
// Weather) que la watch face ne peut pas exploiter.
using Toybox.Application as App;
using Toybox.Attention;
using Toybox.Background;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Position;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.ActivityMonitor;
using Toybox.Weather;
using Toybox.WatchUi as Ui;

const DAY_SECONDS = 86400;

function dayIndex() as Lang.Number {
    return Time.now().value() / DAY_SECONDS;
}

function loadNumber(key as Lang.String) as Lang.Number {
    var v = App.Storage.getValue(key);
    if (v != null && v instanceof Lang.Number) { return v as Lang.Number; }
    return 0;
}

function dayMinutes() as Lang.Number {
    var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    return now.hour * 60 + now.min;
}

function bedMinutes() as Lang.Number {
    var p = UserProfile.getProfile();
    if (p != null && p has :upcomingSleepTime && p.upcomingSleepTime != null) {
        var d = Gregorian.info(p.upcomingSleepTime, Time.FORMAT_SHORT);
        return d.hour * 60 + d.min;
    }
    return 1380; // 23:00 par defaut
}

function sunsetMinutes() as Lang.Number {
    if (Toybox has :Weather && Weather has :getSunset) {
        var pos = Position.getInfo();
        if (pos != null && pos.position != null) {
            var deg = pos.position.toDegrees();
            var loc = new Position.Location({
                :latitude => deg[0], :longitude => deg[1], :format => :degrees
            });
            var moment = Weather.getSunset(loc, Time.now());
            if (moment != null) {
                var d = Gregorian.info(moment, Time.FORMAT_SHORT);
                return d.hour * 60 + d.min;
            }
        }
    }
    return 1050; // 17:30 repli
}

function recentStress() as Lang.Number {
    if (Toybox has :SensorHistory && SensorHistory has :getStressHistory) {
        var iter = SensorHistory.getStressHistory({:period => new Time.Duration(3600)});
        if (iter != null) {
            var sample = iter.next();
            if (sample != null && sample.data != null) {
                return sample.data as Lang.Number;
            }
        }
    }
    var info = ActivityMonitor.getInfo();
    if (info != null && info.stressScore != null) {
        return info.stressScore as Lang.Number;
    }
    return 0;
}

function sleepShort() as Lang.Boolean {
    var p = UserProfile.getProfile();
    if (p == null || !(p has :sleepTime) || p.sleepTime == null) { return false; }
    return (p.sleepTime as Time.Duration).value() < 420 * 60;
}

function nearBed(target as Lang.Number, now as Lang.Number) as Lang.Boolean {
    var delta = bedMinutes() - now;
    return delta >= target - 2 && delta <= target + 2;
}

function wakeWindow(now as Lang.Number) as Lang.Boolean {
    var p = UserProfile.getProfile();
    if (p == null || !(p has :upcomingWakeTime) || p.upcomingWakeTime == null) { return false; }
    var wake = Gregorian.info(p.upcomingWakeTime, Time.FORMAT_SHORT);
    var w = wake.hour * 60 + wake.min;
    var delta = now - w;
    return delta >= 0 && delta <= 30 && sleepShort();
}

function stepsShort() as Lang.Boolean {
    var info = ActivityMonitor.getInfo();
    if (info == null) { return true; }
    var steps = 0;
    var goal = 0;
    if (info.steps != null) { steps = info.steps as Lang.Number; }
    if (info.stepGoal != null) { goal = info.stepGoal as Lang.Number; }
    if (goal <= 0) { return steps < 7000; }
    return steps < goal * 0.85;
}

// Un seul evenement temporel peut etre enregistre : on le recharge a chaque
// reveil, avec le prochain creneau utile.
function registerNext() as Void {
    var now = dayMinutes();
    var cands = [420, 750, 900, 1050, 1110, 1320, 1350] as Lang.Array;
    cands.add(sunsetMinutes());
    cands.add(bedMinutes() - 480);
    cands.add(bedMinutes() - 60);

    // tri insertion (tableau court)
    for (var i = 1; i < cands.size(); i++) {
        var v = cands[i] as Lang.Number;
        var j = i - 1;
        while (j >= 0 && (cands[j] as Lang.Number) > v) {
            cands[j + 1] = cands[j];
            j--;
        }
        cands[j + 1] = v;
    }

    var wait = 1440;
    for (var i = 0; i < cands.size(); i++) {
        var c = cands[i] as Lang.Number;
        if (c > now && c - now < wait) { wait = c - now; }
    }
    if (wait == 1440) { wait = 1440 - now; }
    if (wait < 1) { wait = 1; }
    Background.registerForTemporalEvent(new Time.Duration(wait * 60));
}

function buzzOnce(slot as Lang.Number) as Void {
    var key = "buzz.day." + slot.format("%d");
    if (loadNumber(key) == dayIndex()) { return; }
    App.Storage.setValue(key, dayIndex());
    if (!(Attention has :vibrate)) { return; }
    var settings = System.getDeviceSettings();
    if (settings has :vibrateOn && settings.vibrateOn != null && !settings.vibrateOn) { return; }
    Attention.vibrate([new Attention.VibeProfile(60, 120)]);
}

function evaluateAndBuzz() as Void {
    var now = dayMinutes();
    var h = now / 60;
    var m = now % 60;
    var st = recentStress();
    var slot = -1;

    if (wakeWindow(now)) {
        slot = 700;
    } else if (h == 12 && m >= 30 && m < 31) {
        slot = 1230;
    } else if (nearBed(480, now)) {
        slot = 1500;
    } else if ((now - sunsetMinutes()).abs() <= 2) {
        slot = 1730;
    } else if (h == 18 && m >= 30 && m < 31 && stepsShort()) {
        slot = 1830;
    } else if (st > 50 || (sleepShort() && h >= 10 && h <= 16)) {
        slot = 2100;
    } else if (nearBed(60, now)) {
        slot = 2200;
    } else if (h == 22 && m >= 30 && m < 31 && st > 40) {
        slot = 2230;
    }

    if (slot >= 0) { buzzOnce(slot); }
}

(:background)
class BuzzDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        evaluateAndBuzz();
        registerNext();
        Background.exit(null);
    }
}

class BuzzView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL,
                    "Protocoles Buzz actif",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class BuzzApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary or Null) as Void {
        registerNext();
    }

    function getInitialView() {
        return [new BuzzView()];
    }

    function getServiceDelegate() {
        return [new BuzzDelegate()];
    }
}
