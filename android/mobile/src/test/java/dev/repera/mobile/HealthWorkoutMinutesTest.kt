package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test
class HealthWorkoutMinutesTest {
    @Test fun pauseDurationClipsUnionsAndIgnoresInvalidIntervals() {
        assertEquals(40.0,HealthWorkoutMinutes.measured(0,3600000,listOf(600000L to 1200000L,900000L to 1800000L)),0.0)
        assertEquals(59.0,HealthWorkoutMinutes.measured(0,3600000,listOf(-1000L to 60000L,3600000L to 3900000L,100L to 50L)),0.0)
        assertEquals(0.0,HealthWorkoutMinutes.measured(100,10,emptyList()),0.0)
    }
    @Test fun externalLinkedDurationWinsIncludingPauses() {
        assertEquals(20.0,HealthWorkoutMinutes.resolve(60.0,HealthWorkoutMinutes.Verified(20.0,true)),0.0)
    }
    @Test fun truncatedOwnRecordCannotReplaceFullLocalSession() {
        assertEquals(60.0,HealthWorkoutMinutes.resolve(60.0,HealthWorkoutMinutes.Verified(5.0,false)),0.0)
        assertEquals(50.0,HealthWorkoutMinutes.resolve(60.0,HealthWorkoutMinutes.Verified(50.0,false)),0.0)
        assertEquals(2.0,HealthWorkoutMinutes.resolve(6.0,HealthWorkoutMinutes.Verified(2.0,false)),0.0)
    }
    @Test fun missingOrInvalidMeasurementPreservesLocalValue() {
        assertEquals(60.0,HealthWorkoutMinutes.resolve(60.0,null),0.0)
        assertEquals(60.0,HealthWorkoutMinutes.resolve(60.0,HealthWorkoutMinutes.Verified(Double.NaN,true)),0.0)
        assertEquals(60.0,HealthWorkoutMinutes.resolve(60.0,HealthWorkoutMinutes.Verified(0.0,true)),0.0)
    }
}
