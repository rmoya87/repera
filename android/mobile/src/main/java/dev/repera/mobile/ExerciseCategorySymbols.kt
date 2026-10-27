package dev.repera.mobile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessibilityNew
import androidx.compose.material.icons.filled.Adjust
import androidx.compose.material.icons.filled.Apps
import androidx.compose.material.icons.filled.CallMade
import androidx.compose.material.icons.filled.Chair
import androidx.compose.material.icons.filled.DirectionsBike
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.DonutLarge
import androidx.compose.material.icons.filled.DoorFront
import androidx.compose.material.icons.filled.DownhillSkiing
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.GridOn
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Rowing
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.SportsBasketball
import androidx.compose.material.icons.filled.SportsGymnastics
import androidx.compose.material.icons.filled.Square
import androidx.compose.material.icons.filled.Terrain
import androidx.compose.material.icons.filled.TripOrigin
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Puerto de ExerciseCategorySymbols.swift (Apple 0a640da8, fdbd3558): símbolos
 * de disciplina, equipo y aparatos para chips de biblioteca y ficha. SF Symbols
 * no existe en Android: cada símbolo se aproxima al Material Icon semántico más
 * cercano (el conjunto de reglas de coincidencia es 1:1 con Apple).
 */
object ExerciseCategorySymbols {
    /** figure.stand */
    val muscle: ImageVector = Icons.Filled.AccessibilityNew
    /** dumbbell */
    val equipment: ImageVector = Icons.Filled.FitnessCenter

    fun discipline(name: String): ImageVector =
        when (dev.repera.domain.ExerciseAliasSearch.normalize(name)) {
            "crossfit", "cross fit" -> Icons.Filled.FitnessCenter   // figure.cross.training
            "gimnasia", "gimnasticos", "gymnastics", "gymnastic" ->
                Icons.Filled.SportsGymnastics                       // figure.play
            "hyrox" -> Icons.Filled.DirectionsRun                   // figure.run
            "movilidad", "mobility" -> Icons.Filled.SelfImprovement // figure.flexibility
            "halterofilia", "weightlifting" ->
                Icons.Filled.FitnessCenter                          // figure.strengthtraining.traditional
            "cardio" -> Icons.Filled.Favorite                       // heart
            else -> Icons.Filled.EmojiEvents                        // sportscourt
        }

    /** Símbolos por aparato (reglas contains() 1:1 con Apple). */
    fun equipmentSymbol(material: String): ImageVector {
        val e = dev.repera.domain.ExerciseAliasSearch.normalize(material)
        if (e.contains("cajon") || e.contains("step") || e.contains("plataforma")) return Icons.Filled.Square // cube
        if (e.contains("anillas") || e.contains("rings")) return Icons.Filled.RadioButtonUnchecked // circle
        if (e.contains("barra de dominadas") || e.contains("barra fija")) return Icons.Filled.Terrain // figure.climbing
        if (e.contains("barra") || e.contains("barbell")) return Icons.Filled.FitnessCenter // strengthtraining.traditional
        if (e.contains("mancuerna") || e.contains("dumbbell")) return Icons.Filled.FitnessCenter // dumbbell
        if (e.contains("kettlebell") || e.contains("pesa rusa")) return Icons.Filled.Scale // scalemass
        if (e.contains("lastre") || e.contains("chaleco")) return Icons.Filled.Scale // scalemass
        if (e.contains("comba")) return Icons.Filled.DirectionsRun // figure.jumprope ≈
        if (e.contains("cuerda de trepa")) return Icons.Filled.Terrain // figure.climbing
        if (e.contains("paralela") || e.contains("parallete")) return Icons.Filled.FitnessCenter // strengthtraining.functional
        if (e.contains("rueda abdominal") || e.contains("ab wheel")) return Icons.Filled.TripOrigin // circle.circle
        if (e.contains("rodillo")) return Icons.Filled.RadioButtonUnchecked // circle
        if (e.contains("banco")) return Icons.Filled.Chair // chair.lounge
        if (e.contains("pared") || e.contains("muro")) return Icons.Filled.GridOn // square.grid.3x3
        if (e.contains("puerta")) return Icons.Filled.DoorFront // door.left.hand.closed
        if (e.contains("banda") || e.contains("goma")) return Icons.Filled.DonutLarge // circle.dashed
        if (e.contains("pica")) return Icons.Filled.CallMade // line.diagonal ≈
        if (e.contains("disco")) return Icons.Filled.Adjust // circle.dotted.circle
        if (e.contains("balon") || e.contains("ball")) return Icons.Filled.SportsBasketball // basketball
        if (e.contains("ski") || e.contains("esqui")) return Icons.Filled.DownhillSkiing // figure.skiing.crosscountry
        if (e.contains("remo") || e.contains("rowerg")) return Icons.Filled.Rowing // figure.rower
        if (e.contains("cinta de correr") || e.contains("treadmill")) return Icons.Filled.DirectionsRun // figure.run
        if (e.contains("bicicleta") || e.contains("bike")) return Icons.Filled.DirectionsBike // bicycle
        if (e.contains("ghd")) return Icons.Filled.SelfImprovement // figure.core.training
        if (e.contains("pegboard")) return Icons.Filled.Apps // circle.grid.3x3
        if (e.contains("polea")) return Icons.Filled.Settings // gearshape.2
        if (e.contains("saco") || e.contains("sandbag")) return Icons.Filled.ShoppingBag // bag
        if (e.contains("trineo") || e.contains("sled")) return Icons.Filled.LocalShipping // shippingbox
        if (e.contains("yoke")) return Icons.Filled.FitnessCenter // strengthtraining.traditional
        if (e.contains("maquina") || e.contains("machine")) return Icons.Filled.Settings // gearshape
        if (e.contains("peso corporal") || e.contains("sin material")) return Icons.Filled.AccessibilityNew // figure.stand
        return equipment
    }
}
