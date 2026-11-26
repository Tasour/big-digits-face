// Etat quotidien des rappels du cadran : fonction pure et testable.
using Toybox.Lang;

function shouldResetNotifs(currentDay as Lang.Number, storedDay as Lang.Number) as Lang.Boolean {
    return storedDay != currentDay;
}
