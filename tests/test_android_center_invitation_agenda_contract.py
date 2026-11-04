"""Android Center: invitación por enlace, agenda unificada y retroceso predictivo."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "android/mobile/src/main"
KOTLIN = MOBILE / "java/dev/repera/mobile"


def source(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class AndroidCenterInvitationAgendaContractTests(unittest.TestCase):
    def test_invitation_link_requires_canonical_uuid(self):
        nav = source(KOTLIN / "LiveNavigationTarget.kt")
        self.assertIn("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", nav)
        self.assertIn("pathSegments.singleOrNull()", nav)
        main = source(KOTLIN / "MainActivity.kt")
        self.assertIn("LiveNavigationTarget.route(uri.host, uri.pathSegments.orEmpty())", main)

    def test_invitation_preview_is_server_authorized_rpc(self):
        store = source(KOTLIN / "BusinessCenterStore.kt")
        self.assertIn("/rest/v1/rpc/get_my_invitation_preview", store)
        self.assertIn('"Bearer " + session.accessToken', store)
        center = source(KOTLIN / "CenterTab.kt")
        for state in ("Unavailable", "Offline", "Failed", "Found"):
            self.assertIn("InvitationPreviewResult." + state, center)
        self.assertIn("R.string.invitation_signed_out", center)
        self.assertIn("R.string.invitation_loading", center)

    def test_manifest_keeps_single_exported_deep_link_entry(self):
        manifest = source(MOBILE / "AndroidManifest.xml")
        self.assertIn('<data android:scheme="repera" android:host="invitation" />', manifest)
        self.assertNotIn('android:pathPattern', manifest)
        self.assertIn('android:enableOnBackInvokedCallback="true"', manifest)

    def test_center_has_unified_agenda_like_ios(self):
        center = source(KOTLIN / "CenterTab.kt")
        self.assertIn("AGENDA(null, R.string.center_section_agenda)", center)
        self.assertIn('snapshot.bookings.filter { it.status == "booked" }', center)
        self.assertIn("snapshot.trainingSessions", center)
        strings = source(MOBILE / "res/values/strings.xml")
        self.assertIn('<string name="center_agenda_empty">No tienes clases, citas ni entrenos prescritos próximos.</string>', strings)
        self.assertIn('<string name="center_agenda_no_time">Sin hora concreta — aparece en tu día de Inicio.</string>', strings)


if __name__ == "__main__":
    unittest.main()
