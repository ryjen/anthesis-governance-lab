#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
artifact_env="$repo_root/.anthesis/cli-artifact.env"
install_dir="${1:-$repo_root/.anthesis/bin}"

# shellcheck disable=SC1090
source "$artifact_env"

case "$install_dir" in
  "$repo_root"/*) ;;
  *) echo "install directory must remain inside the repository workspace" >&2; exit 3 ;;
esac

work_dir="$(mktemp -d "$repo_root/.anthesis/artifact.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
archive="$work_dir/artifact.zip"

printf 'Anthesis revision: %s\n' "$ANTHESIS_REVISION"
printf 'Workflow run: %s\n' "$ANTHESIS_WORKFLOW_RUN_ID"
printf 'Artifact ID: %s\n' "$ANTHESIS_ARTIFACT_ID"
printf 'Artifact archive SHA-256: %s\n' "$ANTHESIS_ARTIFACT_ARCHIVE_SHA256"
printf 'Artifact expiry: %s\n' "$ANTHESIS_ARTIFACT_EXPIRES_AT"

headers=(-H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28')
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi
curl --fail --location --proto '=https' --tlsv1.2 "${headers[@]}" \
  "$ANTHESIS_ARTIFACT_URL" --output "$archive"

printf '%s  %s\n' "$ANTHESIS_ARTIFACT_ARCHIVE_SHA256" "$archive" | sha256sum --check --strict
unzip -q "$archive" -d "$work_dir/upload"

tarball="$work_dir/upload/anthesis-lab-linux-x86_64.tar.gz"
test -f "$tarball"
mkdir -p "$work_dir/package"
tar -xzf "$tarball" -C "$work_dir/package" --no-same-owner --no-same-permissions

test "$(find "$work_dir/package" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 2
test -f "$work_dir/package/anthesis-lab"
test -f "$work_dir/package/anthesis-lab.sha256"
(
  cd "$work_dir/package"
  sha256sum --check --strict anthesis-lab.sha256
)

mkdir -p "$install_dir"
install -m 0755 "$work_dir/package/anthesis-lab" "$install_dir/anthesis-lab"
printf 'Verified binary SHA-256: '
sha256sum "$install_dir/anthesis-lab"
