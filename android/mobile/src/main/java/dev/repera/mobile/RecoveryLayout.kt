package dev.repera.mobile
/** Threshold mirrors current Apple HealthRecovery width check; visual parity remains separate. */
internal fun recoveryColumns(widthDp:Float)=adaptiveCardColumns(widthDp)

/** HealthRecovery cut: primary220; DUO uses column surface minus OG.pad*2 (16 each). */
internal fun readinessChartHeightDp(columnWidthDp:Float,expanded:Boolean):Float =
    if(!expanded) 220f else ((columnWidthDp-32f)*(2f/3f)).coerceIn(205f,270f)
