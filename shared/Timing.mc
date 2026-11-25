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

const TIMING_DAY = 1440;
const TIMING_SLEEP_MIN = 420;
const TIMING_CAFFEINE_LEAD = 480;
const TIMING_SCREEN_LEAD = 480;
const TIMING_TEMP_OFFSET = 120;
const TIMING_LIGHT_DELAY = 30;
const TIMING_LIGHT_WINDOW = 30;
const TIMING_STEP_BASE = 7000;
const TIMING_STEP_OPTIMAL = 10000;
const TIMING_STEP_RATE_MAX = 100;
const TIMING_NSDR_MIN = 10;
const TIMING_NSDR_MAX = 30;
const TIMING_POPUP_MS = 3600000;
const TIMING_MAD_SCALE = 1.4826;

function timingMod(v as Lang.Number) as Lang.Number {
    var r = v % TIMING_DAY;
    if (r < 0) { r += TIMING_DAY; }
    return r;
}

function timingHHMM(v as Lang.Number) as Lang.String {
    var m = timingMod(v) as Lang.Number;
    return (m / 60).format("%02d") + ":" + (m % 60).format("%02d");
}

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

function timingTempMin(wake as Lang.Number) as Lang.Number {
    return timingMod(wake - TIMING_TEMP_OFFSET);
}

function timingScreenStart(wake as Lang.Number) as Lang.Number {
    return timingMod(timingTempMin(wake) - TIMING_SCREEN_LEAD);
}

function timingCaffeine(bed as Lang.Number) as Lang.Number {
    return timingMod(bed - TIMING_CAFFEINE_LEAD);
}

function timingLightStart(wake as Lang.Number) as Lang.Number {
    return timingMod(wake + TIMING_LIGHT_DELAY);
}

function timingDebt7(durations as Lang.Array, need as Lang.Number) as Lang.Number {
    var total = 0;
    for (var i = 0; i < durations.size(); i++) {
        var d = durations[i] as Lang.Number;
        if (d > 0 && d < need) { total += need - d; }
    }
    return total;
}

function timingRobustZ(value as Lang.Number, median as Lang.Number, mad as Lang.Number or Null) as Lang.Number {
    if (mad == null || (mad as Lang.Number) <= 0) { return 0; }
    return ((value - median) / ((mad as Lang.Number) * TIMING_MAD_SCALE)).toNumber();
}

function timingStepRate(steps as Lang.Number, goal as Lang.Number, minutesLeft as Lang.Number) as Lang.Number {
    if (minutesLeft <= 0 || goal <= steps) { return 0; }
    return (goal - steps) / minutesLeft;
}

function timingNsdrMinutes(debt as Lang.Number, stressZ as Lang.Number) as Lang.Number {
    if (debt >= 180 || stressZ >= 2.5) { return TIMING_NSDR_MAX; }
    if (debt >= 90 || stressZ >= 2.0) { return 20; }
    return TIMING_NSDR_MIN;
}

function timingHysteresis(base as Lang.Number, outcome as Lang.Symbol) as Lang.Number {
    if (outcome == :done) { return timingMod(base - 15); }
    if (outcome == :dismissed) { return timingMod(base + 15); }
    return timingMod(base);
}

function timingExpired(startMs as Lang.Number, nowMs as Lang.Number, limitMs as Lang.Number) as Lang.Boolean {
    return nowMs - startMs >= limitMs;
}

// Compare un creneau a l'heure courante avec tolerance de 2 minutes.
function timingAt(now as Lang.Number, target as Lang.Number) as Lang.Boolean {
    var delta = timingMod(now - target);
    return delta <= 2 || delta >= TIMING_DAY - 2;
}

function timingWindow(now as Lang.Number, start as Lang.Number, width as Lang.Number) as Lang.Boolean {
    return timingMod(now - start) <= width;
}

function timingChooseSlot(ctx as Lang.Dictionary) as Lang.Dictionary {
    var now = ctx[:now] as Lang.Number;
    var bed = ctx[:bed] as Lang.Number;
    var wake = ctx[:wake] as Lang.Number;
    var steps = ctx[:steps] as Lang.Number;
    var goal = ctx[:goal] as Lang.Number;
    var stressZ = ctx[:stressZ] as Lang.Number;
    var bb = ctx[:bb] as Lang.Number;
    var debt = ctx[:debt] as Lang.Number;
    var sunset = ctx[:sunset] as Lang.Number;
    var span = ctx[:span] as Lang.Number;
    var elapsed = ctx[:elapsed] as Lang.Number;

    // 1. Calme : evenement de stress, pas un creneau fixe.
    if (stressZ >= 2.0 && bb < 40) {
        return {:slot => 2230, :reason => "Stress eleve"};
    }
    // 2. NSDR : dette cumulee, fenetre apres le lever.
    if ((debt >= 120 || (ctx[:shortNight] as Lang.Boolean)) &&
        timingWindow(now, timingLightStart(wake), 120)) {
        return {:slot => 2100, :reason => "Nuit courte"};
    }
    // 3. Lumiere matinale : 5-10 min, +30 min apres le lever.
    if (timingAt(now, timingLightStart(wake))) {
        return {:slot => 700, :reason => "Lever " + timingHHMM(wake) + " + 30"};
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
    // 6. Ecrans : debut de la fenetre de lumiere vive a eviter.
    if (timingAt(now, timingScreenStart(wake))) {
        return {:slot => 2200, :reason => "Lever " + timingHHMM(wake) + " - 10 h"};
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
