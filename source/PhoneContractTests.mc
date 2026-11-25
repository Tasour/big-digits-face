// Tests du contrat binaire telephone (ADR-0014) : trame montre -> telephone
// et trame telephone -> montre. Aucun transport, aucun telephone : le format
// est verifie octet par octet.
using Toybox.Lang;
using Toybox.Test;

function snapCtx() as Lang.Dictionary {
    return {
        :seq => 7, :day => 20450, :ts => 1764100000, :flags => 1,
        :alarm => 390, :bedTarget => 1350, :screensOff => 1290,
        :caffeine => 870, :bedMean => 1404, :wakeMean => 385,
        :bedCount => 4, :lastNight => 421, :debt => 139, :bedSD => 27,
        :stressZ100 => 250, :bb => 22, :steps => 12345, :goal => 10000,
        :sunrise => 435, :sunset => 1035, :nsdrScore => 3,
        :nsdrMin => 30, :verdict => 2, :reasonCode => 4,
        :slot => 2200, :habitBits => 5
    } as Lang.Dictionary;
}

(:test)
function snapSize(logger as Test.Logger) as Lang.Boolean {
    var b = timingSnapshotBytes(snapCtx());
    logger.debug("snapSize=" + b.size().toString());
    return b.size() == TIMING_SNAP_SIZE && b.size() == 62;
}

(:test)
function snapCrcValid(logger as Test.Logger) as Lang.Boolean {
    var b = timingSnapshotBytes(snapCtx());
    logger.debug("snapCrcValid=" + timingSnapshotValid(b).toString());
    return timingSnapshotValid(b);
}

(:test)
function snapCrcRejectsBitFlip(logger as Test.Logger) as Lang.Boolean {
    var b = timingSnapshotBytes(snapCtx());
    b[20] = (((b[20] as Lang.Number) + 1) & 0xFF);
    logger.debug("snapBitFlip=" + timingSnapshotValid(b).toString());
    return !timingSnapshotValid(b);
}

(:test)
function snapRoundtripAlarm(logger as Test.Logger) as Lang.Boolean {
    var d = timingSnapshotDecode(timingSnapshotBytes(snapCtx()));
    if (d == null) { return false; }
    var v = d[:alarm] as Lang.Number;
    logger.debug("snapAlarm=" + v.toString());
    return v == 390;
}

(:test)
function snapRoundtripSteps(logger as Test.Logger) as Lang.Boolean {
    var d = timingSnapshotDecode(timingSnapshotBytes(snapCtx()));
    if (d == null) { return false; }
    var v = d[:steps] as Lang.Number;
    logger.debug("snapSteps=" + v.toString());
    return v == 12345;
}

(:test)
function snapRoundtripTimestamp(logger as Test.Logger) as Lang.Boolean {
    var d = timingSnapshotDecode(timingSnapshotBytes(snapCtx()));
    if (d == null) { return false; }
    var v = d[:ts] as Lang.Number;
    logger.debug("snapTs=" + v.toString());
    return v == 1764100000;
}

(:test)
function snapRoundtripDaySeq(logger as Test.Logger) as Lang.Boolean {
    var d = timingSnapshotDecode(timingSnapshotBytes(snapCtx()));
    if (d == null) { return false; }
    var day = d[:day] as Lang.Number;
    var seq = d[:seq] as Lang.Number;
    logger.debug("snapDay=" + day.toString() + " seq=" + seq.toString());
    return day == 20450 && seq == 7;
}

(:test)
function snapMissingIsMinusOne(logger as Test.Logger) as Lang.Boolean {
    var ctx = {:seq => 1, :day => 1, :ts => 1} as Lang.Dictionary;
    var d = timingSnapshotDecode(timingSnapshotBytes(ctx));
    if (d == null) { return false; }
    var alarm = d[:alarm] as Lang.Number;
    var sunrise = d[:sunrise] as Lang.Number;
    var bb = d[:bb] as Lang.Number;
    logger.debug("snapMissing=" + alarm.toString() + "/" +
                 sunrise.toString() + "/" + bb.toString());
    return alarm == -1 && sunrise == -1 && bb == -1;
}

(:test)
function snapZeroIsNotMissing(logger as Test.Logger) as Lang.Boolean {
    var ctx = {:seq => 1, :day => 1, :ts => 1, :bb => 0} as Lang.Dictionary;
    var d = timingSnapshotDecode(timingSnapshotBytes(ctx));
    if (d == null) { return false; }
    var bb = d[:bb] as Lang.Number;
    logger.debug("snapZero=" + bb.toString());
    return bb == 0;
}

(:test)
function snapRejectsTruncated(logger as Test.Logger) as Lang.Boolean {
    var b = timingSnapshotBytes(snapCtx());
    var short = b.slice(0, 40);
    var d = timingSnapshotDecode(short);
    logger.debug("snapTruncated=" + (d == null ? "null" : "accepte"));
    return d == null;
}

// --- Trame telephone -> montre ---------------------------------------------

function corrCtx() as Lang.Dictionary {
    return {
        :seq => 3, :ts => 1764100000, :exp => 1764200000,
        :needMin => 480, :sleepScore => 71, :debt7 => 120, :bedSD => 24,
        :hrvBase => 52, :bbBase => 31, :nsdrMin => 20, :nsdrAt => 840,
        :verdict => 2, :reasonCode => 3, :confidence => 80
    } as Lang.Dictionary;
}

(:test)
function corrValidAccepted(logger as Test.Logger) as Lang.Boolean {
    var c = timingParseCorrections(timingCorrectionsBytes(corrCtx()), 1764110000);
    if (c == null) { return false; }
    var need = c[:needMin] as Lang.Number;
    var nsdr = c[:nsdrMin] as Lang.Number;
    logger.debug("corrNeed=" + need.toString() + " nsdr=" + nsdr.toString());
    return need == 480 && nsdr == 20 && (c[:exp] as Lang.Number) == 1764200000;
}

(:test)
function corrArrayAccepted(logger as Test.Logger) as Lang.Boolean {
    var b = timingCorrectionsBytes(corrCtx());
    var arr = [] as Lang.Array;
    for (var i = 0; i < b.size(); i++) { arr.add(b[i] as Lang.Number); }
    var c = timingParseCorrections(arr, 1764110000);
    logger.debug("corrArray=" + (c == null ? "null" : "ok"));
    return c != null && (c[:confidence] as Lang.Number) == 80;
}

(:test)
function corrRejectsVersion(logger as Test.Logger) as Lang.Boolean {
    var b = timingCorrectionsBytes(corrCtx());
    b[0] = 9;
    var c = timingParseCorrections(b, 1764110000);
    logger.debug("corrVersion=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsLength(logger as Test.Logger) as Lang.Boolean {
    var b = timingCorrectionsBytes(corrCtx());
    b[1] = 38;
    var c = timingParseCorrections(b, 1764110000);
    logger.debug("corrLength=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsCrc(logger as Test.Logger) as Lang.Boolean {
    var b = timingCorrectionsBytes(corrCtx());
    b[12] = (((b[12] as Lang.Number) + 1) & 0xFF);
    var c = timingParseCorrections(b, 1764110000);
    logger.debug("corrCrc=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsExpired(logger as Test.Logger) as Lang.Boolean {
    var b = timingCorrectionsBytes(corrCtx());
    var c = timingParseCorrections(b, 1764300000);
    logger.debug("corrExpired=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsMinute(logger as Test.Logger) as Lang.Boolean {
    var ctx = corrCtx();
    ctx.put(:needMin, 2000);
    var b = timingCorrectionsBytes(ctx);
    var c = timingParseCorrections(b, 1764110000);
    logger.debug("corrMinute=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsNsdrValue(logger as Test.Logger) as Lang.Boolean {
    var ctx = corrCtx();
    ctx.put(:nsdrMin, 15);
    var b = timingCorrectionsBytes(ctx);
    var c = timingParseCorrections(b, 1764110000);
    logger.debug("corrNsdr=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsNull(logger as Test.Logger) as Lang.Boolean {
    var c = timingParseCorrections(null, 1764110000);
    logger.debug("corrNull=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}

(:test)
function corrRejectsWrongType(logger as Test.Logger) as Lang.Boolean {
    var c = timingParseCorrections("pas une trame", 1764110000);
    logger.debug("corrType=" + (c == null ? "rejete" : "accepte"));
    return c == null;
}
