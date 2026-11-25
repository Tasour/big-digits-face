// Moteur de timing determine : fonctions pures, sans Storage ni horloge.
// Source unique des seuils du livre Protocols, compilee dans la face,
// l'app compagnon et la suite de tests via les chemins Jungle.
//
// Regles source (docs/architecture/protocol-criteria-from-book.md) :
//   chunk_101  lumiere 5-10 min, +30 a +60 min apres le lever
//   chunk_211  temperature minimum = lever - 2 h ; lumiere vive a eviter
//              6 a 8 h avant (ici 8 h, borne conservative)
//   chunk_399  cafeine a eviter 8 a 10 h avant le coucher (ici 8 h)
//   chunk_361  7 a 9 h de sommeil (420 min plancher)
//   chunk_574  7000 pas objectif basal, 10000 optimal
//   chunk_982  NSDR 10 a 30 min
//   chunk_914  1 a 3 soupirs physiologiques
//   chunk_904  soupir = outil immediat quand le stress monte
using Toybox.Lang;
using Toybox.Math;

(:background)
const TIMING_DAY = 1440;
(:background)
const TIMING_SLEEP_MIN = 420;
(:background)
const TIMING_CAFFEINE_LEAD = 480;
(:background)
const TIMING_SCREEN_LEAD = 480;
(:background)
const TIMING_TEMP_OFFSET = 120;
(:background)
const TIMING_LIGHT_DELAY = 30;
(:background)
const TIMING_LIGHT_WINDOW = 30;
(:background)
const TIMING_STEP_BASE = 7000;
(:background)
const TIMING_STEP_OPTIMAL = 10000;
(:background)
const TIMING_STEP_RATE_MAX = 100;
(:background)
const TIMING_NSDR_MIN = 10;
(:background)
const TIMING_NSDR_MAX = 30;
(:background)
const TIMING_POPUP_MS = 3600000;
(:background)
const TIMING_MAD_SCALE = 1.4826;

(:background)
function timingMod(v as Lang.Number) as Lang.Number {
    var r = v % TIMING_DAY;
    if (r < 0) { r += TIMING_DAY; }
    return r;
}

(:background)
function timingHHMM(v as Lang.Number) as Lang.String {
    var m = timingMod(v) as Lang.Number;
    return (m / 60).format("%02d") + ":" + (m % 60).format("%02d");
}

(:background)
function timingCircularMean(values as Lang.Array) as Lang.Number or Null {
    var n = values.size();
    if (n == 0) { return null; }
    var s = 0.0;
    var c = 0.0;
    for (var i = 0; i < n; i++) {
        var a = 2.0 * Math.PI * (values[i] as Lang.Number) / TIMING_DAY;
        s += Math.sin(a);
        c += Math.cos(a);
    }
    var avg = Math.atan2(s / n, c / n) * TIMING_DAY / (2.0 * Math.PI);
    return timingMod(avg.toNumber());
}

(:background)
function timingTempMin(wake as Lang.Number) as Lang.Number {
    return timingMod(wake - TIMING_TEMP_OFFSET);
}

(:background)
function timingScreenStart(wake as Lang.Number) as Lang.Number {
    return timingMod(timingTempMin(wake) - TIMING_SCREEN_LEAD);
}

(:background)
function timingCaffeine(bed as Lang.Number) as Lang.Number {
    return timingMod(bed - TIMING_CAFFEINE_LEAD);
}

(:background)
function timingLightStart(wake as Lang.Number) as Lang.Number {
    return timingMod(wake + TIMING_LIGHT_DELAY);
}

(:background)
function timingDebt7(durations as Lang.Array, need as Lang.Number) as Lang.Number {
    var total = 0;
    for (var i = 0; i < durations.size(); i++) {
        var d = durations[i] as Lang.Number;
        if (d > 0 && d < need) { total += need - d; }
    }
    return total;
}

(:background)
function timingRobustZ(value as Lang.Number, median as Lang.Number, mad as Lang.Number or Null) as Lang.Number {
    if (mad == null || (mad as Lang.Number) <= 0) { return 0; }
    return ((value - median) / ((mad as Lang.Number) * TIMING_MAD_SCALE)).toNumber();
}

(:background)
function timingStepRate(steps as Lang.Number, goal as Lang.Number, minutesLeft as Lang.Number) as Lang.Number {
    if (minutesLeft <= 0 || goal <= steps) { return 0; }
    return (goal - steps) / minutesLeft;
}

(:background)
function timingNsdrMinutes(debt as Lang.Number, stressZ as Lang.Number) as Lang.Number {
    if (debt >= 180 || stressZ >= 2.5) { return TIMING_NSDR_MAX; }
    if (debt >= 90 || stressZ >= 2.0) { return 20; }
    return TIMING_NSDR_MIN;
}

(:background)
function timingHysteresis(base as Lang.Number, outcome as Lang.Symbol) as Lang.Number {
    if (outcome == :done) { return timingMod(base - 15); }
    if (outcome == :dismissed) { return timingMod(base + 15); }
    return timingMod(base);
}

(:background)
function timingExpired(startMs as Lang.Number, nowMs as Lang.Number, limitMs as Lang.Number) as Lang.Boolean {
    return nowMs - startMs >= limitMs;
}

// Compare un creneau a l'heure courante avec tolerance de 2 minutes.
(:background)
function timingAt(now as Lang.Number, target as Lang.Number) as Lang.Boolean {
    var delta = timingMod(now - target);
    return delta <= 2 || delta >= TIMING_DAY - 2;
}

(:background)
function timingWindow(now as Lang.Number, start as Lang.Number, width as Lang.Number) as Lang.Boolean {
    return timingMod(now - start) <= width;
}

(:background)
function timingChooseSlot(ctx as Lang.Dictionary) as Lang.Dictionary {
    var now = ctx[:now] as Lang.Number;
    var bed = ctx[:bed] as Lang.Number;
    var wake = ctx[:wake] as Lang.Number;
    var steps = ctx[:steps] as Lang.Number;
    var goal = ctx[:goal] as Lang.Number;
    var stressZ = ctx[:stressZ] as Lang.Number;
    var bb = ctx[:bb] as Lang.Number;
    var sunset = ctx[:sunset] as Lang.Number;
    var span = ctx[:span] as Lang.Number;
    var elapsed = ctx[:elapsed] as Lang.Number;

    // 1. Calme : evenement de stress, pas un creneau fixe.
    if (stressZ >= 2.0 && bb < 40) {
        return {:slot => 2230, :reason => "Stress eleve"};
    }
    // 2. NSDR : score multi-signaux, creneau selon la cause dominante.
    var nsdrScore = timingNsdrScore(ctx);
    if (nsdrScore >= 1 && timingAt(now, timingNsdrTime(ctx))) {
        return {:slot => 2100, :reason => timingNsdrCause(ctx)};
    }
    // 3. Lumiere : lever du soleil reel quand disponible, sinon lever + 30.
    var sunrise = ctx[:sunrise] as Lang.Number;
    var lightTarget = sunrise >= 0 ? sunrise : timingLightStart(wake);
    if (timingWindow(now, lightTarget, 60)) {
        return {:slot => 700, :reason => "Lever soleil " + timingHHMM(lightTarget)};
    }
    // 4. Pas : notification seulement si le rythme requis devient irrealiste.
    var minutesLeft = span - elapsed;
    if (goal > 0 && minutesLeft > 0 &&
        timingStepRate(steps, goal, minutesLeft) > TIMING_STEP_RATE_MAX) {
        return {:slot => 1830, :reason => "Rythme pas insuffisant"};
    }
    // 5. Stimulants : 8 h avant le coucher reel.
    if (timingAt(now, timingCaffeine(bed))) {
        return {:slot => 1500, :reason => "Coucher " + timingHHMM(bed) + " - 8 h"};
    }
    // 6. Ecrans : une heure avant le coucher calcule (reveil programme ou moyenne).
    if (timingAt(now, timingScreensOff(bed))) {
        return {:slot => 2200, :reason => "Ecrans off " + timingHHMM(timingScreensOff(bed))};
    }
    // 7. Repas : heure non mesurable, creneau fixe documente.
    if (timingAt(now, 750)) {
        return {:slot => 1230, :reason => "Apres le repas"};
    }
    // 8. Coucher du soleil : donnee reelle quand disponible.
    if (timingAt(now, sunset)) {
        return {:slot => 1730, :reason => "Coucher soleil"};
    }
    return {:slot => -1, :reason => "aucun"};
}

// --- Réveil programmé, régularité et NSDR multi-signaux -------------------

(:background)
function timingAlarmBed(wake as Lang.Number, sleepMinutes as Lang.Number) as Lang.Number {
    return timingMod(wake - sleepMinutes);
}

(:background)
function timingScreensOff(bed as Lang.Number) as Lang.Number {
    return timingMod(bed - 60);
}

(:background)
function timingNightAlarm(wake as Lang.Number, typicalWake as Lang.Number) as Lang.Boolean {
    var night = wake <= 270;
    var delta = timingMod(wake - typicalWake);
    var shifted = delta > 120 && delta < TIMING_DAY - 120;
    return night || shifted;
}

(:background)
function timingCircularSD(values as Lang.Array) as Lang.Number {
    var n = values.size();
    if (n < 2) { return 0; }
    var sumS = 0.0;
    var sumC = 0.0;
    for (var i = 0; i < n; i++) {
        var a = 2.0 * Math.PI * (values[i] as Lang.Number) / TIMING_DAY;
        sumS += Math.sin(a);
        sumC += Math.cos(a);
    }
    var r = Math.sqrt(sumS * sumS + sumC * sumC) / n;
    if (r >= 1.0) { return 0; }
    var sd = Math.sqrt(-2.0 * Math.log(r, Math.E)) * TIMING_DAY / (2.0 * Math.PI);
    return sd.toNumber();
}

(:background)
function timingNsdrScore(ctx as Lang.Dictionary) as Lang.Number {
    var debt = ctx[:debt] as Lang.Number;
    var sd = ctx[:bedSD] as Lang.Number;
    var z = ctx[:stressZ] as Lang.Number;
    var bb = ctx[:bb] as Lang.Number;
    var debtPart = debt > 420 ? 1 : debt / 420.0;
    var regPart = sd > 60 ? 1 : sd / 60.0;
    var zPart = z >= 3 ? 1 : (z <= 0 ? 0 : z / 3.0);
    var bbPart = bb >= 70 ? 0 : ((70 - bb) / 70.0 > 1 ? 1 : (70 - bb) / 70.0);
    var score = 0.30 * debtPart + 0.15 * regPart + 0.20 * zPart + 0.15 * bbPart;
    if (ctx[:shortNight] as Lang.Boolean) { score += 0.20; }
    return (score * 5).toNumber();
}

(:background)
function timingNsdrDurationFromScore(score as Lang.Number) as Lang.Number {
    if (score >= 3) { return 30; }
    if (score >= 2) { return 20; }
    if (score >= 1) { return 10; }
    return 0;
}

(:background)
function timingNsdrCause(ctx as Lang.Dictionary) as Lang.String {
    if ((ctx[:stressZ] as Lang.Number) >= 2.0 && (ctx[:bb] as Lang.Number) < 40) {
        return "Stress et battery";
    }
    if (ctx[:nightAlarm] as Lang.Boolean) { return "Reveil de nuit"; }
    if ((ctx[:bedSD] as Lang.Number) > 60) { return "Coucher irregulier"; }
    return "Dette de sommeil";
}

(:background)
function timingNsdrTime(ctx as Lang.Dictionary) as Lang.Number {
    var cause = timingNsdrCause(ctx);
    if (cause.equals("Reveil de nuit")) { return 840; }
    if (cause.equals("Coucher irregulier")) {
        return timingScreensOff(ctx[:bed] as Lang.Number);
    }
    return timingMod((ctx[:wake] as Lang.Number) + 30);
}
