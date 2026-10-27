package dev.repera.mobile

/** ExerciseProgressView.chartYDomain, including tested ceiling's lower half. */
internal object ExerciseChartGeometry {
 fun bounds(values:List<Double>,ceiling:Double?):Pair<Double,Double> {
  var low=values.minOrNull() ?: 0.0
  var high=values.maxOrNull() ?: 1.0
  ceiling?.let {high=maxOf(high,it);low=minOf(low,it*0.5)}
  if(high<=low) high=low+1.0
  val pad=maxOf((high-low)*0.08,1.0)
  return maxOf(0.0,low-pad) to high+pad
 }
 fun fraction(points:List<ExerciseProgressPoint>,index:Int):Float {
  val start=points.first().epochMillis
  val span=points.last().epochMillis-start
  return if(span<=0) 0.5f else ((points[index].epochMillis-start).toDouble()/span).toFloat()
 }
 fun nearest(points:List<ExerciseProgressPoint>,fraction:Float):Int =
  points.indices.minBy {kotlin.math.abs(fraction(points,it)-fraction)}
}
