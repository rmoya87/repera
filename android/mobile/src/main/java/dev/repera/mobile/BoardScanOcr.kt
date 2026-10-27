package dev.repera.mobile

import android.content.Context
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * OCR de pizarra con ML Kit (latin). Equivalente Android de
 * BoardTextRecognizer (Vision) en iOS: foto -> texto plano.
 */
object BoardScanOcr {
    suspend fun recognize(context: Context, uri: Uri): String =
        withContext(Dispatchers.IO) {
            val image = InputImage.fromFilePath(context, uri)
            suspendCancellableCoroutine { cont ->
                val recognizer=TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                cont.invokeOnCancellation {recognizer.close()}
                recognizer.process(image)
                    .addOnSuccessListener { result -> if(cont.isActive) cont.resume(result.text) }
                    .addOnFailureListener { error -> if(cont.isActive) cont.resumeWithException(error) }
                    .addOnCompleteListener {recognizer.close()}
            }
        }
}
