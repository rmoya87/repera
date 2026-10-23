package dev.repera.mobile

import android.app.Activity
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView

/** Explanation shown from Health Connect's permission-management settings. */
class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(ScrollView(this).apply {
            addView(TextView(context).apply {
                textSize = 17f
                val dp = (20 * resources.displayMetrics.density).toInt()
                setPadding(dp, dp, dp, dp)
                text = """
                    Repera · Uso de datos de Salud

                    Los permisos de pasos y calorías activas son opcionales.
                    Se leen para mostrar las mediciones reales del día en la aplicación.
                    Si no hay mediciones o revocas el acceso, Repera muestra datos no disponibles.

                    Repera no genera calorías ficticias, no vende datos de salud y
                    no necesita enviar esas mediciones a Google Drive ni a Supabase
                    para mostrar la actividad diaria.

                    Puedes revocar los permisos desde Health Connect.
                """.trimIndent()
            })
        })
    }
}
