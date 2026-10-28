package dev.repera.mobile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector
import dev.repera.domain.LiveSport

/** Equivalentes Material nativos de los símbolos deportivos Apple. */
internal val LiveSport.materialIcon: ImageVector get() = when (this) {
    LiveSport.RUNNING, LiveSport.TRAIL -> Icons.Outlined.DirectionsRun
    LiveSport.WALKING -> Icons.Outlined.DirectionsWalk
    LiveSport.HIKING -> Icons.Outlined.Hiking
    LiveSport.CYCLING, LiveSport.MOUNTAIN_BIKE, LiveSport.GRAVEL -> Icons.Outlined.DirectionsBike
    LiveSport.CROSSFIT, LiveSport.STRENGTH, LiveSport.HYROX -> Icons.Outlined.FitnessCenter
    LiveSport.HIIT -> Icons.Outlined.Timer
    LiveSport.TENNIS, LiveSport.PADEL -> Icons.Outlined.SportsTennis
    LiveSport.SURFING -> Icons.Outlined.Surfing
    LiveSport.SWIMMING -> Icons.Outlined.Pool
    LiveSport.WINDSURFING -> Icons.Outlined.Sailing
    LiveSport.KITESURFING -> Icons.Outlined.Surfing
    LiveSport.KAYAKING -> Icons.Outlined.Kayaking
    LiveSport.ROWING, LiveSport.CANOEING -> Icons.Outlined.Rowing
    LiveSport.SAILING -> Icons.Outlined.Sailing
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
    LiveSport.BOXING, LiveSport.KICKBOXING, LiveSport.MARTIAL_ARTS, LiveSport.WRESTLING -> Icons.Outlined.SportsMma
    LiveSport.BADMINTON, LiveSport.PICKLEBALL, LiveSport.SQUASH -> Icons.Outlined.SportsTennis
    LiveSport.FUNCTIONAL_STRENGTH, LiveSport.CORE_TRAINING -> Icons.Outlined.FitnessCenter
    LiveSport.ELLIPTICAL -> Icons.Outlined.DirectionsRun
    LiveSport.STAIR_CLIMBING -> Icons.Outlined.Stairs
    LiveSport.AMERICAN_FOOTBALL -> Icons.Outlined.SportsFootball
    LiveSport.BASEBALL, LiveSport.SOFTBALL -> Icons.Outlined.SportsBaseball
    LiveSport.HOCKEY -> Icons.Outlined.SportsHockey
    LiveSport.LACROSSE -> Icons.Outlined.Sports
    LiveSport.RUGBY -> Icons.Outlined.SportsRugby
    LiveSport.OTHER -> Icons.Outlined.Sports
}
