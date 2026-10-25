package dev.repera.mobile

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import dev.repera.domain.WorkoutLocationPin
import dev.repera.domain.WorkoutRoutePoint
import org.junit.Assert.assertEquals
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.size
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import dev.repera.domain.DailyActiveEnergyPoint
import dev.repera.domain.DailyHeartRatePoint
import dev.repera.domain.HeartRatePlotPoint
import dev.repera.domain.ProgressChartBuilder
import dev.repera.domain.ProgressDayPoint
import dev.repera.domain.ProgressPreparedCharts
import dev.repera.domain.ProgressSeriesGranularity
import dev.repera.domain.ProgressTimeRange
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDate

/** Capturas de las pantallas/gráficas nuevas para verificación visual.
 *  Los PNG se extraen del emulador en CI (ver workflow). */
@RunWith(AndroidJUnit4::class)
class VisualVerificationInstrumentedTest {

    @get:Rule
    val compose = createAndroidComposeRule<androidx.activity.ComponentActivity>()

    /** Distancia de color simple (RGB) para gates de píxeles. */
    private fun colorDist(a: Int, b: Int): Int {
        val dr = android.graphics.Color.red(a) - android.graphics.Color.red(b)
        val dg = android.graphics.Color.green(a) - android.graphics.Color.green(b)
        val db = android.graphics.Color.blue(a) - android.graphics.Color.blue(b)
        return dr * dr + dg * dg + db * db
    }

    /** Prueba AISLADA del cargador (contexto target directo, sin UI): verifica
     *  que el asset empaquetado compila a rutas dibujables. No sustituye a la
     *  integración de producción de capturaEquilibrioMuscular. */
    @Test
    fun bodyMapCargaAisladaDesdeContextoApp() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        val paths = kotlinx.coroutines.runBlocking { CompiledBodyPaths.shared(appContext) }
        org.junit.Assert.assertNotNull("BodyPaths.json debe cargar desde el contexto de la app", paths)
        paths!!
        org.junit.Assert.assertTrue(
            "frente sin músculos: ${paths.front.musclePaths.keys}",
            paths.front.musclePaths.size >= 10)
        org.junit.Assert.assertTrue(
            "espalda sin músculos: ${paths.back.musclePaths.keys}",
            paths.back.musclePaths.size >= 8)
        org.junit.Assert.assertTrue("sin cabeza", paths.front.inertPaths.containsKey("head"))

        // Rasterizado DIRECTO con android.graphics (sin Compose): discrimina
        // entre "rutas vacías en dispositivo" y "fallo del dibujo Compose".
        // Pinta todos los músculos del frente en rojo y cuenta píxeles.
        val bmp = android.graphics.Bitmap.createBitmap(800, 1400, android.graphics.Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bmp)
        val paint = android.graphics.Paint().apply {
            color = android.graphics.Color.RED
            style = android.graphics.Paint.Style.FILL
        }
        var rutasPintadas = 0
        for (lista in paths.front.musclePaths.values) for (ruta in lista) {
            canvas.drawPath(ruta, paint); rutasPintadas++
        }
        var rojos = 0
        for (yy in 0 until bmp.height step 4) for (xx in 0 until bmp.width step 4) {
            if (android.graphics.Color.red(bmp.getPixel(xx, yy)) > 200 &&
                android.graphics.Color.green(bmp.getPixel(xx, yy)) < 80) rojos++
        }
        android.util.Log.i("BodyMap", "raster directo: $rutasPintadas rutas, $rojos píxeles rojos (stride 4)")
        org.junit.Assert.assertTrue(
            "rutas del frente NO rasterizan en dispositivo ($rutasPintadas rutas, $rojos píxeles)",
            rojos > 200)
    }

    private fun save(name: String, bitmap: ImageBitmap) {
        // MediaStore (Pictures): visible para `adb pull` en CI; Android/data está
        // filtrado por scoped storage incluso para shell/root en el emulador.
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val values = android.content.ContentValues().apply {
            put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
            put(android.provider.MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(android.provider.MediaStore.Images.Media.RELATIVE_PATH,
                "Pictures/ReperaVerification")
        }
        val uri = ctx.contentResolver.insert(
            android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: error("MediaStore no aceptó la captura $name")
        ctx.contentResolver.openOutputStream(uri)!!.use { out ->
            bitmap.asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, out)
        }
        android.util.Log.i("VisualVerification", "guardada en MediaStore: $uri")
    }

    // Tema real de la app (ReperaMobileScreen): solo se sobreescribe primary.
    // Capturar con MaterialTheme a pelo dibuja la paleta Material por defecto
    // (lavanda) y NO representa la app.
    private fun brandContent(content: @Composable () -> Unit) {
        // Host de prueba edge-to-edge como producción (targetSdk 37): contenido
        // fuera de la barra de estado e iconos oscuros sobre fondo claro, para
        // que las capturas de pantalla completa muestren barras legibles.
        // En el hilo de UI: la ruta Impl30 toca View.setSystemUiVisibility y
        // falla desde el hilo de instrumentación (API 30).
        compose.runOnUiThread {
            compose.activity.window.let { w ->
                androidx.core.view.WindowInsetsControllerCompat(w, w.decorView).apply {
                    isAppearanceLightStatusBars = true
                    isAppearanceLightNavigationBars = true
                }
            }
        }
        compose.setContent {
            // Mismo esquema claro que producción (ReperaMobileScreen): verde legible.
            MaterialTheme(colorScheme = lightColorScheme(
                primary = brandGreenReadable, onPrimary = Color.White)) {
                Surface(modifier = Modifier.fillMaxSize().statusBarsPadding()) { content() }
            }
        }
    }

    private fun fixtureCharts(): ProgressPreparedCharts {
        val today = LocalDate.now()
        val hr = (13L downTo 0).map {
            DailyHeartRatePoint(today.minusDays(it),
                52.0 + (it % 5), 68.0 + (it % 9), 132.0 + (it % 23) * 3)
        }
        val kcal = (13L downTo 0).map {
            DailyActiveEnergyPoint(today.minusDays(it), 220.0 + (it % 6) * 85)
        }
        return ProgressChartBuilder.build(
            range = ProgressTimeRange.WEEK,
            weekStartsOnMonday = true,
            heartRateDays = hr,
            energyDays = kcal,
            workouts = emptyList(),
            external = emptyList(),
            now = today)
    }

    @Test
    fun capturaGraficasActividadYPulso() {
        val charts = fixtureCharts()
        brandContent {
            ProgressChartsCard(charts)
        }
        compose.waitForIdle()
        save("progreso_actividad_pulso", compose.onRoot().captureToImage())
    }

    private fun wodClockFixture(): Pair<ActiveWorkout, WodTimerState> {
        val active = ActiveWorkout(
            id = "wod-visual", title = "WOD Fran", index = 0, total = 1,
            exerciseName = "Fran", completedSets = 0,
            prescribedQuantity = null, prescribedWeightKg = null,
            allowsWeight = false, sets = emptyList(),
            wod = WodExecution(
                format = "emom", capture = "PER_MOVEMENT_SETS", expectsRounds = true,
                title = "EMOM 10",
                movements = listOf(
                    WodMovementSummary(
                        id = "m1", name = "Thruster", isRest = false,
                        reps = 12, repScheme = emptyList(),
                        calories = null, meters = null, restSeconds = null)
                ),
                intervalSeconds = 60, rounds = 10
            )
        )
        return active to WodTimerState(elapsedMillis = 485_000L, running = false)
    }

    // Reloj WOD a pantalla completa con layout adaptativo (paridad
    // BlockTimerScreen de iOS). Cronómetro en pausa para que la captura
    // sea estable (con running=true el LaunchedEffect de tick impediría
    // waitForIdle). Una sola jerarquía por test: createComposeRule no
    // admite dos setContent en el mismo test.
    @Test
    fun capturaRelojWodVertical() {
        val (active, timer) = wodClockFixture()
        brandContent {
            WodClockScreen(active, false, timer, {}, {}, {}, requestNotificationPermission = false)
        }
        compose.waitForIdle()
        save("reloj_wod_vertical", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaRelojWodApaisado() {
        // Orientación REAL: la app no bloquea la orientación (unspecified, como
        // iOS que admite portrait+landscape), así que rotar la ventana debe
        // activar la rama apaisada del reloj. Una caja forzada solo prueba un
        // árbol de composición aislado, no la adaptación real.
        compose.activityRule.scenario.onActivity {
            it.requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }
        compose.waitUntil(15_000) {
            var landscape = false
            compose.activityRule.scenario.onActivity {
                landscape = it.resources.configuration.orientation ==
                    android.content.res.Configuration.ORIENTATION_LANDSCAPE
            }
            landscape
        }
        val (active, timer) = wodClockFixture()
        brandContent {
            WodClockScreen(active, false, timer, {}, {}, {}, requestNotificationPermission = false)
        }
        compose.waitForIdle()
        val captura = compose.onRoot().captureToImage().asAndroidBitmap()
        org.junit.Assert.assertTrue(
            "La ventana no quedó apaisada (${'$'}{captura.width}x${'$'}{captura.height})",
            captura.width > captura.height)
        save("reloj_wod_apaisado", captura.asImageBitmap())
        compose.activityRule.scenario.onActivity {
            it.requestedOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
    }

    @Test
    fun capturaTemporizadorConfig() {
        brandContent { StandaloneTimerScreen(onBack = {}) }
        compose.waitForIdle()
        save("temporizador_config", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaTemporizadorRelojLed() {
        brandContent {
            StandaloneClock(
                title = "Temporizador",
                subtitle = "Trabajar",
                roundNumber = 2,
                totalRounds = 5,
                displaySeconds = 75,
                running = true,
                onPrimary = {},
                onClose = {}
            )
        }
        compose.waitForIdle()
        save("temporizador_reloj_led", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaHeatmaps() {
        val today = LocalDate.now()
        val time = (69L downTo 0).map {
            today.minusDays(it) to ((it * 7) % 5).toInt()
        }
        val volume = (69L downTo 0).map {
            today.minusDays(it) to ((it * 3) % 5).toInt()
        }
        brandContent {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                ActivityHeatmapCard(time, volume,
                    dev.repera.domain.ProgressTimeRange.DAYS_90)
            }
        }
        compose.waitForIdle()
        save("progreso_heatmaps", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaLineasPesoYCardio() {
        val today = LocalDate.now()
        val weight = (29L downTo 0 step 2).map {
            ProgressDayPoint(today.minusDays(it), 82.5 - it * 0.06 + (it % 3) * 0.15)
        }
        val cardio = (13L downTo 0).map {
            ProgressDayPoint(today.minusDays(it), 12.0 + (it % 5) * 9)
        }
        // Misma estructura de tarjeta con título/unidades que ProgressTab:
        // la gráfica aislada no lleva título ni ejes y no es capturable como UX.
        brandContent {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                Card(modifier = Modifier.fillMaxWidth().padding(18.dp)) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Cardio", style = MaterialTheme.typography.titleMedium)
                        Text("${cardio.sumOf { it.value }.toInt()} min en el rango",
                            style = MaterialTheme.typography.bodyMedium)
                        DayPointLineChart(cardio)
                    }
                }
                Card(modifier = Modifier.fillMaxWidth().padding(18.dp)) {
                    Column(modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Peso corporal",
                            style = MaterialTheme.typography.titleMedium)
                        val last = weight.last()
                        Text("Último: ${formatWeight(last.value)} kg " +
                                "(${last.day.format(reperaDayFormatter)})",
                            style = MaterialTheme.typography.bodyMedium)
                        DayPointLineChart(weight)
                    }
                }
            }
        }
        compose.waitForIdle()
        save("progreso_peso_cardio", compose.onRoot().captureToImage())

        // Scrub táctil (iOS: arrastre horizontal selecciona el punto): la
        // imagen con selección debe DIFERIR de la imagen en reposo.
        val antes = compose.onRoot().captureToImage().asAndroidBitmap()
        compose.onAllNodesWithTag("day_point_line_chart")[0].performTouchInput {
            // El nodo etiquetado incluye la columna de valores (52dp) a la
            // izquierda: el down debe caer DENTRO del Canvas o el gesto no
            // llega al pointerInput de la gráfica.
            val y = height * 0.5f
            down(Offset(width * 0.5f, y))
            moveTo(Offset(width * 0.75f, y))
            moveTo(Offset(width * 0.9f, y))
            up()
        }
        compose.waitForIdle()
        val despues = compose.onRoot().captureToImage().asAndroidBitmap()
        save("progreso_cardio_scrub", despues.asImageBitmap())
        if (antes.sameAs(despues)) {
            throw AssertionError("El scrub no cambió la gráfica de cardio")
        }
    }

    @Test
    fun capturaEquilibrioMuscular() {
        // Carga/fatiga sintéticas sobre los slugs del BodyMap (frente y espalda).
        val load = mapOf(
            "chest" to 12.0, "upper-back" to 9.0, "deltoids" to 6.0,
            "quadriceps" to 10.0, "hamstring" to 4.0, "gluteal" to 7.0,
            "biceps" to 5.0, "triceps" to 5.0, "abs" to 3.0, "calves" to 2.0
        )
        val fatigue = mapOf(
            "chest" to 1.2, "upper-back" to 0.7, "deltoids" to 0.45,
            "quadriceps" to 0.9, "gluteal" to 0.3, "biceps" to 0.2,
            "triceps" to 0.2, "abs" to 0.1
        )
        // Modo Esfuerzo con datos DISTINTOS (subconjunto de series duras), para
        // que la captura ejercite el cambio real de datos y no solo el selector.
        val loadHard = mapOf(
            "chest" to 4.0, "upper-back" to 2.0, "quadriceps" to 3.0,
            "gluteal" to 1.0, "triceps" to 2.0
        )
        val fatigueHard = mapOf(
            "chest" to 0.9, "upper-back" to 0.2, "quadriceps" to 0.4,
            "triceps" to 0.05
        )
        brandContent {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                MuscleBalanceCard(
                    loadAll = load, loadHard = loadHard,
                    fatigueAll = fatigue, fatigueHard = fatigueHard,
                    hasHardSets = true)
            }
        }
        compose.waitForIdle()
        // Integración por la ruta de producción: la Activity del test corre en
        // el paquete de la app (com.app.repera, visto en logcat), así que
        // LocalContext.applicationContext es el contexto real de la app con el
        // asset empaquetado; SIN precarga ni loader sustituido. BodyMapView
        // carga BodyPaths.json en Dispatchers.Default: waitForIdle NO lo
        // espera, así que esperamos al nodo y FALLAMOS si no llega.
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("body_map_loaded").fetchSemanticsNodes().isNotEmpty()
        }
        org.junit.Assert.assertTrue(
            "El mapa corporal no apareció tras la espera (placeholder de 220dp)",
            compose.onAllNodesWithTag("body_map_loaded").fetchSemanticsNodes().isNotEmpty())
        compose.waitForIdle()
        // El tag marca el contenedor aunque el Canvas no dibuje nada (un
        // Canvas vacío y el Spacer placeholder producen los mismos píxeles).
        // Gate real: el nodo del mapa debe tener píxeles distintos del fondo.
        val mapa = compose.onNodeWithTag("body_map_loaded").captureToImage().asAndroidBitmap()
        val fondo = mapa.getPixel(2, 2)
        var distintos = 0
        var y = 0
        while (y < mapa.height) {
            var x = 0
            while (x < mapa.width) {
                if (colorDist(mapa.getPixel(x, y), fondo) > 24) distintos++
                x += 3
            }
            y += 3
        }
        org.junit.Assert.assertTrue(
            "Mapa corporal VACÍO: solo $distintos píxeles distintos del fondo " +
                "(el contenedor existe pero no se dibuja nada)",
            distintos > 500)
        save("progreso_equilibrio_muscular", compose.onRoot().captureToImage())
        val capturaFatiga = compose.onRoot().captureToImage().asAndroidBitmap()
        // Segundo modo: Esfuerzo (series duras), paridad del segmented iOS.
        compose.onNodeWithText("Esfuerzo").performClick()
        compose.waitForIdle()
        save("progreso_equilibrio_muscular_esfuerzo", compose.onRoot().captureToImage())
        // Gate de datos reales: con maps distintos por modo, las dos capturas
        // deben diferir en píxeles (si el selector dejara de cambiar los datos,
        // las imágenes serían idénticas y este gate fallaría).
        val capturaEsfuerzo = compose.onRoot().captureToImage().asAndroidBitmap()
        var diffs = 0
        var yy = 0
        while (yy < minOf(capturaFatiga.height, capturaEsfuerzo.height)) {
            var xx = 0
            while (xx < minOf(capturaFatiga.width, capturaEsfuerzo.width)) {
                if (colorDist(capturaFatiga.getPixel(xx, yy),
                        capturaEsfuerzo.getPixel(xx, yy)) > 24) diffs++
                xx += 5
            }
            yy += 5
        }
        org.junit.Assert.assertTrue(
            "Fatiga y Esfuerzo dibujan lo mismo con datos distintos: solo $diffs píxeles",
            diffs > 500)
    }

    private fun estadoSinteticoOverview(): StateOverview {
        val today = LocalDate.now()
        fun exercise(id: String, name: String, muscle: String, equipment: String?) =
            JSONObject().put("id", id).put("name", name).put("muscleGroup", muscle)
                .put("equipment", equipment ?: JSONObject.NULL).put("targetMuscle", muscle)
        val squat = exercise("ex-sentadilla", "Sentadilla", "Piernas", "Barra")
        val bench = exercise("ex-banca", "Press banca", "Pecho", "Barra")
        val run = exercise("ex-carrera", "Carrera", "Cardio", null)
        val workouts = JSONArray()
        val days = listOf(0L, 1L, 3L, 4L, 7L, 8L, 10L, 11L, 14L, 15L, 17L, 18L)
        days.forEachIndexed { i, d ->
            val date = today.minusDays(d)
            val ex = when (i % 3) { 0 -> squat; 1 -> bench; else -> squat }
            val sets = JSONArray()
            repeat(4) { n ->
                sets.put(JSONObject()
                    .put("id", java.util.UUID.randomUUID().toString())
                    .put("reps", 5).put("weightKg", 80.0 + i * 2.5 - n)
                    .put("rir", 2.0).put("phase", "work"))
            }
            val entry = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("exercise", JSONObject(ex.toString()))
                .put("plannedSets", JSONArray())
                .put("loggedSets", sets)
                .put("completedReps", 20).put("isCompleted", true)
                .put("blockId", "b1").put("blockKind", "strength")
            val session = JSONObject()
                .put("id", java.util.UUID.randomUUID().toString())
                .put("title", if (i % 3 == 1) "Empuje" else "Pierna")
                .put("startedAt", date.atTime(18, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("finishedAt", date.atTime(19, 0)
                    .atZone(java.time.ZoneId.systemDefault()).toInstant().toString())
                .put("phase", "finished")
                .put("exercises", JSONArray().put(entry))
            workouts.put(session)
        }
        val weights = JSONArray()
        (20L downTo 0 step 2).forEach { d ->
            weights.put(JSONObject()
                .put("date", today.minusDays(d).toString())
                .put("weightKg", 83.5 - (20 - d) * 0.05))
        }
        val state = JSONObject()
            .put("exercises", JSONArray().put(squat).put(bench).put(run))
            .put("routines", JSONArray())
            .put("workouts", workouts)
            .put("bodyWeights", weights)
            .put("favoriteTimers", JSONArray())
            .put("exerciseLoadPrefs", JSONObject())
            .put("syncRevision", 1)
            .put("lastWriterDeviceId", "visual-test")
        return StateOverview.fromBytes(
            state.toString().toByteArray(Charsets.UTF_8))!!
    }

    @Test
    fun capturaPaywallSheetConPlanes() {
        // Paywall modo sheet con catálogo sintético (anual con ahorro +
        // mensual con trial). Verificación visual de la UI de monetización.
        val manager = fakeSubscriptionManager()
        brandContent {
            dev.repera.mobile.monetization.PaywallScreen(
                subscriptions = manager,
                mode = dev.repera.mobile.monetization.PaywallMode.SHEET
            )
        }
        compose.waitForIdle()
        save("paywall_sheet", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaPaywallOnboardingConMascota() {
        // Modo onboarding: mascota hero real (asset iOS reutilizado).
        val manager = fakeSubscriptionManager()
        brandContent {
            dev.repera.mobile.monetization.PaywallScreen(
                subscriptions = manager,
                mode = dev.repera.mobile.monetization.PaywallMode.ONBOARDING
            )
        }
        compose.waitForIdle()
        save("paywall_onboarding", compose.onRoot().captureToImage())
    }

    private fun fakeSubscriptionManager(): dev.repera.mobile.monetization.SubscriptionManager {
        val provider = object : dev.repera.mobile.monetization.EntitlementProvider {
            override val isConfigured: Boolean get() = true
            override suspend fun refresh() = dev.repera.domain.monetization.CommercialSnapshot(
                status = dev.repera.domain.monetization.SubscriptionStatus.FREE,
                isConfigured = true
            )
            override suspend fun purchase(productID: String) = refresh()
            override suspend fun restore() = refresh()
            override suspend fun offerings() = dev.repera.mobile.monetization.CommercialOfferings(
                packages = listOf(
                    dev.repera.mobile.monetization.CommercialPackageInfo(
                        productID = dev.repera.mobile.monetization.CommercialConfig.ANNUAL_PRODUCT_ID,
                        localizedPrice = "59,99 €",
                        localizedTitle = "Repera Pro Anual",
                        localizedDescription = "12 meses",
                        isAnnual = true,
                        introductoryOfferSummary = null,
                        hasFreeTrial = false,
                        priceValue = 59.99,
                        currencyCode = "EUR"
                    ),
                    dev.repera.mobile.monetization.CommercialPackageInfo(
                        productID = dev.repera.mobile.monetization.CommercialConfig.MONTHLY_PRODUCT_ID,
                        localizedPrice = "7,99 €",
                        localizedTitle = "Repera Pro Mensual",
                        localizedDescription = "1 mes",
                        isAnnual = false,
                        introductoryOfferSummary = "7 días de prueba gratis",
                        hasFreeTrial = true,
                        priceValue = 7.99,
                        currencyCode = "EUR"
                    )
                )
            )
        }
        val dir = androidx.test.platform.app.InstrumentationRegistry
            .getInstrumentation().targetContext.filesDir
        return dev.repera.mobile.monetization.SubscriptionManager(
            provider = provider,
            freeUsage = dev.repera.mobile.monetization.FreeUsageStore.forAccount(
                java.io.File(dir, "test_freeusage")
            )
        )
    }

    @Test
        fun capturaAccesoIAConTemaRepera() {
        // Pantalla Acceso IA con datos sintéticos: tokens, cambio pendiente
        // y estado de bandeja, con el tema de marca.
        val tokens = listOf(
            AIAccessStore.TokenInfo(
                id = "t1", label = "Mi entrenador IA", tokenPrefix = "rpa_7f3c",
                createdAt = "2026-10-01T10:00:00Z",
                expiresAt = "2026-12-30T10:00:00Z",
                revokedAt = null, lastUsedAt = null,
                scopes = listOf("training:read", "training:write")),
            AIAccessStore.TokenInfo(
                id = "t2", label = "Prueba antigua", tokenPrefix = "rpa_00aa",
                createdAt = "2026-01-01T10:00:00Z", expiresAt = null,
                revokedAt = "2026-06-01T10:00:00Z", lastUsedAt = null,
                scopes = listOf("training:read")))
        val change = AIChangeRequestStore.Change(
            id = "c1", operation = "update_workout", targetId = "w1",
            expectedUpdatedAt = "2026-10-24T08:00:00Z",
            payload = JSONObject()
                .put("workoutTitle", "Pierna 24 oct")
                .put("setChanges", JSONArray().put(JSONObject()
                    .put("loggedSetId", "12345678-aaaa-bbbb-cccc-ddddeeeeffff")
                    .put("reps", 8).put("weightKg", 102.5))),
            createdAt = "2026-10-24T09:00:00Z")
        compose.setContent {
            MaterialTheme(colorScheme = androidx.compose.material3.lightColorScheme(
                primary = brandGreenReadable,
                onPrimary = androidx.compose.ui.graphics.Color.White)) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AIAccessScreen(
                        connected = true, busy = false, tokens = tokens,
                        errorMessage = null, successMessage = null,
                        createdToken = null,
                        changes = listOf(change), changeBusy = false,
                        changeError = null,
                        inboxPending = 2,
                        inboxConflicts = listOf(
                            "2026-10-26: el ejercicio 'Pistol squat' no existe"),
                        onRefresh = {}, onCreate = { _, _, _ -> },
                        onRevoke = {}, onDecide = { _, _ -> },
                        onDismissCreated = {}, onCopyCreated = {})
                }
            }
        }
        compose.waitForIdle()
        save("acceso_ia", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaPantallaProgresoCompletaConTemaRepera() {
        // Pantalla real: tema de marca (verde Repera) + datos reales construidos
        // por el pipeline StateOverview.fromBytes, no composables aislados.
        val overview = estadoSinteticoOverview()
        compose.setContent {
            MaterialTheme(colorScheme = androidx.compose.material3.lightColorScheme(
                primary = brandGreenReadable,
                onPrimary = androidx.compose.ui.graphics.Color.White)) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    ProgressTab(
                        busy = false, syncing = false, status = null,
                        overview = overview,
                        onInitializeLocal = {}, onImportJson = {}, onDriveSync = {},
                        onExportJson = {}, onSignOut = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> },
                        onLogBodyWeight = {})
                }
            }
        }
        compose.waitForIdle()
        save("pantalla_progreso_tema_repera", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaPantallaInicioConTemaRepera() {
        // Pantalla de inicio real con tema de marca y datos del pipeline real.
        val overview = estadoSinteticoOverview()
        compose.setContent {
            MaterialTheme(colorScheme = androidx.compose.material3.lightColorScheme(
                primary = brandGreenReadable,
                onPrimary = androidx.compose.ui.graphics.Color.White)) {
                Surface(modifier = Modifier.fillMaxSize()) {
                    HomeTab(
                        displayName = "Ramón", busy = false, syncing = false,
                        status = null, overview = overview, todayHealth = null,
                        onHealthConnect = {}, activeWorkout = null, wodTimer = null,
                        onWodTimerAction = {}, onWodTimerTick = {},
                        onStartRoutine = {}, onWodScore = { _, _, _ -> },
                        onWodMovement = { _, _, _, _ -> },
                        onCompleteWodBlock = {},
                        onReviseWodMovement = { _, _, _ -> },
                        onDeleteWodMovement = {},
                        onLogSet = { _, _, _, _, _, _, _ -> },
                        onLogDropSet = { _, _, _ -> },
                        onLogRestPauseSet = { _, _ -> },
                        onReviseSet = { _, _, _, _, _, _ -> },
                        onDeleteSet = {},
                        onReviseFinishedSet = { _, _, _, _, _, _ -> },
                        onDeleteFinishedSet = { _, _, _ -> },
                        onNext = {}, onFinish = {},
                        onInitializeLocal = {}, onImportJson = {},
                        onDriveSync = {}, onExportJson = {}, onSignOut = {},
                        onNavigateCreate = {}, onOpenClock = {})
                }
            }
        }
        compose.waitForIdle()
        save("pantalla_inicio_tema_repera", compose.onRoot().captureToImage())
    }

    // ---- Editores (plan y entreno terminado): evidencia visual real en emulador ----
    // Main 25/10: los editores no se dan por listos sin capturas de sus flujos.

    private fun editorPlanVisualFixture() = RoutineEntry(
        id = "r-vis", title = "Plan visual", supported = true,
        blocks = listOf(
            RoutineBlockInfo(title = "Fuerza", format = "strength", id = "b-s",
                entries = listOf(RoutineBlockEntryInfo(exerciseId = "ex-1", name = "Dominadas",
                    quantity = 5, sets = 2, weightKg = 40.0, id = "it-1",
                    plannedSets = listOf(PlannedSetDraft(5, 40.0, 2.0, "sp-1"),
                        PlannedSetDraft(3, 45.0, null, "sp-2"))))),
            RoutineBlockInfo(title = "WOD", format = "amrap", id = "b-w", entries = emptyList())))

    @Test
    fun capturaEditorPlanBloques() {
        val exercise = ExerciseEntry(id = "ex-1", name = "Dominadas", supportsBasicInput = true,
            allowsWeight = true, muscleGroup = "Espalda")
        brandContent {
            RoutineBlocksEditorScreen(routine = editorPlanVisualFixture(),
                exercises = listOf(exercise), busy = false, onReplace = {}, onBack = {})
        }
        compose.waitForIdle()
        save("editor_plan_bloques", compose.onRoot().captureToImage())
        // Parte inferior del editor (bloque WOD + acciones) tras scroll real.
        compose.onNodeWithText("Añadir bloque").performScrollTo()
        compose.waitForIdle()
        save("editor_plan_bloques_inferior", compose.onRoot().captureToImage())
    }

    // ---- Selector de lugar + mapa de ruta: evidencia visual real (25/10) ----

    private class FakePlaceProvider : PlaceSearchProvider {
        override suspend fun search(query: String, biasMinLat: Double?, biasMinLon: Double?,
                                    biasMaxLat: Double?, biasMaxLon: Double?) = listOf(
            PlaceSearchResult("Box Ejemplo Norte", 40.4380, -3.7030, "fake-1",
                addressLine = "Calle Falsa 1, Madrid"),
            PlaceSearchResult("Parque Ejemplo", 40.4200, -3.6900, "fake-2",
                addressLine = "Av. de Prueba 22, Madrid"))
    }

    @Test
    fun capturaSelectorLugarEstados() {
        var pin by mutableStateOf<WorkoutLocationPin?>(null)
        val styleLoaded = java.util.concurrent.CountDownLatch(1)
        brandContent {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                WorkoutPlacePickerRow(pin = pin, accountId = "acc-vis",
                    onPinChange = { pin = it },
                    onMapStyleLoaded = { styleLoaded.countDown() })
            }
        }
        compose.waitForIdle()
        save("lugar_selector_vacio", compose.onRoot().captureToImage())
        pin = WorkoutLocationPin(40.4380, -3.7030, 1_700_000_000_000L,
            name = "Box Ejemplo Norte", mapItemIdentifier = "fake-1")
        compose.waitForIdle()
        save("lugar_selector_con_pin", compose.onRoot().captureToImage())
        // El preview del pin es GL (invisible para captureToImage): captura de
        // pantalla real tras el estilo + asentado de teselas, como la ruta.
        if (styleLoaded.await(60, java.util.concurrent.TimeUnit.SECONDS)) {
            Thread.sleep(8_000)
            val shot = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()
            if (shot != null) save("lugar_selector_pin_mapa", shot.asImageBitmap())
        }
    }

    @Test
    fun flujoBusquedaLugarConProveedorSimulado() {
        var selected: WorkoutLocationPin? = null
        brandContent {
            PlaceSearchSheet(initialPin = null, accountId = "acc-vis",
                onSelect = { selected = it }, onDismiss = {},
                providerOverride = FakePlaceProvider())
        }
        compose.waitForIdle()
        compose.onNodeWithTag("place_query").performTextInput("box madrid")
        // Política de dominio real: debounce 800 ms antes de consultar.
        compose.waitUntil(timeoutMillis = 10_000) {
            compose.onAllNodesWithText("Box Ejemplo Norte").fetchSemanticsNodes().isNotEmpty()
        }
        compose.waitForIdle()
        save("lugar_hoja_resultados", compose.onRoot().captureToImage())
        compose.onNodeWithText("Box Ejemplo Norte").performClick()
        compose.waitForIdle()
        save("lugar_hoja_confirmar", compose.onRoot().captureToImage())
        compose.onNodeWithTag("place_confirm").performClick()
        compose.waitForIdle()
        assertEquals("Box Ejemplo Norte", selected?.name)
        assertEquals("fake-1", selected?.mapItemIdentifier)
    }

    /** ActivityHeatmapCard: franja (semana) vs rejilla (90 días) + cambio de
     *  métrica, para fidelidad con ActivityHeatmapView iOS. */
    @Test
    fun capturaHeatmapActividadFranjaYRejilla() {
        val hoy = java.time.LocalDate.now()
        val niveles = { seed: Int ->
            (0..97).map { i ->
                val dia = hoy.minusDays((97 - i).toLong())
                dia to ((i * 7 + seed) % 5)
            }
        }
        var range by mutableStateOf(dev.repera.domain.ProgressTimeRange.WEEK)
        brandContent {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                ActivityHeatmapCard(
                    timeLevels = niveles(1).takeLast(if (range == dev.repera.domain.ProgressTimeRange.WEEK) 7 else 98),
                    volumeLevels = niveles(3).takeLast(if (range == dev.repera.domain.ProgressTimeRange.WEEK) 7 else 98),
                    range = range)
            }
        }
        compose.waitForIdle()
        save("heatmap_franja_semana", compose.onRoot().captureToImage())
        range = dev.repera.domain.ProgressTimeRange.DAYS_90
        compose.waitForIdle()
        save("heatmap_rejilla_90d", compose.onRoot().captureToImage())
        compose.onNodeWithTag("heatmap_metric_volume").performClick()
        compose.waitForIdle()
        save("heatmap_rejilla_volumen", compose.onRoot().captureToImage())
        // El selector segmentado conmuta la leyenda a volumen.
        compose.onAllNodesWithText("Menos volumen").fetchSemanticsNodes().isNotEmpty().let { hay ->
            if (!hay) throw AssertionError("La leyenda de volumen no aparece tras cambiar de métrica")
        }
    }

    /** SessionPreviewSheet (SessionPreviewView iOS): contraste de las tarjetas
     *  de bloque y de los textos secundarios sobre el fondo de la hoja. */
    @Test
    fun capturaVistaPreviaSesion() {
        val routine = RoutineEntry(
            id = "r1", title = "Torso pesado", supported = true,
            weekday = 1, timeMinutes = 8 * 60 + 30,
            blocks = listOf(
                RoutineBlockInfo(title = "A", format = "strength", entries = listOf(
                    RoutineBlockEntryInfo(exerciseId = "x1", name = "Press banca",
                        quantity = 5, sets = 4, weightKg = 80.0),
                    RoutineBlockEntryInfo(exerciseId = "x2", name = "Remo con barra",
                        quantity = 8, sets = 3, weightKg = 60.0))),
                RoutineBlockInfo(title = "B", format = "emom",
                    timeCapMinutes = 10, emomIntervalSeconds = 90, entries = listOf(
                        RoutineBlockEntryInfo(exerciseId = "x3", name = "Dominadas",
                            quantity = 6)))))
        brandContent {
            // La hoja lleva su propio verticalScroll: envolverla en otro
            // Column con scroll la mide con altura infinita y crashea el
            // proceso (arrastrando tests ajenos).
            SessionPreviewSheet(routine = routine, busy = false,
                onStart = {}, onEdit = {}, onDelete = {}, onClose = {})
        }
        compose.waitForIdle()
        save("session_preview", compose.onRoot().captureToImage())
    }

    private fun rutaCardioSintetica(): List<WorkoutRoutePoint> {
        // Bucle sintético ~1,2 km alrededor del Retiro (Madrid) con velocidad
        // variable para cubrir los colores por segmento (paridad speedColor iOS).
        val base = listOf(
            40.4153 to -3.6845, 40.4160 to -3.6830, 40.4170 to -3.6820,
            40.4180 to -3.6825, 40.4188 to -3.6840, 40.4190 to -3.6860,
            40.4182 to -3.6880, 40.4170 to -3.6890, 40.4158 to -3.6885,
            40.4150 to -3.6870, 40.4148 to -3.6855, 40.4153 to -3.6845)
        val speeds = listOf(2.2, 2.6, 3.1, 3.4, 2.9, 2.4, 2.8, 3.3, 3.0, 2.5, 2.3, 0.0)
        return base.mapIndexed { i, (lat, lon) ->
            WorkoutRoutePoint(i, lat, lon, 1_700_000_000_000L + i * 45_000L,
                speedMps = speeds[i], altitudeMeters = 640.0 + i)
        }
    }

    @Test
    fun capturaRutaCardioMapa() {
        // El mapa nativo (MapLibre/GL) NO lo captura captureToImage: hay que
        // leer el framebuffer real (UiAutomation, API 30+). Se espera a que el
        // estilo cargue (seam de verificación) y a que lleguen teselas.
        val styleLoaded = java.util.concurrent.CountDownLatch(1)
        brandContent {
            Column(Modifier.fillMaxSize()) {
                RouteMapView(points = rutaCardioSintetica(), isInteractive = false,
                    modifier = Modifier.fillMaxWidth().height(420.dp),
                    onStyleLoaded = { styleLoaded.countDown() })
            }
        }
        compose.waitForIdle()
        val loaded = styleLoaded.await(60, java.util.concurrent.TimeUnit.SECONDS)
        if (!loaded) {
            // Sin red/teselas el componente degrada a Canvas. Nombre distinto:
            // los píxeles del fallback NUNCA deben confundirse con MapLibre real.
            save("ruta_cardio_mapa_fallback_canvas", compose.onRoot().captureToImage())
            return
        }
        Thread.sleep(8_000) // teselas asíncronas tras el estilo
        val shot = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot()
        checkNotNull(shot) { "UiAutomation.takeScreenshot devolvió null" }
        save("ruta_cardio_mapa", shot.asImageBitmap())
    }

    private val editorTerminadoBlocksJson = """[{"id":"b1","title":"A","kind":"strength","exercises":[
        {"id":"e1","exerciseId":"x1","plannedSets":[{"id":"p1","targetReps":5,"targetWeightKg":60,"targetRir":2}]}]},
        {"id":"b2","title":"B","kind":"strength","exercises":[]}]"""

    private fun editorTerminadoVisualFixture() = WorkoutHistoryEntry(
        id = "w-vis", title = "Entreno visual", startedAt = "25 oct", results = emptyList(),
        movements = emptyList(), startedAtIso = "2026-10-25T10:00:00Z",
        finishedAtIso = "2026-10-25T11:00:00Z", notes = "nota",
        editableBlocksJson = editorTerminadoBlocksJson)

    private val editorTerminadoCatalog =
        listOf(ExerciseEntry("x1", "Sentadilla", true, true), ExerciseEntry("x2", "Press", true, true))

    @Test
    fun capturaEditorEntrenoTerminado() {
        brandContent {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                FinishedWorkoutEditorSection(editorTerminadoVisualFixture(), "acc", false,
                    editorTerminadoCatalog) {}
            }
        }
        compose.waitForIdle()
        save("editor_terminado_colapsado", compose.onRoot().captureToImage())
        compose.onNodeWithTag("edit_finished_workout").performScrollTo().performClick()
        compose.waitForIdle()
        save("editor_terminado_edicion", compose.onRoot().captureToImage())
        // Acciones inferiores (Guardar / Cancelar / guardar como favorito):
        // main 25/10 — no basta la zona superior.
        compose.onNodeWithTag("edit_save").performScrollTo()
        compose.waitForIdle()
        save("editor_terminado_acciones", compose.onRoot().captureToImage())
    }

    @Test
    fun capturaEditorTerminadoDragABloqueVacio() {
        // Mismo flujo que dragExerciseIntoEmptyBlockMovesItKeepingId (el test de
        // datos afirma ids): aquí queda la evidencia visual antes/después del drop.
        brandContent {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                FinishedWorkoutEditorSection(editorTerminadoVisualFixture(), "acc", false,
                    editorTerminadoCatalog) {}
            }
        }
        compose.waitForIdle()
        compose.onNodeWithTag("edit_finished_workout").performScrollTo().performClick()
        compose.waitForIdle()
        save("editor_terminado_drag_antes", compose.onRoot().captureToImage())
        val startY = compose.onNodeWithTag("ex_drag_0_0").fetchSemanticsNode().boundsInRoot.center.y
        val targetY = compose.onNodeWithTag("block_title_1").fetchSemanticsNode().boundsInRoot.center.y
        compose.onNodeWithTag("ex_drag_0_0").performTouchInput {
            down(center); advanceEventTime(700)
            repeat(12) { moveBy(Offset(0f, (targetY - startY) / 12f)); advanceEventTime(50) }
            advanceEventTime(50); up()
        }
        compose.waitForIdle()
        save("editor_terminado_drag_despues", compose.onRoot().captureToImage())
    }
}
