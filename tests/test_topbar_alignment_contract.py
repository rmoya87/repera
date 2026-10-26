"""Regresión: controles de cabeceras iOS 27 alineados con la safe area.

Comprueba geometría común de nuestras barras SwiftUI. Las toolbars nativas
conservan deliberadamente los insets de iOS y no reciben glass adicional.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "Apps" / "Repera" / "Sources"


def read(name):
    return (SRC / name).read_text(encoding="utf-8")


class TopBarAlignmentContractTests(unittest.TestCase):
    def test_shared_measurements_are_explicit_and_consistent(self):
        theme = read("Theme.swift")
        self.assertIn("static let topBarHorizontalInset: CGFloat = 16", theme)
        self.assertIn("static let topBarTopInset: CGFloat = 4", theme)
        self.assertIn("static let topBarBottomInset: CGFloat = 8", theme)
        self.assertIn("static let toolbarGlassSize: CGFloat = 44", theme)

    def test_fixed_root_header_top_aligns_action_even_with_subtitle(self):
        source = read("Theme.swift").split("struct OGFixedTopBar<Trailing: View>: View {", 1)[1]
        header = source.split("/// Cabecera de página estilo Inicio / Progreso", 1)[0]
        self.assertIn("HStack(alignment: .top, spacing: 12)", header)
        self.assertNotIn("subtitle == nil ? .center : .center", header)
        self.assertIn(".frame(minHeight: OG.toolbarGlassSize, alignment: .top)", header)
        for p in (".padding(.horizontal, OG.topBarHorizontalInset)",
                  ".padding(.top, OG.topBarTopInset)",
                  ".padding(.bottom, OG.topBarBottomInset)"):
            self.assertIn(p, header)
        self.assertIn('ogFixedTopBar("repera"', read("HomeView.swift"))
        self.assertIn('OGFixedTopBar(title: "Progreso"', read("StatsView.swift"))

    def test_custom_page_and_back_headers_share_same_vertical_insets(self):
        source = read("Theme.swift")
        page = source.split("struct OGPageHeader<", 1)[1].split(
            "extension OGPageHeader where Leading == EmptyView, Trailing == EmptyView", 1
        )[0]
        back = source.split("struct OGBackPageHeader<", 1)[1].split(
            "extension OGBackPageHeader where Trailing == EmptyView", 1
        )[0]
        for header in (page, back):
            self.assertIn(".padding(.top, OG.topBarTopInset)", header)
            self.assertIn(".padding(.bottom, OG.topBarBottomInset)", header)

    def test_compact_diary_and_split_exercises_use_shared_spacing(self):
        diary = read("PlanView.swift")
        section = diary.split("private var diaryTopBar:", 1)[1].split(
            "private struct DiaryDateBox:", 1
        )[0]
        self.assertIn("OGFixedTopBar(title:", section)
        for p in (".padding(.horizontal, OG.topBarHorizontalInset)",
                  ".padding(.top, OG.topBarTopInset)",
                  ".padding(.bottom, OG.topBarBottomInset)"):
            self.assertIn(p, section)
        library = read("LibraryView.swift")
        root = library.split('Text("Ejercicios")', 1)[1].split("HStack(spacing: 9)", 1)[0]
        for p in (".padding(.horizontal, OG.topBarHorizontalInset)",
                  ".padding(.top, OG.topBarTopInset)",
                  ".padding(.bottom, OG.topBarBottomInset)"):
            self.assertIn(p, root)

    def test_sheet_headers_do_not_add_hidden_extra_top_padding(self):
        sections = (
            (read("DayPlusSheet.swift"), 'OGPageHeader(title: "Añadir entreno"'),
            (read("DayOverrideSheet.swift"), "OGPageHeader(title: dayLabel)"),
            (read("PlanView.swift"), 'OGPageHeader(title: "Añadir rutina")'),
            (read("LibraryView.swift"), 'OGPageHeader(title: "Ordenar y filtrar")'),
        )
        for source, anchor in sections:
            snippet = source.split(anchor, 1)[1].split("}", 2)[-1][:120]
            self.assertNotIn(".padding(.top, 4)", snippet, anchor)

    def test_native_toolbar_is_not_forced_into_manual_custom_geometry(self):
        theme = read("Theme.swift")
        button = theme.split("struct OGToolbarGlassButton: View {", 1)[1].split(
            "private struct OGToolbarGlassModifier:", 1
        )[0]
        self.assertIn("appliesGlass: Bool = false", button)
        self.assertIn("appliesGlass ? OG.toolbarGlassSize : 36", button)
        self.assertIn("appliesGlass ? OG.toolbarGlassIcon : 17", button)
        self.assertIn(".ogTransparentNav()", theme)


if __name__ == "__main__":
    unittest.main()
