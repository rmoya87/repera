"""Contracts for WeatherKit attribution and provider separation (no Apple SDK needed)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class WeatherSourcesContractTests(unittest.TestCase):
    def test_both_apple_targets_embed_weatherkit_and_attribution(self):
        project = source("project.yml")
        watch = project.split("  ReperaWatch:\n", 1)[1].split("  ReperaWatchWidget:\n", 1)[0]
        iphone = project.split("  Repera:\n", 1)[1].split("  ReperaRestWidget:\n", 1)[0]
        for target in (iphone, watch):
            self.assertIn("com.apple.developer.weatherkit: true", target)
            self.assertIn("WeatherKit.framework", target)
            self.assertIn("Apps/Shared/AppleWeatherConditionsClient.swift", target)
            self.assertIn("Apps/Shared/AppleWeatherAttributionView.swift", target)
        self.assertIn("com.apple.developer.weatherkit", source(
            "Apps/ReperaWatch/Resources/ReperaWatch.entitlements"
        ))

    def test_live_apple_weather_is_primary(self):
        for path in (
            "Apps/Repera/Sources/LiveActivityView.swift",
            "Apps/ReperaWatch/Sources/WatchLiveSessionView.swift",
            "Apps/ReperaWatch/Sources/WatchSessionHub.swift",
        ):
            self.assertIn("AppleWeatherConditionsClient.fetch(", source(path))
            self.assertNotIn("OpenMeteoConditionsClient.fetch(", source(path))

        shared = source("Apps/Shared/AppleWeatherConditionsClient.swift")
        self.assertIn("WeatherService.shared.weather(", shared)
        self.assertIn(".snowfallAmount", shared)
        self.assertIn(".appleWeather", shared)

    def test_open_meteo_only_supplies_specialized_data_on_apple(self):
        domain = source("Packages/ReperaDomain/Sources/ReperaDomain/ActivityConditions.swift")
        self.assertIn('"snow_depth"', domain)
        self.assertIn('"sea_level_height_msl,wave_height"', domain)
        self.assertNotIn('"temperature_2m"', domain)
        self.assertNotIn('"wind_speed_10m"', domain)
        self.assertNotIn('hourly["snowfall"]', domain)
        for path in (
            "Apps/Repera/Sources/OpenMeteoConditionsClient.swift",
            "Apps/ReperaWatch/Sources/OpenMeteoConditionsClient.swift",
        ):
            client = source(path)
            self.assertIn("snowDepthURL", client)
            self.assertIn("marineURL", client)
            self.assertNotIn("forecastURL", client)
        self.assertTrue((ROOT / "android/mobile/src/main/java/dev/repera/mobile/OpenMeteoWeatherClient.kt").exists())

    def test_visible_legal_attribution_on_both_platforms(self):
        shared = source("Apps/Shared/AppleWeatherAttributionView.swift")
        self.assertIn("WeatherService.shared.attribution", shared)
        self.assertIn("combinedMarkLightURL", shared)
        self.assertIn("combinedMarkDarkURL", shared)
        self.assertIn("legalPageURL", shared)
        self.assertIn("Fuentes legales", shared)
        for path in (
            "Apps/Repera/Sources/CardioRouteComponents.swift",
            "Apps/ReperaWatch/Sources/WatchActivityConditionsBlock.swift",
        ):
            ui = source(path)
            self.assertIn("AppleWeatherAttributionView", ui)
            self.assertIn("Open-Meteo", ui)
            self.assertIn("creativecommons.org/licenses/by/4.0/", ui)


if __name__ == "__main__":
    unittest.main()
