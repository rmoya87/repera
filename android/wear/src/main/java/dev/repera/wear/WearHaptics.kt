package dev.repera.wear

import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View

/** System haptics respect the user's touch-feedback setting and need no VIBRATE permission. */
internal enum class WearHaptic { CONFIRM, REJECT, TOGGLE_ON, TOGGLE_OFF }

internal fun wearHapticConstant(kind: WearHaptic, sdk: Int = Build.VERSION.SDK_INT): Int = when (kind) {
    WearHaptic.CONFIRM -> HapticFeedbackConstants.CONFIRM
    WearHaptic.REJECT -> HapticFeedbackConstants.REJECT
    WearHaptic.TOGGLE_ON ->
        if (sdk >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) HapticFeedbackConstants.TOGGLE_ON
        else HapticFeedbackConstants.CONFIRM
    WearHaptic.TOGGLE_OFF ->
        if (sdk >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) HapticFeedbackConstants.TOGGLE_OFF
        else HapticFeedbackConstants.CLOCK_TICK
}

internal fun View.performWearHaptic(kind: WearHaptic) {
    performHapticFeedback(wearHapticConstant(kind))
}
