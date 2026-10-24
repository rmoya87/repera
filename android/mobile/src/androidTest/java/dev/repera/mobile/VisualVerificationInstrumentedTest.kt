package dev.repera.mobile

import android.graphics.Bitmap
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.layout.size
import androidx.compose.ui.unit.dp
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
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
    val compose = createComposeRule()

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
        compose.setContent {
            MaterialTheme(colorScheme = lightColorScheme(
                primary = brandGreen, onPrimary = Color.Black)) {
                Surface(modifier = Modifier.fillMaxSize()) { content() }
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
        val (active, timer) = wodClockFixture()
        brandContent {
            // Caja 400x200 dp (proporción landscape): fuerza la rama apaisada
            // (ancho > alto) SIN exceder la ventana del emulador: 840dp quedaba
            // recortado a los 411dp visibles y las cifras LED salían cortadas.
            androidx.compose.foundation.layout.Box(
                modifier = Modifier
                    .requiredSize(400.dp, 200.dp)
                    .testTag("wod_landscape_capture")
            ) {
                WodClockScreen(active, false, timer, {}, {}, {}, requestNotificationPermission = false)
            }
        }
        compose.waitForIdle()
        save(
            "reloj_wod_apaisado",
            compose.onNodeWithTag("wod_landscape_capture").captureToImage()
        )
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
                HeatmapCard("Constancia (minutos por día)", time)
                HeatmapCard("Volumen (kg por día)", volume)
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
        brandContent {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                MuscleBalanceCard(
                    loadAll = load, loadHard = load,
                    fatigueAll = fatigue, fatigueHard = fatigue,
                    hasHardSets = true)
            }
        }
        compose.waitForIdle()
        // BodyMapView carga BodyPaths.json de assets en Dispatchers.Default:
        // waitForIdle NO lo espera. Precarga determinista desde el contexto
        // de la app bajo test y espera al nodo; si no aparece, FALLO (la
        // captura anterior mostraba el Spacer de 220dp y nadie lo detectó).
        val appContext = androidx.test.platform.app.InstrumentationRegistry
            .getInstrumentation().targetContext
        kotlinx.coroutines.runBlocking {
            org.junit.Assert.assertNotNull(
                "BodyPaths.json debe cargar desde assets del target",
                CompiledBodyPaths.shared(appContext))
        }
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("body_map_loaded").fetchSemanticsNodes().isNotEmpty()
        }
        org.junit.Assert.assertTrue(
            "El mapa corporal no apareció tras la espera (placeholder de 220dp)",
            compose.onAllNodesWithTag("body_map_loaded").fetchSemanticsNodes().isNotEmpty())
        compose.waitForIdle()
        save("progreso_equilibrio_muscular", compose.onRoot().captureToImage())
        // Segundo modo: Esfuerzo (series duras), paridad del segmented iOS.
        compose.onNodeWithText("Esfuerzo").performClick()
        compose.waitForIdle()
        save("progreso_equilibrio_muscular_esfuerzo", compose.onRoot().captureToImage())
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
                primary = brandGreen,
                onPrimary = androidx.compose.ui.graphics.Color.Black)) {
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
                primary = brandGreen,
                onPrimary = androidx.compose.ui.graphics.Color.Black)) {
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
                primary = brandGreen,
                onPrimary = androidx.compose.ui.graphics.Color.Black)) {
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
}
