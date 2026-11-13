"""Splash: cara estática (sin idle animado ni párpados overlay)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
IOS_APP = ROOT / "Apps/Repera/Sources/ReperaApp.swift"
IOS_FACE = ROOT / "Apps/Repera/Sources/LaunchFaceSplashView.swift"
ANDROID = ROOT / "android/mobile/src/main/java/dev/repera/mobile/ReperaMascot.kt"
PROJECT = ROOT / "project.yml"


class SplashFaceMotionContractTests(unittest.TestCase):
    def test_no_idle_animation_assets(self):
        self.assertFalse((ROOT / "Apps/Repera/Resources/mascot-face-idle.webp").exists())
        self.assertFalse((ROOT / "Apps/Repera/Resources/mascot-face-idle.gif").exists())
        self.assertFalse(
            (ROOT / "android/mobile/src/main/assets/mascot/mascot-face-idle.webp").exists()
        )
        self.assertFalse(
            (ROOT / "android/mobile/src/main/assets/mascot/mascot-face-idle.gif").exists()
        )
        self.assertFalse((ROOT / "Apps/Repera/Resources/.preview-mascot-face-idle.gif").exists())
        project = PROJECT.read_text(encoding="utf-8")
        self.assertNotIn("mascot-face-idle", project)

    def test_ios_static_face_only(self):
        face = IOS_FACE.read_text(encoding="utf-8")
        app = IOS_APP.read_text(encoding="utf-8")
        self.assertIn('Image("MascotFace")', face)
        self.assertIn("48 / 255", face)
        self.assertNotIn("ImageIO", face)
        self.assertNotIn("animationImages", face)
        self.assertNotIn("mascot-face-idle", face)
        self.assertNotIn("leftLid", face)
        self.assertNotIn("performBlink", face)
        self.assertIn("LaunchFaceSplashView()", app)

    def test_android_static_face_only(self):
        text = ANDROID.read_text(encoding="utf-8")
        self.assertIn("mascot/mascot-face.png", text)
        self.assertIn("0xFF30D158", text)
        self.assertIn("fun LaunchSplashScreen()", text)
        self.assertNotIn("mascot-face-idle", text)
        self.assertNotIn("AnimatedImageDrawable", text)
        self.assertNotIn("drawLid", text)


if __name__ == "__main__":
    unittest.main()
