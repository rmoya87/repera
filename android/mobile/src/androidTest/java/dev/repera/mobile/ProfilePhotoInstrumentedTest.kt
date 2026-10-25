package dev.repera.mobile
import androidx.test.platform.app.InstrumentationRegistry
import android.graphics.Bitmap
import android.graphics.Color
import android.net.Uri
import org.junit.Assert.*
import org.junit.Test
import org.json.*

class ProfilePhotoInstrumentedTest {
    @Test fun selectedPhotoRotatesExifBoundsJpegAndPersistsOnlyInOwnAccount() {
        val context=InstrumentationRegistry.getInstrumentation().targetContext
        val file=java.io.File.createTempFile("profile-fixture-",".jpg",context.cacheDir)
        try {
            val source=Bitmap.createBitmap(800,400,Bitmap.Config.ARGB_8888)
            for(y in 0 until 400) for(x in 0 until 800) source.setPixel(x,y,if(x<400) Color.RED else Color.BLUE)
            file.outputStream().use {assertTrue(source.compress(Bitmap.CompressFormat.JPEG,95,it))};source.recycle()
            android.media.ExifInterface(file.path).apply {
                setAttribute(android.media.ExifInterface.TAG_ORIENTATION,android.media.ExifInterface.ORIENTATION_ROTATE_90.toString())
                saveAttributes()
            }
            val encoded=ProfilePhotoCodec.jpeg(context.contentResolver,Uri.fromFile(file))
            val bitmap=android.graphics.BitmapFactory.decodeByteArray(encoded,0,encoded.size)
            assertEquals(128,bitmap.width);assertEquals(256,bitmap.height)
            assertTrue(Color.red(bitmap.getPixel(64,30))>200)
            assertTrue(Color.blue(bitmap.getPixel(64,225))>200)
            val account="photo-${java.util.UUID.randomUUID()}"
            val local=LocalSnapshotStore(context,account)
            local.write(JSONObject().put("workouts",JSONArray()).put("routines",JSONArray()).put("exercises",JSONArray()).toString().toByteArray())
            WorkoutRepository(context,account).updateProfile(ProfileSettings("Prueba",android.util.Base64.encodeToString(encoded,android.util.Base64.NO_WRAP)))
            val read=StateOverview.fromBytes(local.read())!!.profileSettings
            assertEquals("Prueba",read.displayName)
            assertArrayEquals(encoded,android.util.Base64.decode(read.avatarJPEG,android.util.Base64.DEFAULT))
            assertNull(LocalSnapshotStore(context,"other-$account").read())
            // Persist the decoded output as visual evidence of orientation, not the source fixture.
            val values=android.content.ContentValues().apply {
                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME,"perfil_foto_orientada_sintetica.png")
                put(android.provider.MediaStore.Images.Media.MIME_TYPE,"image/png")
                put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,"Pictures/ReperaVerification")
            }
            val uri=context.contentResolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI,values)!!
            context.contentResolver.openOutputStream(uri)!!.use {bitmap.compress(Bitmap.CompressFormat.PNG,100,it)}
            bitmap.recycle()
        } finally {file.delete()}
    }
}
