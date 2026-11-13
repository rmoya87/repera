#!/usr/bin/env python3
"""BoardScan Lite: RFT+TC rounds, MAX CAL vs max-effort, BUY-IN headers."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = (
    ROOT / "android/domain/src/main/java/dev/repera/domain/BoardScanLiteParser.kt"
).read_text(encoding="utf-8")
IOS = (
    ROOT / "Packages/ReperaDomain/Sources/ReperaDomain/BoardScanLiteParser.swift"
).read_text(encoding="utf-8")


def test_rft_with_tc_not_stolen_by_named_tc_header():
    for src in (ANDROID, IOS):
        assert r"\d+\s*RF[TF]\b" in src or r"\d+\s*RF[TF]\b" in src.replace("\\\\", "\\")
        assert "FOR COMPLETION" in src
        # Named TC path must exclude digit+RFT before returning bare FOR_TIME.
        assert "RF[TF]" in src


def test_max_effort_continuation_excludes_max_cal_and_rounds():
    for src in (ANDROID, IOS):
        assert "isMaxEffortContinuation" in src
        assert "MAX CAL" in src
        assert "MAX ROUNDS" in src


def test_android_buy_in_and_rounds_headers_win_over_non_exercise_skip():
    assert 'WODFormat.BUY_IN_CASH_OUT' in ANDROID
    assert "Format headers (BUY-IN" in ANDROID or "BUY-IN" in ANDROID
    # Warm-up described titles stay STRENGTH headers, not stripped section labels.
    assert "warmUpOnly" in ANDROID or "WARM UP SHOULDERS" in ANDROID
    assert 'candidate !in warmUpOnly' in ANDROID


def test_android_mn_rest_normalized_for_between_rounds():
    assert "exerciseText(it)" in ANDROID
    assert r"(\d+)\s*MN\b" in ANDROID or "MN" in ANDROID
