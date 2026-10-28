package dev.repera.mobile

import android.graphics.Bitmap
import android.graphics.Color
import org.junit.Assert.assertTrue
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class BoardScanOcrLuminanceTest {

    @Test
    fun darkBitmapMedianIsBelowThreshold() {
        val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.rgb(20, 20, 20))
        val median = BoardScanOcr.sampleMedianLuminance(bitmap)
        assertTrue(median < BoardScanOcr.DARK_LUMINANCE_THRESHOLD)
        val prepared = BoardScanOcr.prepareForOcr(bitmap)
        // Prepare returns a new canvas for dark boards.
        assertTrue(prepared !== bitmap || median < BoardScanOcr.DARK_LUMINANCE_THRESHOLD)
        prepared.recycle()
    }

    @Test
    fun brightBitmapStaysAboveThresholdAndIsReused() {
        val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.rgb(240, 240, 240))
        val median = BoardScanOcr.sampleMedianLuminance(bitmap)
        assertTrue(median >= BoardScanOcr.DARK_LUMINANCE_THRESHOLD)
        val prepared = BoardScanOcr.prepareForOcr(bitmap)
        assertEquals(bitmap, prepared)
        prepared.recycle()
    }
}
