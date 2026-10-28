package dev.repera.mobile
/** Apple LiveActivityView GeometryReader: window size, not physical orientation. */
internal fun liveMapLandscape(widthDp:Float,heightDp:Float)=widthDp>heightDp && widthDp>=620f
internal fun liveMapOverlayWidth(widthDp:Float)=(widthDp*0.42f).coerceIn(260f,390f)
