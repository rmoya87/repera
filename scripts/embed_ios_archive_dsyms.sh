#!/usr/bin/env bash
# Copy or generate dSYMs for embedded binaries (frameworks/dylibs) into the archive.
#
# Root cause: Firebase Analytics / GoogleAppMeasurement ship via SPM as binary
# XCFrameworks without public .dSYM bundles. Xcode 16+ Organizer then reports
# "Upload Symbols Failed" for those UUIDs. dsymutil on the Mach-O embedded in
# the .app produces a stub dSYM with the matching UUID, which clears the warning.
#
# Modes:
#   1) Build phase "Run script only when installing" (Product → Archive):
#      uses DWARF_DSYM_FOLDER_PATH and the in-progress build products.
#   2) Scheme Archive post-action / manual:
#        scripts/embed_ios_archive_dsyms.sh --archive /path/App.xcarchive
#      writes into <archive>/dSYMs (safety net if the build phase missed a binary).
#
# Adapted from Cafesito's embed_ios_archive_dsyms.sh (same Firebase SPM issue).
set -euo pipefail

ARCHIVE_PATH_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      ARCHIVE_PATH_ARG="${2:-}"
      shift 2
      ;;
    -h|--help)
      echo "usage: $0 [--archive <path.xcarchive>]"
      exit 0
      ;;
    *)
      echo "usage: $0 [--archive <path.xcarchive>]" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${ARCHIVE_PATH_ARG}" && -n "${ARCHIVE_PATH:-}" && "${ACTION:-}" != "install" ]]; then
  ARCHIVE_PATH_ARG="${ARCHIVE_PATH}"
fi

if [[ -n "${ARCHIVE_PATH_ARG}" ]]; then
  MODE="archive"
  if [[ ! -d "${ARCHIVE_PATH_ARG}" ]]; then
    echo "embed_ios_archive_dsyms: archive not found: ${ARCHIVE_PATH_ARG}" >&2
    exit 1
  fi
  DEST="${ARCHIVE_PATH_ARG}/dSYMs"
  mkdir -p "${DEST}"
else
  MODE="build-phase"
  if [[ "${ACTION:-}" != "install" ]]; then
    exit 0
  fi
  DEST="${DWARF_DSYM_FOLDER_PATH:-}"
  if [[ -z "${DEST}" || ! -d "${DEST}" ]]; then
    echo "embed_ios_archive_dsyms: no DWARF_DSYM_FOLDER_PATH; skipping."
    exit 0
  fi
fi

uuids_of() {
  dwarfdump --uuid "$1" 2>/dev/null | awk '/UUID:/ {print $2}' | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//'
}

uuids_subset_of() {
  local needle="$1"
  local haystack="$2"
  local uuid
  [[ -n "${needle}" && -n "${haystack}" ]] || return 1
  for uuid in ${needle}; do
    [[ " ${haystack} " == *" ${uuid} "* ]] || return 1
  done
  return 0
}

verify_dsym_covers_binary() {
  local dsym_path="$1"
  local binary_path="$2"
  if [[ ! -d "${dsym_path}" || ! -f "${binary_path}" ]]; then
    return 1
  fi
  local binary_uuids dsym_uuids
  binary_uuids="$(uuids_of "${binary_path}")"
  dsym_uuids="$(uuids_of "${dsym_path}")"
  uuids_subset_of "${binary_uuids}" "${dsym_uuids}"
}

binary_in_framework() {
  local framework="$1"
  local name candidate
  name="$(basename "${framework}")"
  name="${name%.framework}"
  for candidate in \
    "${framework}/Versions/A/${name}" \
    "${framework}/Versions/Current/${name}" \
    "${framework}/${name}"; do
    if [[ -f "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

find_existing_dsym_source() {
  local dsym_name="$1"
  local binary_path="$2"
  local framework_root="$3"
  local candidate
  local candidates=(
    "${framework_root}/../dSYMs/${dsym_name}"
    "${framework_root}/../../dSYMs/${dsym_name}"
  )

  if [[ "${MODE}" == "build-phase" ]]; then
    candidates+=(
      "${BUILT_PRODUCTS_DIR:-}/${dsym_name}"
      "${CONFIGURATION_BUILD_DIR:-}/${dsym_name}"
      "${TARGET_BUILD_DIR:-}/${dsym_name}"
    )
  fi

  for candidate in "${candidates[@]}"; do
    [[ -d "${candidate}" ]] || continue
    if verify_dsym_covers_binary "${candidate}" "${binary_path}"; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

merge_dsym_into() {
  local dest="$1"
  local src="$2"
  local dest_dwarf src_dwarf
  local src_file base target idx

  dest_dwarf="${dest}/Contents/Resources/DWARF"
  src_dwarf="${src}/Contents/Resources/DWARF"
  mkdir -p "${dest_dwarf}"

  if [[ -d "${src_dwarf}" ]]; then
    for src_file in "${src_dwarf}"/*; do
      [[ -f "${src_file}" ]] || continue
      base="$(basename "${src_file}")"
      target="${dest_dwarf}/${base}"
      if [[ -f "${target}" ]]; then
        if [[ "$(uuids_of "${src_file}")" == "$(uuids_of "${target}")" ]]; then
          continue
        fi
        idx=2
        while [[ -e "${dest_dwarf}/${base}.${idx}" ]]; do
          idx=$((idx + 1))
        done
        target="${dest_dwarf}/${base}.${idx}"
      fi
      cp "${src_file}" "${target}"
    done
  fi
}

install_dsym_for_binary() {
  local label="$1"
  local binary_path="$2"
  local dsym_name="$3"
  local framework_root="${4:-$(dirname "${binary_path}")}"
  local dest_dsym="${DEST}/${dsym_name}"

  [[ -f "${binary_path}" ]] || return 1

  if [[ -d "${dest_dsym}" ]] && verify_dsym_covers_binary "${dest_dsym}" "${binary_path}"; then
    echo "dSYM already covers ${label}: ${dsym_name}"
    return 0
  fi

  local source_dsym=""
  local tmp_out=""

  if source_dsym="$(find_existing_dsym_source "${dsym_name}" "${binary_path}" "${framework_root}")"; then
    echo "dSYM ${label}: reusing ${source_dsym}"
  else
    # Precompiled Firebase / GoogleAppMeasurement binaries often lack DWARF.
    # dsymutil warns but still emits a dSYM with the UUID App Store Connect expects.
    tmp_out="$(mktemp -d)"
    if ! dsymutil "${binary_path}" -o "${tmp_out}/${dsym_name}" >/dev/null 2>&1 \
      || ! verify_dsym_covers_binary "${tmp_out}/${dsym_name}" "${binary_path}"; then
      rm -rf "${tmp_out}"
      return 1
    fi
    source_dsym="${tmp_out}/${dsym_name}"
    echo "dSYM ${label}: generated with dsymutil"
  fi

  if [[ -d "${dest_dsym}" ]]; then
    echo "dSYM ${label}: merging UUIDs into ${dsym_name}"
    merge_dsym_into "${dest_dsym}" "${source_dsym}"
  else
    cp -R "${source_dsym}" "${dest_dsym}"
  fi

  [[ -n "${tmp_out}" ]] && rm -rf "${tmp_out}"

  if ! verify_dsym_covers_binary "${dest_dsym}" "${binary_path}"; then
    echo "warning: embed_ios_archive_dsyms: ${dsym_name} still missing UUID(s) for ${label}" >&2
    return 1
  fi

  echo "  → ${dest_dsym} [$(uuids_of "${dest_dsym}")]"
  return 0
}

collect_app_bundle_candidates() {
  local bundles=()
  local candidate root

  for candidate in \
    "${TARGET_BUILD_DIR:-}/${WRAPPER_NAME:-}" \
    "${BUILT_PRODUCTS_DIR:-}/${WRAPPER_NAME:-}" \
    "${CONFIGURATION_BUILD_DIR:-}/${WRAPPER_NAME:-}" \
    "${DSTROOT:-}${INSTALL_PATH:-}/${WRAPPER_NAME:-}" \
    "${INSTALL_DIR:-}/${WRAPPER_NAME:-}" \
    "${ARCHIVE_PRODUCTS_PATH:-}/Applications/${WRAPPER_NAME:-}"; do
    [[ "${candidate}" == *.app && -d "${candidate}" ]] && bundles+=("${candidate}")
  done

  for root in \
    "${ARCHIVE_PATH_ARG:+${ARCHIVE_PATH_ARG}/Products}" \
    "${ARCHIVE_PRODUCTS_PATH:-}" \
    "${DSTROOT:-}"; do
    [[ -n "${root}" && -d "${root}" ]] || continue
    while IFS= read -r candidate; do
      [[ -n "${candidate}" ]] && bundles+=("${candidate}")
    done < <(find "${root}" -maxdepth 4 -name "*.app" -type d 2>/dev/null || true)
  done

  [[ "${#bundles[@]}" -eq 0 ]] && return 0
  printf '%s\n' "${bundles[@]}" | awk '!seen[$0]++'
}

collect_embedded_binaries() {
  local bundle="$1"
  find "${bundle}" -mindepth 1 \
    \( -name "*.app" -prune \) -o \
    \( \( -name "*.framework" -o -name "*.dylib" \) -print \) 2>/dev/null | sort
}

embed_dsyms_from_app_bundles() {
  local generated=()
  local failed=()
  local bundle item binary_path dsym_name base

  while IFS= read -r bundle; do
    [[ -z "${bundle}" ]] && continue
    echo "embed_ios_archive_dsyms: scanning ${bundle}"

    while IFS= read -r item; do
      [[ -z "${item}" ]] && continue
      base="$(basename "${item}")"

      if [[ "${item}" == *.framework ]]; then
        [[ -d "${item}" ]] || continue
        binary_path="$(binary_in_framework "${item}" || true)"
        [[ -n "${binary_path}" ]] || continue
        dsym_name="${base}.dSYM"
      else
        [[ -f "${item}" && ! -L "${item}" ]] || continue
        case "${base}" in
          libswift*|libclang_rt*|libSystem*) continue ;;
        esac
        binary_path="${item}"
        dsym_name="${base}.dSYM"
      fi

      if install_dsym_for_binary "${base}" "${binary_path}" "${dsym_name}" "${item}"; then
        generated+=("${dsym_name}")
      else
        failed+=("${dsym_name}")
      fi
    done < <(collect_embedded_binaries "${bundle}")
  done < <(collect_app_bundle_candidates)

  if [[ "${#generated[@]}" -eq 0 && "${#failed[@]}" -eq 0 ]]; then
    echo "warning: embed_ios_archive_dsyms: no .app found (mode ${MODE})."
    echo "warning: After Archive, run: scripts/embed_ios_archive_dsyms.sh --archive <path.xcarchive>"
    return 0
  fi

  if [[ "${#failed[@]}" -gt 0 ]]; then
    echo "warning: embed_ios_archive_dsyms: no dSYM for: ${failed[*]}"
    echo "warning: App Store Connect may still report Upload Symbols Failed for those binaries."
  fi
}

echo "embed_ios_archive_dsyms: mode ${MODE}, dest ${DEST}"
embed_dsyms_from_app_bundles

echo "embed_ios_archive_dsyms: dSYMs in dest:"
ls -1 "${DEST}" 2>/dev/null | grep '\.dSYM$' | sed 's/^/  - /' || true
