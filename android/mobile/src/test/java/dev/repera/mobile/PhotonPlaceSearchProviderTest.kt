package dev.repera.mobile

import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import java.util.concurrent.atomic.AtomicInteger

/** Sólo fixtures: ninguna prueba toca la red ni usa ubicación real. */
class PhotonPlaceSearchProviderTest {
    private val fixture = """{"features":[
      {"geometry":{"coordinates":[2.1,41.4]},"properties":{"name":"Gimnasio Demo","osm_id":123,"osm_type":"N","street":"Calle Falsa","housenumber":"1","city":"Ciudad","country":"España"}},
      {"geometry":{"coordinates":[2.2,41.5]},"properties":{"osm_id":5,"osm_type":"W"}},
      {"geometry":{"coordinates":[500,41.5]},"properties":{"name":"Fuera de rango","osm_id":6,"osm_type":"N"}},
      {"geometry":{"coordinates":[2.1,41.4]},"properties":{"name":"Gimnasio Demo","osm_id":123,"osm_type":"N"}}
    ]}"""

    @Test fun parseKeepsValidNamedFeaturesAndDedupes() {
        val r = PhotonPlaceSearchProvider.parse(fixture)
        assertEquals(1, r.size)
        assertEquals("Gimnasio Demo", r[0].name)
        assertEquals(41.4, r[0].latitude, 1e-9)
        assertEquals(2.1, r[0].longitude, 1e-9)
        assertEquals("osm:N123", r[0].providerId)
        assertEquals("Calle Falsa 1, Ciudad, España", r[0].addressLine)
    }

    @Test fun parseGarbageIsEmpty() {
        assertTrue(PhotonPlaceSearchProvider.parse("no json").isEmpty())
        assertTrue(PhotonPlaceSearchProvider.parse("{}").isEmpty())
    }

    @Test fun urlRoundsBiasToTwoDecimalsAndEncodesQuery() {
        val u = PhotonPlaceSearchProvider.buildUrl("gym & café", 41.123456, 2.987654)
        assertTrue(u, u.contains("q=gym+%26+caf%C3%A9"))
        assertTrue(u, u.contains("lat=41.12&lon=2.99"))
        assertFalse(u, u.contains("41.123"))
        assertTrue(u, u.contains("lang="))
    }

    @Test fun shortQueryNeverHitsNetwork() = runBlocking {
        val calls = AtomicInteger()
        val p = PhotonPlaceSearchProvider({ calls.incrementAndGet(); PhotonPlaceSearchProvider.HttpResult(200, fixture) })
        assertTrue(p.search("ab").isEmpty())
        assertEquals(0, calls.get())
    }

    @Test fun cacheAvoidsRepeatedRequests() = runBlocking {
        val calls = AtomicInteger()
        var t = 1_000_000L
        val p = PhotonPlaceSearchProvider({ calls.incrementAndGet(); PhotonPlaceSearchProvider.HttpResult(200, fixture) }, { t })
        assertEquals(1, p.search("gimnasio").size)
        t += 5_000
        assertEquals(1, p.search("gimnasio").size)
        assertEquals(1, calls.get())
    }

    @Test fun minIntervalWaitsInsteadOfFailing() = runBlocking {
        val calls = AtomicInteger()
        val waits = mutableListOf<Long>()
        var t = 1_000_000L
        val p = PhotonPlaceSearchProvider(
            { calls.incrementAndGet(); PhotonPlaceSearchProvider.HttpResult(200, fixture) },
            { t }, { waits += it })
        p.search("gimnasio")
        t += 200
        assertEquals(1, p.search("gimnasio centro").size)
        assertFalse(p.degraded)
        assertEquals(2, calls.get())
        assertEquals(800L, waits.last())
    }

    @Test fun rateLimitOpensCooldownThenRecovers() = runBlocking {
        val calls = AtomicInteger()
        var t = 1_000_000L
        var code = 429
        val p = PhotonPlaceSearchProvider({ calls.incrementAndGet(); PhotonPlaceSearchProvider.HttpResult(code, if (code == 200) fixture else "") }, { t })
        assertTrue(p.search("gimnasio").isEmpty())
        assertTrue(p.degraded)
        t += PhotonPlaceSearchProvider.COOLDOWN_MS / 2
        code = 200
        assertTrue(p.search("parque").isEmpty()) // aún en enfriamiento: sin red
        assertEquals(1, calls.get())
        t += PhotonPlaceSearchProvider.COOLDOWN_MS
        assertEquals(1, p.search("parque").size)
        assertFalse(p.degraded)
        assertEquals(2, calls.get())
    }

    @Test fun networkExceptionDegradesQuietly() = runBlocking {
        val p = PhotonPlaceSearchProvider({ throw java.io.IOException("offline") })
        assertTrue(p.search("gimnasio").isEmpty())
        assertTrue(p.degraded)
    }

    @Test fun compositeFallsBackWhenPrimaryEmpty() = runBlocking {
        val fb = PlaceSearchResult("Dir", 1.0, 2.0, "geocoder:x")
        val primary = object : PlaceSearchProvider {
            override suspend fun search(query: String, a: Double?, b: Double?, c: Double?, d: Double?) = emptyList<PlaceSearchResult>()
        }
        val fallback = object : PlaceSearchProvider {
            override suspend fun search(query: String, a: Double?, b: Double?, c: Double?, d: Double?) = listOf(fb)
        }
        assertEquals(listOf(fb), CompositePlaceSearchProvider(primary, fallback).search("abc"))
    }

    @Test fun searchCombinesFreePoiAndGeocoderAddresses() = runBlocking {
        val poi=PlaceSearchResult("Parque Norte",40.50,-3.65,"osm:N1")
        val addr=PlaceSearchResult("Calle Mayor",40.51,-3.65,"geocoder:street")
        val primary=object:PlaceSearchProvider {
            override suspend fun search(query:String,a:Double?,b:Double?,c:Double?,d:Double?)=listOf(poi)
        }
        val fallback=object:PlaceSearchProvider {
            override suspend fun search(query:String,a:Double?,b:Double?,c:Double?,d:Double?)=
                listOf(addr,poi.copy(providerId="geocoder:poi"))
        }
        assertEquals(listOf(poi,addr),CompositePlaceSearchProvider(primary,fallback).search("parque"))
    }

    /** Respuesta REAL del servicio (consulta sintética «Berlin Hauptbahnhof», 25/10/2026,
     *  sin ubicación del usuario): comprueba que el contrato asumido coincide con el servicio. */
    private val realResponse = """{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"osm_type":"N","osm_id":3856100103,"osm_key":"railway","osm_value":"station","type":"house","housenumber":"1","name":"Berlin Hauptbahnhof","street":"Europaplatz","locality":"Europacity","district":"Moabit","city":"Berlin","country":"Deutschland","postcode":"10557","countrycode":"DE"},"geometry":{"type":"Point","coordinates":[13.3696614,52.5249451]}},{"type":"Feature","properties":{"osm_type":"R","osm_id":3600565,"osm_key":"building","osm_value":"train_station","type":"house","name":"Berlin Hauptbahnhof","street":"Eingangsebene","locality":"Europacity","district":"Moabit","city":"Berlin","country":"Deutschland","postcode":"10557","countrycode":"DE","extent":[13.3682756,52.52574,13.3706245,52.5242887]},"geometry":{"type":"Point","coordinates":[13.369448,52.5250175]}}]}"""

    @Test fun parsesRealServiceResponseShape() {
        val r = PhotonPlaceSearchProvider.parse(realResponse)
        assertEquals(2, r.size)
        assertEquals("Berlin Hauptbahnhof", r[0].name)
        assertEquals(52.5249451, r[0].latitude, 1e-9)
        assertEquals(13.3696614, r[0].longitude, 1e-9)
        assertEquals("osm:N3856100103", r[0].providerId)
        assertEquals("osm:R3600565", r[1].providerId)
        assertEquals("Europaplatz 1, Berlin, Deutschland", r[0].addressLine)
    }
}
