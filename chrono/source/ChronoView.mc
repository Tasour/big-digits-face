using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Timer;
using Toybox.WatchUi;

// Big Digits Chrono
// H M S (ou M S si H=0) sur une ligne, centiemes au centre en bas.
class ChronoView extends WatchUi.View {

    const LABEL = 0x999999;

    // Cote (H, S ou CM) : 28 x 52, trait 6.
    const S_W = 28;
    const S_H = 52;
    const S_S = 6;
    const S_MID = 22;
    const S_GAP = 4;
    const S_X = 196;
    const S_CX = 226;
    const H_X = 4;
    const H_CX = 34;

    // Milieu (M ou S) : 45 x 84, trait 8.
    const M_W = 45;
    const M_H = 84;
    const M_S = 8;
    const M_MID = 38;
    const M_GAP = 6;
    const M_X = 82;

    // Centiemes en bas : 2 chiffres 18 x 32, trait 3.
    const CM_W = 18;
    const CM_H = 32;
    const CM_S = 3;
    const CM_MID = 14;
    const CM_GAP = 4;
    const CM_X = 110;

    const M_Y = 84;
    const S_Y = 100;
    const LABEL_M_Y = 172;
    const LABEL_TOP_M = 68;
    const LABEL_TOP_S = 84;
    const LABEL_S_Y = 156;
    const CM_Y = 190;
    const LABEL_CM_Y = 226;

    const STATE_READY = 0;
    const STATE_RUNNING = 1;
    const STATE_PAUSED = 2;

    const TICK_MS = 20;
    const GO_MS = 3000;
    const LAP_MS = 2000;

    hidden var _state;
    hidden var _baseMs;
    hidden var _startMs;
    hidden var _goUntil;
    hidden var _lapFlashUntil;
    hidden var _lapMs;
    hidden var _lastLapMs;
    hidden var _timer;

    function initialize() {
        View.initialize();
        _state = STATE_READY;
        _baseMs = 0;
        _startMs = 0;
        _goUntil = 0;
        _lapFlashUntil = 0;
        _lapMs = 0;
        _lastLapMs = 0;
        _timer = new Timer.Timer();
    }

    function onShow() as Void {
        if (_state == STATE_RUNNING) {
            startTimer();
        }
    }

    function onHide() as Void {
        stopTimer();
    }

    // START / STOP (haut droite).
    function toggle() as Void {
        if (_state == STATE_RUNNING) {
            _baseMs += System.getTimer() - _startMs;
            _state = STATE_PAUSED;
            _lapFlashUntil = 0;
            stopTimer();
        } else {
            _startMs = System.getTimer();
            _state = STATE_RUNNING;
            _goUntil = _startMs + GO_MS;
            startTimer();
        }
        WatchUi.requestUpdate();
    }

    // RESET (bas droite).
    function reset() as Void {
        _state = STATE_READY;
        _baseMs = 0;
        _startMs = 0;
        _goUntil = 0;
        _lapFlashUntil = 0;
        _lapMs = 0;
        _lastLapMs = 0;
        stopTimer();
        WatchUi.requestUpdate();
    }

    // LAP (haut gauche) : affiche le tour 2 s.
    function lap() as Void {
        if (_state == STATE_RUNNING) {
            var now = elapsedMs();
            _lapMs = now - _lastLapMs;
            _lastLapMs = now;
            _lapFlashUntil = System.getTimer() + LAP_MS;
            WatchUi.requestUpdate();
        }
    }

    // Retour au cadran (bas gauche).
    function exit() as Void {
        stopTimer();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onTick() as Void {
        WatchUi.requestUpdate();
    }

    private function startTimer() as Void {
        _timer.start(method(:onTick), TICK_MS, true);
    }

    private function stopTimer() as Void {
        _timer.stop();
    }

    private function elapsedMs() as Lang.Number {
        var t = _baseMs;
        if (_state == STATE_RUNNING) {
            t += System.getTimer() - _startMs;
        }
        return t;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var now = System.getTimer();
        var total = elapsedMs();
        var shown = total;
        if (now < _lapFlashUntil) {
            shown = _lapMs;
        }

        var csTotal = shown / 10;
        var h = csTotal / 360000;
        var m = (csTotal / 6000) % 60;
        var s = (csTotal / 100) % 60;
        var cm = csTotal % 100;
        if (h > 99) {
            h = 99;
        }

        var cmStr = cm.format("%d");
        if (cm < 10) {
            cmStr = "0" + cmStr;
        }

        drawTime(dc, h.format("%d"), m.format("%d"), s.format("%d"), cmStr, h > 0);

        if (_state == STATE_READY) {
            drawReady(dc);
        } else if (_state == STATE_RUNNING && now < _goUntil) {
            drawGo(dc);
        }
    }

    private function drawTime(dc as Graphics.Dc, h as Lang.String, m as Lang.String, s as Lang.String, cm as Lang.String, showH as Lang.Boolean) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (showH) {
            drawGroup(dc, H_X, 60, S_Y, h, S_W, S_H, S_S, S_MID, true);
            drawGroup(dc, M_X, 96, M_Y, m, M_W, M_H, M_S, M_MID, true);
            drawGroup(dc, S_X, 60, S_Y, s, S_W, S_H, S_S, S_MID, true);
            drawGroup(dc, CM_X, 40, CM_Y, cm, CM_W, CM_H, CM_S, CM_MID, false);
        } else {
            drawGroup(dc, H_X, 60, S_Y, m, S_W, S_H, S_S, S_MID, true);
            drawGroup(dc, M_X, 96, M_Y, s, M_W, M_H, M_S, M_MID, true);
            drawGroup(dc, S_X, 60, S_Y, cm, S_W, S_H, S_S, S_MID, false);
        }

        dc.setColor(LABEL, Graphics.COLOR_TRANSPARENT);
        if (showH) {
            drawLetter(dc, H_CX - 5, LABEL_TOP_S, "H");
            drawLetter(dc, 125, LABEL_TOP_M, "M");
            drawLetter(dc, S_CX - 5, LABEL_TOP_S, "S");
            drawLetter(dc, 120, LABEL_CM_Y, "C");
            drawLetter(dc, 131, LABEL_CM_Y, "M");
        } else {
            drawLetter(dc, H_CX - 5, LABEL_S_Y, "M");
            drawLetter(dc, 125, LABEL_M_Y, "S");
            drawLetter(dc, S_CX - 10, LABEL_S_Y, "C");
            drawLetter(dc, S_CX + 1, LABEL_S_Y, "M");
        }
    }

    private function drawGroup(dc as Graphics.Dc, slotX as Lang.Number, slotW as Lang.Number, y as Lang.Number, value as Lang.String, w as Lang.Number, h as Lang.Number, s as Lang.Number, mid as Lang.Number, mask as Lang.Boolean) as Void {
        var n = value.length();
        if (mask && n == 2 && value.substring(0, 1).equals("0")) {
            drawDigit(dc, slotX + (slotW - w) / 2, y, value.substring(1, 2).toNumber(), w, h, s, mid);
            return;
        }
        if (n == 1) {
            drawDigit(dc, slotX + (slotW - w) / 2, y, value.toNumber(), w, h, s, mid);
            return;
        }
        var gap = (slotW - n * w) / (n - 1);
        var startX = slotX + (slotW - (n * w + (n - 1) * gap)) / 2;
        for (var i = 0; i < n; i++) {
            drawDigit(dc, startX + i * (w + gap), y, value.substring(i, i + 1).toNumber(), w, h, s, mid);
        }
    }

    private function drawDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, digit as Lang.Number, w as Lang.Number, h as Lang.Number, s as Lang.Number, mid as Lang.Number) as Void {
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

    private function drawLetter(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, ch as Lang.String) as Void {
        if (ch.equals("H")) {
            dc.fillRectangle(x + 1, y, 1, 12); dc.fillRectangle(x + 8, y, 1, 12);
            dc.fillRectangle(x + 1, y + 5, 8, 1);
        } else if (ch.equals("M")) {
            dc.fillRectangle(x + 1, y, 1, 12); dc.fillRectangle(x + 8, y, 1, 12);
            dc.drawLine(x + 1, y, x + 4, y + 5); dc.drawLine(x + 8, y, x + 5, y + 5);
        } else if (ch.equals("S")) {
            dc.fillRectangle(x + 1, y, 8, 1); dc.fillRectangle(x + 1, y, 1, 6);
            dc.fillRectangle(x + 1, y + 5, 8, 1); dc.fillRectangle(x + 8, y + 5, 1, 7);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        } else if (ch.equals("C")) {
            dc.fillRectangle(x + 1, y, 8, 1); dc.fillRectangle(x + 1, y, 1, 12);
            dc.fillRectangle(x + 1, y + 11, 8, 1);
        }
    }

    // Are you READY ? : seul READY est gras.
    private function drawReady(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var fLight = Graphics.FONT_SYSTEM_SMALL;
        var fBold = Graphics.FONT_SMALL;
        var a = "Are you";
        var b = "READY";
        var c = "?";
        var gap = 4;
        var w1 = dc.getTextWidthInPixels(a, fLight);
        var w2 = dc.getTextWidthInPixels(b, fBold);
        var w3 = dc.getTextWidthInPixels(c, fLight);
        var total = w1 + gap + w2 + gap + w3;
        var x = 130 - total / 2;
        var baseline = 48;
        var h1 = dc.getFontHeight(fLight);
        var h2 = dc.getFontHeight(fBold);
        var y1 = baseline - (h1 * 78) / 100;
        var y2 = baseline - (h2 * 78) / 100;
        dc.drawText(x, y1, fLight, a, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + w1 + gap, y2, fBold, b, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + w1 + gap + w2 + gap, y1, fLight, c, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawGo(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(130, 26, Graphics.FONT_MEDIUM, "GO!", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
