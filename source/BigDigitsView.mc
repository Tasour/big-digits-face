using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.UserProfile;
using Toybox.WatchUi;

var gBigDigitsView as BigDigitsView or Null;

// Big Digits — cadran "gros chiffres" + rappels Protocoles.
//
// Source des messages : base RAG Synthetix / EPUB Huberman (docs/rag-messages.md).
// Regles design : ~/.config/opencode/design/UNIVERSAL_DESIGN_RULES.md v1.8.0.
//   U03/U33 : titre et message en FONT_SMALL, contexte en FONT_TINY (echelle fermee)
//   U41     : categorie portee par le titre texte ET par la bordure coloree
//   U62     : rappel non bloquant, 25 s
//   U73     : wrap sur frontiere de mot, jamais de coupure au milieu
//   U79     : rectangle en surimpression, sans decalage des chiffres de l'heure
class BigDigitsView extends WatchUi.WatchFace {

    const CELL = 90;
    const STROKE = 18;
    const MID = 36;

    const X_LEFT = 38;
    const X_RIGHT = 132;
    const Y_TOP = 38;
    const Y_BOTTOM = 132;

    const SEC_W = 10;
    const SEC_H = 14;
    const SEC_S = 2;
    const SEC_MID = 6;
    const SEC_GAP = 2;
    const SEC_Y = 232;
    const SEC_X = 118;
    const BATTERY_X = 150;
    const DOT_X = 105;
    const DOT_Y = 239;

    const DATA_LEFT_X = 22;
    const DATA_RIGHT_X = 238;
    const DATA_CY = 132;
    const CAL_LABEL_X = 9;
    const STEP_LABEL_X = 246;
    const LABEL_Y = 129;

    const DATE_Y = 18;

    const C_DATE = 0xFFFFFF;
    const C_DATA = 0x909090;
    const C_ARC = 0x777777;

    // Popup : centre legerement plus haut que l'ancienne version, hauteur
    // portee a 112 px pour loger des carres de 30 px avec leurs lettres.
    const POP_X = 8;
    const POP_Y = 88;
    const POP_W = 244;
    const POP_H = 112;
    const POP_MS = 25000;

    // Tokens de couleur par categorie (U19) — valeurs CIQ, pas de volatiles.
    const C_BORDER_LUMIERE = Graphics.COLOR_ORANGE;
    const C_BORDER_MARCHE = Graphics.COLOR_BLUE;
    const C_BORDER_STIMULANTS = Graphics.COLOR_PURPLE;
    const C_BORDER_SOLEIL = Graphics.COLOR_PURPLE;
    const C_BORDER_NSDR = Graphics.COLOR_PURPLE;
    const C_BORDER_ECRANS = Graphics.COLOR_PURPLE;
    const C_BORDER_CALME = Graphics.COLOR_PURPLE;

    private var lastVibKey as Lang.Number = -1;
    private var activeKey as Lang.Number = -1;
    private var popupStart as Lang.Number = 0;
    private var activeColor as Lang.Number = Graphics.COLOR_LT_GRAY;
    private var activeTitle as Lang.String = "";
    private var activeMsg as Lang.String = "";
    private var activeCtx as Lang.String = "";
    private var activeBits as Lang.Number = 0;
    private var popupTimer as Timer.Timer or Null;

    function initialize() {
        WatchFace.initialize();
        gBigDigitsView = self;
    }

    function onLayout(dc as Graphics.Dc) as Void {}
    function onShow() as Void {}
    function onHide() as Void {
        if (popupTimer != null) { popupTimer.stop(); }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var clock = System.getClockTime();
        var settings = System.getDeviceSettings();
        var hour = clock.hour;

        if (!settings.is24Hour) {
            if (hour == 0) {
                hour = 12;
            } else if (hour > 12) {
                hour -= 12;
            }
        }

        var minute = clock.min;
        var seconds = clock.sec;

        var stats = System.getSystemStats();
        var batteryDays = stats.batteryInDays;
        var wholeDays = Math.floor(batteryDays);
        var batteryHours = Math.floor((batteryDays - wholeDays) * 24);
        var battText;
        if (stats.charging) {
            battText = "CHG";
        } else if (wholeDays >= 1) {
            battText = wholeDays.format("%.0f") + "J";
        } else {
            battText = batteryHours.format("%.0f") + "H";
        }
        var phoneConnected = settings.phoneConnected;

        var steps = 0;
        var kcal = 0;
        var stepGoal = 0;
        var stress = 0;
        var activity = ActivityMonitor.getInfo();
        if (activity != null) {
            if (activity.steps != null) { steps = activity.steps as Lang.Number; }
            if (activity.calories != null) { kcal = activity.calories as Lang.Number; }
            if (activity.stepGoal != null) { stepGoal = activity.stepGoal as Lang.Number; }
            if (activity.stressScore != null) { stress = activity.stressScore as Lang.Number; }
        }

        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dows = ["DIM", "LUN", "MAR", "MER", "JEU", "VEN", "SAM"];
        var months = ["JAN", "FEV", "MAR", "AVR", "MAI", "JUIN", "JUIL", "AOU", "SEP", "OCT", "NOV", "DEC"];
        var dowIdx = info.day_of_week - 1;
        if (dowIdx < 0) { dowIdx = 0; }
        if (dowIdx > 6) { dowIdx = 6; }
        var monIdx = info.month - 1;
        if (monIdx < 0) { monIdx = 0; }
        if (monIdx > 11) { monIdx = 11; }
        var dowStr = dows[dowIdx];
        var dayStr = info.day.format("%d");
        var monStr = months[monIdx];

        var profile = UserProfile.getProfile();
        if (profile != null) {
            var birthYear = profile.birthYear;
            var height = profile.height;
            var weight = profile.weight;
            var gender = profile.gender;
            if (birthYear != null && height != null && weight != null && gender != null) {
                var age = info.year - (birthYear as Lang.Number);
                var hProfile = height as Lang.Number;
                var w = (weight as Lang.Number) / 1000.0;
                var rest = 0.0;
                if (gender == UserProfile.GENDER_MALE) {
                    rest = 5.2 - 6.116 * age + 7.628 * hProfile + 12.2 * w;
                } else {
                    rest = -197.6 - 6.116 * age + 7.628 * hProfile + 12.2 * w;
                }
                rest = Math.round((info.hour * 60 + info.min) * rest / 1440).toNumber();
                kcal = kcal - rest;
                if (kcal < 0) { kcal = 0; }
            }
        }

        drawFace(dc, hour, minute, seconds, dowStr, dayStr, monStr,
                 kcal.format("%d"), steps.format("%d"), battText, phoneConnected);

        updatePopup(clock.hour, clock.min, dowIdx, steps, stepGoal, stress, settings, info);
        if (activeKey >= 0) {
            drawPopup(dc);
        }
    }

    // Les secondes sont le seul element qui change chaque seconde.
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        var clock = System.getClockTime();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(SEC_X - 2, SEC_Y - 2, SEC_W * 2 + SEC_GAP + 4, SEC_H + 4);
        drawSeconds(dc, clock.sec);
        if (activeKey >= 0) {
            var nowMs = Time.now().value() * 1000;
            if (nowMs - popupStart >= POP_MS) {
                activeKey = -1;
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
                dc.fillRectangle(POP_X, POP_Y, POP_W, POP_H);
                WatchUi.requestUpdate();
            }
        }
    }

    // --- Rappels Protocoles -----------------------------------------------

    private function res(id as Lang.ResourceId) as Lang.String {
        return Application.loadResource(id) as Lang.String;
    }

    private function store(key as Lang.String, value as Lang.Number) as Void {
        Application.Storage.setValue(key, value);
    }

    private function load(key as Lang.String) as Lang.Number {
        var v = Application.Storage.getValue(key);
        if (v != null && v instanceof Lang.Number) { return v as Lang.Number; }
        return 0;
    }

    private function dayIndex() as Lang.Number {
        return Time.now().value() / 86400;
    }

    private function habitBits(key as Lang.Number) as Lang.Number {
        var k = "habit.bits." + key.format("%d");
        var kd = "habit.day." + key.format("%d");
        var today = dayIndex();
        var last = load(kd);
        var bits = load(k);
        if (last == 0 || last < today - 1) {
            bits = 0;
        } else if (last < today) {
            bits = (bits << 1) & 0x7F;
        }
        return bits;
    }

    // Accuse de reception via bouton START/ENTER. Un seul appui par jour.
    public function markDone() as Lang.Boolean {
        if (activeKey < 0) { return false; }
        var k = "habit.bits." + activeKey.format("%d");
        var kd = "habit.day." + activeKey.format("%d");
        var today = dayIndex();
        if (load(kd) == today) {
            return true;
        }
        var bits = habitBits(activeKey) | 1;
        store(k, bits);
        store(kd, today);
        activeBits = bits;
        popupStart = Time.now().value() * 1000;
        WatchUi.requestUpdate();
        return true;
    }

    private function setPopup(key as Lang.Number, title as Lang.String, msg as Lang.String, ctx as Lang.String, color as Lang.Number) as Void {
        if (key == activeKey) { return; }
        activeKey = key;
        activeTitle = title;
        activeMsg = msg;
        activeCtx = ctx;
        activeColor = color;
        activeBits = habitBits(key);
        popupStart = Time.now().value() * 1000;
        lastVibKey = key;
        // Pas de Timer : la watch face est redessinee par le systeme (onUpdate).
        // La fenetre de 25 s est verifiee dans onPartialUpdate.
    }

    function onPopupTick() as Void {
        WatchUi.requestUpdate();
    }

    private function minutesOfMoment(m as Time.Moment or Null) as Lang.Number {
        if (m == null) { return -1; }
        var d = Gregorian.info(m, Time.FORMAT_SHORT);
        return d.hour * 60 + d.min;
    }

    private function sleepMinutes() as Lang.Number {
        var profile = UserProfile.getProfile();
        if (profile == null) { return 480; }
        if (!(profile has :sleepTime)) { return 480; }
        var t = profile.sleepTime;
        if (t == null) { return 480; }
        return (t as Time.Duration).value() / 60;
    }

    private function nearBed(targetMinutesBefore as Lang.Number, nowMin as Lang.Number) as Lang.Boolean {
        var profile = UserProfile.getProfile();
        if (profile == null) { return false; }
        var bed = -1;
        if (profile has :upcomingSleepTime) {
            bed = minutesOfMoment(profile.upcomingSleepTime);
        }
        if (bed < 0 && profile has :sleepTime) {
            var bedDur = profile.sleepTime;
            if (bedDur != null) {
                bed = 1380 - ((bedDur as Time.Duration).value() / 60);
            }
        }
        if (bed < 0) { return false; }
        var delta = bed - nowMin;
        return delta >= targetMinutesBefore - 2 && delta <= targetMinutesBefore + 2;
    }

    private function wakeWindow(nowMin as Lang.Number) as Lang.Boolean {
        var profile = UserProfile.getProfile();
        if (profile == null) { return false; }
        var wake = -1;
        if (profile has :upcomingWakeTime) {
            wake = minutesOfMoment(profile.upcomingWakeTime);
        }
        if (wake < 0) { return false; }
        var delta = nowMin - wake;
        return delta >= 0 && delta <= 30 && sleepMinutes() < 420;
    }

    private function isSteppingShort(steps as Lang.Number, goal as Lang.Number) as Lang.Boolean {
        if (goal <= 0) { return steps < 7000; }
        return steps < goal * 0.85;
    }

    // Calcul solaire NOAA简化：declinaison + heure du coucher, position en cache.
    private function sunsetMinutes(info as Gregorian.Info) as Lang.Number {
        var lat = load("solar.lat") / 1000.0;
        var lon = load("solar.lon") / 1000.0;
        if (load("solar.lat") == 0 && load("solar.lon") == 0) {
            return -1;
        }
        var days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        var doy = days[info.month - 1] + info.day;
        var gamma = 2.0 * Math.PI / 365.0 * (doy - 1 + (12.0 - 12.0) / 24.0);
        var eqtime = 229.18 * (0.000075 + 0.001868 * Math.cos(gamma) - 0.032077 * Math.sin(gamma)
                     - 0.014615 * Math.cos(2 * gamma) - 0.040849 * Math.sin(2 * gamma));
        var decl = 0.006918 - 0.399912 * Math.cos(gamma) + 0.070257 * Math.sin(gamma)
                 - 0.006758 * Math.cos(2 * gamma) + 0.000907 * Math.sin(2 * gamma)
                 - 0.002697 * Math.cos(3 * gamma) + 0.00148 * Math.sin(3 * gamma);
        var latR = lat * Math.PI / 180.0;
        var cosH = Math.cos(90.833 * Math.PI / 180.0) / (Math.cos(latR) * Math.cos(decl)) - Math.tan(latR) * Math.tan(decl);
        if (cosH < -1 || cosH > 1) { return -1; }
        var ha = Math.acos(cosH) * 180.0 / Math.PI;
        var sunsetUTC = 720 - 4 * (lon + ha) - eqtime;
        var nowUTC = (Time.now().value() / 60) % 1440;
        var nowLocal = info.hour * 60 + info.min;
        var offset = nowLocal - nowUTC;
        while (offset > 720) { offset -= 1440; }
        while (offset < -720) { offset += 1440; }
        var sunsetLocal = sunsetUTC + offset;
        while (sunsetLocal < 0) { sunsetLocal += 1440; }
        while (sunsetLocal >= 1440) { sunsetLocal -= 1440; }
        return sunsetLocal.toNumber();
    }

    private function refreshPosition() as Void {
        if (Position has :getInfo) {
            var pos = Position.getInfo();
            if (pos != null && pos.position != null) {
                var deg = pos.position.toDegrees();
                var lat = (deg[0] as Lang.Number) * 1000;
                var lon = (deg[1] as Lang.Number) * 1000;
                var oldLat = load("solar.lat");
                var oldLon = load("solar.lon");
                var moved = true;
                if (oldLat != 0 && oldLon != 0) {
                    var dLat = (lat - oldLat) / 1000.0;
                    var dLon = (lon - oldLon) / 1000.0;
                    moved = (dLat * dLat + dLon * dLon) > 0.05 * 0.05;
                }
                if (moved) {
                    store("solar.lat", lat.toNumber());
                    store("solar.lon", lon.toNumber());
                }
            }
        }
    }

    // Selection du moment NSDR, extraite pour etre appelee telle quelle par le
    // harnais de capture (le rendu ne depend pas des capteurs, seulement de l'heure).
    private function nsdrContext(hour as Lang.Number) as Lang.String {
        if (hour < 10) { return res(Rez.Strings.Pup21Matin); }
        if (hour >= 16 && hour < 20) { return res(Rez.Strings.Pup21Seance); }
        if (hour >= 20) { return res(Rez.Strings.Pup21Soir); }
        return res(Rez.Strings.Pup21ApresMidi);
    }

    // Duree NSDR selon le moment : 30 min le matin, 20 l'apres-midi,
    // 10 avant seance et 10 le soir (10-30 min dans le livre).
    private function nsdrMessage(hour as Lang.Number) as Lang.String {
        if (hour < 10) { return res(Rez.Strings.Pup21Msg30); }
        if (hour >= 16 && hour < 20) { return res(Rez.Strings.Pup21Msg10Seance); }
        if (hour >= 20) { return res(Rez.Strings.Pup21Msg10Soir); }
        return res(Rez.Strings.Pup21Msg20);
    }

    private function updatePopup(hour as Lang.Number, minute as Lang.Number, dow as Lang.Number,
                                 steps as Lang.Number, goal as Lang.Number, stress as Lang.Number,
                                 settings as System.DeviceSettings, info as Gregorian.Info) as Void {
        var nowMin = hour * 60 + minute;
        var profile = UserProfile.getProfile();

        // 07:00 — Reveil / lumiere, declenche par l'heure de reveal configuree.
        if (wakeWindow(nowMin)) {
            setPopup(700, res(Rez.Strings.Pup07Title), res(Rez.Strings.Pup07Msg),
                     res(Rez.Strings.Pup07Ctx), C_BORDER_LUMIERE);
            return;
        }

        // 12:30 — Marche apres repas (non mesure : creneau fixe, marque如 tel).
        if (hour == 12 && minute >= 30 && minute < 31) {
            setPopup(1230, res(Rez.Strings.Pup1230Title), res(Rez.Strings.Pup1230Msg),
                     res(Rez.Strings.Pup1230Ctx), C_BORDER_MARCHE);
            return;
        }

        // Coucher - 8 h — Cafeine / alcool, deriver de l'heure de coucher.
        if (nearBed(480, nowMin)) {
            setPopup(1500, res(Rez.Strings.Pup15Title), res(Rez.Strings.Pup15Msg),
                     res(Rez.Strings.Pup15Ctx), C_BORDER_STIMULANTS);
            return;
        }

        // Coucher solaire — calcul NOAA, position en cache.
        if (hour >= 16 && hour <= 20 && minute % 5 == 0) {
            refreshPosition();
        }
        var sunset = sunsetMinutes(info);
        if (sunset >= 0) {
            if (nowMin >= sunset && nowMin <= sunset + 2) {
                setPopup(1730, res(Rez.Strings.Pup17Title), res(Rez.Strings.Pup17Msg),
                         res(Rez.Strings.Pup17Ctx), C_BORDER_SOLEIL);
                return;
            }
        } else if (nearBed(120, nowMin)) {
            setPopup(1730, res(Rez.Strings.Pup17Title), res(Rez.Strings.Pup17Msg),
                     "Coucher approx.", C_BORDER_SOLEIL);
            return;
        }

        // 18:30 — Pas : 85 % du stepGoal.
        if (hour == 18 && minute >= 30 && minute < 31 && isSteppingShort(steps, goal)) {
            setPopup(1830, res(Rez.Strings.Pup18Title), res(Rez.Strings.Pup18Msg),
                     res(Rez.Strings.Pup18Ctx), C_BORDER_MARCHE);
            return;
        }

        // NSDR — 4 moments du livre, proxy face-only.
        if (stress > 50 || (profile != null && sleepMinutes() < 420 && hour >= 10 && hour <= 16)) {
            setPopup(2100, res(Rez.Strings.Pup21Title), nsdrMessage(hour),
                     nsdrContext(hour), C_BORDER_NSDR);
            return;
        }

        // Coucher - 1 h — Ecrans.
        if (nearBed(60, nowMin)) {
            setPopup(2200, res(Rez.Strings.Pup22Title), res(Rez.Strings.Pup22Msg),
                     res(Rez.Strings.Pup22Ctx), C_BORDER_ECRANS);
            return;
        }

        // 22:30 — Soupirs : stress eleve.
        if (hour == 22 && minute >= 30 && minute < 31 && stress > 40) {
            setPopup(2230, res(Rez.Strings.Pup2230Title), res(Rez.Strings.Pup2230Msg),
                     res(Rez.Strings.Pup2230Ctx), C_BORDER_CALME);
            return;
        }

        // Aucun rappel actif.
        activeKey = -1;
        if (popupTimer != null) { popupTimer.stop(); }
    }

    // Lettres LMMJVSD pour les 7 jours de la fenetre glissante.
    // bit 0 = aujourd'hui, bit 6 = il y a six jours.
    private function weekdayLetters() as Lang.Array {
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

    private function drawPopup(dc as Graphics.Dc) as Void {
        // U79 : surimpression, le cadran reste a sa place (aucun decalage).
        // Fond noir : la couleur de categorie est portee par la bordure (U19/U41).
        var border = 3;
        dc.setColor(activeColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(POP_X, POP_Y, POP_W, POP_H);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(POP_X + border, POP_Y + border,
                         POP_W - 2 * border, POP_H - 2 * border);

        // Centrage horizontal et vertical de chaque bloc de texte.
        var centerX = POP_X + POP_W / 2;
        var justify = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, POP_Y + 20, Graphics.FONT_SMALL, activeTitle, justify);

        var parts = wrapText(activeMsg, 30);
        var lineY = POP_Y + 48;
        for (var i = 0; i < parts.size() && i < 2; i++) {
            var part = parts[i] as Lang.String;
            if (part == null) { part = "?" as Lang.String; }
            if (part.length() > 30) { part = part.substring(0, 30); }
            dc.drawText(centerX, lineY, Graphics.FONT_SYSTEM_XTINY, part, justify);
            lineY += 20;
        }

        // Barre de 7 carres avec la lettre du jour concerne au centre.
        var side = 30;
        var gap = 2;
        var total = 7 * side + 6 * gap;
        var bx = centerX - total / 2 + side / 2;
        var by = POP_Y + 92;
        var letters = weekdayLetters();
        for (var i = 0; i < 7; i++) {
            var cx = bx + i * (side + gap);
            var x = cx - side / 2;
            var y = by - side / 2;
            var done = (activeBits & (1 << i)) != 0;
            if (done) {
                dc.setColor(activeColor, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x, y, side, side);
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(x, y, side, side);
            }
            dc.drawText(cx, by, Graphics.FONT_XTINY, letters[i] as Lang.String, justify);
        }
    }

    // Wrap sur frontiere de mot. Un mot plus long que maxLen est coupe avec "…".
    // Le tableau demarre vide : une entree "" decalerait toutes les lignes et
    // ferait disparaitre la premiere ligne du message (defaut observe en capture).
    private function wrapText(text as Lang.String, maxLen as Lang.Number) as Lang.Array {
        if (text == null) { return [""] as Lang.Array; }
        var lines = [] as Lang.Array;
        var current = "" as Lang.String;
        var word = "" as Lang.String;
        for (var i = 0; i <= text.length(); i++) {
            var ch = i < text.length() ? text.substring(i, i + 1) : " ";
            if (ch.equals(" ") || i == text.length()) {
                if (!word.equals("")) {
                    var candidate = current.equals("") ? word : current + " " + word;
                    if (candidate.length() > maxLen && !current.equals("")) {
                        lines.add(current);
                        current = word;
                    } else {
                        current = candidate;
                    }
                    word = "" as Lang.String;
                }
            } else {
                word = word + ch;
            }
        }
        if (!current.equals("")) { lines.add(current); }
        return lines;
    }

    private function drawFace(dc as Graphics.Dc, hour as Lang.Number, minute as Lang.Number, seconds as Lang.Number, dowStr as Lang.String, dayStr as Lang.String, monStr as Lang.String, kcalStr as Lang.String, stepsStr as Lang.String, battText as Lang.String, phoneConnected as Lang.Boolean) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawArcs(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawBigDigit(dc, X_LEFT, Y_TOP, hour / 10);
        drawBigDigit(dc, X_RIGHT, Y_TOP, hour % 10);
        drawBigDigit(dc, X_LEFT, Y_BOTTOM, minute / 10);
        drawBigDigit(dc, X_RIGHT, Y_BOTTOM, minute % 10);

        drawDate(dc, dowStr, dayStr, monStr);

        drawVerticalData(dc, DATA_LEFT_X, kcalStr);
        drawVerticalData(dc, DATA_RIGHT_X, stepsStr);

        dc.setColor(C_DATA, Graphics.COLOR_TRANSPARENT);
        drawPixelChar(dc, CAL_LABEL_X, LABEL_Y, "C", 1);
        drawPixelChar(dc, STEP_LABEL_X, LABEL_Y, "P", 1);

        drawBottomStatus(dc, seconds, battText, phoneConnected);
    }

    private function drawArcs(dc as Graphics.Dc) as Void {
        dc.setColor(C_ARC, Graphics.COLOR_TRANSPARENT);
        drawArcPair(dc, 60, 120);
        drawArcPair(dc, 330, 390);
        drawArcPair(dc, 240, 300);
        drawArcPair(dc, 150, 210);
    }

    private function drawArcPair(dc as Graphics.Dc, start as Lang.Number, end as Lang.Number) as Void {
        dc.drawArc(130, 130, 126, Graphics.ARC_COUNTER_CLOCKWISE, start, end);
        dc.drawArc(130, 130, 125, Graphics.ARC_COUNTER_CLOCKWISE, start, end);
    }

    private function drawDate(dc as Graphics.Dc, dowStr as Lang.String, dayStr as Lang.String, monStr as Lang.String) as Void {
        var gap = 6;
        var advance = 12;
        var leftW = dowStr.length() * advance - 4;
        var dayW = dayStr.length() * 12 + (dayStr.length() - 1) * 2;
        var rightW = monStr.length() * advance - 4;
        var total = leftW + gap + dayW + gap + rightW;
        var x = 130 - total / 2;

        dc.setColor(C_DATE, Graphics.COLOR_TRANSPARENT);
        var cursor = x;
        for (var i = 0; i < dowStr.length(); i++) {
            drawDateChar(dc, cursor, DATE_Y, dowStr.substring(i, i + 1));
            cursor += advance;
        }

        var dayX = x + leftW + gap;
        for (var i = 0; i < dayStr.length(); i++) {
            var digit = dayStr.substring(i, i + 1).toNumber();
            drawSegDigit(dc, dayX + i * 14, DATE_Y - 5, digit, 12, 18, 2, 8);
        }

        cursor = dayX + dayW + gap;
        for (var i = 0; i < monStr.length(); i++) {
            drawDateChar(dc, cursor, DATE_Y, monStr.substring(i, i + 1));
            cursor += advance;
        }
    }

    private function drawDateChar(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, ch as Lang.String) as Void {
        if (ch.equals("A")) {
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
        } else if (ch.equals("C")) {
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
            dc.fillRectangle(x + 8, y, 1, 2);
            dc.fillRectangle(x + 8, y + 10, 1, 2);
        } else if (ch.equals("D")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("E")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("F")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
        } else if (ch.equals("I")) {
            dc.fillRectangle(x + 2, y, 6, 1);
            dc.fillRectangle(x + 2, y + 11, 6, 1);
            dc.fillRectangle(x + 4, y, 1, 12);
        } else if (ch.equals("J")) {
            dc.fillRectangle(x + 7, y, 1, 10);
            dc.fillRectangle(x + 1, y + 8, 1, 4);
            dc.fillRectangle(x + 1, y + 11, 7, 1);
        } else if (ch.equals("L")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("M")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.drawLine(x + 1, y, x + 4, y + 5);
            dc.drawLine(x + 8, y, x + 5, y + 5);
        } else if (ch.equals("N")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.drawLine(x + 1, y, x + 8, y + 11);
        } else if (ch.equals("O")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("P")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 8, y, 1, 6);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
        } else if (ch.equals("R")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 8, y, 1, 6);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
            dc.drawLine(x + 4, y + 6, x + 8, y + 11);
        } else if (ch.equals("S")) {
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 1, y, 1, 6);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
            dc.fillRectangle(x + 8, y + 5, 1, 7);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("T")) {
            dc.fillRectangle(x + 1, y, 8, 1);
            dc.fillRectangle(x + 4, y, 1, 12);
        } else if (ch.equals("U")) {
            dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 8, y, 1, 12);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("V")) {
            dc.drawLine(x + 1, y, x + 4, y + 11);
            dc.drawLine(x + 8, y, x + 5, y + 11);
        }
    }

    private function drawPixelChar(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, ch as Lang.String, scale as Lang.Number) as Void {
        var rows = glyphRows(ch);
        for (var r = 0; r < 7; r++) {
            var mask = rows[r] as Lang.Number;
            for (var c = 0; c < 5; c++) {
                if ((mask & (1 << (4 - c))) != 0) {
                    dc.fillRectangle(x + c * scale, y + r * scale, scale, scale);
                }
            }
        }
    }

    private function glyphRows(ch as Lang.String) as Lang.Array {
        if (ch.equals("A")) { return [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11]; }
        if (ch.equals("C")) { return [0x0F, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0F]; }
        if (ch.equals("D")) { return [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E]; }
        if (ch.equals("E")) { return [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F]; }
        if (ch.equals("F")) { return [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10]; }
        if (ch.equals("G")) { return [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0E]; }
        if (ch.equals("H")) { return [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11]; }
        if (ch.equals("I")) { return [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x1F]; }
        if (ch.equals("J")) { return [0x07, 0x02, 0x02, 0x02, 0x12, 0x12, 0x0C]; }
        if (ch.equals("L")) { return [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F]; }
        if (ch.equals("M")) { return [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11]; }
        if (ch.equals("N")) { return [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11]; }
        if (ch.equals("O")) { return [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]; }
        if (ch.equals("P")) { return [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10]; }
        if (ch.equals("R")) { return [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11]; }
        if (ch.equals("S")) { return [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E]; }
        if (ch.equals("T")) { return [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04]; }
        if (ch.equals("U")) { return [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]; }
        if (ch.equals("V")) { return [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04]; }
        if (ch.equals("0")) { return [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E]; }
        if (ch.equals("1")) { return [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E]; }
        if (ch.equals("2")) { return [0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F]; }
        if (ch.equals("3")) { return [0x1E, 0x01, 0x01, 0x0E, 0x01, 0x01, 0x1E]; }
        if (ch.equals("4")) { return [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02]; }
        if (ch.equals("5")) { return [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E]; }
        if (ch.equals("6")) { return [0x0E, 0x10, 0x1E, 0x11, 0x11, 0x11, 0x0E]; }
        if (ch.equals("7")) { return [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08]; }
        if (ch.equals("8")) { return [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E]; }
        if (ch.equals("9")) { return [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x01, 0x0E]; }
        return [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
    }

    private function drawVerticalData(dc as Graphics.Dc, cx as Lang.Number, value as Lang.String) as Void {
        var baseLine = 17;
        var groupGap = 4;
        var n = value.length();
        var hasGroupGap = (n == 5);
        var total = (n - 1) * baseLine + 14;
        if (hasGroupGap) { total += groupGap; }
        var y = DATA_CY - total / 2;
        var split = n - 3;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < n; i++) {
            if (hasGroupGap && i == split) { y += groupGap; }
            var digit = value.substring(i, i + 1).toNumber();
            drawSegDigit(dc, cx - 5, y, digit, 10, 14, 2, 6);
            y += baseLine;
        }
    }

    private function drawBottomStatus(dc as Graphics.Dc, seconds as Lang.Number, battText as Lang.String, phoneConnected as Lang.Boolean) as Void {
        drawSeconds(dc, seconds);
        if (phoneConnected) {
            dc.setColor(C_DATA, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(DOT_X, DOT_Y, 2);
        }
        drawBatteryTime(dc, BATTERY_X, SEC_Y, battText);
    }

    private function drawBatteryTime(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, text as Lang.String) as Void {
        dc.setColor(C_DATA, Graphics.COLOR_TRANSPARENT);
        var last = text.substring(text.length() - 1, text.length());
        if (last.equals("J") || last.equals("H")) {
            var num = text.substring(0, text.length() - 1);
            var cursor = x;
            var numY = y + 1;
            for (var i = 0; i < num.length(); i++) {
                var digit = num.substring(i, i + 1).toNumber();
                drawSegDigit(dc, cursor, numY, digit, 7, 11, 1, 5);
                cursor += 9;
            }
            drawUnit(dc, cursor + 2, numY, last);
        } else {
            var cursor = x;
            for (var i = 0; i < text.length(); i++) {
                drawPixelChar(dc, cursor, y + 4, text.substring(i, i + 1), 1);
                cursor += 6;
            }
        }
    }

    private function drawUnit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, unit as Lang.String) as Void {
        var rows;
        if (unit.equals("J")) {
            rows = [0x07, 0x02, 0x02, 0x02, 0x12, 0x12, 0x0C];
        } else {
            rows = [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11];
        }
        for (var r = 0; r < 7; r++) {
            var mask = rows[r] as Lang.Number;
            for (var c = 0; c < 5; c++) {
                if ((mask & (1 << (4 - c))) != 0) {
                    dc.fillRectangle(x + c, y + r, 1, 1);
                }
            }
        }
    }

    private function drawSeconds(dc as Graphics.Dc, seconds as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawSegDigit(dc, SEC_X, SEC_Y, seconds / 10, SEC_W, SEC_H, SEC_S, SEC_MID);
        drawSegDigit(dc, SEC_X + SEC_W + SEC_GAP, SEC_Y, seconds % 10, SEC_W, SEC_H, SEC_S, SEC_MID);
    }

    private function drawBigDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, digit as Lang.Number) as Void {
        drawSegDigit(dc, x, y, digit, CELL, CELL, STROKE, MID);
    }

    private function drawSegDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, digit as Lang.Number, w as Lang.Number, h as Lang.Number, s as Lang.Number, mid as Lang.Number) as Void {
        if (digit == 1) {
            dc.fillRectangle(x + (w - s) / 2, y, s, h);
            return;
        }
        var low = h - s;
        var a = (digit == 0 || digit == 2 || digit == 3 || digit == 5 || digit == 6 || digit == 7 || digit == 8 || digit == 9);
        var b = (digit == 0 || digit == 2 || digit == 3 || digit == 4 || digit == 7 || digit == 8 || digit == 9);
        var c = (digit == 0 || digit == 3 || digit == 4 || digit == 5 || digit == 6 || digit == 7 || digit == 8 || digit == 9);
        var d = (digit == 0 || digit == 2 || digit == 3 || digit == 5 || digit == 6 || digit == 8 || digit == 9);
        var e = (digit == 0 || digit == 2 || digit == 6 || digit == 8);
        var f = (digit == 0 || digit == 4 || digit == 5 || digit == 6 || digit == 8 || digit == 9);
        var g = (digit == 2 || digit == 3 || digit == 4 || digit == 5 || digit == 6 || digit == 8 || digit == 9);
        if (a) { dc.fillRectangle(x, y, w, s); }
        if (g) { dc.fillRectangle(x, y + mid, w, s); }
        if (d) { dc.fillRectangle(x, y + low, w, s); }
        if (f) { dc.fillRectangle(x, y, s, mid + s); }
        if (b) { dc.fillRectangle(x + w - s, y, s, mid + s); }
        if (e) { dc.fillRectangle(x, y + mid, s, h - mid); }
        if (c) { dc.fillRectangle(x + w - s, y + mid, s, h - mid); }
    }
}
