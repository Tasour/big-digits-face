// Motifs de vibration de Protocoles Buzz. Module pur : chaque motif est une
// liste d'etapes [intensite 0-100, duree ms] ; intensite 0 = silence.
// Le compagnon convertit ces etapes en Attention.VibeProfile.
using Toybox.Lang;

module VibrationPatterns {
    const COUNT = 5;
    const VIBRATION_DEFAULT = 0;

    function names() as Lang.Array {
        return ["Court-court-long", "Battement", "Trois courts",
                "Long unique", "Escalier"] as Lang.Array;
    }

    function pattern(index as Lang.Number) as Lang.Array {
        if (index == 0) {
            return [[80, 90], [0, 70], [80, 90], [0, 70], [100, 260]] as Lang.Array;
        }
        if (index == 1) {
            return [[90, 180], [0, 80], [60, 90], [0, 160],
                    [90, 180], [0, 80], [60, 90]] as Lang.Array;
        }
        if (index == 2) {
            return [[80, 100], [0, 90], [80, 100], [0, 90], [80, 100]] as Lang.Array;
        }
        if (index == 3) {
            return [[100, 600]] as Lang.Array;
        }
        if (index == 4) {
            return [[50, 70], [0, 60], [70, 100], [0, 60], [90, 140]] as Lang.Array;
        }
        return [[80, 250]] as Lang.Array;
    }

    function totalMs(index as Lang.Number) as Lang.Number {
        var steps = pattern(index);
        var total = 0;
        for (var i = 0; i < steps.size(); i++) {
            var step = steps[i] as Lang.Array;
            total += step[1] as Lang.Number;
        }
        return total;
    }

    function valid(index as Lang.Number) as Lang.Boolean {
        if (index < 0 || index >= COUNT) { return false; }
        var steps = pattern(index);
        if (steps.size() == 0 || totalMs(index) > 1200) { return false; }
        for (var i = 0; i < steps.size(); i++) {
            var step = steps[i] as Lang.Array;
            var power = step[0] as Lang.Number;
            var ms = step[1] as Lang.Number;
            if (power < 0 || power > 100 || ms <= 0 || ms > 700) { return false; }
        }
        return true;
    }
}
