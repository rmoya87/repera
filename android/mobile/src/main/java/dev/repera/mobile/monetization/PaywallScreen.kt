package dev.repera.mobile.monetization

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
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
import dev.repera.domain.monetization.PaywallContext
import dev.repera.mobile.brandGreen
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

enum class PaywallMode { SHEET, ONBOARDING }

/**
 * Paywall Repera Pro. Port 1:1 de PaywallView.swift (modos sheet/onboarding).
 */
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

    val context = if (mode == PaywallMode.ONBOARDING) PaywallContext.ONBOARDING
    else subscriptions.paywall.context
    val packages = subscriptions.offerings.packages
    val annual = packages.firstOrNull { it.isAnnual }
    val monthly = packages.firstOrNull { !it.isAnnual }

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
        Box(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                PaywallHeader(mode, context)
                PaywallBenefits(context)
                PaywallPlans(
                    subscriptions = subscriptions,
                    annual = annual,
                    monthly = monthly,
                    selectedProductID = selectedProductID,
                    onSelect = { selectedProductID = it }
                )
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
            if (mode == PaywallMode.SHEET) {
                IconButton(
                    onClick = { subscriptions.dismissPaywall() },
                    modifier = Modifier.align(Alignment.TopEnd).padding(8.dp)
                ) {
                    Icon(Icons.Default.Close, contentDescription = "Cerrar")
                }
            }
        }
    }
}

@Composable
private fun PaywallHeader(mode: PaywallMode, context: PaywallContext) {
    Column(
        modifier = Modifier.padding(top = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Paridad iOS: mascota hero en onboarding, icono de marca en sheet.
        if (mode == PaywallMode.ONBOARDING) {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                dev.repera.mobile.ReperaMascot(dev.repera.mobile.ReperaMascotPose.HERO, maxHeight = 160.dp)
            }
        } else {
            Icon(
                Icons.Default.FitnessCenter,
                contentDescription = null,
                tint = brandGreen,
                modifier = Modifier.size(36.dp)
            )
        }
        Text(
            context.headline,
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onBackground
        )
        Text(
            context.subtitle,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PaywallBenefits(context: PaywallContext) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            context.prioritizedBenefits.forEach { benefit ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = brandGreen,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        benefit,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
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
        Card(modifier = Modifier.fillMaxWidth()) {
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
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
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
            .border(
                width = 1.5.dp,
                color = if (selected) brandGreen else androidx.compose.ui.graphics.Color.Transparent,
                shape = shape
            ),
        shape = shape
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                if (selected) Icons.Default.CheckCircle else Icons.Outlined.Circle,
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
    val title = if (selected?.hasFreeTrial == true) "Probar Repera Pro" else "Continuar con Repera Pro"
    Surface(
        onClick = {
            val id = selectedProductID ?: return@Surface
            scope.launch { onResult(subscriptions.purchase(id)) }
        },
        enabled = selectedProductID != null && !subscriptions.purchaseInFlight && packages.isNotEmpty(),
        modifier = Modifier.fillMaxWidth().height(50.dp),
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
        verticalArrangement = Arrangement.spacedBy(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (mode == PaywallMode.ONBOARDING) {
            TextButton(onClick = { onContinueFree?.invoke() }) {
                Text("Seguir con el plan Gratis", fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface)
            }
        }
        TextButton(
            onClick = {
                scope.launch {
                    val ok = subscriptions.restorePurchases()
                    if (ok) {
                        if (mode == PaywallMode.ONBOARDING) onPurchaseSuccess?.invoke()
                    } else onError()
                }
            },
            enabled = !subscriptions.purchaseInFlight
        ) {
            Text("Restaurar compras", fontWeight = FontWeight.SemiBold, color = brandGreen)
        }
        if (mode == PaywallMode.SHEET) {
            TextButton(onClick = { openUrl(CommercialConfig.MANAGE_SUBSCRIPTIONS_URL) }) {
                Text("Gestionar suscripción", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            TextButton(onClick = { openUrl(CommercialConfig.PRIVACY_POLICY_URL) }) {
                Text("Privacidad", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            TextButton(onClick = { openUrl(CommercialConfig.TERMS_OF_USE_URL) }) {
                Text("Términos", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
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
