// Tests unitaires Run No Evil — fenetre glissante d'habitude.
// Compile avec --unit-test, execute avec monkeydo <prg> fr955 /t.
using Toybox.Lang;
using Toybox.Test;

(:test)
function habitNoGap(logger as Test.Logger) as Lang.Boolean {
    var bits = shiftHabitBits(0x01, 0);
    logger.debug("habitNoGap = " + bits.format("%02x"));
    return bits == 0x01;
}

(:test)
function habitThreeDaysMissing(logger as Test.Logger) as Lang.Boolean {
    // Un marquage a J-3 doit rester visible au bit 3, pas disparaitre.
    var bits = shiftHabitBits(0x01, 3);
    logger.debug("habitThreeDaysMissing = " + bits.format("%02x"));
    return bits == 0x08;
}

(:test)
function habitSevenDaysMissing(logger as Test.Logger) as Lang.Boolean {
    var bits = shiftHabitBits(0x01, 7);
    logger.debug("habitSevenDaysMissing = " + bits.format("%02x"));
    return bits == 0x00;
}

(:test)
function habitClockBackward(logger as Test.Logger) as Lang.Boolean {
    var bits = shiftHabitBits(0x01, -1);
    logger.debug("habitClockBackward = " + bits.format("%02x"));
    return bits == 0x01;
}

(:test)
function habitFullWeek(logger as Test.Logger) as Lang.Boolean {
    var bits = shiftHabitBits(0x7F, 2);
    logger.debug("habitFullWeek = " + bits.format("%02x"));
    return bits == 0x7C;
}

(:test)
function weekdaySunday(logger as Test.Logger) as Lang.Boolean {
    var c = weekdayLetterFor(1, 0);
    logger.debug("weekdaySunday = " + c);
    return c.equals("D");
}

(:test)
function weekdayTuesdaySequence(logger as Test.Logger) as Lang.Boolean {
    var s = "";
    for (var i = 0; i < 7; i++) {
        s = s + weekdayLetterFor(3, i);
    }
    logger.debug("weekdayTuesdaySequence = " + s);
    return s.equals("MLDSVJM");
}
