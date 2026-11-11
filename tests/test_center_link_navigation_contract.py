"""Contratos de navegación de centros y encabezado Buscar sin clipping."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class CenterLinkNavigationContractTests(unittest.TestCase):
    def test_ios_plus_requires_active_client_link(self):
        root = source("Apps/Repera/Sources/RootTabView.swift")
        self.assertIn("!businessData.athleteCenterIds.isEmpty", root)
        self.assertIn("private var hasLinkedCenter: Bool", root)
        # Focus Filter puede silenciar Center; el Tab usa showsCenterTab.
        self.assertIn("if showsCenterTab {", root)
        self.assertIn("SwiftUI.Tab(value: AppTab.plus)", root)
        self.assertIn("if !linked && tab == .plus { tab = .home }", root)
        self.assertIn('FindCenterTrainerView()', source("Apps/Repera/Sources/SettingsView.swift"))

    def test_android_plus_requires_active_client_link(self):
        root = source("android/mobile/src/main/java/dev/repera/mobile/ReperaMobileScreen.kt")
        tabs = source("android/mobile/src/main/java/dev/repera/mobile/ReperaFloatingTabBar.kt")
        self.assertIn("centerSnapshot?.athleteCenterIds?.isNotEmpty() == true", root)
        self.assertIn('if (route != "plus" || hasLinkedCenter)', root)
        self.assertIn('if (!hasLinkedCenter && currentRoute == "plus") navigateTab("inicio")', root)
        self.assertIn("showCenterTab = hasLinkedCenter", root)
        self.assertIn('reperaMainTabs.filterNot { it.route == "plus" }', tabs)
        self.assertIn('tabs = reperaTabsForCenter(showCenterTab)', tabs)

    def test_buscar_title_is_outside_list_without_duplicate_spacing(self):
        view = source("Apps/Repera/Sources/BusinessCenterViews.swift")
        buscar = view.split("struct FindCenterTrainerView: View", 1)[1]
        buscar = buscar.split("struct LinkedCenterDetailView: View", 1)[0]
        self.assertIn('OGScrollablePageTitle("Buscar")', buscar)
        self.assertLess(buscar.index('OGScrollablePageTitle("Buscar")'), buscar.index('List {'))
        self.assertNotIn('OGScrollablePageTitle("Buscar").ogScrollingTitleListRow()', buscar)
        self.assertIn("VStack(spacing: 0)", buscar)
        self.assertIn(".contentMargins(.top, 0, for: .scrollContent)", buscar)
        self.assertIn(".ogScrollingTitleNav(usesGroupedList: false)", buscar)

    def test_buscar_empty_state_uses_outer_white_list_row_only(self):
        view = source("Apps/Repera/Sources/BusinessCenterViews.swift")
        buscar = view.split("struct FindCenterTrainerView: View", 1)[1]
        buscar = buscar.split("struct LinkedCenterDetailView: View", 1)[0]
        self.assertIn("Busca tu entrenador o centro", buscar)
        self.assertNotIn(".background(OG.surface2.opacity(0.4)", buscar)
        self.assertIn(".listRowSeparator(.hidden)", buscar)

    def test_shared_title_pattern_audited_without_unrelated_layout_changes(self):
        # Con ogListChrome el título scrolla en el Form (no VStack fijo) y usa
        # ogScrollingTitleSection para no cortar glifos con la caja redondeada.
        settings = source("Apps/Repera/Sources/SettingsView.swift")
        theme = source("Apps/Repera/Sources/Theme.swift")
        history = source("Apps/Repera/Sources/HistoryView.swift")
        self.assertIn("func ogScrollingTitleSection()", theme)
        self.assertIn("listSectionMargins(.horizontal, 0)", theme)
        for title in ("Ajustes", "Rotación", "Objetivos"):
            self.assertIn(f'OGScrollablePageTitle("{title}")', settings)
            self.assertIn(".ogScrollingTitleListRow()", settings)
        self.assertEqual(settings.count(".ogScrollingTitleSection()"), 3)
        # No fijar el título fuera del Form (no hace scroll).
        settings_body = settings.split("struct SettingsView: View", 1)[1].split(
            "struct SettingsAccountSection", 1
        )[0]
        self.assertNotIn("VStack(spacing: 0)", settings_body)
        self.assertIn('OGScrollablePageTitle("Historial").ogScrollingTitleListRow()', history)


if __name__ == "__main__":
    unittest.main()
