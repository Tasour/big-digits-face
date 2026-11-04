using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.WatchUi;

// Big Digits — direction B5 « data latérale + secondes en bas ».
//
//   MAR 3 NOV
//  kcal 1 2 pas
//  ...  3 4
//       [ss]
//
// Bloc 184 (2×90 + 4), aucun rognage ; calories verticales à gauche,
// pas verticaux à droite ; secondes horizontales en bas au centre ;
// date en police pixel 5×7 blanche ; arcs segmentés.
class BigDigitsView extends WatchUi.WatchFace {

    const CELL = 90;
    const STROKE = 18;
    const MID = 36;

    const X_LEFT = 38;
    const X_RIGHT = 132;
    const Y_TOP = 38;
    const Y_BOTTOM = 132;

    // Secondes en bas au centre : 2 chiffres 10×14, trait 2, écart 2.
    // Même hauteur (14 px) et même graisse que la date pixel.
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

    // Données verticales : calories à gauche, pas à droite.
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

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
    }

    function onHide() as Void {
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
        var activity = ActivityMonitor.getInfo();
        if (activity != null) {
            var activitySteps = activity.steps;
            if (activitySteps != null) {
                steps = activitySteps as Lang.Number;
            }
            var activityCalories = activity.calories;
            if (activityCalories != null) {
                kcal = activityCalories as Lang.Number;
            }
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

        // Connect IQ ne fournit que les calories totales (BMR + actif).
        // On estime les calories de repos depuis le profil et on les soustrait.
        var profile = UserProfile.getProfile();
        if (profile != null) {
            var birthYear = profile.birthYear;
            var height = profile.height;
            var weight = profile.weight;
            var gender = profile.gender;
            if (birthYear != null && height != null && weight != null && gender != null) {
                var age = info.year - (birthYear as Lang.Number);
                var h = height as Lang.Number;
                var w = (weight as Lang.Number) / 1000.0;
                var rest = 0.0;
                if (gender == UserProfile.GENDER_MALE) {
                    rest = 5.2 - 6.116 * age + 7.628 * h + 12.2 * w;
                } else {
                    rest = -197.6 - 6.116 * age + 7.628 * h + 12.2 * w;
                }
                rest = Math.round((info.hour * 60 + info.min) * rest / 1440).toNumber();
                kcal = kcal - rest;
                if (kcal < 0) {
                    kcal = 0;
                }
            }
        }

        drawFace(dc, hour, minute, seconds, dowStr, dayStr, monStr, kcal.format("%d"), steps.format("%d"), battText, phoneConnected);
    }

    // Les secondes sont le seul élément qui change chaque seconde.
    function onPartialUpdate(dc as Graphics.Dc) as Void {
        var clock = System.getClockTime();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(SEC_X - 2, SEC_Y - 2, SEC_W * 2 + SEC_GAP + 4, SEC_H + 4);
        drawSeconds(dc, clock.sec);
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

    // Quatre arcs de 60° à r=126, trous de 30° aux diagonales ; 2 px.
    private function drawArcs(dc as Graphics.Dc) as Void {
        dc.setColor(C_ARC, Graphics.COLOR_TRANSPARENT);
        drawArcPair(dc, 60, 120);   // haut
        drawArcPair(dc, 330, 390);  // droite
        drawArcPair(dc, 240, 300);  // bas
        drawArcPair(dc, 150, 210);  // gauche
    }

    private function drawArcPair(dc as Graphics.Dc, start as Lang.Number, end as Lang.Number) as Void {
        dc.drawArc(130, 130, 126, Graphics.ARC_COUNTER_CLOCKWISE, start, end);
        dc.drawArc(130, 130, 125, Graphics.ARC_COUNTER_CLOCKWISE, start, end);
    }

    // Date : jour en 7 segments 10×16, jour/mois en pixel 5×7 échelle 2,
    // le tout en blanc. Seul le numéro du jour est agrandi.
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

    // Lettres de date : police trait 10×12, 1 px, pour un rendu plus léger.
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

    // Police pixel 5×7 : une ligne = 5 bits (MSB à gauche).
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

    // Valeur verticale : chiffres 7 segments 10×14 (trait 2), comme les
    // secondes, mais empilés verticalement et en gris. Un peu d'air entre
    // chaque chiffre, et davantage entre les milliers et les centaines.
    private function drawVerticalData(dc as Graphics.Dc, cx as Lang.Number, value as Lang.String) as Void {
        var baseLine = 17;
        var groupGap = 4;
        var n = value.length();
        var hasGroupGap = (n == 5);
        var total = (n - 1) * baseLine + 14;
        if (hasGroupGap) {
            total += groupGap;
        }
        var y = DATA_CY - total / 2;
        var split = n - 3;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < n; i++) {
            if (hasGroupGap && i == split) {
                y += groupGap;
            }
            var digit = value.substring(i, i + 1).toNumber();
            drawSegDigit(dc, cx - 5, y, digit, 10, 14, 2, 6);
            y += baseLine;
        }
    }

    // Ligne du bas : point de connexion (gauche), secondes (centre),
    // autonomie restante (droite), en police pixel 5×7.
    private function drawBottomStatus(dc as Graphics.Dc, seconds as Lang.Number, battText as Lang.String, phoneConnected as Lang.Boolean) as Void {
        drawSeconds(dc, seconds);
        if (phoneConnected) {
            dc.setColor(C_DATA, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(DOT_X, DOT_Y, 2);
        }
        drawBatteryTime(dc, BATTERY_X, SEC_Y, battText);
    }

    // « 5J » / « 12H » : nombre en 5×7 (échelle 2), unité en 5×7 (échelle 1)
    // en haut à droite. « CHG » est affiché petit, centré verticalement.
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

    // Unité J/H : mêmes glyphes 5×7 que la date et les data, échelle 1.
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

    // Secondes horizontales en bas : 2 chiffres 10×14, trait 2.
    private function drawSeconds(dc as Graphics.Dc, seconds as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawSegDigit(dc, SEC_X, SEC_Y, seconds / 10, SEC_W, SEC_H, SEC_S, SEC_MID);
        drawSegDigit(dc, SEC_X + SEC_W + SEC_GAP, SEC_Y, seconds % 10, SEC_W, SEC_H, SEC_S, SEC_MID);
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

    // 1 : barre verticale de 18 px, centrée, sur toute la hauteur.
    private function drawOne(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, height as Lang.Number) as Void {
        var k = height / 90.0;
        dc.fillRectangle(x + 36 * k, y, 18 * k, height);
    }

    private function drawBigDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, digit as Lang.Number) as Void {
        if (digit == 1) {
            drawOne(dc, x, y, CELL);
        } else {
            drawBigDigitSized(dc, x, y, digit, CELL, CELL, STROKE, MID);
        }
    }

    private function drawBigDigitSized(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, digit as Lang.Number, w as Lang.Number, h as Lang.Number, s as Lang.Number, mid as Lang.Number) as Void {
        var low = h - s;
        var a = (digit == 0 || digit == 2 || digit == 3 || digit == 5 || digit == 6 || digit == 7 || digit == 8 || digit == 9);
        var b = (digit == 0 || digit == 1 || digit == 2 || digit == 3 || digit == 4 || digit == 7 || digit == 8 || digit == 9);
        var c = (digit == 0 || digit == 1 || digit == 3 || digit == 4 || digit == 5 || digit == 6 || digit == 7 || digit == 8 || digit == 9);
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
