#!/usr/bin/env python3
"""Generate Play version + evidence-based Spanish release notes from a Play snapshot."""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

VERSION_RE = re.compile(r"^(\d{4})\.(0[1-9]|1[0-2])\.(\d+)$")
MADRID = ZoneInfo("Europe/Madrid")
PLAY_MAX_CODE = 2_100_000_000
TOPICS = (
    (re.compile(r"notif|foreground|primer plano|bloqueo|lock.?screen|permission", re.I),
     "Controla tus actividades y temporizadores desde las notificaciones."),
    (re.compile(r"wod|cron[oó]metr|temporiz|timer|clock|fuerza", re.I),
     "Más control sobre tus tiempos y entrenamientos de fuerza."),
    (re.compile(r"gps|ruta|mapa|navega|location|ubicaci[oó]n", re.I),
     "Mejoras para seguir tus rutas y actividades."),
    (re.compile(r"health|salud|cardio|pulso|calor[ií]as|heart.?rate", re.I),
     "Consulta las métricas de tu actividad con más claridad."),
    (re.compile(r"ejercici|exercise|biblioteca|cat[aá]logo|movimiento", re.I),
     "Organiza tus ejercicios con más facilidad."),
    (re.compile(r"progreso|evoluci[oó]n|estad[ií]stica|gr[aá]fic", re.I),
     "Visualiza tus avances con información más clara."),
    (re.compile(r"advertis|adservices|ad.?id|publicidad", re.I),
     "Más privacidad: Repera no solicita permisos de identificación publicitaria."),
)
MAINTENANCE = re.compile(r"fix|correg|bug|crash|rendimiento|performance|optim|regresi[oó]n|stabil|error", re.I)
NON_USER_FACING = re.compile(r"^(?:test|tests|ci|docs|chore|build|style|refactor)\b|^fix\((?:test|ci|docs)\)", re.I)


def testing_tracks(snapshot: dict, configured_closed: str = "") -> str:
    """Select an existing closed track, never open testing or production."""
    track_names = {str(t.get("track", "")).strip() for t in snapshot.get("tracks", [])}
    # Historical Play API installations may expose internal as "qa".
    if not ({"internal", "qa"} & track_names):
        raise ValueError("No se encontró la pista de prueba interna en Google Play")
    closed = {name for name in track_names
              if name and name not in {"internal", "qa", "beta", "production"}
              and ":" not in name}
    requested = configured_closed.strip()
    if requested:
        if requested not in closed:
            raise ValueError("REPERA_PLAY_CLOSED_TRACK no coincide con una pista cerrada existente: "
                             + requested)
        selected = requested
    elif "alpha" in closed:
        selected = "alpha"
    elif len(closed) == 1:
        selected = next(iter(closed))
    else:
        raise ValueError("No se puede determinar una única pista cerrada. "
                         "Configura REPERA_PLAY_CLOSED_TRACK con su ID real de Play Console")
    return f"internal,{selected}"


def all_releases(snapshot: dict) -> list[dict]:
    return [dict(release, track=track.get("track", ""))
            for track in snapshot.get("tracks", [])
            for release in track.get("releases", [])]


def version_for_month(snapshot: dict, now: datetime) -> str:
    prefix = (now.astimezone(MADRID).year, now.astimezone(MADRID).month)
    previous = []
    for release in all_releases(snapshot):
        match = VERSION_RE.fullmatch(str(release.get("name", "")).strip())
        if match and (int(match[1]), int(match[2])) == prefix:
            previous.append(int(match[3]))
    return f"{prefix[0]}.{prefix[1]:02d}.{max(previous, default=-1) + 1}"


def version_code(snapshot: dict, now: datetime) -> int:
    codes = [int(c) for release in all_releases(snapshot)
             for c in release.get("versionCodes", [])]
    codes += [int(b.get("versionCode", 0)) for b in snapshot.get("bundles", [])]
    # Preserve the existing monotonic floor for older Repera releases.
    epoch_minutes = int(now.timestamp() // 60) - 29_453_760
    result = max(max(codes, default=0) + 1, epoch_minutes, 1)
    if result > PLAY_MAX_CODE:
        raise ValueError("versionCode supera el máximo permitido por Google Play")
    return result


def production_release(snapshot: dict) -> dict | None:
    released = [r for r in all_releases(snapshot)
                if r["track"] == "production"
                and r.get("status") in ("completed", "inProgress")
                and r.get("versionCodes")]
    return max(released, key=lambda r: max(map(int, r["versionCodes"])), default=None)


def baseline_date(snapshot: dict, now: datetime, settings: dict) -> tuple[str, str]:
    production = production_release(snapshot)
    if production is not None:
        # Publisher API does not return release upload timestamps. A verified
        # production date must be supplied by Play release tracking, not guessed
        # from the commit's author date or the current internal track.
        expected = settings.get("REPERA_LAST_PRODUCTION_VERSION", "")
        date_text = settings.get("REPERA_LAST_PRODUCTION_DATE", "")
        if not expected or expected != production.get("name") or not date_text:
            raise ValueError(
                "Existe producción en Play: configura REPERA_LAST_PRODUCTION_VERSION "
                "y REPERA_LAST_PRODUCTION_DATE (ISO 8601 verificada); "
                "deben corresponder al release de producción actual."
            )
        try:
            parsed = datetime.fromisoformat(date_text.replace("Z", "+00:00"))
        except ValueError as error:
            raise ValueError("REPERA_LAST_PRODUCTION_DATE debe ser ISO 8601") from error
        if parsed.tzinfo is None or parsed > now:
            raise ValueError("La fecha de producción debe incluir zona horaria y no ser futura")
        return parsed.astimezone(timezone.utc).isoformat(), "production"
    month_start = now.astimezone(MADRID).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return month_start.astimezone(timezone.utc).isoformat(), "first-release-month"


def git_subjects(since: str, *, root: Path = Path(".")) -> list[str]:
    """Only commits touching shipping Android sources count as release evidence."""
    command = [
        "git", "log", "--no-merges", "--format=%s", f"--since={since}",
        "HEAD", "--", "android/mobile/src/main", "android/domain/src/main",
        "android/wear/src/main",
    ]
    return [subject.strip() for subject in subprocess.check_output(
        command, cwd=root, text=True).splitlines() if subject.strip()]


def user_facing_subjects(subjects: list[str]) -> list[str]:
    return [s for s in subjects if not NON_USER_FACING.search(s)]


def release_notes(subjects: list[str]) -> str:
    if not subjects:
        raise ValueError("No hay cambios Android verificables desde la última referencia")
    relevant = user_facing_subjects(subjects)
    if not relevant:
        return "Mejoras internas para ofrecerte una experiencia más estable."
    lines = []
    combined = "\n".join(relevant)
    for pattern, benefit in TOPICS:
        if pattern.search(combined):
            lines.append("• " + benefit)
        if len(lines) == 3:
            break
    if MAINTENANCE.search(combined):
        lines.append("• Correcciones para entrenar con mayor estabilidad.")
    if not lines:
        lines.append("• Ajustes para mejorar tu experiencia de entrenamiento.")
    result = "¡Repera sigue mejorando!\n" + "\n".join(lines[:4])
    if len(result) > 500:
        raise ValueError("Las novedades superan los 500 caracteres permitidos")
    return result


def prepare(snapshot: dict, now: datetime, settings: dict, subjects: list[str]) -> dict:
    since, baseline = baseline_date(snapshot, now, settings)
    return {
        "versionName": version_for_month(snapshot, now),
        "versionCode": version_code(snapshot, now),
        "baseline": baseline,
        "since": since,
        "notes": release_notes(subjects),
        "evidence": user_facing_subjects(subjects)[:40],
        "commit": settings.get("GITHUB_SHA", ""),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--snapshot", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    snapshot = json.loads(Path(args.snapshot).read_text(encoding="utf-8"))
    now = datetime.now(timezone.utc)
    since, _ = baseline_date(snapshot, now, os.environ)
    data = prepare(snapshot, now, os.environ, git_subjects(since))
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    news = output / "whatsnew"
    news.mkdir(exist_ok=True)
    (news / "whatsnew-es-ES").write_text(data["notes"] + "\n", encoding="utf-8")
    (output / "release-metadata.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    env_path = os.environ.get("GITHUB_ENV")
    if env_path:
        with open(env_path, "a", encoding="utf-8") as stream:
            stream.write(f"REPERA_VERSION_NAME={data['versionName']}\n")
            stream.write(f"REPERA_VERSION_CODE={data['versionCode']}\n")
    print(json.dumps(data, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
