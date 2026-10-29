package dev.repera.mobile.monetization

import dev.repera.mobile.ReperaCard

import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.repera.mobile.brandGreen
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

enum class PaywallMode { SHEET, ONBOARDING }

/** Página de pricing nativa, sin hoja inferior. Paridad visual con PaywallView.swift. */
@Composable
fun PaywallScreen(
    subscriptions: SubscriptionManager,
    mode: PaywallMode = PaywallMode.SHEET,
    onContinueFree: (() -> Unit)? = null,
    onPurchaseSuccess: (() -> Unit)? = null
) {
    val scope = rememberCoroutineScope()
    val uriHandler = LocalUriHandler.current
    var selectedProductID by rememberSaveable { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }

    val packages = subscriptions.offerings.packages
    val annual = packages.firstOrNull { it.isAnnual }
    val monthly = packages.firstOrNull { !it.isAnnual }

    androidx.activity.compose.BackHandler(enabled = mode == PaywallMode.SHEET) {
        subscriptions.dismissPaywall()
    }

    LaunchedEffect(Unit) {
        subscriptions.start()
        subscriptions.loadOfferings()
    }
    LaunchedEffect(packages.map { it.productID }) {
        if (selectedProductID == null || packages.none { it.productID == selectedProductID }) {
            selectedProductID = annual?.productID ?: monthly?.productID
        }
    }

    if (showError) {
        AlertDialog(
            onDismissRequest = { showError = false },
            confirmButton = { TextButton(onClick = { showError = false }) { Text("OK") } },
            title = { Text("No se pudo completar") },
            text = { Text(subscriptions.lastErrorMessage ?: "Inténtalo de nuevo.") }
        )
    }

    Surface(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .statusBarsPadding()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 12.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                PaywallHeader(mode = mode, onBack = { subscriptions.dismissPaywall() })
                PaywallComparison()
                Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
                    PaywallSectionHeading("ELIGE TU PLAN")
                    PaywallPlans(
                        subscriptions = subscriptions,
                        annual = annual,
                        monthly = monthly,
                        selectedProductID = selectedProductID,
                        onSelect = { selectedProductID = it }
                    )
                }
                PaywallSecondaryActions(
                    subscriptions = subscriptions,
                    mode = mode,
                    onContinueFree = onContinueFree,
                    onPurchaseSuccess = onPurchaseSuccess,
                    onError = { showError = true },
                    scope = scope,
                    openUrl = { uriHandler.openUri(it) }
                )
                PaywallLegalFooter(packages, selectedProductID)
            }

            // R7 P0: CTA por encima de la barra de gestos (navigationBarsPadding).
            Surface(color = MaterialTheme.colorScheme.background) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .padding(horizontal = 20.dp, vertical = 6.dp)
                ) {
                    PaywallPrimaryCTA(
                        subscriptions = subscriptions,
                        packages = packages,
                        selectedProductID = selectedProductID,
                        onResult = { ok ->
                            if (ok) {
                                if (mode == PaywallMode.SHEET) subscriptions.dismissPaywall()
                                onPurchaseSuccess?.invoke()
                            } else if (subscriptions.lastErrorMessage != null) {
                                showError = true
                            }
                        },
                        scope = scope
                    )
                }
            }
        }
    }
}

@Composable
private fun PaywallSectionHeading(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 1.sp,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

@Composable
private fun PaywallHeader(mode: PaywallMode, onBack: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (mode == PaywallMode.SHEET) {
                // R7: touch 48 / círculo 44 / icono 24.
                IconButton(onClick = onBack, modifier = Modifier.size(48.dp)) {
                    Icon(
                        androidx.compose.material.icons.Icons.Outlined.ArrowBack,
                        contentDescription = "Volver",
                        tint = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }
            Text(
                "Repera Pro",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // R8 P2-6: eyebrow iOS «DESBLOQUEA MÁS».
                Text(
                    "DESBLOQUEA MÁS",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    "Todo tu progreso.",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    "Desbloquea el siguiente nivel de Repera.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Box(
                modifier = Modifier.size(100.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(85.dp)
                        .background(brandGreen.copy(alpha = 0.10f), CircleShape)
                )
                dev.repera.mobile.ReperaMascot(
                    dev.repera.mobile.ReperaMascotPose.HERO,
                    maxHeight = 97.dp
                )
            }
        }
    }
}

@Composable
private fun PaywallComparison() {
    val limits = dev.repera.domain.monetization.FreePlanLimits
    val rows = listOf(
        // Paridad PaywallView.swift: («Mapa», «2D», «2D + 3D»).
        Triple("Mapa", "2D", "2D + 3D"),
        Triple("Progreso", "Esta semana", "Todos los periodos"),
        Triple("Por ejercicio", "Última + récord", "Historial completo"),
        Triple("Rutinas / favoritos",
            "${limits.MAX_LIBRARY_ROUTINES} / ${limits.MAX_FAVORITE_ITEMS}", "Sin límites"),
        Triple("Ejercicios propios", "${limits.MAX_CUSTOM_EXERCISES}", "Sin límites"),
        Triple("Escáner WOD", "${limits.MAX_BOARD_SCANS_PER_MONTH}/mes", "Ilimitado"),
        Triple("Análisis y WOD", "Básico", "Avanzado")
    )
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        PaywallSectionHeading("GRATIS VS PRO")
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("FUNCIÓN", modifier = Modifier.weight(1.1f),
                fontSize = 10.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("GRATIS", modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                fontSize = 10.sp, fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("PRO", modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                fontSize = 10.sp, fontWeight = FontWeight.SemiBold, color = brandGreen)
        }
        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth().heightIn(min = 29.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(row.first, modifier = Modifier.weight(1.1f),
                    fontSize = 11.sp, lineHeight = 13.sp, fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface)
                Text(row.second, modifier = Modifier.weight(1f),
                    fontSize = 11.sp, lineHeight = 13.sp,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(row.third, modifier = Modifier.weight(1f),
                    fontSize = 11.sp, lineHeight = 13.sp,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurface)
            }
            androidx.compose.material3.HorizontalDivider(
                color = MaterialTheme.colorScheme.outlineVariant,
                thickness = 0.6.dp
            )
        }
    }
}

@Composable
private fun PaywallPlans(
    subscriptions: SubscriptionManager,
    annual: CommercialPackageInfo?,
    monthly: CommercialPackageInfo?,
    selectedProductID: String?,
    onSelect: (String) -> Unit
) {
    if (subscriptions.offerings.packages.isEmpty()) {
        ReperaCard(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    "Compras no disponibles",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    subscriptions.offerings.unavailableReason
                        ?: "No se han podido cargar las suscripciones. Comprueba la conexión e inténtalo de nuevo.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    } else {
        Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
            annual?.let {
                PlanRow(it, savingsBadge(it, monthly), selectedProductID == it.productID, onSelect)
            }
            monthly?.let {
                PlanRow(it, null, selectedProductID == it.productID, onSelect)
            }
        }
    }
}

@Composable
private fun PlanRow(
    pkg: CommercialPackageInfo,
    badge: String?,
    selected: Boolean,
    onSelect: (String) -> Unit
) {
    val shape = RoundedCornerShape(16.dp)
    Surface(
        onClick = { onSelect(pkg.productID) },
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .semantics { role = androidx.compose.ui.semantics.Role.RadioButton; this.selected = selected }
            .border(
                width = 1.5.dp,
                color = if (selected) brandGreen else MaterialTheme.colorScheme.outlineVariant,
                shape = shape
            ),
        shape = shape,
        color = MaterialTheme.colorScheme.surface
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                if (selected) Icons.Outlined.CheckCircle else Icons.Outlined.Circle,
                contentDescription = null,
                tint = if (selected) brandGreen else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(24.dp)
            )
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        if (pkg.isAnnual) "Anual" else "Mensual",
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    badge?.let {
                        Text(
                            it,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = androidx.compose.ui.graphics.Color.Black,
                            modifier = Modifier
                                .background(brandGreen, CircleShape)
                                .padding(horizontal = 8.dp, vertical = 3.dp)
                        )
                    }
                }
                Text(
                    pkg.localizedPrice + if (pkg.isAnnual) " / año" else " / mes",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                pkg.introductoryOfferSummary?.let {
                    Text(it, fontSize = 12.sp, color = brandGreen)
                }
            }
        }
    }
}

@Composable
private fun PaywallPrimaryCTA(
    subscriptions: SubscriptionManager,
    packages: List<CommercialPackageInfo>,
    selectedProductID: String?,
    onResult: (Boolean) -> Unit,
    scope: kotlinx.coroutines.CoroutineScope
) {
    val selected = packages.firstOrNull { it.productID == selectedProductID }
    // PaywallView.swift: «Continuar con Pro» (no «…con Repera Pro»).
    val title = if (selected?.hasFreeTrial == true) "Probar Repera Pro" else "Continuar con Pro →"
    Surface(
        onClick = {
            val id = selectedProductID ?: return@Surface
            scope.launch { onResult(subscriptions.purchase(id)) }
        },
        enabled = selectedProductID != null && !subscriptions.purchaseInFlight && packages.isNotEmpty(),
        modifier = Modifier.fillMaxWidth().height(48.dp),
        shape = RoundedCornerShape(14.dp),
        color = brandGreen
    ) {
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (subscriptions.purchaseInFlight) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = androidx.compose.ui.graphics.Color.Black,
                    strokeWidth = 2.dp
                )
                Spacer(Modifier.size(8.dp))
            }
            Text(title, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                color = androidx.compose.ui.graphics.Color.Black)
        }
    }
}

@Composable
private fun PaywallSecondaryActions(
    subscriptions: SubscriptionManager,
    mode: PaywallMode,
    onContinueFree: (() -> Unit)?,
    onPurchaseSuccess: (() -> Unit)?,
    onError: () -> Unit,
    scope: kotlinx.coroutines.CoroutineScope,
    openUrl: (String) -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (mode == PaywallMode.ONBOARDING) {
            TextButton(onClick = { onContinueFree?.invoke() }) {
                Text("Seguir con Gratis", fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurface)
            }
        }

        // En móviles normales caben en la misma fila; si la fuente es grande
        // o la pantalla estrecha, se reparte en dos filas sin recortar enlaces.
        androidx.compose.foundation.layout.BoxWithConstraints(Modifier.fillMaxWidth()) {
            val compact = maxWidth < 340.dp
            if (compact) {
                Column {
                    Row(Modifier.fillMaxWidth()) {
                        PaywallFooterAction("Restaurar", Modifier.weight(1f)) {
                            scope.launch {
                                if (subscriptions.restorePurchases()) {
                                    if (mode == PaywallMode.ONBOARDING) onPurchaseSuccess?.invoke()
                                } else onError()
                            }
                        }
                        PaywallFooterAction("Gestionar", Modifier.weight(1f)) {
                            openUrl(CommercialConfig.MANAGE_SUBSCRIPTIONS_URL)
                        }
                    }
                    Row(Modifier.fillMaxWidth()) {
                        PaywallFooterAction("Privacidad", Modifier.weight(1f)) {
                            openUrl(CommercialConfig.PRIVACY_POLICY_URL)
                        }
                        PaywallFooterAction("Términos", Modifier.weight(1f)) {
                            openUrl(CommercialConfig.TERMS_OF_USE_URL)
                        }
                    }
                }
            } else {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    PaywallFooterAction("Restaurar", Modifier.weight(1f)) {
                        scope.launch {
                            if (subscriptions.restorePurchases()) {
                                if (mode == PaywallMode.ONBOARDING) onPurchaseSuccess?.invoke()
                            } else onError()
                        }
                    }
                    PaywallFooterAction("Gestionar", Modifier.weight(1f)) {
                        openUrl(CommercialConfig.MANAGE_SUBSCRIPTIONS_URL)
                    }
                    PaywallFooterAction("Privacidad", Modifier.weight(1f)) {
                        openUrl(CommercialConfig.PRIVACY_POLICY_URL)
                    }
                    PaywallFooterAction("Términos", Modifier.weight(1f)) {
                        openUrl(CommercialConfig.TERMS_OF_USE_URL)
                    }
                }
            }
        }
    }
}

@Composable
private fun PaywallFooterAction(
    title: String,
    modifier: Modifier = Modifier,
    action: () -> Unit
) {
    androidx.compose.material3.TextButton(
        onClick = action,
        modifier = modifier.height(32.dp),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 0.dp, vertical = 0.dp)
    ) {
        Text(title, fontSize = 11.sp, maxLines = 1,
            color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun PaywallLegalFooter(packages: List<CommercialPackageInfo>, selectedProductID: String?) {
    val parts = mutableListOf(
        "El pago se cargará en tu cuenta de Google Play al confirmar la compra.",
        "La suscripción se renueva automáticamente salvo que la canceles antes del final del periodo."
    )
    packages.firstOrNull { it.productID == selectedProductID }?.let { pkg ->
        parts += "Precio de renovación: ${pkg.localizedPrice}${if (pkg.isAnnual) " al año" else " al mes"}."
        if (pkg.hasFreeTrial && pkg.introductoryOfferSummary != null) {
            parts += "${pkg.introductoryOfferSummary}. Tras la prueba se aplica el precio de renovación indicado."
        }
    }
    parts += "Puedes gestionar o cancelar en Play Store > Pagos y suscripciones."
    Text(
        parts.joinToString(" "),
        fontSize = 11.sp,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.fillMaxWidth()
    )
}

private fun savingsBadge(annual: CommercialPackageInfo, monthly: CommercialPackageInfo?): String? {
    val annualPrice = annual.priceValue ?: return null
    val monthlyPrice = monthly?.priceValue ?: return null
    if (monthlyPrice <= 0) return null
    val yearOfMonthly = monthlyPrice * 12
    if (yearOfMonthly <= annualPrice) return null
    val pct = ((yearOfMonthly - annualPrice) / yearOfMonthly * 100).roundToInt()
    return if (pct > 0) "Ahorra $pct%" else null
}
