"""Regresión de CI: el emulador Wear no puede agotarse en disco ni validar 0 tests.

En el run 41829036961 la imagen Wear OS 5.1 pidió 7,37 GB de userdata
con 5,26 GB libres y nunca abrió el AVD; el deploy beta quedó sin validar.
"""
import unittest
from pathlib import Path

WORKFLOW = (Path(__file__).resolve().parents[1] / ".github/workflows/android-native-ci.yml").read_text(encoding="utf-8")
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


if __name__ == "__main__":
    unittest.main()
