// Tests du mini-interpreteur de validation.
using Toybox.Lang;
using Toybox.Test;

function vmCtx() as Lang.Dictionary {
    return {
        :snapSize => 62, :corrSize => 40, :snapCrc => true, :corrCrc => true,
        :missingDecoded => -1,
        :alarm => 390, :bedTarget => 1350, :bedCount => 4, :debt => 139,
        :sunrise => 435, :sunset => 1035, :lightSource => "reel",
        :stressZ100 => 250, :bb => 22, :sample1h => true,
        :nsdrScore => 3, :nsdrMin => 30, :verdict => 2, :corrFresh => true,
        :bleState => "attente", :seq => 7, :tries => 1,
        :width => 454, :boxW => 299, :boxH => 330, :top => 62, :inside => true,
        :keyCount => 8, :storageOk => true, :logReadable => true
    } as Lang.Dictionary;
}

(:test)
function vmQuickOk(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run(ScriptLibrary.QUICK, vmCtx());
    logger.debug("vmQuick=" + (r.get(:reason) as Lang.String));
    return r.get(:ok) as Lang.Boolean;
}

(:test)
function vmContractOk(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run(ScriptLibrary.CONTRACT, vmCtx());
    return r.get(:ok) as Lang.Boolean;
}

(:test)
function vmSleepOk(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run(ScriptLibrary.SLEEP, vmCtx());
    return r.get(:ok) as Lang.Boolean;
}

(:test)
function vmAllScriptOk(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run(ScriptLibrary.ALL, vmCtx());
    return r.get(:ok) as Lang.Boolean;
}

(:test)
function vmRejectsUnknownPrimitive(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run("SAUTER 1\nEND", vmCtx());
    var lines = r.get(:lines) as Lang.Array;
    return !(r.get(:ok) as Lang.Boolean) &&
           (lines[0] as Lang.String).find("inconnue") != null;
}

(:test)
function vmRejectsLongLine(logger as Test.Logger) as Lang.Boolean {
    var long = "";
    for (var i = 0; i < 260; i++) { long += "x"; }
    var r = ScriptVm.run(long, vmCtx());
    return !(r.get(:ok) as Lang.Boolean) &&
           (r.get(:reason) as Lang.String).equals("echec");
}

(:test)
function vmRejectsTooManyLines(logger as Test.Logger) as Lang.Boolean {
    var script = "";
    for (var i = 0; i < 40; i++) { script += "SKIP ligne\n"; }
    var r = ScriptVm.run(script, vmCtx());
    return !(r.get(:ok) as Lang.Boolean) &&
           (r.get(:reason) as Lang.String).equals("trop de lignes");
}

(:test)
function vmTokensAndLines(logger as Test.Logger) as Lang.Boolean {
    var t = ScriptVm.tokens("CHECK contract ok");
    var l = ScriptVm.lines("A\nB\nC");
    return t.size() == 3 && (t[1] as Lang.String).equals("contract") &&
           l.size() == 3 && (l[2] as Lang.String).equals("C");
}

(:test)
function vmExpectFailureIsReported(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run("CHECK contract\nEXPECT verdict == fail\nEND", vmCtx());
    var lines = r.get(:lines) as Lang.Array;
    return !(r.get(:ok) as Lang.Boolean) &&
           (lines[1] as Lang.String).find("fail") != null;
}

(:test)
function vmSkipAndLogProduceNoProbe(logger as Test.Logger) as Lang.Boolean {
    var r = ScriptVm.run("SKIP commentaire\nPRINT rapport\nEND", vmCtx());
    var lines = r.get(:lines) as Lang.Array;
    return (r.get(:ok) as Lang.Boolean) && lines.size() == 1 &&
           (lines[0] as Lang.String).equals("rapport ");
}
