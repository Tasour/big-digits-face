// Sondes de validation des fonctionnalites. Module pur : il ne lit ni storage,
// ni capteur, ni horloge. L'app compagnon construit le contexte, ce module ne
// juge que des valeurs recues et produit un rapport texte.
//
// Verdicts : "ok" (mesure prouvee), "fail" (mesure contraire a la regle),
// "notMeasured" (valeur absente, jamais un echec invente).

using Toybox.Lang;

module FeatureProbes {
    const PROBE_CONTRACT = "contract";
    const PROBE_SLEEP = "sleep";
    const PROBE_LIGHT = "light";
    const PROBE_STRESS = "stress";
    const PROBE_NSDR = "nsdr";
    const PROBE_BLE = "ble";
    const PROBE_LAYOUT = "layout";
    const PROBE_STORAGE = "storage";

    function probeIds() as Lang.Array {
        return [PROBE_CONTRACT, PROBE_SLEEP, PROBE_LIGHT, PROBE_STRESS,
                PROBE_NSDR, PROBE_BLE, PROBE_LAYOUT, PROBE_STORAGE] as Lang.Array;
    }

    function num(ctx as Lang.Dictionary, key as Lang.Symbol) as Lang.Number {
        var v = ctx.get(key);
        if (v != null && v instanceof Lang.Number) { return v as Lang.Number; }
        return -1;
    }

    function text(ctx as Lang.Dictionary, key as Lang.Symbol) as Lang.String {
        var v = ctx.get(key);
        if (v != null && v instanceof Lang.String) { return v as Lang.String; }
        return "absent";
    }

    function flag(ctx as Lang.Dictionary, key as Lang.Symbol) as Lang.Boolean {
        var v = ctx.get(key);
        if (v != null && v instanceof Lang.Boolean) { return v as Lang.Boolean; }
        return false;
    }

    function result(id as Lang.String, label as Lang.String, verdict as Lang.String,
                    lines as Lang.Array) as Lang.Dictionary {
        return {:id => id, :label => label, :verdict => verdict,
                :lines => lines} as Lang.Dictionary;
    }

    function judge(hasValue as Lang.Boolean, passes as Lang.Boolean) as Lang.String {
        if (!hasValue) { return "notMeasured"; }
        return passes ? "ok" : "fail";
    }

    // --- Sondes -------------------------------------------------------------

    function probeContract(ctx as Lang.Dictionary) as Lang.Dictionary {
        var snap = num(ctx, :snapSize);
        var corr = num(ctx, :corrSize);
        var snapCrc = flag(ctx, :snapCrc);
        var corrCrc = flag(ctx, :corrCrc);
        var missing = num(ctx, :missingDecoded);
        // -1 est une valeur decodee legitime pour l'absence : il ne faut pas
        // en faire un marqueur d'absence de mesure.
        var seen = snap != -1 && corr != -1;
        var ok = snap == 62 && corr == 40 && snapCrc && corrCrc && missing == -1;
        return result(PROBE_CONTRACT, "Contrat binaire", judge(seen, ok), [
            "snapshot=" + snap.toString() + "o/62",
            "corrections=" + corr.toString() + "o/40",
            "CRC=" + (snapCrc ? "ok" : "ko") + "/" + (corrCrc ? "ok" : "ko"),
            "absence=" + missing.toString()
        ] as Lang.Array);
    }

    function probeSleep(ctx as Lang.Dictionary) as Lang.Dictionary {
        var alarm = num(ctx, :alarm);
        var bed = num(ctx, :bedTarget);
        var nights = num(ctx, :bedCount);
        var debt = num(ctx, :debt);
        var seen = alarm != -1 && bed != -1 && nights != -1 && debt != -1;
        var ok = alarm >= 0 && alarm <= 1439 && bed >= 0 && bed <= 1439 &&
                 nights >= 0 && debt >= 0;
        return result(PROBE_SLEEP, "Reveil / sommeil", judge(seen, ok), [
            "reveil=" + alarm.toString() + " min",
            "coucher vise=" + bed.toString() + " min",
            "nuits enregistrees=" + nights.toString(),
            "dette 7 nuits=" + debt.toString() + " min"
        ] as Lang.Array);
    }

    function probeLight(ctx as Lang.Dictionary) as Lang.Dictionary {
        var rise = num(ctx, :sunrise);
        var set = num(ctx, :sunset);
        var src = text(ctx, :lightSource);
        var seen = rise != -1 && set != -1;
        var ok = rise >= 0 && rise <= 1439 && set >= 0 && set <= 1439 && rise < set;
        return result(PROBE_LIGHT, "Lumiere", judge(seen, ok), [
            "lever=" + rise.toString() + " min",
            "coucher=" + set.toString() + " min",
            "source=" + src
        ] as Lang.Array);
    }

    function probeStress(ctx as Lang.Dictionary) as Lang.Dictionary {
        var z = num(ctx, :stressZ100);
        var bb = num(ctx, :bb);
        var sample = flag(ctx, :sample1h);
        var seen = z != -1 && bb != -1;
        var ok = z >= 0 && bb >= 0 && bb <= 100;
        return result(PROBE_STRESS, "Stress / Battery", judge(seen, ok), [
            "stress z x100=" + z.toString(),
            "Body Battery=" + bb.toString() + "/100",
            "echantillon 1h=" + (sample ? "present" : "absent")
        ] as Lang.Array);
    }

    function probeNsdr(ctx as Lang.Dictionary) as Lang.Dictionary {
        var score = num(ctx, :nsdrScore);
        var minutes = num(ctx, :nsdrMin);
        var verdict = num(ctx, :verdict);
        var fresh = flag(ctx, :corrFresh);
        var seen = score != -1 && minutes != -1 && verdict != -1;
        var ok = score >= 0 && score <= 5 &&
                 (minutes == 0 || minutes == 10 || minutes == 20 || minutes == 30) &&
                 verdict >= 0 && verdict <= 2 && fresh;
        return result(PROBE_NSDR, "NSDR", judge(seen, ok), [
            "score=" + score.toString() + "/5",
            "duree=" + minutes.toString() + " min (0/10/20/30)",
            "verdict=" + verdict.toString(),
            "correction fraiche=" + (fresh ? "oui" : "non")
        ] as Lang.Array);
    }

    function probeBle(ctx as Lang.Dictionary) as Lang.Dictionary {
        var state = text(ctx, :bleState);
        var seq = num(ctx, :seq);
        var tries = num(ctx, :tries);
        var seen = seq != -1 && tries != -1;
        var ok = !state.equals("absent") && seq >= 0 && tries >= 0 && tries <= 3;
        return result(PROBE_BLE, "Lien telephone", judge(seen, ok), [
            "etat=" + state,
            "seq=" + seq.toString(),
            "tentatives=" + tries.toString() + "/3"
        ] as Lang.Array);
    }

    function probeLayout(ctx as Lang.Dictionary) as Lang.Dictionary {
        var width = num(ctx, :width);
        var boxW = num(ctx, :boxW);
        var top = num(ctx, :top);
        var boxH = num(ctx, :boxH);
        var inside = flag(ctx, :inside);
        var seen = width != -1 && boxW != -1 && top != -1 && boxH != -1;
        var ok = inside && boxW * 10 <= width * 7 && top >= 0;
        return result(PROBE_LAYOUT, "Grille du diagnostic", judge(seen, ok), [
            "ecran=" + width.toString() + " px",
            "bloc=" + boxW.toString() + "x" + boxH.toString() + " px",
            "haut=" + top.toString() + " px",
            "dans le cercle=" + (inside ? "oui" : "non")
        ] as Lang.Array);
    }

    function probeStorage(ctx as Lang.Dictionary) as Lang.Dictionary {
        var count = num(ctx, :keyCount);
        var storageOk = flag(ctx, :storageOk);
        var logOk = flag(ctx, :logReadable);
        var seen = count != -1;
        var ok = storageOk && logOk && count > 0;
        return result(PROBE_STORAGE, "Stockage / journal", judge(seen, ok), [
            "cles de validation=" + count.toString(),
            "ecriture storage=" + (storageOk ? "ok" : "ko"),
            "journal lisible=" + (logOk ? "oui" : "non")
        ] as Lang.Array);
    }

    function probe(id as Lang.String, ctx as Lang.Dictionary) as Lang.Dictionary {
        if (id.equals(PROBE_CONTRACT)) { return probeContract(ctx); }
        if (id.equals(PROBE_SLEEP)) { return probeSleep(ctx); }
        if (id.equals(PROBE_LIGHT)) { return probeLight(ctx); }
        if (id.equals(PROBE_STRESS)) { return probeStress(ctx); }
        if (id.equals(PROBE_NSDR)) { return probeNsdr(ctx); }
        if (id.equals(PROBE_BLE)) { return probeBle(ctx); }
        if (id.equals(PROBE_LAYOUT)) { return probeLayout(ctx); }
        if (id.equals(PROBE_STORAGE)) { return probeStorage(ctx); }
        return result(id, "Inconnu", "notMeasured", ["sonde inconnue : " + id] as Lang.Array);
    }

    function reportAll(ctx as Lang.Dictionary) as Lang.Array {
        var ids = probeIds();
        var reports = [] as Lang.Array;
        for (var i = 0; i < ids.size(); i++) {
            reports.add(probe(ids[i] as Lang.String, ctx));
        }
        return reports;
    }

    function lines(report as Lang.Dictionary) as Lang.Array {
        var out = [] as Lang.Array;
        var label = report.get(:label) as Lang.String;
        var verdict = report.get(:verdict) as Lang.String;
        out.add(label + " -> " + verdict);
        var rows = report.get(:lines) as Lang.Array;
        for (var i = 0; i < rows.size(); i++) {
            out.add("  " + (rows[i] as Lang.String));
        }
        return out;
    }
}
