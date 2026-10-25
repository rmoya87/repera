package dev.repera.mobile

import android.Manifest
import android.location.Location
import android.location.LocationManager
import android.os.SystemClock
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import dev.repera.domain.LiveGPSOdometer
import dev.repera.domain.LiveSport
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CopyOnWriteArrayList

/** Emulator-only provider. Synthetic coordinates; no account, Health or backend. */
@RunWith(AndroidJUnit4::class)
class LiveLocationSourceInstrumentedTest {
    // A foreground location request must be tested while the app is visible,
    // not from a background instrumentation process without an Activity/FGS.
    @get:org.junit.Rule val compose=androidx.compose.ui.test.junit4.createAndroidComposeRule<androidx.activity.ComponentActivity>()
    @Suppress("DEPRECATION")
    @Test fun syntheticPlatformProviderStopsOnPauseAndResumeDoesNotBridgeGap() {
        val instrument=InstrumentationRegistry.getInstrumentation()
        val context=instrument.targetContext
        val manager=context.getSystemService(LocationManager::class.java)
        val updates=CopyOnWriteArrayList<LiveGPSOdometer.Update>()
        val source=LiveLocationSource(context) { updates.add(it) }
        fun shell(command:String) {
            instrument.uiAutomation.executeShellCommand(command).use { p ->
                java.io.FileInputStream(p.fileDescriptor).use { it.readBytes() }
            }
        }
        fun awaitCount(count:Int) {
            val end=SystemClock.elapsedRealtime()+10_000
            while(updates.size<count && SystemClock.elapsedRealtime()<end) Thread.sleep(50)
            assertEquals("Expected synthetic provider updates",count,updates.size)
        }
        compose.setContent { androidx.compose.material3.Text("GPS sintético en primer plano") }
        compose.waitForIdle()
        val provider="fused"
        instrument.uiAutomation.grantRuntimePermission(context.packageName,Manifest.permission.ACCESS_COARSE_LOCATION)
        instrument.uiAutomation.grantRuntimePermission(context.packageName,Manifest.permission.ACCESS_FINE_LOCATION)
        shell("appops set ${context.packageName} android:mock_location allow")
        try {
            manager.addTestProvider(provider,false,false,false,false,true,true,true,1,1)
            manager.setTestProviderEnabled(provider,true)
            instrument.runOnMainSync { assertTrue(source.start("synthetic-provider",LiveSport.RUNNING,emptyList(),0.0)) }
            val start=System.currentTimeMillis()
            fun fix(lat:Double,seconds:Long) {
                manager.setTestProviderLocation(provider,Location(provider).apply {
                    latitude=lat;longitude=-3.703;accuracy=3f
                    time=start+seconds*1000;elapsedRealtimeNanos=SystemClock.elapsedRealtimeNanos()
                })
            }
            fix(40.438,0);awaitCount(1)
            Thread.sleep(1_100);fix(40.4381,5);awaitCount(2)
            val meters=updates.last().distanceMeters
            assertTrue(meters>10)
            instrument.runOnMainSync { source.stop("synthetic-provider",false) }
            Thread.sleep(1_100);fix(40.45,6);Thread.sleep(1_500)
            assertEquals(2,updates.size)
            instrument.runOnMainSync { assertTrue(source.start("synthetic-provider",LiveSport.RUNNING,updates.map { it.point },meters)) }
            Thread.sleep(1_100);fix(40.45,7);awaitCount(3)
            assertEquals(meters,updates.last().distanceMeters,0.001)
            assertEquals(3,updates.last().point.id+1)
        } finally {
            instrument.runOnMainSync { source.stop("synthetic-provider") }
            runCatching { manager.removeTestProvider(provider) }
            shell("appops set ${context.packageName} android:mock_location default")
        }
    }
}
