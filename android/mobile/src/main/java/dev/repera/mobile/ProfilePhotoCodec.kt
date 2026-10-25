package dev.repera.mobile
import android.content.ContentResolver
import android.net.Uri

/** Decode selected image with EXIF orientation before bounding it to a profile JPEG. */
internal object ProfilePhotoCodec {
    fun jpeg(resolver:ContentResolver,uri:Uri):ByteArray {
        val source=android.graphics.ImageDecoder.createSource(resolver,uri)
        val bitmap=android.graphics.ImageDecoder.decodeBitmap(source) {decoder,info,_ ->
            val scale=minOf(1.0,256.0/maxOf(info.size.width,info.size.height))
            decoder.setTargetSize(maxOf(1,(info.size.width*scale).toInt()),maxOf(1,(info.size.height*scale).toInt()))
            decoder.allocator=android.graphics.ImageDecoder.ALLOCATOR_SOFTWARE
        }
        return try {
            java.io.ByteArrayOutputStream().also {
                check(bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG,82,it))
            }.toByteArray().also {require(it.isNotEmpty() && it.size<=200_000)}
        } finally {bitmap.recycle()}
    }
}
