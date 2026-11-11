#!/usr/bin/env python3
"""Contrato: métricas reloj valor|etiqueta, FC con LPM, outdoor layout."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


class WatchWearOutdoorMetricLayoutContract(unittest.TestCase):
    def test_watch_metric_row_is_value_then_label(self):
        live = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        row = live.split("struct WatchLiveMetricInline:", 1)[1].split(
            "struct WatchLiveMetricRow:", 1
        )[0]
        value_idx = row.find("Text(value)")
        label_idx = row.find("Text(label)")
        self.assertGreater(value_idx, 0)
        self.assertGreater(label_idx, value_idx)
        self.assertIn('label: "último km"', live)
        self.assertIn('"ritmo medio"', live)
        self.assertIn('label: "Kcal"', live)
        self.assertIn('Text("LPM")', live)
        self.assertNotIn('Text(zone.map { "Zona', live)

    def test_watch_outdoor_time_alone_km_kcal_row_and_side_labels(self):
        live = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        companion = read("Apps/ReperaWatch/Sources/WatchSessionView.swift")
        # Tiempo solo (sin km a la derecha).
        self.assertIn("Tiempo solo; km/kcal van debajo en outdoor.", live)
        self.assertIn("WatchLiveMetricScale.fit(", live)
        self.assertIn("WatchLiveMetricScale.fit(", companion)
        # Tiempo ~⅓ mayor (tope ~77 / suelo ~69).
        scale = live.split("static func fit(", 1)[1].split("let split =", 1)[0]
        self.assertIn("77", scale)
        self.assertIn("69", scale)
        self.assertIn("h * 0.45", scale)
        # Sin Spacer muerto bajo LPM: hueco repartido entre filas.
        self.assertIn("Spacer(minLength: scale.gap)", live)
        self.assertNotIn("Spacer(minLength: 0)", live.split("struct WatchLiveSessionView", 1)[1].split(
            "struct WatchOutdoorMetricsBlock", 1
        )[0])
        self.assertIn("WatchOutdoorKmKcalRow(", live)
        self.assertIn("WatchOutdoorKmKcalRow(", companion)
        # Etiqueta a la derecha del número en 2 líneas; label fijo 10pt.
        cell = live.split("private struct WatchOutdoorSplitCell:", 1)[1].split(
            "enum WatchOutdoorMetricFormat", 1
        )[0]
        self.assertIn("labelLines", cell)
        self.assertIn(".font(.system(size: 10, weight: .semibold))", cell)
        self.assertIn("valueSize: CGFloat = 36", cell)
        self.assertIn("scale.time", live)
        self.assertIn("scale.time", companion)
        self.assertIn("Sin ScrollView", live)

    def test_wear_metric_row_is_value_then_label(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        row = wear.split("internal fun WearLiveMetricInline(", 1)[1].split(
            "internal fun WearLiveMetricRow(", 1
        )[0]
        value_idx = row.find("value,")
        label_idx = row.find("label,")
        self.assertGreater(value_idx, 0)
        self.assertGreater(label_idx, value_idx)
        self.assertIn('leftLabel = "último km"', wear)
        self.assertIn('"ritmo medio"', wear)
        self.assertIn('label = "Kcal"', wear)
        self.assertIn('"LPM"', wear)
        self.assertNotIn("Zona —/5", wear)
        self.assertIn("lastKilometerSeconds", wear)

    def test_wear_outdoor_time_alone_km_kcal_and_side_labels(self):
        wear = read("android/wear/src/main/java/dev/repera/wear/WearLiveActivityScreen.kt")
        self.assertIn("Tiempo solo; km/kcal debajo alineados con las columnas outdoor.", wear)
        self.assertIn("WearLiveMetricsScale.fit(", wear)
        self.assertIn("gap = 11.dp", wear)
        cell = wear.split("private fun WearOutdoorSplitCell(", 1)[1].split(
            "internal fun WearHeartRateBpmLabel(", 1
        )[0]
        # Wear circular: etiqueta completa debajo (no al lado).
        self.assertIn("etiqueta COMPLETA debajo", cell)
        self.assertIn("textAlign = TextAlign.Center", cell)
        self.assertNotIn("parts.size >= 2", cell)
        self.assertIn("WearOutdoorKmKcalRow(", wear)
        self.assertIn("Modifier.weight(1f)", wear)
        self.assertIn("rimBottomRight = true", wear)
        self.assertIn("WearHeartRateBpmLabel(", wear)
        self.assertIn("WearHeartRateZoneRim(", wear)
        self.assertIn("side * 0.14f", wear)
        self.assertIn("0.5.dp.toPx()", wear)
        self.assertIn("startDeg = -22f", wear)
        # Condiciones fuera del viewport live (recortaban km/kcal/LPM).
        self.assertIn("Condiciones fuera del viewport live", wear)
        # Watch conserva etiqueta a la derecha; Wear no la copia.
        watch = read("Apps/ReperaWatch/Sources/WatchLiveSessionView.swift")
        self.assertIn("labelLines", watch)

    def test_phone_and_android_publish_last_kilometer(self):
        ios = read("Apps/Repera/Sources/LiveActivityView.swift")
        snap = read(
            "Packages/ReperaDomain/Sources/ReperaDomain/WatchLiveActivitySnapshot.swift"
        )
        bridge = read(
            "android/mobile/src/main/java/dev/repera/mobile/WearActiveSessionBridge.kt"
        )
        self.assertIn("lastKilometerSeconds: sport.usesGPS ? kilometerSplits.last?.seconds", ios)
        self.assertIn("lastKilometerSeconds", snap)
        self.assertIn('"lastKilometerSeconds"', bridge)
        self.assertIn("state.splitsSeconds.lastOrNull()", bridge)


if __name__ == "__main__":
    unittest.main()
