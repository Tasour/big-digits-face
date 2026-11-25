// Tests unitaires du moteur de timing (fonctions pures, sans horloge).
using Toybox.Lang;
using Toybox.Test;

(:test)
function timingWrap(logger as Test.Logger) as Lang.Boolean {
    var v = timingMod(-60);
    logger.debug("timingWrap = " + v.format("%d"));
    return v == 1380;
}

(:test)
function timingCircular(logger as Test.Logger) as Lang.Boolean {
    var vals = [1380, 60] as Lang.Array;
    var v = timingCircularMean(vals);
    logger.debug("timingCircular = " + (v == null ? "null" : v.format("%d")));
    return v != null && (v as Lang.Number) == 0;
}

(:test)
function timingTempAt(logger as Test.Logger) as Lang.Boolean {
    var v = timingTempMin(385);
    logger.debug("timingTempAt = " + v.format("%d"));
    return v == 265;
}

(:test)
function timingScreenAt(logger as Test.Logger) as Lang.Boolean {
    var v = timingScreenStart(385);
    logger.debug("timingScreenAt = " + v.format("%d"));
    return v == 1225;
}

(:test)
function timingCaffeineAt(logger as Test.Logger) as Lang.Boolean {
    var v = timingCaffeine(1404);
    logger.debug("timingCaffeineAt = " + v.format("%d"));
    return v == 924;
}

(:test)
function timingDebt(logger as Test.Logger) as Lang.Boolean {
    var vals = [420, 259, 420, 420, 420] as Lang.Array;
    var v = timingDebt7(vals, 420);
    logger.debug("timingDebt = " + v.format("%d"));
    return v == 161;
}

(:test)
function timingZNoBaseline(logger as Test.Logger) as Lang.Boolean {
    var v = timingRobustZ(60, 50, null);
    logger.debug("timingZNoBaseline = " + v.format("%d"));
    return v == 0;
}

(:test)
function timingZPositive(logger as Test.Logger) as Lang.Boolean {
    var v = timingRobustZ(60, 50, 3);
    logger.debug("timingZPositive = " + v.format("%d"));
    return v > 0;
}

(:test)
function timingStepNeed(logger as Test.Logger) as Lang.Boolean {
    var v = timingStepRate(5000, 7000, 100);
    logger.debug("timingStepNeed = " + v.format("%d"));
    return v == 20;
}

(:test)
function timingNsdrDuration(logger as Test.Logger) as Lang.Boolean {
    var a = timingNsdrMinutes(240, 0.0 as Lang.Number);
    var b = timingNsdrMinutes(100, 0.0 as Lang.Number);
    var c = timingNsdrMinutes(0, 0.0 as Lang.Number);
    logger.debug("timingNsdrDuration = " + a.format("%d") + "/" + b.format("%d") + "/" + c.format("%d"));
    return a == 30 && b == 20 && c == 10;
}

(:test)
function timingHysteresisBoth(logger as Test.Logger) as Lang.Boolean {
    var done = timingHysteresis(924, :done);
    var dismissed = timingHysteresis(924, :dismissed);
    var none = timingHysteresis(924, :none);
    logger.debug("timingHysteresisBoth = " + done.format("%d") + "/" + dismissed.format("%d"));
    return done == 909 && dismissed == 939 && none == 924;
}

(:test)
function timingExpiry(logger as Test.Logger) as Lang.Boolean {
    var exact = timingExpired(0, 3600000, 3600000);
    var early = timingExpired(0, 3599999, 3600000);
    logger.debug("timingExpiry = " + (exact ? "1" : "0") + (early ? "1" : "0"));
    return exact && !early;
}

(:test)
function timingChooseCaffeine(logger as Test.Logger) as Lang.Boolean {
    var ctx = {
        :now => 924, :bed => 1404, :wake => 385,
        :steps => 7000, :goal => 7000, :stressZ => 0, :bb => 60,
        :debt => 0, :shortNight => false, :sunset => 1050,
        :sunrise => -1, :bedSD => 0, :nightAlarm => false,
        :span => 720, :elapsed => 0
    } as Lang.Dictionary;
    var r = timingChooseSlot(ctx);
    logger.debug("timingChooseCaffeine = " + (r[:slot] as Lang.Number).format("%d"));
    return (r[:slot] as Lang.Number) == 1500;
}

(:test)
function timingChooseScreens(logger as Test.Logger) as Lang.Boolean {
    var ctx = {
        :now => 1344, :bed => 1404, :wake => 385,
        :steps => 7000, :goal => 7000, :stressZ => 0, :bb => 60,
        :debt => 0, :shortNight => false, :sunset => 1050,
        :sunrise => -1, :bedSD => 0, :nightAlarm => false,
        :span => 720, :elapsed => 0
    } as Lang.Dictionary;
    var r = timingChooseSlot(ctx);
    logger.debug("timingChooseScreens = " + (r[:slot] as Lang.Number).format("%d"));
    return (r[:slot] as Lang.Number) == 2200;
}

(:test)
function timingChooseCalm(logger as Test.Logger) as Lang.Boolean {
    var ctx = {
        :now => 924, :bed => 1404, :wake => 385,
        :steps => 7000, :goal => 7000, :stressZ => 2.5, :bb => 25,
        :debt => 0, :shortNight => false, :sunset => 1050,
        :sunrise => -1, :bedSD => 0, :nightAlarm => false,
        :span => 720, :elapsed => 0
    } as Lang.Dictionary;
    var r = timingChooseSlot(ctx);
    logger.debug("timingChooseCalm = " + (r[:slot] as Lang.Number).format("%d"));
    return (r[:slot] as Lang.Number) == 2230;
}

(:test)
function timingAlarmBedAt(logger as Test.Logger) as Lang.Boolean {
    var v = timingAlarmBed(390, 480);
    logger.debug("timingAlarmBedAt = " + v.format("%d"));
    return v == 1350;
}

(:test)
function timingScreensAt(logger as Test.Logger) as Lang.Boolean {
    var v = timingScreensOff(1350);
    logger.debug("timingScreensAt = " + v.format("%d"));
    return v == 1290;
}

(:test)
function timingNightMatch(logger as Test.Logger) as Lang.Boolean {
    var a = timingNightAlarm(210, 390);
    var b = timingNightAlarm(390, 390);
    logger.debug("timingNightMatch = " + (a ? "1" : "0") + (b ? "1" : "0"));
    return a && !b;
}

(:test)
function timingSpread(logger as Test.Logger) as Lang.Boolean {
    var vals = [1380, 60, 1380, 60] as Lang.Array;
    var v = timingCircularSD(vals);
    logger.debug("timingSpread = " + v.format("%d"));
    return v > 40;
}

(:test)
function timingScoreLow(logger as Test.Logger) as Lang.Boolean {
    var ctx = {:debt => 0, :bedSD => 0, :stressZ => 0, :bb => 80,
               :shortNight => false} as Lang.Dictionary;
    var v = timingNsdrScore(ctx);
    logger.debug("timingScoreLow = " + v.format("%d"));
    return v == 0;
}

(:test)
function timingScoreHigh(logger as Test.Logger) as Lang.Boolean {
    var ctx = {:debt => 600, :bedSD => 90, :stressZ => 3, :bb => 15,
               :shortNight => true} as Lang.Dictionary;
    var v = timingNsdrScore(ctx);
    logger.debug("timingScoreHigh = " + v.format("%d"));
    return v >= 4;
}

(:test)
function timingNsdrTable(logger as Test.Logger) as Lang.Boolean {
    var a = timingNsdrDurationFromScore(3);
    var b = timingNsdrDurationFromScore(2);
    var c = timingNsdrDurationFromScore(1);
    var d = timingNsdrDurationFromScore(0);
    logger.debug("timingNsdrTable = " + a.format("%d") + "/" + b.format("%d") +
                 "/" + c.format("%d") + "/" + d.format("%d"));
    return a == 30 && b == 20 && c == 10 && d == 0;
}

(:test)
function timingNsdrCauseMatch(logger as Test.Logger) as Lang.Boolean {
    var ctx = {:stressZ => 0, :bb => 60, :nightAlarm => true,
               :bedSD => 10, :bed => 1350, :wake => 390} as Lang.Dictionary;
    var cause = timingNsdrCause(ctx);
    var when = timingNsdrTime(ctx);
    logger.debug("timingNsdrCauseMatch = " + cause + " " + when.format("%d"));
    return cause.equals("Reveil de nuit") && when == 840;
}
