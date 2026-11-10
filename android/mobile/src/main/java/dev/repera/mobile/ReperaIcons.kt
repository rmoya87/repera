package dev.repera.mobile

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

/** Iconos vectoriales propios para paridad SF Symbols (p. ej. `dumbbell` horizontal). */
internal object ReperaIcons {
    /** Mancuerna horizontal (SF `dumbbell`); Material FitnessCenter es diagonal. */
    val Dumbbell: ImageVector
        get() {
            if (_dumbbell != null) return _dumbbell!!
            _dumbbell = ImageVector.Builder(
                name = "Repera.Dumbbell",
                defaultWidth = 24.dp,
                defaultHeight = 24.dp,
                viewportWidth = 24f,
                viewportHeight = 24f
            ).apply {
                // Barra central
                path(
                    fill = SolidColor(Color.Black),
                    stroke = null,
                    strokeLineWidth = 0f,
                    strokeLineCap = StrokeCap.Butt,
                    strokeLineJoin = StrokeJoin.Miter,
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(7f, 11f)
                    horizontalLineTo(17f)
                    verticalLineTo(13f)
                    horizontalLineTo(7f)
                    close()
                }
                // Disco izquierdo
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(3f, 8f)
                    horizontalLineTo(6f)
                    verticalLineTo(16f)
                    horizontalLineTo(3f)
                    close()
                }
                // Tope izquierdo
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(1.5f, 9.5f)
                    horizontalLineTo(3f)
                    verticalLineTo(14.5f)
                    horizontalLineTo(1.5f)
                    close()
                }
                // Disco derecho
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(18f, 8f)
                    horizontalLineTo(21f)
                    verticalLineTo(16f)
                    horizontalLineTo(18f)
                    close()
                }
                // Tope derecho
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(21f, 9.5f)
                    horizontalLineTo(22.5f)
                    verticalLineTo(14.5f)
                    horizontalLineTo(21f)
                    close()
                }
            }.build()
            return _dumbbell!!
        }

    /**
     * Persona con barra (SF `figure.strengthtraining.traditional`, trazado).
     * Usado en entreno programado de Inicio y atajo «Entreno de hoy».
     */
    val StrengthTraditional: ImageVector
        get() {
            if (_strengthTraditional != null) return _strengthTraditional!!
            _strengthTraditional = ImageVector.Builder(
                name = "Repera.StrengthTraditional",
                defaultWidth = 24.dp,
                defaultHeight = 24.dp,
                viewportWidth = 24f,
                viewportHeight = 24f
            ).apply {
                // Torso + brazos + barra
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(9.95f, 6.12f)
                    lineTo(14.60f, 6.39f)
                    lineTo(18.15f, 12.68f)
                    lineTo(19.52f, 12.68f)
                    lineTo(20.07f, 10.22f)
                    lineTo(21.43f, 10.22f)
                    lineTo(21.71f, 12.41f)
                    lineTo(22.80f, 12.96f)
                    lineTo(22.80f, 13.50f)
                    lineTo(21.71f, 14.05f)
                    lineTo(21.43f, 15.96f)
                    lineTo(20.34f, 16.24f)
                    lineTo(19.79f, 15.69f)
                    lineTo(19.52f, 13.78f)
                    lineTo(18.70f, 13.78f)
                    lineTo(18.15f, 15.14f)
                    lineTo(17.33f, 15.14f)
                    lineTo(16.24f, 13.78f)
                    lineTo(7.76f, 13.78f)
                    lineTo(6.67f, 15.14f)
                    lineTo(5.85f, 15.14f)
                    lineTo(5.57f, 14.05f)
                    lineTo(4.48f, 13.78f)
                    lineTo(4.21f, 15.69f)
                    lineTo(3.66f, 16.24f)
                    lineTo(2.84f, 16.24f)
                    lineTo(2.57f, 14.05f)
                    lineTo(1.20f, 13.50f)
                    lineTo(1.47f, 12.68f)
                    lineTo(2.57f, 12.41f)
                    lineTo(2.57f, 10.50f)
                    lineTo(3.93f, 10.22f)
                    lineTo(4.21f, 12.41f)
                    lineTo(6.12f, 12.68f)
                    lineTo(8.86f, 7.22f)
                    lineTo(9.68f, 6.39f)
                    close()
                }
                // Piernas
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(9.68f, 14.60f)
                    lineTo(14.32f, 14.60f)
                    lineTo(14.60f, 14.87f)
                    lineTo(16.51f, 21.71f)
                    lineTo(15.96f, 22.80f)
                    lineTo(15.14f, 22.80f)
                    lineTo(14.60f, 22.25f)
                    lineTo(13.78f, 18.15f)
                    lineTo(12.41f, 15.69f)
                    lineTo(11.86f, 15.42f)
                    lineTo(10.22f, 18.15f)
                    lineTo(9.40f, 22.25f)
                    lineTo(8.86f, 22.80f)
                    lineTo(8.04f, 22.80f)
                    lineTo(7.76f, 20.89f)
                    lineTo(8.31f, 18.15f)
                    lineTo(9.68f, 14.87f)
                    close()
                }
                // Cabeza
                path(
                    fill = SolidColor(Color.Black),
                    pathFillType = PathFillType.NonZero
                ) {
                    moveTo(11.59f, 1.20f)
                    lineTo(13.50f, 1.75f)
                    lineTo(14.05f, 2.84f)
                    lineTo(13.78f, 4.21f)
                    lineTo(12.96f, 5.03f)
                    lineTo(11.32f, 5.03f)
                    lineTo(10.22f, 4.21f)
                    lineTo(9.95f, 3.39f)
                    lineTo(10.22f, 2.29f)
                    lineTo(11.32f, 1.47f)
                    close()
                }
            }.build()
            return _strengthTraditional!!
        }

    private var _dumbbell: ImageVector? = null
    private var _strengthTraditional: ImageVector? = null
}
