// Tests de la reinitialisation quotidienne des creneaux.
using Toybox.Lang;
using Toybox.Test;

(:test)
function resetWhenNeverStored(logger as Test.Logger) as Lang.Boolean {
    return shouldResetNotifs(20451, 0);
}

(:test)
function resetWhenPreviousDay(logger as Test.Logger) as Lang.Boolean {
    return shouldResetNotifs(20451, 20450);
}

(:test)
function keepWhenSameDay(logger as Test.Logger) as Lang.Boolean {
    return !shouldResetNotifs(20451, 20451);
}

(:test)
function keepWhenFutureDayIsIgnored(logger as Test.Logger) as Lang.Boolean {
    // Un jour futur est traite comme un etat invalide : on reinitialise.
    return shouldResetNotifs(20451, 20452);
}
