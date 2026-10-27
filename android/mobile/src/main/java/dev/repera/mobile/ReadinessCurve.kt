package dev.repera.mobile

/** Uniform Catmull-Rom -> cubic Bezier controls. Endpoints repeat at boundaries;
 *  no synthetic observations are added. Coordinates belong to the plot only. */
internal object ReadinessCurve {
 data class Point(val x:Float,val y:Float)
 data class Cubic(val start:Point,val control1:Point,val control2:Point,val end:Point)
 fun segments(points:List<Point>):List<Cubic> = points.zipWithNext().mapIndexed {i,(a,b) ->
  val before=points.getOrElse(i-1) {a}
  val after=points.getOrElse(i+2) {b}
  Cubic(a,Point(a.x+(b.x-before.x)/6f,a.y+(b.y-before.y)/6f),
   Point(b.x-(after.x-a.x)/6f,b.y-(after.y-a.y)/6f),b)
 }
}
