package dev.repera.wear

import androidx.health.services.client.data.ExerciseCapabilities
import androidx.health.services.client.data.ExerciseType
import dev.repera.domain.LiveSport

/**
 * Maps Repera [LiveSport] to Health Services [ExerciseType].
 * Falls back to a supported type on the device; never invents metrics.
 */
internal object WearHealthExerciseTypes {
    fun preferred(sportId: String?): ExerciseType {
        val sport = sportId?.let(LiveSport::byId) ?: return ExerciseType.STRENGTH_TRAINING
        return when (sport) {
            LiveSport.RUNNING, LiveSport.TRAIL -> ExerciseType.RUNNING
            LiveSport.WALKING -> ExerciseType.WALKING
            LiveSport.HIKING -> ExerciseType.HIKING
            LiveSport.CYCLING, LiveSport.MOUNTAIN_BIKE, LiveSport.GRAVEL -> ExerciseType.BIKING
            LiveSport.SWIMMING -> ExerciseType.SWIMMING_POOL
            LiveSport.ROWING -> ExerciseType.ROWING
            LiveSport.ELLIPTICAL -> ExerciseType.ELLIPTICAL
            LiveSport.STAIR_CLIMBING -> ExerciseType.STAIR_CLIMBING
            LiveSport.HIIT, LiveSport.CROSSFIT, LiveSport.HYROX ->
                ExerciseType.HIGH_INTENSITY_INTERVAL_TRAINING
            LiveSport.STRENGTH, LiveSport.FUNCTIONAL_STRENGTH, LiveSport.CORE_TRAINING ->
                ExerciseType.STRENGTH_TRAINING
            LiveSport.YOGA -> ExerciseType.YOGA
            LiveSport.PILATES -> ExerciseType.PILATES
            LiveSport.DANCE -> ExerciseType.DANCING
            LiveSport.MOBILITY -> ExerciseType.STRETCHING
            LiveSport.TENNIS, LiveSport.PADEL, LiveSport.PICKLEBALL -> ExerciseType.TENNIS
            LiveSport.BADMINTON -> ExerciseType.BADMINTON
            LiveSport.SQUASH -> ExerciseType.SQUASH
            LiveSport.BOXING -> ExerciseType.BOXING
            LiveSport.KICKBOXING, LiveSport.MARTIAL_ARTS, LiveSport.WRESTLING ->
                ExerciseType.MARTIAL_ARTS
            LiveSport.SOCCER -> ExerciseType.SOCCER
            LiveSport.BASKETBALL -> ExerciseType.BASKETBALL
            LiveSport.VOLLEYBALL -> ExerciseType.VOLLEYBALL
            LiveSport.BASEBALL -> ExerciseType.BASEBALL
            LiveSport.SOFTBALL -> ExerciseType.SOFTBALL
            LiveSport.AMERICAN_FOOTBALL -> ExerciseType.FOOTBALL_AMERICAN
            LiveSport.RUGBY -> ExerciseType.RUGBY
            LiveSport.HOCKEY -> ExerciseType.ICE_HOCKEY
            LiveSport.GOLF -> ExerciseType.GOLF
            LiveSport.SKIING -> ExerciseType.SKIING
            LiveSport.CROSS_COUNTRY_SKIING -> ExerciseType.CROSS_COUNTRY_SKIING
            LiveSport.SNOWBOARDING -> ExerciseType.SNOWBOARDING
            LiveSport.ICE_SKATING -> ExerciseType.ICE_SKATING
            LiveSport.SKATEBOARDING -> ExerciseType.SKATING
            LiveSport.CLIMBING -> ExerciseType.ROCK_CLIMBING
            LiveSport.SURFING, LiveSport.WINDSURFING, LiveSport.KITESURFING -> ExerciseType.SURFING
            LiveSport.KAYAKING, LiveSport.CANOEING -> ExerciseType.PADDLING
            LiveSport.SAILING -> ExerciseType.SAILING
            LiveSport.LACROSSE, LiveSport.OTHER -> ExerciseType.WORKOUT
        }
    }

    fun resolve(capabilities: ExerciseCapabilities, sportId: String?): ExerciseType {
        val preferred = preferred(sportId)
        if (preferred in capabilities.supportedExerciseTypes) return preferred
        for (fallback in listOf(
            ExerciseType.WORKOUT,
            ExerciseType.STRENGTH_TRAINING,
            ExerciseType.WALKING,
            ExerciseType.RUNNING
        )) {
            if (fallback in capabilities.supportedExerciseTypes) return fallback
        }
        error("Este reloj no permite registrar un ejercicio con Health Services.")
    }

    fun usesGps(sportId: String?): Boolean =
        sportId?.let(LiveSport::byId)?.usesGPS == true
}
