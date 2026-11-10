#!/usr/bin/env python3
"""Publish a signed Repera AAB to verified Google Play testing tracks.

The internal and closed tracks are selected/verified earlier by
play_release_metadata.testing_tracks. This uploader rejects production/open
tracks, verifies the returned bundle version, and commits only after validation.
No credentials or Google API responses containing credentials are logged.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import zipfile
from pathlib import Path

BUNDLE_MAPPING_PATH = "BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map"
PLAY_SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def parse_tracks(value: str) -> list[str]:
    tracks = [x.strip() for x in value.split(",")]
    if len(tracks) != 2 or tracks[0] != "internal":
        raise ValueError("Solo se permite publicar simultáneamente en internal y una pista cerrada")
    closed = tracks[1]
    if not re.fullmatch(r"[A-Za-z0-9_-]+", closed) or closed in {
        "internal", "qa", "beta", "production"
    }:
        raise ValueError("Pista cerrada inválida o no permitida")
    return tracks


def make_release(track: str, name: str, version_code: int, notes: str) -> dict:
    if not track or not name or version_code < 1:
        raise ValueError("Datos de versión incompletos")
    if not notes.strip() or len(notes.strip()) > 500:
        raise ValueError("Las novedades de Google Play deben tener entre 1 y 500 caracteres")
    return {"track": track, "releases": [{
        "name": name, "status": "completed",
        "versionCodes": [str(version_code)],
        "releaseNotes": [{"language": "es-ES", "text": notes.strip()}],
    }]}


def has_embedded_mapping(bundle: Path) -> bool:
    with zipfile.ZipFile(bundle, "r") as archive:
        return BUNDLE_MAPPING_PATH in archive.namelist()


def disable_httplib2_308_redirects() -> None:
    """Play resumable AAB uploads answer with HTTP 308 and no Location header.

    That status means "resume incomplete", not a browser redirect. Stock
    httplib2 (including the Ubuntu system package on GitHub runners) treats 308
    as a redirect and raises RedirectMissingLocation before googleapiclient can
    continue the MediaFileUpload. Strip 308 from redirect handling only.
    """
    import httplib2

    codes = getattr(httplib2, "REDIRECT_CODES", None)
    if not codes:
        return
    httplib2.REDIRECT_CODES = frozenset(code for code in codes if code != 308)


def build_publisher(credentials):
    """Android Publisher client that survives resumable-upload 308 responses."""
    from google_auth_httplib2 import AuthorizedHttp
    from googleapiclient.discovery import build
    import httplib2

    disable_httplib2_308_redirects()
    http = AuthorizedHttp(credentials, http=httplib2.Http(timeout=180))
    return build("androidpublisher", "v3", cache_discovery=False, http=http)


def publish(api, *, package: str, aab: Path, mapping: Path, notes: str,
            tracks: list[str], name: str, version_code: int) -> None:
    from googleapiclient.http import MediaFileUpload

    edit_id = api.edits().insert(packageName=package, body={}).execute(num_retries=3)["id"]
    committed = False
    try:
        uploaded = api.edits().bundles().upload(
            packageName=package, editId=edit_id,
            media_body=MediaFileUpload(str(aab), mimetype="application/octet-stream",
                                       chunksize=8 * 1024 * 1024, resumable=True),
        ).execute(num_retries=3)
        actual = int(uploaded["versionCode"])
        if actual != version_code:
            raise ValueError(f"El AAB subido tiene versionCode {actual}; se esperaba {version_code}")

        if not has_embedded_mapping(aab):
            # Only APK-like bundles without embedded R8 mapping need an
            # additional deobfuscation upload. AGP 4.1+ normally embeds it.
            if not mapping.is_file() or mapping.stat().st_size == 0:
                raise FileNotFoundError("No hay mapping R8 embebido ni mapping.txt para Play")
            api.edits().deobfuscationfiles().upload(
                packageName=package, editId=edit_id, apkVersionCode=actual,
                deobfuscationFileType="proguard",
                media_body=MediaFileUpload(str(mapping), mimetype="application/octet-stream"),
            ).execute(num_retries=3)

        for track in tracks:
            api.edits().tracks().update(
                packageName=package, editId=edit_id, track=track,
                body=make_release(track, name, version_code, notes),
            ).execute(num_retries=3)
        api.edits().validate(packageName=package, editId=edit_id).execute(num_retries=3)
        api.edits().commit(packageName=package, editId=edit_id).execute(num_retries=3)
        committed = True
        print(f"Google Play: publicación confirmada {name} ({actual}) en {', '.join(tracks)}")
    finally:
        if not committed:
            try:
                api.edits().delete(packageName=package, editId=edit_id).execute(num_retries=1)
            except Exception as exc:
                # Never obscure the original failure with an edit cleanup error.
                print(f"Advertencia: no se pudo cerrar el borrador de Play ({type(exc).__name__})")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--package", required=True)
    p.add_argument("--aab", type=Path, required=True)
    p.add_argument("--mapping", type=Path, required=True)
    p.add_argument("--notes", type=Path, required=True)
    p.add_argument("--tracks", required=True)
    p.add_argument("--release-name", required=True)
    p.add_argument("--version-code", required=True, type=int)
    args = p.parse_args()
    tracks = parse_tracks(args.tracks)
    if not args.aab.is_file() or args.aab.stat().st_size == 0:
        raise FileNotFoundError("No existe un AAB release firmado")
    notes = args.notes.read_text(encoding="utf-8").strip()
    for track in tracks:
        make_release(track, args.release_name, args.version_code, notes)

    # Credentials stay in memory and are provided only by GitHub secret.
    from google.oauth2.service_account import Credentials
    service_account = json.loads(os.environ["REPERA_PLAY_SERVICE_ACCOUNT_JSON"])
    credentials = Credentials.from_service_account_info(
        service_account, scopes=[PLAY_SCOPE])
    api = build_publisher(credentials)
    publish(api, package=args.package, aab=args.aab, mapping=args.mapping,
            notes=notes, tracks=tracks, name=args.release_name,
            version_code=args.version_code)


if __name__ == "__main__":
    main()
