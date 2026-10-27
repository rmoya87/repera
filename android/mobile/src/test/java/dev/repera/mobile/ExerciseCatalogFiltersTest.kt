package dev.repera.mobile
import org.junit.Assert.*
import org.junit.Test

class ExerciseCatalogFiltersTest {
 @Test fun hyroxMovementSetMatchesAppleBaseline() {
  // Apple HyroxExercises.matchingNames (bd4d7637), incluidas equivalencias ES y plurales.
  for (name in listOf("Run","Running","Carrera","Cinta / carrera","SkiErg","Esquí ergómetro",
   "Sled push","Empuje de trineo","Sled pull","Arrastre de trineo",
   "Burpee Broad Jump","Burpee Broad Jumps","Burpee con salto de longitud","Burpees con salto de longitud",
   "Remo máquina","Remoergómetro","RowErg","Rowing",
   "Farmer carry","Farmer walk","Farmers carry","Paseo del granjero",
   "Sandbag Lunges","Sandbag Lunge","Zancadas con saco",
   "Wall ball","Wall balls","Lanzamiento de balón a pared"))
   assertTrue(name, ExerciseCatalogFilters.isHyroxTrainingMovement(name))
 }
 @Test fun nonHyroxMovementsStayOut() {
  for (name in listOf("Sentadilla","Dominadas","Muscle-up","Remo con barra","Carrera de orientación libre"))
   assertFalse(name, ExerciseCatalogFilters.isHyroxTrainingMovement(name))
 }
}
