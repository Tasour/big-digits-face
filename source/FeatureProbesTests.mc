// Tests des sondes de validation : chaque sonde est testee avec un contexte
// synthetique. Aucune valeur n'est inventee pour une mesure absente.
using Toybox.Lang;
using Toybox.Test;

(:test)
function probeContractOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_CONTRACT, {
        :snapSize => 62, :corrSize => 40, :snapCrc => true,
        :corrCrc => true, :missingDecoded => -1
    } as Lang.Dictionary);
    logger.debug("probeContract=" + (r.get(:verdict) as Lang.String));
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeContractRejectsBadCrc(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_CONTRACT, {
        :snapSize => 62, :corrSize => 40, :snapCrc => false,
        :corrCrc => true, :missingDecoded => -1
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("fail");
}

(:test)
function probeSleepOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_SLEEP, {
        :alarm => 390, :bedTarget => 1350, :bedCount => 4, :debt => 139
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeLightOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_LIGHT, {
        :sunrise => 435, :sunset => 1035, :lightSource => "reel"
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeStressOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_STRESS, {
        :stressZ100 => 250, :bb => 22, :sample1h => true
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeNsdrRejectsExpiredCorrection(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_NSDR, {
        :nsdrScore => 3, :nsdrMin => 20, :verdict => 2, :corrFresh => false
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("fail");
}

(:test)
function probeBleOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_BLE, {
        :bleState => "attente", :seq => 7, :tries => 1
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeLayoutOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_LAYOUT, {
        :width => 454, :boxW => 299, :boxH => 330, :top => 62, :inside => true
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeStorageOk(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_STORAGE, {
        :keyCount => 8, :storageOk => true, :logReadable => true
    } as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("ok");
}

(:test)
function probeMissingIsNotMeasured(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_STRESS, {} as Lang.Dictionary);
    logger.debug("probeMissing=" + (r.get(:verdict) as Lang.String));
    return (r.get(:verdict) as Lang.String).equals("notMeasured");
}

(:test)
function probeUnknownIsNotMeasured(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe("inconnu", {} as Lang.Dictionary);
    return (r.get(:verdict) as Lang.String).equals("notMeasured");
}

(:test)
function probeAllCoversEightFeatures(logger as Test.Logger) as Lang.Boolean {
    var reports = FeatureProbes.reportAll({} as Lang.Dictionary);
    logger.debug("probeAll=" + reports.size().toString());
    return reports.size() == 8;
}

(:test)
function probeLinesCarryReport(logger as Test.Logger) as Lang.Boolean {
    var r = FeatureProbes.probe(FeatureProbes.PROBE_BLE, {
        :bleState => "attente", :seq => 7, :tries => 1
    } as Lang.Dictionary);
    var lines = FeatureProbes.lines(r);
    return lines.size() >= 2 && (lines[0] as Lang.String).find("-> ok") != null;
}
