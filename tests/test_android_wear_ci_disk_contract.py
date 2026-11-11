"""Regresión de CI: el emulador Wear no puede agotarse en disco ni validar 0 tests.

En el run 41829036961 la imagen Wear OS 5.1 pidió 7,37 GB de userdata
con 5,26 GB libres y nunca abrió el AVD; el deploy beta quedó sin validar.
"""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = (ROOT / ".github/workflows/android-native-ci.yml").read_text(encoding="utf-8")
WEAR = WORKFLOW.split("  wear-instrumented:", 1)[1].split("  deploy-internal-beta:", 1)[0]


class WearCIRunnerDiskBudgetContract(unittest.TestCase):
    def test_wear_frees_unused_runner_tools_before_emulator_creation(self):
        self.assertIn("Free runner disk for Wear emulator images", WEAR)
        self.assertIn("sudo rm -rf /usr/share/dotnet /opt/ghc", WEAR)
        self.assertIn("df -h", WEAR)
        self.assertLess(WEAR.index("Free runner disk for Wear emulator images"),
                        WEAR.index("uses: reactivecircus/android-emulator-runner@v2"))

    def test_wear_avd_partition_is_explicitly_limited(self):
        self.assertIn("disk-size: 4096M", WEAR)
        self.assertIn("emulator-boot-timeout: 1200", WEAR)
        self.assertIn("profile: wearos_small_round", WEAR)
        self.assertIn("target: ${{ matrix.target }}", WEAR)

    def test_wear_does_not_pretend_a_missing_emulator_is_success(self):
        self.assertIn("continue-on-error: false", WEAR)
        self.assertIn("connectedDebugAndroidTest", WEAR)
        self.assertIn("Reporte obligatorio de validación Wear", WEAR)
        self.assertIn("if [ \"$N\" -lt 1 ]; then exit 1; fi", WEAR)
        self.assertIn("if [ \"$OK\" = 0 ]; then exit 1; fi", WEAR)

    def test_push_ci_is_beta_only_not_main(self):
        # main no debe disparar este workflow en push (sí PRs / workflow_dispatch).
        push = WORKFLOW.split("on:", 1)[1].split("concurrency:", 1)[0]
        self.assertIn("- beta", push)
        self.assertNotIn("- main", push)

    def test_beta_deploy_still_gated_on_phone_emulator_tests(self):
        # Teléfono estable bloquea Play; Wear/canary dan señal sin frenar el AAB.
        deploy = WORKFLOW.split("  deploy-internal-beta:", 1)[1]
        self.assertIn("needs: [android-native, android-instrumented]", deploy)
        self.assertIn("github.ref == 'refs/heads/beta'", deploy)
        self.assertNotIn("wear-instrumented", deploy.split("if:", 1)[0])

    def test_artifact_uploads_do_not_fail_green_instrumented_jobs(self):
        # Run 43093615938: connectedDebugAndroidTest verde; upload-artifact
        # falló (servicio) y dejó jobs en rojo / in_progress → sin Play.
        phone = WORKFLOW.split("  android-instrumented:", 1)[1].split(
            "  android-instrumented-android17:", 1
        )[0]
        canary = WORKFLOW.split("  android-instrumented-android17:", 1)[1].split(
            "  wear-instrumented:", 1
        )[0]
        for section_name, section in (
            ("phone", phone),
            ("canary", canary),
            ("wear", WEAR),
        ):
            uploads = [
                block
                for block in section.split("- name: Upload")
                if "upload-artifact@" in block
            ]
            self.assertGreaterEqual(len(uploads), 1, section_name)
            for block in uploads:
                self.assertIn("continue-on-error: true", block, section_name)

    def test_play_upload_pins_httplib2_and_strips_308_redirect(self):
        deploy = WORKFLOW.split("  deploy-internal-beta:", 1)[1]
        self.assertIn("httplib2>=0.22.0,<1", deploy)
        uploader = (ROOT / "android/scripts/upload_play_release.py").read_text(encoding="utf-8")
        self.assertIn("disable_httplib2_308_redirects", uploader)
        self.assertIn("code != 308", uploader)


if __name__ == "__main__":
    unittest.main()
