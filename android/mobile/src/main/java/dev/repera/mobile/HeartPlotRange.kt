package dev.repera.mobile

import dev.repera.domain.HeartRatePlotPoint

/** Extrema across the complete displayed range, never just the endpoint days. */
internal fun heartPlotRange(points:List<HeartRatePlotPoint>):Pair<Double,Double>? =
    if(points.isEmpty()) null else points.minOf {it.minBpm} to points.maxOf {it.maxBpm}
