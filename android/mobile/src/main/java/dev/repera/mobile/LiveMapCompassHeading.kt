package dev.repera.mobile

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver

/** Sensor de orientación antes de Play; GPS medido prevalece al caminar.
 * Sin sensor se omite rumbo. Se detiene al pasar a background. */
@Composable internal fun rememberLiveMapCompassHeading(
    enabled:Boolean,latitude:Double?,longitude:Double?
):Double? {
    val context=LocalContext.current
    val lifecycle=LocalLifecycleOwner.current.lifecycle
    val coords by rememberUpdatedState(latitude to longitude)
    var heading by remember { mutableStateOf<Double?>(null) }
    DisposableEffect(context,lifecycle,enabled) {
        val mgr=context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor=mgr?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if(!enabled || mgr==null || sensor==null) onDispose { heading=null }
        else {
            val listener=object:SensorEventListener {
                override fun onAccuracyChanged(sensor:Sensor?,accuracy:Int) {}
                override fun onSensorChanged(event:SensorEvent) {
                    if(event.sensor.type!=Sensor.TYPE_ROTATION_VECTOR) return
                    val matrix=FloatArray(9);val orientation=FloatArray(3)
                    SensorManager.getRotationMatrixFromVector(matrix,event.values)
                    SensorManager.getOrientation(matrix,orientation)
                    val magnetic=Math.toDegrees(orientation[0].toDouble())
                    val (lat,lon)=coords
                    val declination=if(lat!=null && lon!=null && lat.isFinite() && lon.isFinite() &&
                        lat in -90.0..90.0 && lon in -180.0..180.0)
                        GeomagneticField(lat.toFloat(),lon.toFloat(),0f,
                            System.currentTimeMillis()).declination.toDouble()
                    else 0.0
                    heading=(magnetic+declination+360.0)%360.0
                }
            }
            fun sync() {
                mgr.unregisterListener(listener)
                if(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED))
                    mgr.registerListener(listener,sensor,SensorManager.SENSOR_DELAY_UI)
            }
            val observer=LifecycleEventObserver { _,_ -> sync() }
            lifecycle.addObserver(observer);sync()
            onDispose { lifecycle.removeObserver(observer);mgr.unregisterListener(listener);heading=null }
        }
    }
    return heading
}
