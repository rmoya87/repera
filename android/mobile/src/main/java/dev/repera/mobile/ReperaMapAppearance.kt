package dev.repera.mobile

import org.maplibre.android.maps.Style
import org.maplibre.android.style.expressions.Expression
import org.maplibre.android.style.layers.BackgroundLayer
import org.maplibre.android.style.layers.FillLayer
import org.maplibre.android.style.layers.FillExtrusionLayer
import org.maplibre.android.style.layers.LineLayer
import org.maplibre.android.style.layers.SymbolLayer
import org.maplibre.android.style.layers.Property
import org.maplibre.android.style.layers.PropertyFactory

/** Estética Repera inspirada en la legibilidad de Apple Maps, no en sus assets.
 * Mantiene OpenFreeMap y su atribución; sin servicios de pago. */
internal object ReperaMapAppearance {
    fun styleUrl(dark: Boolean) =
        if (dark) "https://tiles.openfreemap.org/styles/dark"
        else "https://tiles.openfreemap.org/styles/liberty"
    data class Palette(val background:String,val water:String,val park:String,
        val woods:String,val buildings:String,val roads:String,val majorRoad:String,
        val casing:String,val text:String,val halo:String)
    val light=Palette("#F6F7F5","#CFE7F5","#DDEDD9","#E2EDDB","#E6E8EA",
        "#FFFFFF","#FFF0C7","#D9DEE2","#39464F","#FFFFFF")
    val night=Palette("#19232B","#294657","#294235","#263F34","#46525A",
        "#3F4B55","#665B46","#303A43","#E1E8ED","#19232B")

    fun apply(style:Style, dark:Boolean, navigation3D:Boolean) {
        val p=if(dark) night else light
        (style.getLayer("background") as? BackgroundLayer)?.setProperties(
            PropertyFactory.backgroundColor(p.background))
        val fills=mapOf("water" to p.water,"park" to p.park,
            "landcover_wood" to p.woods,"landcover_grass" to p.woods,
            "landuse_residential" to p.background,
            "landuse_pitch" to p.park,"landuse_track" to p.park,
            "landuse_cemetery" to p.park,
            "landuse_school" to (if(dark) "#38473E" else "#EDF3E8"),
            "landuse_hospital" to (if(dark) "#493C43" else "#F6E8E9"),
            "building" to p.buildings)
        fills.forEach { (id,color) ->
            (style.getLayer(id) as? FillLayer)?.setProperties(PropertyFactory.fillColor(color))
        }
        for(id in listOf("waterway_river","waterway_other","waterway_tunnel"))
            (style.getLayer(id) as? LineLayer)?.setProperties(PropertyFactory.lineColor(p.water))
        // Restrict to basemap roads: never recolor GPX / actual route layers.
        style.layers.forEach { layer ->
            val id=layer.id
            if ((id.startsWith("road_") || id.startsWith("bridge_") ||
                    id.startsWith("tunnel_")) && layer is LineLayer &&
                !id.contains("rail") && !id.contains("transit") && !id.contains("hatching")) {
                val color=when {
                    id.contains("casing") -> p.casing
                    listOf("motorway","primary","secondary","trunk").any { id.contains(it) } -> p.majorRoad
                    else -> p.roads
                }
                layer.setProperties(PropertyFactory.lineColor(color))
            }
            if(layer is SymbolLayer &&
                (id.startsWith("highway-name") || id.startsWith("place_") ||
                    id.startsWith("poi_") || id.startsWith("road-name")))
                layer.setProperties(PropertyFactory.textColor(p.text),
                    PropertyFactory.textHaloColor(p.halo))
        }
        ensureBuildings(style,p)
        setBuildings3D(style,navigation3D)
    }

    private fun ensureBuildings(style:Style,p:Palette) {
        if(style.getSource("openmaptiles")==null) return
        if(style.getLayer("repera-building-flat")==null) {
            val flat=FillLayer("repera-building-flat","openmaptiles")
                .withSourceLayer("building")
                .withProperties(PropertyFactory.fillColor(p.buildings),
                    PropertyFactory.fillOutlineColor(p.casing))
            flat.minZoom=14f
            if(style.getLayer("building-3d")!=null) style.addLayerBelow(flat,"building-3d")
            else style.addLayer(flat)
        }
        if(style.getLayer("building-3d")==null && style.getLayer("repera-building-3d")==null) {
            val extrusion=FillExtrusionLayer("repera-building-3d","openmaptiles")
                .withSourceLayer("building")
                .withProperties(PropertyFactory.fillExtrusionColor(p.buildings),
                    PropertyFactory.fillExtrusionHeight(Expression.get("render_height")),
                    PropertyFactory.fillExtrusionBase(Expression.get("render_min_height")),
                    PropertyFactory.fillExtrusionOpacity(0.88f))
            extrusion.minZoom=14f
            style.addLayer(extrusion)
        }
        for(id in listOf("building-3d","repera-building-3d"))
            (style.getLayer(id) as? FillExtrusionLayer)?.setProperties(
                PropertyFactory.fillExtrusionColor(p.buildings),
                PropertyFactory.fillExtrusionOpacity(0.88f))
    }

    fun setBuildings3D(style:Style, enabled:Boolean) {
        val on=if(enabled) Property.VISIBLE else Property.NONE
        val off=if(enabled) Property.NONE else Property.VISIBLE
        for(id in listOf("building-3d","repera-building-3d"))
            style.getLayer(id)?.setProperties(PropertyFactory.visibility(on))
        style.getLayer("repera-building-flat")?.setProperties(PropertyFactory.visibility(off))
    }
}
