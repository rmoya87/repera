package dev.repera.wear;

import androidx.health.services.client.data.ExerciseTrackedStatus;

/** Java reads public static constants without Kotlin's library-restricted Companion. */
final class ExerciseOwnership {
    static final int OTHER = ExerciseTrackedStatus.OTHER_APP_IN_PROGRESS;
    static final int OWNED = ExerciseTrackedStatus.OWNED_EXERCISE_IN_PROGRESS;
    static final int NONE = ExerciseTrackedStatus.NO_EXERCISE_IN_PROGRESS;
    private ExerciseOwnership() {}
}
