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
                    no necesita enviar esas mediciones a Google Drive ni a la nube
                    para mostrar la actividad diaria.

                    El acceso al historial anterior a 30 días es opcional y se solicita
                    solo si tu versión de Health Connect lo permite. Se usa para las
                    tendencias de Progreso, peso y recuperación. Sin ese permiso,
                    Health Connect limita las lecturas antiguas; no significa que nunca
                    hayas tenido registros. Las lecturas que ya hayas autorizado siguen disponibles.

                    Sueño y ciclo requieren además que actives su opción privada en Repera.
                    Las decisiones de esas opciones se guardan solo en este dispositivo.
                    Puedes revocar los permisos desde Health Connect.
                """.trimIndent()
            })
        })
    }
}
