package dev.repera.mobile

import android.graphics.Bitmap
import android.graphics.Color
import android.media.ExifInterface
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

    @Test
    fun exifRotate90SwapsWidthAndHeight() {
        val source = Bitmap.createBitmap(40, 20, Bitmap.Config.ARGB_8888)
        source.eraseColor(Color.WHITE)
        val rotated = BoardScanOcr.applyExifOrientation(
            source, ExifInterface.ORIENTATION_ROTATE_90
        )
        assertEquals(20, rotated.width)
        assertEquals(40, rotated.height)
        if (rotated !== source) source.recycle()
        rotated.recycle()
    }

    @Test
    fun exifNormalReusesBitmap() {
        val source = Bitmap.createBitmap(16, 16, Bitmap.Config.ARGB_8888)
        val same = BoardScanOcr.applyExifOrientation(
            source, ExifInterface.ORIENTATION_NORMAL
        )
        assertEquals(source, same)
        source.recycle()
    }
}
