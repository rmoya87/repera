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

    private var _dumbbell: ImageVector? = null
}
