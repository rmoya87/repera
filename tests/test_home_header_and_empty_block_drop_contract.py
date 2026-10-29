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

    def test_empty_blocks_accept_drag_without_fake_model_items(self):
        for swift in (PLAN, PLAY):
            with self.subTest(screen="Plan" if swift is PLAN else "Play"):
                self.assertIn("if rows.isEmpty {", swift)
                self.assertIn('Text("Soltar ejercicio")', swift)
                self.assertIn(".frame(maxWidth: .infinity, minHeight: 104)", swift)
                self.assertIn(".contentShape(Rectangle())", swift)
                self.assertIn(".onDrop(", swift)
                self.assertIn('accepts: { _ in true }', swift)
                self.assertIn('if token.hasPrefix("block:")', swift)
                self.assertIn("movedBlock", swift)

    def test_reorder_does_not_use_swiftui_beta_uuid_containers(self):
        for swift in (PLAN, PLAY):
            self.assertNotIn(".reorderContainer(", swift)
            self.assertNotIn(".reorderable(", swift)
            self.assertIn(".onDrag", swift)
            self.assertIn(".onDrop(", swift)
            self.assertIn("NSItemProvider(object: dragToken as NSString)", swift)
            self.assertIn("delegate: OGReorderDropDelegate(", swift)
            self.assertNotIn(".dropDestination(for: String.self)", swift)
        self.assertNotIn("emptyDropTarget", THEME)

    def test_reorder_keeps_workout_data_update_paths(self):
        self.assertIn("applyReorder(token, into: block.id, before:", PLAN)
        self.assertIn("reorderBlockToken(token, before:", PLAN)
        self.assertIn("movePlayReorderToken(token, into: block.id", PLAY)
        self.assertIn("movePlayBlockToken(token, before:", PLAY)
        self.assertIn("commitPlayReorder()", PLAY)
        self.assertIn("draft.blocks.insert(moved, at: target)", PLAY)
        self.assertIn("changed = draft.blocks.map(\\.id) != originalOrder", PLAY)

    def test_drop_position_and_full_card_header_are_used(self):
        for swift in (PLAN, PLAY):
            self.assertIn("location.y > 28", swift)
            self.assertIn("rows.dropFirst(index + 1).first?.id", swift)
            self.assertIn("location.y > 34", swift)
            self.assertIn("dropFirst(position + 1).first?.id", swift)
            self.assertIn("OGReorderDragPreview", swift)
            self.assertIn("OGReorderInsertionGap", swift)
    def test_reorder_dispatches_to_mutating_handlers_instead_of_returning_success(self):
        head = PLAN.split("private func reorderBlockBox(", 1)[1].split(
            "private func reorderBlockHeader(", 1
        )[0]
        self.assertIn("changed = reorderBlockToken(token, before: before)", head)
        self.assertIn("changed = applyReorder(token, into: block.id, before: before)", head)
        play_head = PLAY.split("private func playReorderBlockBox(", 1)[1].split(
            "private func playReorderBlockHeader(", 1
        )[0]
        self.assertIn("moved = movePlayBlockToken(token, before: before)", play_head)
        self.assertIn("return movePlayReorderItem(sourceItem, from: from, into: blockID, before: itemID)", PLAY)
        self.assertIn("moved = true", PLAY)
        self.assertIn("return moved", PLAY)
        self.assertIn("moved = movePlayReorderToken(token, into: block.id, before: before)", play_head)
        # Los movimientos se computan tras eliminar el elemento original.
        self.assertIn("let moved = routine.blocks.remove(at: source)", PLAN)
        self.assertIn("routine.blocks.insert(moved, at: destination)", PLAN)
        self.assertIn("draft.blocks.remove(at: source)", PLAY)
        self.assertIn("draft.blocks.insert(moved, at: target)", PLAY)

    def test_reorder_drop_delegate_accepts_only_internal_move_and_clears_drag(self):
        shared = THEME.split("struct OGReorderDropDelegate: DropDelegate {", 1)[1].split(
            "struct OGReorderInsertionGap:", 1
        )[0]
        self.assertIn("func validateDrop(info: DropInfo) -> Bool", shared)
        self.assertIn("func dropUpdated(info: DropInfo) -> DropProposal?", shared)
        self.assertIn("func performDrop(info: DropInfo) -> Bool", shared)
        self.assertIn("return info.hasItemsConforming(to: [UTType.plainText.identifier])", shared)
        self.assertIn("let changed = performMove(draggedToken, info.location)", shared)
        self.assertIn("if changed { self.draggedToken = nil }", shared)
        for swift in (PLAN, PLAY):
            self.assertIn("UTType.plainText.identifier", swift)
            self.assertIn("@State private var ", swift)


if __name__ == "__main__":
    unittest.main()
