package dev.repera.wear

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DirectionsBike
import androidx.compose.material.icons.outlined.DirectionsRun
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.DownhillSkiing
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.GolfCourse
import androidx.compose.material.icons.outlined.Hiking
import androidx.compose.material.icons.outlined.IceSkating
import androidx.compose.material.icons.outlined.Kayaking
import androidx.compose.material.icons.outlined.MusicNote
import androidx.compose.material.icons.outlined.NordicWalking
import androidx.compose.material.icons.outlined.Pool
import androidx.compose.material.icons.outlined.Rowing
import androidx.compose.material.icons.outlined.Sailing
import androidx.compose.material.icons.outlined.SelfImprovement
import androidx.compose.material.icons.outlined.Skateboarding
import androidx.compose.material.icons.outlined.Snowboarding
import androidx.compose.material.icons.outlined.Sports
import androidx.compose.material.icons.outlined.SportsBaseball
import androidx.compose.material.icons.outlined.SportsBasketball
import androidx.compose.material.icons.outlined.SportsFootball
import androidx.compose.material.icons.outlined.SportsHockey
import androidx.compose.material.icons.outlined.SportsKabaddi
import androidx.compose.material.icons.outlined.SportsMma
import androidx.compose.material.icons.outlined.SportsRugby
import androidx.compose.material.icons.outlined.SportsSoccer
import androidx.compose.material.icons.outlined.SportsTennis
import androidx.compose.material.icons.outlined.SportsVolleyball
import androidx.compose.material.icons.outlined.Stairs
import androidx.compose.material.icons.outlined.Surfing
import androidx.compose.material.icons.outlined.Terrain
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.ui.graphics.vector.ImageVector
import dev.repera.domain.LiveSport

/**
 * Equivalentes Material de los SF Symbols de Comenzar en iPhone
 * (`LiveSport.symbol` / `LiveSportIcon` del móvil).
 */
internal val LiveSport.wearIcon: ImageVector
    get() = when (this) {
        LiveSport.RUNNING, LiveSport.TRAIL, LiveSport.HYROX -> Icons.Outlined.DirectionsRun
        LiveSport.WALKING -> Icons.Outlined.DirectionsWalk
        LiveSport.HIKING -> Icons.Outlined.Hiking
        LiveSport.CYCLING, LiveSport.MOUNTAIN_BIKE, LiveSport.GRAVEL -> Icons.Outlined.DirectionsBike
        LiveSport.CROSSFIT, LiveSport.STRENGTH, LiveSport.FUNCTIONAL_STRENGTH,
        LiveSport.CORE_TRAINING -> Icons.Outlined.FitnessCenter
        LiveSport.HIIT -> Icons.Outlined.Timer
        LiveSport.TENNIS, LiveSport.PADEL, LiveSport.BADMINTON,
        LiveSport.PICKLEBALL, LiveSport.SQUASH -> Icons.Outlined.SportsTennis
        LiveSport.SURFING, LiveSport.KITESURFING -> Icons.Outlined.Surfing
        LiveSport.SWIMMING -> Icons.Outlined.Pool
        LiveSport.WINDSURFING, LiveSport.SAILING -> Icons.Outlined.Sailing
        LiveSport.KAYAKING -> Icons.Outlined.Kayaking
        LiveSport.ROWING, LiveSport.CANOEING -> Icons.Outlined.Rowing
        LiveSport.GOLF -> Icons.Outlined.GolfCourse
        LiveSport.SKIING -> Icons.Outlined.DownhillSkiing
        LiveSport.ICE_SKATING -> Icons.Outlined.IceSkating
        LiveSport.SNOWBOARDING -> Icons.Outlined.Snowboarding
        LiveSport.CROSS_COUNTRY_SKIING -> Icons.Outlined.NordicWalking
        LiveSport.SOCCER -> Icons.Outlined.SportsSoccer
        LiveSport.BASKETBALL -> Icons.Outlined.SportsBasketball
        LiveSport.VOLLEYBALL -> Icons.Outlined.SportsVolleyball
        LiveSport.CLIMBING -> Icons.Outlined.Terrain
        LiveSport.DANCE -> Icons.Outlined.MusicNote
        LiveSport.PILATES, LiveSport.YOGA, LiveSport.MOBILITY -> Icons.Outlined.SelfImprovement
        LiveSport.SKATEBOARDING -> Icons.Outlined.Skateboarding
        LiveSport.BOXING, LiveSport.KICKBOXING, LiveSport.MARTIAL_ARTS -> Icons.Outlined.SportsMma
        LiveSport.WRESTLING -> Icons.Outlined.SportsKabaddi
        LiveSport.ELLIPTICAL -> Icons.Outlined.DirectionsRun
        LiveSport.STAIR_CLIMBING -> Icons.Outlined.Stairs
        LiveSport.AMERICAN_FOOTBALL -> Icons.Outlined.SportsFootball
        LiveSport.BASEBALL, LiveSport.SOFTBALL -> Icons.Outlined.SportsBaseball
        LiveSport.HOCKEY -> Icons.Outlined.SportsHockey
        LiveSport.LACROSSE -> Icons.Outlined.Sports
        LiveSport.RUGBY -> Icons.Outlined.SportsRugby
        LiveSport.OTHER -> Icons.Outlined.Sports
    }
