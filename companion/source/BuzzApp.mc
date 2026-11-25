// App compagnon du cadran Big Digits : buzz, diagnostic des donnees et
// declencheurs enrichis (Weather, SensorHistory) que la watch face ne peut pas
// utiliser. La face reste le fallback visuel automatique.
using Toybox.Application as App;
using Toybox.Attention;
using Toybox.Background;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Timer;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.ActivityMonitor;
using Toybox.Communications;
using Toybox.Weather;
using Toybox.WatchUi as Ui;

(:background)
const DAY_SECONDS = 86400;
(:background)
var gMetrics as Lang.Array = [] as Lang.Array;
(:background)
var gLastEvent as Lang.String = "aucun";
(:background)
var gLastBuzz as Lang.String = "aucun";
(:background)
var gPending as Lang.Number = 0;
(:background)
var gEvents as Lang.Number = 0;
(:background)
var gReason as Lang.String = "aucun";
(:background)
var gBle as Lang.String = "aucun";
(:background)
var gSource as Lang.String = "local";
(:background)
var gDiagPage as Lang.Number = 0;
var gSending as Lang.Boolean = false;

(:background)
function dayIndex() as Lang.Number {
    return Time.now().value() / DAY_SECONDS;
}

(:background)
function loadNumber(key as Lang.String) as Lang.Number {
    var v = App.Storage.getValue(key);
    if (v != null && v instanceof Lang.Number) { return v as Lang.Number; }
    return 0;
}

(:background)
function loadString(key as Lang.String) as Lang.String {
    var v = App.Storage.getValue(key);
    if (v != null && v instanceof Lang.String) { return v as Lang.String; }
    return "aucun";
}

(:background)
function recordSleepEvent(kind as Lang.Symbol) as Void {
    var prefix = kind == :wake ? "sleep.wake." : "sleep.bed.";
    App.Storage.setValue(prefix + dayIndex().format("%d"), dayMinutes());
}

(:background)
function averageMinutes(prefix as Lang.String) as Lang.Number or Null {
    var sumS = 0.0;
    var sumC = 0.0;
    var n = 0;
    var today = dayIndex();
    for (var i = 0; i < 7; i++) {
        var v = App.Storage.getValue(prefix + (today - i).format("%d"));
        if (v != null && v instanceof Lang.Number) {
            var angle = 2.0 * Math.PI * (v as Lang.Number) / 1440.0;
            sumS += Math.sin(angle);
            sumC += Math.cos(angle);
            n++;
        }
    }
    if (n == 0) { return null; }
    var avg = Math.atan2(sumS / n, sumC / n) * 1440.0 / (2.0 * Math.PI);
    if (avg < 0) { avg += 1440; }
    return avg as Lang.Number;
}

(:background)
function sleepDurationMinutes() as Lang.Number or Null {
    var bed = App.Storage.getValue("sleep.bed." + (dayIndex() - 1).format("%d"));
    var wake = App.Storage.getValue("sleep.wake." + dayIndex().format("%d"));
    if (bed == null || wake == null) { return null; }
    if (!(bed instanceof Lang.Number) || !(wake instanceof Lang.Number)) { return null; }
    var d = (wake as Lang.Number) - (bed as Lang.Number);
    if (d < 0) { d += 1440; }
    if (d <= 0 || d > 900) { return null; }
    return d as Lang.Number;
}

(:background)
function clockText() as Lang.String {
    var t = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    return t.hour.format("%02d") + ":" + t.min.format("%02d");
}

(:background)
function dayMinutes() as Lang.Number {
    var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    return now.hour * 60 + now.min;
}

// Confiance : au moins trois couchers réels sur sept jours. En dessous,
// on utilise les heures configurées (UserProfile) et on le dit dans le diagnostic.
(:background)
function bedEventCount() as Lang.Number {
    var today = dayIndex();
    var n = 0;
    for (var i = 0; i < 7; i++) {
        var v = App.Storage.getValue("sleep.bed." + (today - i).format("%d"));
        if (v != null && v instanceof Lang.Number) { n++; }
    }
    return n;
}

(:background)
function eventConfidence() as Lang.Boolean {
    return bedEventCount() >= 3;
}

(:background)
function confidentAverage(prefix as Lang.String) as Lang.Number or Null {
    if (!eventConfidence()) { return null; }
    return averageMinutes(prefix);
}

(:background)
function nightDurations() as Lang.Array {
    var out = [] as Lang.Array;
    var today = dayIndex();
    for (var i = 1; i <= 7; i++) {
        var bed = App.Storage.getValue("sleep.bed." + (today - i).format("%d"));
        var wake = App.Storage.getValue("sleep.wake." + (today - i + 1).format("%d"));
        if (bed == null || wake == null) { continue; }
        if (!(bed instanceof Lang.Number) || !(wake instanceof Lang.Number)) { continue; }
        var d = (wake as Lang.Number) - (bed as Lang.Number);
        if (d < 0) { d += TIMING_DAY; }
        if (d > 0 && d <= 900) { out.add(d as Lang.Number); }
    }
    return out;
}

(:background)
function sleepDebt() as Lang.Number {
    var corr = loadCorrections(Time.now().value());
    if (corr != null && (corr[:debt7] as Lang.Number) >= 0) {
        return corr[:debt7] as Lang.Number;
    }
    return timingDebt7(nightDurations(), effectiveNeed());
}

// --- Corrections recues du telephone (ADR-0014) -----------------------------

(:background)
function effectiveNeed() as Lang.Number {
    var corr = loadCorrections(Time.now().value());
    if (corr != null) {
        var n = corr[:needMin] as Lang.Number;
        if (n > 0) { return n; }
    }
    return TIMING_SLEEP_MIN as Lang.Number;
}

(:background)
function saveCorrections(c as Lang.Dictionary) as Void {
    App.Storage.setValue("corr.exp", c[:exp] as Lang.Number);
    App.Storage.setValue("corr.need", c[:needMin] as Lang.Number);
    App.Storage.setValue("corr.score", c[:sleepScore] as Lang.Number);
    App.Storage.setValue("corr.debt", c[:debt7] as Lang.Number);
    App.Storage.setValue("corr.bedsd", c[:bedSD] as Lang.Number);
    App.Storage.setValue("corr.hrv", c[:hrvBase] as Lang.Number);
    App.Storage.setValue("corr.bb", c[:bbBase] as Lang.Number);
    App.Storage.setValue("corr.nsdr", c[:nsdrMin] as Lang.Number);
    App.Storage.setValue("corr.nsdr_at", c[:nsdrAt] as Lang.Number);
    App.Storage.setValue("corr.verdict", c[:verdict] as Lang.Number);
    App.Storage.setValue("corr.reason", c[:reasonCode] as Lang.Number);
    App.Storage.setValue("corr.conf", c[:confidence] as Lang.Number);
    App.Storage.setValue("corr.ts", c[:ts] as Lang.Number);
}

// Une correction n'est appliquee que si elle n'a pas expire. Sinon le calcul
// local reprend la main : aucun seuil telephone perime ne pilote un rappel.
(:background)
function loadCorrections(nowSeconds as Lang.Number) as Lang.Dictionary or Null {
    var exp = loadNumber("corr.exp");
    if (exp <= nowSeconds) { return null; }
    if (App.Storage.getValue("corr.need") == null) { return null; }
    return {
        :needMin => loadNumber("corr.need"), :sleepScore => loadNumber("corr.score"),
        :debt7 => loadNumber("corr.debt"), :bedSD => loadNumber("corr.bedsd"),
        :hrvBase => loadNumber("corr.hrv"), :bbBase => loadNumber("corr.bb"),
        :nsdrMin => loadNumber("corr.nsdr"), :nsdrAt => loadNumber("corr.nsdr_at"),
        :verdict => loadNumber("corr.verdict"), :reasonCode => loadNumber("corr.reason"),
        :confidence => loadNumber("corr.conf"), :exp => exp
    } as Lang.Dictionary;
}

(:background)
function correctionSource() as Lang.String {
    return loadCorrections(Time.now().value()) == null ? "local" : "connect";
}

(:background)
function alarmMinute() as Lang.Number or Null {
    // Sur fr955, `upcomingWakeTime` est signale non supporte par le compileur
    // (-l 3) : on utilise l'heure de reveal configuree `wakeTime`, qui est la
    // recurrence quotidienne equivalente. Le cadran garde `upcomingWakeTime`
    // quand il est disponible.
    var p = UserProfile.getProfile();
    if (p == null || !(p has :wakeTime) || p.wakeTime == null) { return null; }
    return ((p.wakeTime as Time.Duration).value() / 60) as Lang.Number;
}

(:background)
function bedTarget() as Lang.Number {
    var alarm = alarmMinute();
    if (alarm != null) { return timingAlarmBed(alarm as Lang.Number, 480); }
    return bedMinutes();
}

(:background)
function screensOffMinute() as Lang.Number {
    return timingScreensOff(bedTarget());
}

(:background)
function nightAlarm() as Lang.Boolean {
    var alarm = alarmMinute();
    if (alarm == null) { return false; }
    return timingNightAlarm(alarm as Lang.Number, wakeMinute());
}

(:background)
function bedtimeSD() as Lang.Number {
    var corr = loadCorrections(Time.now().value());
    if (corr != null && (corr[:bedSD] as Lang.Number) >= 0) {
        return corr[:bedSD] as Lang.Number;
    }
    var vals = [] as Lang.Array;
    var today = dayIndex();
    for (var i = 0; i < 7; i++) {
        var v = App.Storage.getValue("sleep.bed." + (today - i).format("%d"));
        if (v != null && v instanceof Lang.Number) { vals.add(v as Lang.Number); }
    }
    return timingCircularSD(vals);
}

(:background)
function wakeMinute() as Lang.Number {
    var avg = confidentAverage("sleep.wake.");
    if (avg != null) { return avg as Lang.Number; }
    var p = UserProfile.getProfile();
    if (p != null && p has :upcomingWakeTime && p.upcomingWakeTime != null) {
        var d = Gregorian.info(p.upcomingWakeTime as Time.Moment, Time.FORMAT_SHORT);
        return d.hour * 60 + d.min;
    }
    return 420;
}

(:background)
function bedMinutes() as Lang.Number {
    var avg = confidentAverage("sleep.bed.");
    if (avg != null) { return avg as Lang.Number; }
    var p = UserProfile.getProfile();
    if (p != null && p has :upcomingSleepTime && p.upcomingSleepTime != null) {
        var d = Gregorian.info(p.upcomingSleepTime as Time.Moment, Time.FORMAT_SHORT);
        return d.hour * 60 + d.min;
    }
    return 1380;
}

(:background)
function rawSunsetMinutes() as Lang.Number or Null {
    if (!(Toybox has :Weather) || !(Weather has :getSunset)) { return null; }
    var pos = Position.getInfo();
    if (pos == null || pos.position == null) { return null; }
    var deg = (pos.position as Position.Location).toDegrees();
    var loc = new Position.Location({
        :latitude => deg[0], :longitude => deg[1], :format => :degrees
    });
    var moment = Weather.getSunset(loc, Time.now());
    if (moment == null) { return null; }
    var d = Gregorian.info(moment, Time.FORMAT_SHORT);
    return d.hour * 60 + d.min;
}

(:background)
function rawSunriseMinutes() as Lang.Number or Null {
    if (!(Toybox has :Weather) || !(Weather has :getSunrise)) { return null; }
    var pos = Position.getInfo();
    if (pos == null || pos.position == null) { return null; }
    var deg = (pos.position as Position.Location).toDegrees();
    var loc = new Position.Location({
        :latitude => deg[0], :longitude => deg[1], :format => :degrees
    });
    var moment = Weather.getSunrise(loc, Time.now());
    if (moment == null) { return null; }
    var d = Gregorian.info(moment, Time.FORMAT_SHORT);
    return d.hour * 60 + d.min;
}

(:background)
function sunsetMinutes() as Lang.Number {
    var sun = rawSunsetMinutes();
    return sun == null ? 1050 : sun as Lang.Number;
}

(:background)
function sunriseMinutes() as Lang.Number {
    var sun = rawSunriseMinutes();
    return sun == null ? -1 : sun as Lang.Number;
}

(:background)
function sensorSample(method as Lang.Symbol) as Lang.Number or Null {
    if (!(Toybox has :SensorHistory)) { return null; }
    var it;
    if (method == :stress) {
        if (!(SensorHistory has :getStressHistory)) { return null; }
        it = SensorHistory.getStressHistory({:period => new Time.Duration(3600)});
    } else {
        if (!(SensorHistory has :getBodyBatteryHistory)) { return null; }
        it = SensorHistory.getBodyBatteryHistory({:period => new Time.Duration(3600)});
    }
    if (it == null) { return null; }
    var s = it.next();
    if (s == null || s.data == null) { return null; }
    return s.data as Lang.Number;
}

(:background)
function recentStress() as Lang.Number {
    var s = sensorSample(:stress);
    if (s != null) { return s as Lang.Number; }
    var info = ActivityMonitor.getInfo();
    if (info != null && info.stressScore != null) {
        return info.stressScore as Lang.Number;
    }
    return 0;
}

(:background)
function stressTrend() as Lang.Number {
    if (!(Toybox has :SensorHistory) || !(SensorHistory has :getStressHistory)) {
        return recentStress();
    }
    var it = SensorHistory.getStressHistory({:period => new Time.Duration(3600)});
    if (it == null) { return recentStress(); }
    var total = 0;
    var n = 0;
    for (var i = 0; i < 5; i++) {
        var s = it.next();
        if (s == null || s.data == null) { break; }
        total += s.data as Lang.Number;
        n++;
    }
    if (n == 0) { return recentStress(); }
    return total / n;
}

// Baseline robuste : mediane + MAD sur les echantillons disponibles.
(:background)
function sortNumbers(values as Lang.Array) as Lang.Array {
    for (var i = 1; i < values.size(); i++) {
        var v = values[i] as Lang.Number;
        var j = i - 1;
        while (j >= 0 && (values[j] as Lang.Number) > v) {
            values[j + 1] = values[j];
            j--;
        }
        values[j + 1] = v;
    }
    return values;
}

(:background)
function medianOf(values as Lang.Array) as Lang.Number {
    var n = values.size();
    if (n == 0) { return 0; }
    var sorted = sortNumbers(values);
    var mid = n / 2;
    if (n % 2 == 0) {
        return ((sorted[mid - 1] as Lang.Number) + (sorted[mid] as Lang.Number)) / 2;
    }
    return sorted[mid] as Lang.Number;
}

(:background)
function stressBaseline() as Lang.Dictionary {
    var vals = [] as Lang.Array;
    if (Toybox has :SensorHistory && SensorHistory has :getStressHistory) {
        var it = SensorHistory.getStressHistory({:period => new Time.Duration(86400)});
        if (it != null) {
            for (var i = 0; i < 20; i++) {
                var s = it.next();
                if (s == null || s.data == null) { break; }
                vals.add(s.data as Lang.Number);
            }
        }
    }
    if (vals.size() < 10) { return {:ok => false, :median => 0, :mad => 0, :n => vals.size()}; }
    var med = medianOf(vals);
    var dev = [] as Lang.Array;
    for (var i = 0; i < vals.size(); i++) {
        var d = (vals[i] as Lang.Number) - med;
        dev.add(d < 0 ? -d : d as Lang.Number);
    }
    return {:ok => true, :median => med, :mad => medianOf(dev), :n => vals.size()};
}

(:background)
function stressZ() as Lang.Number {
    var base = stressBaseline();
    if (!(base[:ok] as Lang.Boolean)) { return 0; }
    return timingRobustZ(recentStress(), base[:median] as Lang.Number,
                         base[:mad] as Lang.Number);
}

(:background)
function sleepShort() as Lang.Boolean {
    var d = sleepDurationMinutes();
    if (d != null) { return (d as Lang.Number) < TIMING_SLEEP_MIN; }
    var p = UserProfile.getProfile();
    if (p == null || !(p has :sleepTime) || p.sleepTime == null) { return false; }
    return (p.sleepTime as Time.Duration).value() < TIMING_SLEEP_MIN * 60;
}

(:background)
function nearBed(target as Lang.Number, now as Lang.Number) as Lang.Boolean {
    var delta = bedMinutes() - now;
    return delta >= target - 2 && delta <= target + 2;
}

(:background)
function wakeWindow(now as Lang.Number) as Lang.Boolean {
    var delta = now - wakeMinute();
    return delta >= 0 && delta <= 30 && sleepShort();
}

(:background)
function stepsShort() as Lang.Boolean {
    var info = ActivityMonitor.getInfo();
    if (info == null) { return true; }
    var steps = 0;
    var goal = 0;
    if (info.steps != null) { steps = info.steps as Lang.Number; }
    if (info.stepGoal != null) { goal = info.stepGoal as Lang.Number; }
    var span = bedMinutes() - wakeMinute();
    if (span <= 0) { span += 1440; }
    if (span <= 0 || span > 1200) { span = 720; }
    var elapsed = dayMinutes() - wakeMinute();
    if (elapsed < 0) { elapsed = 0; }
    if (elapsed > span) { elapsed = span; }
    var target = (goal > 0 ? goal : 7000) * elapsed / span;
    return steps < target * 0.85;
}

// Un seul evenement temporel actif : on replanifie le prochain creneau exact.
(:background)
function registerNext() as Void {
    var now = dayMinutes();
    var bed = bedTarget();
    var wake = wakeMinute();
    var sun = sunsetMinutes();
    var rise = sunriseMinutes();
    var light = rise >= 0 ? rise : timingLightStart(wake);
    var ctx = buildContext();
    var alarm = alarmMinute();
    var cands = [nextTime(700, light), 750,
                 (alarm == null ? 1440 : alarm as Lang.Number),
                 nextTime(1500, timingCaffeine(bed)),
                 sun - 2, sun, sun + 2,
                 nextTime(1830, 1110), nextTime(2100, timingNsdrTime(ctx)),
                 nextTime(2200, screensOffMinute()),
                 2230] as Lang.Array;

    for (var i = 1; i < cands.size(); i++) {
        var v = cands[i] as Lang.Number;
        var j = i - 1;
        while (j >= 0 && (cands[j] as Lang.Number) > v) {
            cands[j + 1] = cands[j];
            j--;
        }
        cands[j + 1] = v;
    }

    var wait = 1440 - now;
    for (var i = 0; i < cands.size(); i++) {
        var c = cands[i] as Lang.Number;
        if (c > now) { wait = c - now; break; }
    }
    if (wait < 5) { wait = 5; }

    // Le SDK interdit les Duration < 5 min ; un Moment absolu est legal.
    var at = Time.now().add(new Time.Duration(wait * 60));
    var last = Background.getLastTemporalEventTime();
    if (last != null) {
        var earliest = last.add(new Time.Duration(5 * 60));
        if (at.value() < earliest.value()) { at = earliest; }
    }
    Background.registerForTemporalEvent(at);
}

function canVibrate() as Lang.Boolean {
    if (!(Attention has :vibrate)) { return false; }
    var settings = System.getDeviceSettings();
    if (settings has :vibrateOn && settings.vibrateOn != null && !settings.vibrateOn) {
        return false;
    }
    return true;
}

function doBuzz(slot as Lang.Number, once as Lang.Boolean) as Lang.Boolean {
    if (!canVibrate()) {
        gLastBuzz = "indisponible " + clockText();
        App.Storage.setValue("diag.lastbuzz", gLastBuzz);
        return false;
    }
    if (once) {
        var key = "buzz.day." + slot.format("%d");
        if (loadNumber(key) == dayIndex()) { return true; }
    }
    Attention.vibrate([new Attention.VibeProfile(60, 120)]);
    gLastBuzz = slot.format("%d") + " " + clockText();
    App.Storage.setValue("diag.lastbuzz", gLastBuzz);
    if (once) {
        App.Storage.setValue("buzz.day." + slot.format("%d"), dayIndex());
    }
    Ui.requestUpdate();
    return true;
}

// Un seul rappel par categorie et par jour local.
(:background)
function alreadyNotified(slot as Lang.Number) as Lang.Boolean {
    return loadNumber("notif.day." + slot.format("%d")) == dayIndex();
}

(:background)
function markNotified(slot as Lang.Number) as Void {
    App.Storage.setValue("notif.day." + slot.format("%d"), dayIndex());
}

(:background)
function recordOutcome(slot as Lang.Number, base as Lang.Number, outcome as Lang.Symbol) as Void {
    var next = timingHysteresis(base, outcome);
    App.Storage.setValue("notif.next." + slot.format("%d"), next);
}

(:background)
function nextTime(slot as Lang.Number, base as Lang.Number) as Lang.Number {
    var v = loadNumber("notif.next." + slot.format("%d"));
    return v == 0 ? base : v;
}

(:background)
function buildContext() as Lang.Dictionary {
    var info = ActivityMonitor.getInfo();
    var steps = 0;
    var goal = 0;
    if (info != null) {
        if (info.steps != null) { steps = info.steps as Lang.Number; }
        if (info.stepGoal != null) { goal = info.stepGoal as Lang.Number; }
    }
    var wake = wakeMinute();
    var bed = bedTarget();
    var span = bed - wake;
    if (span <= 0) { span += TIMING_DAY; }
    if (span <= 0 || span > 1200) { span = 720; }
    var elapsed = dayMinutes() - wake;
    if (elapsed < 0) { elapsed = 0; }
    if (elapsed > span) { elapsed = span; }
    var bb = sensorSample(:bodybattery);
    var bbn = bb == null ? 100 : bb as Lang.Number;
    var d = sleepDurationMinutes();
    return {
        :now => dayMinutes(), :bed => bed, :wake => wake,
        :steps => steps, :goal => goal, :stressZ => stressZ(), :bb => bbn,
        :debt => sleepDebt(), :shortNight => (d != null && (d as Lang.Number) < TIMING_SLEEP_MIN),
        :bedSD => bedtimeSD(), :nightAlarm => nightAlarm(),
        :sunrise => sunriseMinutes(), :sunset => sunsetMinutes(),
        :span => span, :elapsed => elapsed
    } as Lang.Dictionary;
}

// --- Lien telephone : une trame par reveil, plus un envoi manuel -----------

(:background)
function bedEventBits() as Lang.Number {
    var today = dayIndex();
    var bits = 0;
    for (var i = 0; i < 7; i++) {
        var v = App.Storage.getValue("sleep.bed." + (today - i).format("%d"));
        if (v != null && v instanceof Lang.Number) { bits = bits | (1 << i); }
    }
    return bits;
}

// Table immuable des codes de raison (PHONE-CONTRACT.md). Jamais renumerotee.
(:background)
function reasonCodeForSlot(slot as Lang.Number) as Lang.Number {
    if (slot == 700) { return 1; }
    if (slot == 1230) { return 2; }
    if (slot == 1500) { return 3; }
    if (slot == 1730) { return 4; }
    if (slot == 1830) { return 5; }
    if (slot == 2100) { return 6; }
    if (slot == 2200) { return 7; }
    if (slot == 2230) { return 8; }
    if (slot == 2400) { return 9; }
    return 0;
}

(:background)
function nextSeq() as Lang.Number {
    var s = loadNumber("ble.seq") + 1;
    if (s > 65534) { s = 1; }
    return s;
}

// Contexte complet de la trame montre -> telephone. Toute absence vaut -1 :
// aucun zero ne peut etre confondu avec une mesure.
(:background)
function snapshotContext() as Lang.Dictionary {
    var ctx = buildContext();
    var info = ActivityMonitor.getInfo();
    var steps = -1;
    var goal = -1;
    if (info != null) {
        if (info.steps != null) { steps = info.steps as Lang.Number; }
        if (info.stepGoal != null) { goal = info.stepGoal as Lang.Number; }
    }
    var alarm = alarmMinute();
    var bb = sensorSample(:bodybattery);
    var night = sleepDurationMinutes();
    var score = timingNsdrScore(ctx);
    var verdict = 0;
    if (score >= 3) { verdict = 2; } else if (score >= 1) { verdict = 1; }
    return {
        :seq => nextSeq(), :day => dayIndex() % 65534, :ts => Time.now().value(),
        :flags => (nightAlarm() ? 1 : 0),
        :alarm => (alarm == null ? -1 : alarm as Lang.Number),
        :bedTarget => bedTarget(), :screensOff => screensOffMinute(),
        :caffeine => timingCaffeine(bedTarget()),
        :bedMean => bedMinutes(), :wakeMean => wakeMinute(),
        :bedCount => bedEventCount(),
        :lastNight => (night == null ? -1 : night as Lang.Number),
        :debt => sleepDebt(), :bedSD => bedtimeSD(),
        :stressZ100 => (stressZ() * 100).toNumber(),
        :bb => (bb == null ? -1 : bb as Lang.Number),
        :steps => steps, :goal => goal,
        :sunrise => sunriseMinutes(), :sunset => sunsetMinutes(),
        :nsdrScore => score, :nsdrMin => timingNsdrDurationFromScore(score),
        :verdict => verdict,
        :reasonCode => reasonCodeForSlot(loadNumber("diag.slot.id")),
        :slot => loadNumber("diag.slot.id"),
        :habitBits => bedEventBits()
    } as Lang.Dictionary;
}

function bleState(label as Lang.String) as Void {
    gBle = label;
    App.Storage.setValue("diag.ble", label);
    // Trace lisible par le simulateur et par le MCP (ciq_ble_probe) : sans
    // elle, l'etat BLE ne serait observable que par capture d'ecran.
    System.println("BLE " + label);
}

class PhoneListener extends Communications.ConnectionListener {
    function initialize() {
        Communications.ConnectionListener.initialize();
    }

    function onComplete() as Void {
        gSending = false;
        App.Storage.setValue("ble.pending", 0);
        App.Storage.setValue("ble.tries", 0);
        bleState("ok");
        Ui.requestUpdate();
    }

    // Pas de minuterie en fond (interdite sous 5 min) : la nouvelle tentative
    // a lieu a la prochaine ouverture de l'app, trois fois par jour au plus.
    function onError() as Void {
        gSending = false;
        var tries = loadNumber("ble.tries") + 1;
        App.Storage.setValue("ble.tries", tries);
        if (tries >= 3) {
            App.Storage.setValue("ble.pending", 0);
            bleState("abandon");
        } else {
            bleState("attente");
        }
        Ui.requestUpdate();
    }
}

// Envoi d'une seule trame, dans le contexte avant-plan : le service de fond
// prepare le reveil, l'app envoie une fois reveillee.
function sendSnapshot() as Lang.Boolean {
    if (!(Toybox has :Communications) || !(Communications has :transmit)) {
        bleState("indispo");
        return false;
    }
    // Une seule requete en vol : profondeur de file = 1.
    if (gSending) {
        bleState("envoi en cours");
        return false;
    }
    var ctx = snapshotContext();
    var bytes = timingSnapshotBytes(ctx);
    App.Storage.setValue("ble.seq", timingNum(ctx, :seq, 0));
    App.Storage.setValue("ble.day", dayIndex());
    App.Storage.setValue("ble.pending", 1);
    gSending = true;
    bleState("envoi");
    try {
        Communications.transmit(bytes as Lang.Array<Communications.TransmitType>,
                                null, new PhoneListener());
    } catch (e instanceof Lang.Exception) {
        gSending = false;
        bleState("indispo");
        return false;
    }
    return true;
}

// Appele par la methode de BuzzApp (les callbacks doivent etre des methodes
// de classe : method(:nom) ne resout pas une fonction de module).
function handlePhoneMessage(raw as Lang.Object or Null) as Void {
    var corr = timingParseCorrections(raw, Time.now().value());
    if (corr == null) {
        bleState("rejete");
        App.Storage.setValue("diag.ble.reject", loadNumber("diag.ble.reject") + 1);
        return;
    }
    saveCorrections(corr);
    bleState("recu");
    Ui.requestUpdate();
}

function handlePhoneError() as Void {
    bleState("erreur");
}

(:background)
function evaluateSlot() as Lang.Number {
    var alarm = alarmMinute();
    if (alarm != null && nightAlarm() && timingAt(dayMinutes(), alarm as Lang.Number)
        && !alreadyNotified(2400)) {
        markNotified(2400);
        App.Storage.setValue("diag.slot.reason", "Reveil de nuit");
        return 2400;
    }
    var r = timingChooseSlot(buildContext());
    var slot = r[:slot] as Lang.Number;
    if (slot < 0 || alreadyNotified(slot)) { return -1; }
    markNotified(slot);
    App.Storage.setValue("diag.slot.reason", r[:reason] as Lang.String);
    return slot;
}

(:background)
function messageForSlot(slot as Lang.Number) as Lang.String {
    var reason = loadString("diag.slot.reason");
    var msg = "Rappel";
    if (slot == 700) { msg = "Part regarder le lever de soleil"; }
    else if (slot == 1230) { msg = "Marche 5-10 min apres le repas"; }
    else if (slot == 1500) { msg = "Plus de cafeine ni d'alcool ce soir"; }
    else if (slot == 1730) { msg = "Part regarder le coucher de soleil"; }
    else if (slot == 1830) { msg = "Marche 5 min, pas assez"; }
    else if (slot == 2100) {
        var score = timingNsdrScore(buildContext());
        msg = timingNsdrDurationFromScore(score).format("%d") + " min de repos";
    } else if (slot == 2200) {
        msg = "Ecrans off a " + timingHHMM(screensOffMinute());
    } else if (slot == 2400) {
        msg = "Reveil de nuit : match? NSDR a prevoir";
    }
    else if (slot == 2230) { msg = "1-3 soupirs physiologiques"; }
    else { return "Panneau de test"; }
    if (reason.equals("aucun")) { return msg; }
    return msg + " (" + reason + ")";
}

// --- Diagnostic ------------------------------------------------------------

(:background)
function checkStorage() as Lang.Boolean {
    var key = "diag.probe";
    App.Storage.setValue(key, 42);
    var v = App.Storage.getValue(key);
    App.Storage.setValue(key, 0);
    return v != null && v instanceof Lang.Number && (v as Lang.Number) == 42;
}

(:background)
function profileHasWake() as Lang.Boolean {
    var p = UserProfile.getProfile();
    return p != null && p has :upcomingWakeTime && p.upcomingWakeTime != null;
}

(:background)
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
    gLastEvent = loadString("diag.lastevent");
    gLastBuzz = loadString("diag.lastbuzz");
    gPending = loadNumber("diag.pending");
    gEvents = bedEventCount();
    gReason = loadString("diag.slot.reason");
    gBle = loadString("diag.ble");
    gSource = correctionSource();

    gMetrics = [
        ["Horloge", System.getClockTime() != null],
        ["Reglages", settings != null],
        ["Reveil", profileHasWake()],
        ["Sommeil", profileHasSleep()],
        ["Corps", body],
        ["Pas", info != null && info.steps != null],
        ["Objectif", info != null && info.stepGoal != null],
        ["Stress", info != null && info.stressScore != null],
        ["Position", Position.getInfo() != null],
        ["Meteo", rawSunsetMinutes() != null],
        ["Stress 1h", sensorSample(:stress) != null],
        ["Battery", sensorSample(:bodybattery) != null],
        ["Buzz", Attention has :vibrate],
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
    var dow = Gregorian.info(Time.now(), Time.FORMAT_SHORT).day_of_week as Lang.Number;
    for (var i = 0; i < 7; i++) {
        var gi = (dow - 1 - i) % 7;
        if (gi < 0) { gi += 7; }
        out.add(names[(gi + 6) % 7]);
    }
    return out;
}

function drawSquares(dc as Graphics.Dc, cx as Lang.Number, cy as Lang.Number, bits as Lang.Number, color as Lang.Number) as Void {
    var side = 30;
    var bx = cx - (7 * side) / 2 + side / 2;
    var letters = weekdayLetters();
    var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    for (var i = 0; i < 7; i++) {
        var x = bx + i * side - side / 2;
        var y = cy - side / 2;
        if ((bits & (1 << i)) != 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y, side, side);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(x, y, side, side);
        }
        dc.drawText(x + side / 2, cy, Graphics.FONT_XTINY, letters[i] as Lang.String, justify);
    }
}

(:typecheck(disableBackgroundCheck))
class DiagView extends Ui.View {
    function initialize() {
        View.initialize();
    }

    // Deux pages d'une seule colonne : la grille est calculee par le module
    // pur DiagLayout, avec une marge de 10 % qui garde le cadre dans le
    // cercle du cadran meme quand les polices du device sont plus grandes.
    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var font = Graphics.FONT_XTINY;
        var titleFont = Graphics.FONT_TINY;
        var lineH = dc.getFontHeight(font) + 2;
        var titleH = dc.getFontHeight(titleFont) + 6;
        var margin = (height * 10) / 100;
        var footer = 2;
        if ((height - 2 * margin - titleH) / lineH < 9) { footer = 1; }

        var g = DiagLayout.grid(width, height, lineH, titleH, footer);
        var boxW = g[:boxW] as Lang.Number;
        var boxH = g[:boxH] as Lang.Number;
        var left = g[:left] as Lang.Number;
        var top = g[:top] as Lang.Number;
        var rowY = g[:rowY] as Lang.Number;
        var footerY = g[:footerY] as Lang.Number;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, top, boxW, boxH);

        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var leftJustify = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, top + titleH / 2, titleFont,
                    "DIAGNOSTIC " + (gDiagPage + 1).format("%d") + "/2", justify);

        var count = gMetrics.size();
        var perPage = 7;
        var start = gDiagPage * perPage;
        var textGap = (dc.getFontHeight(font) + 8);
        for (var i = 0; i < perPage && start + i < count; i++) {
            var row = gMetrics[start + i] as Lang.Array;
            var y = rowY + i * lineH;
            drawGlyph(dc, left + 10, y, row[1] as Lang.Boolean);
            dc.drawText(left + 10 + textGap, y, font, row[0] as Lang.String, leftJustify);
        }

        // Observabilite : une ligne par page, ou deux quand la place le permet.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var cx = width / 2;
        if (gDiagPage == 0) {
            var first = "E:" + gEvents.format("%d") + "/7 " + gLastEvent +
                        "  B:" + gLastBuzz;
            // Une seule ligne disponible : on garde les trois etats courts.
            var merged = "E:" + gEvents.format("%d") + "/7 B:" + gLastBuzz +
                         " R:" + gReason;
            dc.drawText(cx, footerY, font, footer == 1 ? merged : first, justify);
            if (footer == 2) {
                dc.drawText(cx, footerY + lineH, font, "R:" + gReason, justify);
            }
        } else {
            var link = "BLE:" + gBle;
            dc.drawText(cx, footerY, font, footer == 1 ? link + "  S:" + gSource : link,
                        justify);
            if (footer == 2) {
                dc.drawText(cx, footerY + lineH, font, "S:" + gSource, justify);
            }
        }
    }
}

(:typecheck(disableBackgroundCheck))
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
        drawSquares(dc, cx, y + 108, 0x05, Graphics.COLOR_ORANGE);
    }
}

(:typecheck(disableBackgroundCheck))
class PopupView extends Ui.View {
    var msg as Lang.String = "Rappel";
    var closeTimer as Timer.Timer or Null = null;

    function initialize(message as Lang.String) {
        View.initialize();
        msg = message;
        closeTimer = new Timer.Timer();
        closeTimer.start(method(:onTimer), 25000, false);
    }

    function onHide() as Void {
        if (closeTimer != null) { closeTimer.stop(); }
    }

    function onTimer() as Void {
        closePopup();
    }

    function closePopup() as Void {
        if (closeTimer != null) { closeTimer.stop(); closeTimer = null; }
        recordOutcome(loadNumber("diag.slot.id"), loadNumber("diag.slot.base"), :none);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var x = 20;
        var y = 61;
        var w = 220;
        var h = 138;
        dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 3, y + 3, w - 6, h - 6);
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, y + 18, Graphics.FONT_SMALL, "Protocole", justify);
        dc.drawText(130, y + 48, Graphics.FONT_TINY, msg, justify);
        drawSquares(dc, 130, y + 108, 0x01, Graphics.COLOR_PURPLE);
    }
}

(:typecheck(disableBackgroundCheck))
class PopupDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Appui court : accuser sans cocher la case, et decaler le prochain rappel.
    function onPress() as Lang.Boolean {
        recordOutcome(loadNumber("diag.slot.id"), loadNumber("diag.slot.base"), :dismissed);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onMenu() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }
}

(:typecheck(disableBackgroundCheck))
class TestPanelDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Lang.Boolean {
        // Le test background a 10 s est interdit par le SDK : on ne garde que
        // le buzz de test immediat (onPress) et on ferme le panneau.
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onBack() as Lang.Boolean {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onPress() as Lang.Boolean {
        // Envoi manuel de la trame telephone, puis buzz de confirmation.
        var sent = sendSnapshot();
        doBuzz(sent ? 9998 : 9997, false);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        return true;
    }
}

(:typecheck(disableBackgroundCheck))
class DiagDelegate extends Ui.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Long appui bouton milieu gauche : panneau de test.
    function onMenu() as Lang.Boolean {
        Ui.pushView(new TestPanelView(), new TestPanelDelegate(), Ui.SLIDE_IMMEDIATE);
        return true;
    }

    function onNextPage() as Lang.Boolean {
        gDiagPage = (gDiagPage + 1) % 2;
        Ui.requestUpdate();
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        gDiagPage = (gDiagPage + 1) % 2;
        Ui.requestUpdate();
        return true;
    }

    function onKey(keyEvent as Ui.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();
        if (key == Ui.KEY_UP) { return onPreviousPage(); }
        if (key == Ui.KEY_DOWN) { return onNextPage(); }
        return false;
    }

    // Bouton haut droit : test vibration immediat.
    function onPress() as Lang.Boolean {
        doBuzz(9999, false);
        return true;
    }
}

(:background)
class BuzzDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onSleepTime() as Void {
        recordSleepEvent(:bed);
        Background.exit(null);
    }

    function onWakeTime() as Void {
        recordSleepEvent(:wake);
        gLastEvent = "reveil " + clockText();
        App.Storage.setValue("diag.lastevent", gLastEvent);
        gPending = 1;
        App.Storage.setValue("diag.pending", 1);
        App.Storage.setValue("diag.slot.id", 700);
        App.Storage.setValue("diag.slot.base", dayMinutes());
        App.Storage.setValue("diag.pending.msg", "Part regarder le lever de soleil");
        Background.requestApplicationWake("Protocoles Buzz");
        Background.exit(null);
    }

    function onTemporalEvent() as Void {
        var slot = evaluateSlot();
        gLastEvent = (slot >= 0 ? slot.format("%d") : "rien") + " " + clockText();
        App.Storage.setValue("diag.lastevent", gLastEvent);
        if (slot >= 0) {
            gPending = 1;
            App.Storage.setValue("diag.pending", 1);
            App.Storage.setValue("diag.slot.id", slot);
            App.Storage.setValue("diag.slot.base", dayMinutes());
            App.Storage.setValue("diag.pending.msg", messageForSlot(slot));
            Background.requestApplicationWake("Protocoles Buzz");
        }
        registerNext();
        Background.exit(null);
    }
}

class BuzzApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    (:typecheck(disableBackgroundCheck))
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        handlePhoneMessage(msg.data);
    }

    (:typecheck(disableBackgroundCheck))
    function onPhoneMessageError(err as Communications.PhoneAppMessageError) as Void {
        handlePhoneError();
    }

    (:typecheck(disableBackgroundCheck))
    // onStart est aussi appele dans le processus de fond lorsque
    // Background.requestApplicationWake() reveille l'app : il ne doit donc
    // toucher qu'aux API autorisees en fond (moteur, stockage, planification).
    // Aucun chargement d'UI, aucune API de premier plan, aucun BLE ici.
    function onStart(state as Lang.Dictionary or Null) as Void {
        registerNext();
        if (Background has :registerForSleepEvent) { Background.registerForSleepEvent(); }
        if (Background has :registerForWakeEvent) { Background.registerForWakeEvent(); }
    }

    // Appele uniquement depuis l'interface (DiagDelegate.onShow), donc
    // toujours au premier plan : enregistrement des messages telephone et
    // envoi quotidien de l'instantane.
    (:typecheck(disableBackgroundCheck))
    function activateLink() as Void {
        if (Toybox has :Communications && Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
            if (Communications has :registerForPhoneAppMessageErrors) {
                Communications.registerForPhoneAppMessageErrors(method(:onPhoneMessageError));
            }
        }
        if (loadNumber("ble.day") != dayIndex()) {
            sendSnapshot();
        } else if (loadNumber("ble.pending") == 1 && loadNumber("ble.tries") < 3) {
            sendSnapshot();
        }
    }

    (:typecheck(disableBackgroundCheck))
    function getInitialView() {
        // Seul point d'entree garanti au premier plan : mesures et lien
        // telephone n'ont pas le droit de tourner dans le processus de fond.
        refreshMetrics();
        activateLink();
        if (loadNumber("diag.pending") == 1) {
            var msg = loadString("diag.pending.msg");
            App.Storage.setValue("diag.pending", 0);
            gPending = 0;
            doBuzz(loadNumber("diag.slot.id"), true);
            return [new PopupView(msg), new PopupDelegate()];
        }
        return [new DiagView(), new DiagDelegate()];
    }

    (:background)
    function getServiceDelegate() {
        return [new BuzzDelegate()];
    }
}
