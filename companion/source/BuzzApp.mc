// App compagnon du cadran Big Digits : buzz court, diagnostic des donnees
// utilisees par les algorithmes et panneau de test du rendu.
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
var gMetrics = [] as Lang.Array;

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
    return 1380;
}

function rawSunsetMinutes() as Lang.Number or Null {
    if (!(Toybox has :Weather) || !(Weather has :getSunset)) { return null; }
    var pos = Position.getInfo();
    if (pos == null || pos.position == null) { return null; }
    var deg = pos.position.toDegrees();
    var loc = new Position.Location({
        :latitude => deg[0], :longitude => deg[1], :format => :degrees
    });
    var moment = Weather.getSunset(loc, Time.now());
    if (moment == null) { return null; }
    var d = Gregorian.info(moment, Time.FORMAT_SHORT);
    return d.hour * 60 + d.min;
}

function sunsetMinutes() as Lang.Number {
    var sun = rawSunsetMinutes();
    return sun == null ? 1050 : sun as Lang.Number;
}

function sensorSample(method as Lang.Symbol) as Lang.Number or Null {
    if (!(Toybox has :SensorHistory)) { return null; }
    if (method == :stress) {
        if (!(SensorHistory has :getStressHistory)) { return null; }
        var it = SensorHistory.getStressHistory({:period => new Time.Duration(3600)});
        if (it == null) { return null; }
        var s = it.next();
        if (s == null || s.data == null) { return null; }
        return s.data as Lang.Number;
    }
    if (!(SensorHistory has :getBodyBatteryHistory)) { return null; }
    var it2 = SensorHistory.getBodyBatteryHistory({:period => new Time.Duration(3600)});
    if (it2 == null) { return null; }
    var s2 = it2.next();
    if (s2 == null || s2.data == null) { return null; }
    return s2.data as Lang.Number;
}

function recentStress() as Lang.Number {
    var s = sensorSample(:stress);
    if (s != null) { return s as Lang.Number; }
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

function registerNext() as Void {
    var now = dayMinutes();
    var cands = [420, 750, 900, 1050, 1110, 1320, 1350] as Lang.Array;
    cands.add(sunsetMinutes());
    cands.add(bedMinutes() - 480);
    cands.add(bedMinutes() - 60);

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
    var sd = now - sunsetMinutes();
    if (sd < 0) { sd = -sd; }

    if (wakeWindow(now)) {
        slot = 700;
    } else if (h == 12 && m >= 30 && m < 31) {
        slot = 1230;
    } else if (nearBed(480, now)) {
        slot = 1500;
    } else if (sd <= 2) {
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

// --- Diagnostic des donnees ------------------------------------------------

function checkStorage() as Lang.Boolean {
    var key = "diag.probe";
    App.Storage.setValue(key, 42);
    var v = App.Storage.getValue(key);
    App.Storage.setValue(key, 0);
    return v != null && v instanceof Lang.Number && (v as Lang.Number) == 42;
}

function profileHasWake() as Lang.Boolean {
    var p = UserProfile.getProfile();
    return p != null && p has :upcomingWakeTime && p.upcomingWakeTime != null;
}

function profileHasSleep() as Lang.Boolean {
    var p = UserProfile.getProfile();
    return p != null && p has :sleepTime && p.sleepTime != null;
}

function refreshMetrics() as Void {
    var info = ActivityMonitor.getInfo();
    var prof = UserProfile.getProfile();
    var body = false;
    if (prof != null) {
        body = prof.birthYear != null && prof.height != null &&
               prof.weight != null && prof.gender != null;
    }
    var settings = System.getDeviceSettings();

    gMetrics = [
        ["Horloge", System.getClockTime() != null],
        ["Réglages", settings != null],
        ["Réveil", profileHasWake()],
        ["Sommeil", profileHasSleep()],
        ["Corps", body],
        ["Pas", info != null && info.steps != null],
        ["Objectif", info != null && info.stepGoal != null],
        ["Stress", info != null && info.stressScore != null],
        ["Position", Position.getInfo() != null],
        ["Météo", rawSunsetMinutes() != null],
        ["Stress 1h", sensorSample(:stress) != null],
        ["Battery", sensorSample(:bodybattery) != null],
        ["Buzz", Attention has :vibrate],
        ["Background", Background has :registerForTemporalEvent],
        ["Stockage", checkStorage()]
    ] as Lang.Array;
}

function drawGlyph(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, ok as Lang.Boolean) as Void {
    dc.setColor(ok ? Graphics.COLOR_GREEN : Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    if (ok) {
        dc.drawLine(x - 4, y, x - 1, y + 3);
        dc.drawLine(x - 1, y + 3, x + 5, y - 4);
    } else {
        dc.drawLine(x - 4, y - 4, x + 4, y + 4);
        dc.drawLine(x + 4, y - 4, x - 4, y + 4);
    }
}

function weekdayLetters() as Lang.Array {
    var names = ["L", "M", "M", "J", "V", "S", "D"];
    var out = [] as Lang.Array;
    var dow = Gregorian.info(Time.now(), Time.FORMAT_SHORT).day_of_week;
    for (var i = 0; i < 7; i++) {
        var gi = (dow - 1 - i) % 7;
        if (gi < 0) { gi += 7; }
        out.add(names[(gi + 6) % 7]);
    }
    return out;
}

class DiagView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, 26, Graphics.FONT_SMALL, "DIAGNOSTIC",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        // Deux colonnes : 8 lignes par colonne, libelles courts et non coupes.
        for (var i = 0; i < gMetrics.size(); i++) {
            var row = gMetrics[i] as Lang.Array;
            var col = i / 8;
            var idx = i % 8;
            var x = col == 0 ? 18 : 136;
            var y = 42 + idx * 20;
            drawGlyph(dc, x, y, row[1] as Lang.Boolean);
            dc.drawText(x + 12, y, Graphics.FONT_SYSTEM_XTINY, row[0] as Lang.String,
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class TestPanelView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var x = 20;
        var y = 61;
        var w = 220;
        var h = 138;
        var border = 3;
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + border, y + border, w - 2 * border, h - 2 * border);

        var cx = x + w / 2;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y + 20, Graphics.FONT_SMALL, "TEST", justify);
        dc.drawText(cx, y + 48, Graphics.FONT_SYSTEM_XTINY, "Panneau de test", justify);

        var side = 30;
        var gap = 0;
        var bx = cx - (7 * side + 6 * gap) / 2 + side / 2;
        var by = y + 108;
        var letters = weekdayLetters();
        for (var i = 0; i < 7; i++) {
            var px = bx + i * (side + gap) - side / 2;
            var py = by - side / 2;
            var done = (0x05 & (1 << i)) != 0;
            if (done) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(px, py, side, side);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(px, py, side, side);
            }
            dc.drawText(px + side / 2, by, Graphics.FONT_XTINY, letters[i] as Lang.String, justify);
        }
    }
}

class TestPanelDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onPress() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }
}

class DiagDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onPress() as Lang.Boolean {
        refreshMetrics();
        Ui.pushView(new TestPanelView(), new TestPanelDelegate(), Ui.SLIDE_IMMEDIATE);
        return true;
    }
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

class BuzzApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary or Null) as Void {
        refreshMetrics();
        registerNext();
    }

    function getInitialView() {
        return [new DiagView(), new DiagDelegate()];
    }

    function getServiceDelegate() {
        return [new BuzzDelegate()];
    }
}
