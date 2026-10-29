"""Regresiones de UI: fondo de Inicio y drop nativo en bloques vacíos.

Contratos estáticos: no sustituyen una prueba de gestos en iPhone.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1] / "Apps" / "Repera" / "Sources"
HOME = (ROOT / "HomeView.swift").read_text(encoding="utf-8")
PLAN = (ROOT / "PlanView.swift").read_text(encoding="utf-8")
PLAY = (ROOT / "WorkoutView.swift").read_text(encoding="utf-8")
THEME = (ROOT / "Theme.swift").read_text(encoding="utf-8")


class HomeBackgroundAndEmptyReorderContracts(unittest.TestCase):
    def test_home_topbar_is_transparent_and_its_underlay_is_white(self):
        self.assertIn(
            '.ogFixedTopBar("repera", subtitle: SpanishDate.long(selectedDay), drawsBackground: false)',
            HOME,
        )
        outer_background = HOME.split('.ogFixedTopBar("repera"', 1)[1].split(".onAppear {", 1)[0]
        self.assertIn(".background(OG.surface.ignoresSafeArea())", outer_background)

    def test_home_scroll_background_is_gray_but_does_not_enter_top_safe_area(self):
        before_toolbar = HOME.split('.ogFixedTopBar("repera"', 1)[0]
        self.assertIn(
            ".background(OG.bg.ignoresSafeArea(edges: [.horizontal, .bottom]))",
            before_toolbar,
        )
        self.assertNotIn(
            ".background(OG.bg.ignoresSafeArea())\n            .onGeometryChange",
            HOME,
        )
        self.assertIn(
            ".background(OG.surface.ignoresSafeArea(edges: [.top, .horizontal]))",
            before_toolbar,
        )

    def test_empty_block_is_a_native_drop_target_in_both_screens(self):
        target = "ForEach(rows.isEmpty ? [OGReorderEntry.emptyDropTarget(for: block.id)] : rows)"
        for swift in (PLAN, PLAY):
            with self.subTest(screen="Plan" if swift is PLAN else "Play"):
                self.assertIn(target, swift)
                self.assertIn('if row.type == "emptyDropTarget"', swift)
                self.assertIn(".frame(maxWidth: .infinity, minHeight: 104)", swift)
                self.assertIn(".contentShape(Rectangle())", swift)
                self.assertIn(".reorderable(collectionID: block.id.uuidString)", swift)
                self.assertIn(".reorderContainer(for: OGReorderEntry.self, in: String.self)", swift)

    def test_placeholder_has_stable_distinct_identity_and_is_not_persisted(self):
        source = THEME.split("struct OGReorderEntry: Identifiable, Sendable", 1)[1].split(
            "struct OGReorderInsertionGap:", 1
        )[0]
        self.assertIn("static func emptyDropTarget(for blockID: UUID) -> Self", source)
        self.assertIn("var bytes = blockID.uuid", source)
        self.assertIn("bytes.0 ^= 0x80", source)
        self.assertIn('type: "emptyDropTarget"', source)
        # The reorder callback only accepts actual exercises and movements.
        for swift in (PLAN, PLAY):
            self.assertIn("$0.exercises.contains(where: { $0.id == id })", swift)
            self.assertIn("$0.movements.contains(where: { $0.id == id })", swift)


if __name__ == "__main__":
    unittest.main()
