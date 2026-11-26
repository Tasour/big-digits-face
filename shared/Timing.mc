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
const TIMING_POPUP_MS = 30000;
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

function timingAlarmBed(wake as Lang.Number, sleepMinutes as Lang.Number) as Lang.Number {
    return timingMod(wake - sleepMinutes);
}

function timingScreensOff(bed as Lang.Number) as Lang.Number {
    return timingMod(bed - 60);
}

function timingNightAlarm(wake as Lang.Number, typicalWake as Lang.Number) as Lang.Boolean {
    var night = wake <= 270;
    var delta = timingMod(wake - typicalWake);
    var shifted = delta > 120 && delta < TIMING_DAY - 120;
    return night || shifted;
}

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

function timingNsdrDurationFromScore(score as Lang.Number) as Lang.Number {
    if (score >= 3) { return 30; }
    if (score >= 2) { return 20; }
    if (score >= 1) { return 10; }
    return 0;
}

function timingNsdrCause(ctx as Lang.Dictionary) as Lang.String {
    if ((ctx[:stressZ] as Lang.Number) >= 2.0 && (ctx[:bb] as Lang.Number) < 40) {
        return "Stress et battery";
    }
    if (ctx[:nightAlarm] as Lang.Boolean) { return "Reveil de nuit"; }
    if ((ctx[:bedSD] as Lang.Number) > 60) { return "Coucher irregulier"; }
    return "Dette de sommeil";
}

function timingNsdrTime(ctx as Lang.Dictionary) as Lang.Number {
    var cause = timingNsdrCause(ctx);
    if (cause.equals("Reveil de nuit")) { return 840; }
    if (cause.equals("Coucher irregulier")) {
        return timingScreensOff(ctx[:bed] as Lang.Number);
    }
    return timingMod((ctx[:wake] as Lang.Number) + 30);
}

// --- Contrat binaire telephone (ADR-0014) ---------------------------------
//
// Deux trames, little-endian, entiers 16 bits non signes, absence = 0xFFFF.
// Aucune fonction de ce bloc n'utilise Communications : le transport reste
// dans l'app compagnon, le format reste testable sur la face.
//
// Les trames sont des Lang.Array de nombres 0-255, le type exact accepte par
// Communications.transmit() ; une trame recue en ByteArray est convertie.

const TIMING_SNAP_VERSION = 1;
const TIMING_SNAP_SIZE = 62;      // 12 octets d'en-tete + 48 + 2 de CRC
const TIMING_SNAP_FIELDS = 24;
const TIMING_SNAP_MISSING = 65535;
const TIMING_SNAP_O_LEN = 1;
const TIMING_SNAP_O_SEQ = 2;
const TIMING_SNAP_O_DAY = 4;
const TIMING_SNAP_O_TS = 6;
const TIMING_SNAP_O_FLAGS = 10;
const TIMING_SNAP_O_FIELDS = 12;
const TIMING_SNAP_O_CRC = 60;

const TIMING_CORR_VERSION = 1;
const TIMING_CORR_SIZE = 40;      // 8 + 26 + 4 (exp) + 2 (CRC)
const TIMING_CORR_FIELDS = 13;
const TIMING_CORR_O_FIELDS = 8;
const TIMING_CORR_O_EXP = 34;
const TIMING_CORR_O_CRC = 38;

// Lit un champ numerique sans lever d'exception quand la cle manque.
function timingNum(d as Lang.Dictionary, key as Lang.Symbol, fallback as Lang.Number) as Lang.Number {
    var v = d.get(key);
    if (v != null && v instanceof Lang.Number) { return v as Lang.Number; }
    return fallback;
}

// Normalise une trame recue (ByteArray du telephone, Array ou null).
function timingToBytes(raw as Lang.Object or Null) as Lang.Array or Null {
    if (raw == null) { return null; }
    var out = [] as Lang.Array;
    if (raw instanceof Lang.ByteArray) {
        var ba = raw as Lang.ByteArray;
        for (var i = 0; i < ba.size(); i++) { out.add(ba[i] as Lang.Number); }
        return out;
    }
    if (raw instanceof Lang.Array) {
        var arr = raw as Lang.Array;
        for (var i = 0; i < arr.size(); i++) {
            var e = arr[i];
            if (!(e instanceof Lang.Number)) { return null; }
            out.add(e as Lang.Number);
        }
        return out;
    }
    return null;
}

// CRC-16/CCITT-FALSE : polynome 0x1021, initialisation 0xFFFF.
function timingCrc16(bytes as Lang.Array, from as Lang.Number, to as Lang.Number) as Lang.Number {
    var crc = 0xFFFF;
    for (var i = from; i < to; i++) {
        crc = (crc ^ (((bytes[i] as Lang.Number) & 0xFF) << 8)) & 0xFFFF;
        for (var k = 0; k < 8; k++) {
            if ((crc & 0x8000) != 0) {
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
            } else {
                crc = (crc << 1) & 0xFFFF;
            }
        }
    }
    return crc & 0xFFFF;
}

function timingPushU16(out as Lang.Array, v as Lang.Number) as Void {
    var x = v;
    if (x < 0) { x = TIMING_SNAP_MISSING; }
    else if (x > 65534) { x = 65534; }
    out.add(x & 0xFF);
    out.add((x >> 8) & 0xFF);
}

function timingPushU32(out as Lang.Array, v as Lang.Number) as Void {
    var x = v;
    if (x < 0) { x = 0; }
    out.add(x & 0xFF);
    out.add((x >> 8) & 0xFF);
    out.add((x >> 16) & 0xFF);
    out.add((x >> 24) & 0xFF);
}

function timingReadU16(bytes as Lang.Array, offset as Lang.Number) as Lang.Number {
    var lo = (bytes[offset] as Lang.Number) & 0xFF;
    var hi = (bytes[offset + 1] as Lang.Number) & 0xFF;
    return lo + (hi << 8);
}

function timingReadU32(bytes as Lang.Array, offset as Lang.Number) as Lang.Number {
    var b0 = (bytes[offset] as Lang.Number) & 0xFF;
    var b1 = (bytes[offset + 1] as Lang.Number) & 0xFF;
    var b2 = (bytes[offset + 2] as Lang.Number) & 0xFF;
    var b3 = (bytes[offset + 3] as Lang.Number) & 0xFF;
    return b0 + (b1 << 8) + (b2 << 16) + (b3 << 24);
}

// Ordre des 24 champs de la trame montre -> telephone. Jamais renumerote.
function timingSnapshotValues(ctx as Lang.Dictionary) as Lang.Array {
    return [
        timingNum(ctx, :alarm, -1),
        timingNum(ctx, :bedTarget, -1),
        timingNum(ctx, :screensOff, -1),
        timingNum(ctx, :caffeine, -1),
        timingNum(ctx, :bedMean, -1),
        timingNum(ctx, :wakeMean, -1),
        timingNum(ctx, :bedCount, -1),
        timingNum(ctx, :lastNight, -1),
        timingNum(ctx, :debt, -1),
        timingNum(ctx, :bedSD, -1),
        timingNum(ctx, :stressZ100, -1),
        timingNum(ctx, :bb, -1),
        timingNum(ctx, :steps, -1),
        timingNum(ctx, :goal, -1),
        timingNum(ctx, :sunrise, -1),
        timingNum(ctx, :sunset, -1),
        timingNum(ctx, :nsdrScore, -1),
        timingNum(ctx, :nsdrMin, -1),
        timingNum(ctx, :verdict, -1),
        timingNum(ctx, :reasonCode, -1),
        timingNum(ctx, :slot, -1),
        timingNum(ctx, :habitBits, -1),
        timingNum(ctx, :reserved1, -1),
        timingNum(ctx, :reserved2, -1)
    ] as Lang.Array;
}

function timingSnapshotBytes(ctx as Lang.Dictionary) as Lang.Array {
    var out = [] as Lang.Array;
    out.add(TIMING_SNAP_VERSION);
    out.add(TIMING_SNAP_SIZE);
    timingPushU16(out, timingNum(ctx, :seq, 0));
    timingPushU16(out, timingNum(ctx, :day, 0));
    timingPushU32(out, timingNum(ctx, :ts, 0));
    timingPushU16(out, timingNum(ctx, :flags, 0));
    var vals = timingSnapshotValues(ctx);
    for (var i = 0; i < vals.size(); i++) {
        timingPushU16(out, vals[i] as Lang.Number);
    }
    timingPushU16(out, timingCrc16(out, 0, out.size()));
    return out;
}

function timingSnapshotValid(raw as Lang.Object or Null) as Lang.Boolean {
    var bytes = timingToBytes(raw);
    if (bytes == null) { return false; }
    var b = bytes as Lang.Array;
    if (b.size() != TIMING_SNAP_SIZE) { return false; }
    if ((b[0] as Lang.Number) != TIMING_SNAP_VERSION) { return false; }
    if ((b[TIMING_SNAP_O_LEN] as Lang.Number) != TIMING_SNAP_SIZE) { return false; }
    return timingReadU16(b, TIMING_SNAP_O_CRC) == timingCrc16(b, 0, TIMING_SNAP_O_CRC);
}

function timingSnapshotField(bytes as Lang.Array, index as Lang.Number) as Lang.Number {
    var raw = timingReadU16(bytes, TIMING_SNAP_O_FIELDS + index * 2);
    return raw == TIMING_SNAP_MISSING ? -1 : raw;
}

// Decode une trame montre -> telephone en Dictionary nomme, ou null si invalide.
function timingSnapshotDecode(raw as Lang.Object or Null) as Lang.Dictionary or Null {
    if (!timingSnapshotValid(raw)) { return null; }
    var bytes = timingToBytes(raw) as Lang.Array;
    return {
        :version => TIMING_SNAP_VERSION,
        :seq => timingReadU16(bytes, TIMING_SNAP_O_SEQ),
        :day => timingReadU16(bytes, TIMING_SNAP_O_DAY),
        :ts => timingReadU32(bytes, TIMING_SNAP_O_TS),
        :flags => timingReadU16(bytes, TIMING_SNAP_O_FLAGS),
        :alarm => timingSnapshotField(bytes, 0),
        :bedTarget => timingSnapshotField(bytes, 1),
        :screensOff => timingSnapshotField(bytes, 2),
        :caffeine => timingSnapshotField(bytes, 3),
        :bedMean => timingSnapshotField(bytes, 4),
        :wakeMean => timingSnapshotField(bytes, 5),
        :bedCount => timingSnapshotField(bytes, 6),
        :lastNight => timingSnapshotField(bytes, 7),
        :debt => timingSnapshotField(bytes, 8),
        :bedSD => timingSnapshotField(bytes, 9),
        :stressZ100 => timingSnapshotField(bytes, 10),
        :bb => timingSnapshotField(bytes, 11),
        :steps => timingSnapshotField(bytes, 12),
        :goal => timingSnapshotField(bytes, 13),
        :sunrise => timingSnapshotField(bytes, 14),
        :sunset => timingSnapshotField(bytes, 15),
        :nsdrScore => timingSnapshotField(bytes, 16),
        :nsdrMin => timingSnapshotField(bytes, 17),
        :verdict => timingSnapshotField(bytes, 18),
        :reasonCode => timingSnapshotField(bytes, 19),
        :slot => timingSnapshotField(bytes, 20),
        :habitBits => timingSnapshotField(bytes, 21),
        :reserved1 => timingSnapshotField(bytes, 22),
        :reserved2 => timingSnapshotField(bytes, 23)
    } as Lang.Dictionary;
}

// Construit une trame telephone -> montre. Reservee au telephone et aux tests.
function timingCorrectionsBytes(ctx as Lang.Dictionary) as Lang.Array {
    var out = [] as Lang.Array;
    out.add(TIMING_CORR_VERSION);
    out.add(TIMING_CORR_SIZE);
    timingPushU16(out, timingNum(ctx, :seq, 0));
    timingPushU32(out, timingNum(ctx, :ts, 0));
    timingPushU16(out, timingNum(ctx, :needMin, -1));
    timingPushU16(out, timingNum(ctx, :sleepScore, -1));
    timingPushU16(out, timingNum(ctx, :debt7, -1));
    timingPushU16(out, timingNum(ctx, :bedSD, -1));
    timingPushU16(out, timingNum(ctx, :hrvBase, -1));
    timingPushU16(out, timingNum(ctx, :bbBase, -1));
    timingPushU16(out, timingNum(ctx, :nsdrMin, -1));
    timingPushU16(out, timingNum(ctx, :nsdrAt, -1));
    timingPushU16(out, timingNum(ctx, :verdict, -1));
    timingPushU16(out, timingNum(ctx, :reasonCode, -1));
    timingPushU16(out, timingNum(ctx, :confidence, -1));
    timingPushU16(out, -1);
    timingPushU16(out, -1);
    timingPushU32(out, timingNum(ctx, :exp, 0));
    timingPushU16(out, timingCrc16(out, 0, out.size()));
    return out;
}

function timingCorrInRange(v as Lang.Number, max as Lang.Number) as Lang.Boolean {
    return v == -1 || (v >= 0 && v <= max);
}

// Valide une trame telephone -> montre. Retourne null si un seul controle
// echoue : type, taille, version, longueur, CRC, expiration, bornes.
function timingParseCorrections(raw as Lang.Object or Null, nowSeconds as Lang.Number) as Lang.Dictionary or Null {
    var bytes = timingToBytes(raw);
    if (bytes == null) { return null; }
    var b = bytes as Lang.Array;
    if (b.size() != TIMING_CORR_SIZE) { return null; }
    if ((b[0] as Lang.Number) != TIMING_CORR_VERSION) { return null; }
    if ((b[1] as Lang.Number) != TIMING_CORR_SIZE) { return null; }
    if (timingReadU16(b, TIMING_CORR_O_CRC) != timingCrc16(b, 0, TIMING_CORR_O_CRC)) {
        return null;
    }
    var exp = timingReadU32(b, TIMING_CORR_O_EXP);
    if (exp <= nowSeconds) { return null; }

    var v = [] as Lang.Array;
    for (var i = 0; i < TIMING_CORR_FIELDS; i++) {
        var raw16 = timingReadU16(b, TIMING_CORR_O_FIELDS + i * 2);
        v.add(raw16 == TIMING_SNAP_MISSING ? -1 : raw16);
    }
    var needMin = v[0] as Lang.Number;
    var sleepScore = v[1] as Lang.Number;
    var debt7 = v[2] as Lang.Number;
    var bedSD = v[3] as Lang.Number;
    var hrvBase = v[4] as Lang.Number;
    var bbBase = v[5] as Lang.Number;
    var nsdrMin = v[6] as Lang.Number;
    var nsdrAt = v[7] as Lang.Number;
    var verdict = v[8] as Lang.Number;
    var reasonCode = v[9] as Lang.Number;
    var confidence = v[10] as Lang.Number;

    if (!timingCorrInRange(needMin, 1440)) { return null; }
    if (!timingCorrInRange(sleepScore, 100)) { return null; }
    if (debt7 < -1 || debt7 > 5000) { return null; }
    if (!timingCorrInRange(bedSD, 720)) { return null; }
    if (!timingCorrInRange(hrvBase, 200)) { return null; }
    if (!timingCorrInRange(bbBase, 100)) { return null; }
    if (!(nsdrMin == -1 || nsdrMin == 0 || nsdrMin == 10 ||
          nsdrMin == 20 || nsdrMin == 30)) { return null; }
    if (!timingCorrInRange(nsdrAt, 1439)) { return null; }
    if (verdict < -1 || verdict > 2) { return null; }
    if (reasonCode < -1 || reasonCode > 15) { return null; }
    if (!timingCorrInRange(confidence, 100)) { return null; }

    return {
        :version => TIMING_CORR_VERSION,
        :seq => timingReadU16(b, 2),
        :ts => timingReadU32(b, 4),
        :needMin => needMin, :sleepScore => sleepScore, :debt7 => debt7,
        :bedSD => bedSD, :hrvBase => hrvBase, :bbBase => bbBase,
        :nsdrMin => nsdrMin, :nsdrAt => nsdrAt, :verdict => verdict,
        :reasonCode => reasonCode, :confidence => confidence, :exp => exp
    } as Lang.Dictionary;
}
