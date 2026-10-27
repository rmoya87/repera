package dev.repera.wear

import android.content.ComponentName
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Test

/** Compiled, not run. Provider/lifecycle/notification need a real watch test. */
class WearHealthServiceManifestInstrumentedTest {
    @Test fun healthRecorderIsPrivateAndDeclaresHealthType() {
        val ctx=InstrumentationRegistry.getInstrumentation().targetContext
        val info=ctx.packageManager.getServiceInfo(ComponentName(ctx,WearHealthService::class.java),PackageManager.GET_META_DATA)
        assertFalse(info.exported)
        assertEquals(ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH,info.foregroundServiceType)
    }
}
