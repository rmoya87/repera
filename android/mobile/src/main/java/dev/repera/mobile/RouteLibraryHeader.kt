package dev.repera.mobile
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/** LiveRouteLibraryView final cut: large title and neutral close on one row. */
@Composable internal fun RouteLibraryHeader(onClose:()->Unit) {
 Row(Modifier.fillMaxWidth(),verticalAlignment=Alignment.CenterVertically) {
  Text("Mis rutas",fontSize=31.sp,fontWeight=FontWeight.Bold,
   color=MaterialTheme.colorScheme.onSurface,modifier=Modifier.weight(1f))
  IconButton(onClick=onClose) {
   Icon(Icons.Default.Close,contentDescription="Cerrar Mis rutas",
    tint=MaterialTheme.colorScheme.onSurface)
  }
 }
}
