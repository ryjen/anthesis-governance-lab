#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
artifact_env="$repo_root/.anthesis/cli-artifact.env"
install_dir="${1:-$repo_root/.anthesis/bin}"

fail_boundary() {
  echo "$1" >&2
  exit 3
}

[[ -f "$artifact_env" && ! -L "$artifact_env" ]] || \
  fail_boundary "artifact metadata must be a regular, non-symlink file"

declare -A metadata=()
allowed_keys=' ANTHESIS_REVISION ANTHESIS_WORKFLOW_RUN_ID ANTHESIS_ARTIFACT_ID ANTHESIS_ARTIFACT_NAME ANTHESIS_ARTIFACT_ARCHIVE_SHA256 ANTHESIS_ARTIFACT_EXPIRES_AT ANTHESIS_ARTIFACT_URL '
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -n "$line" && "$line" != *$'\r'* && "$line" == *=* ]] || \
    fail_boundary "artifact metadata contains a malformed line"
  key=${line%%=*}
  value=${line#*=}
  [[ "$key" =~ ^[A-Z0-9_]+$ && "$allowed_keys" == *" $key "* ]] || \
    fail_boundary "artifact metadata contains an unknown key"
  [[ -z "${metadata[$key]+x}" ]] || fail_boundary "artifact metadata contains a duplicate key"
  [[ -n "$value" && "$value" != *$'\n'* ]] || fail_boundary "artifact metadata contains an empty value"
  metadata[$key]=$value
done < "$artifact_env"

for key in \
  ANTHESIS_REVISION \
  ANTHESIS_WORKFLOW_RUN_ID \
  ANTHESIS_ARTIFACT_ID \
  ANTHESIS_ARTIFACT_NAME \
  ANTHESIS_ARTIFACT_ARCHIVE_SHA256 \
  ANTHESIS_ARTIFACT_EXPIRES_AT \
  ANTHESIS_ARTIFACT_URL
do
  [[ -n "${metadata[$key]:-}" ]] || fail_boundary "artifact metadata is missing $key"
done

ANTHESIS_REVISION=${metadata[ANTHESIS_REVISION]}
ANTHESIS_WORKFLOW_RUN_ID=${metadata[ANTHESIS_WORKFLOW_RUN_ID]}
ANTHESIS_ARTIFACT_ID=${metadata[ANTHESIS_ARTIFACT_ID]}
ANTHESIS_ARTIFACT_NAME=${metadata[ANTHESIS_ARTIFACT_NAME]}
ANTHESIS_ARTIFACT_ARCHIVE_SHA256=${metadata[ANTHESIS_ARTIFACT_ARCHIVE_SHA256]}
ANTHESIS_ARTIFACT_EXPIRES_AT=${metadata[ANTHESIS_ARTIFACT_EXPIRES_AT]}
ANTHESIS_ARTIFACT_URL=${metadata[ANTHESIS_ARTIFACT_URL]}

[[ "$ANTHESIS_REVISION" =~ ^[0-9a-f]{40}$ ]] || fail_boundary "Anthesis revision must be a full commit SHA"
[[ "$ANTHESIS_WORKFLOW_RUN_ID" =~ ^[0-9]+$ ]] || fail_boundary "workflow run ID must be numeric"
[[ "$ANTHESIS_ARTIFACT_ID" =~ ^[0-9]+$ ]] || fail_boundary "artifact ID must be numeric"
[[ "$ANTHESIS_ARTIFACT_NAME" == 'anthesis-lab-linux-x86_64' ]] || \
  fail_boundary "artifact name is not the promoted Linux x86_64 package"
[[ "$ANTHESIS_ARTIFACT_ARCHIVE_SHA256" =~ ^[0-9a-f]{64}$ ]] || \
  fail_boundary "artifact archive SHA-256 is malformed"
[[ "$ANTHESIS_ARTIFACT_EXPIRES_AT" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || \
  fail_boundary "artifact expiry is malformed"
expected_artifact_url="https://api.github.com/repos/hackelia-micrantha/anthesis/actions/artifacts/${ANTHESIS_ARTIFACT_ID}/zip"
[[ "$ANTHESIS_ARTIFACT_URL" == "$expected_artifact_url" ]] || \
  fail_boundary "artifact URL does not match the pinned Anthesis producer endpoint"

[[ ! -L "$repo_root/.anthesis" ]] || fail_boundary ".anthesis must not be a symlink"
command -v realpath >/dev/null || fail_boundary "realpath is required to validate the install path"
resolved_install_dir="$(realpath -m -- "$install_dir")"
case "$resolved_install_dir" in
  "$repo_root"/*) ;;
  *) fail_boundary "install directory must remain inside the repository workspace" ;;
esac
mkdir -p "$resolved_install_dir"
[[ "$(cd "$resolved_install_dir" && pwd -P)" == "$resolved_install_dir" ]] || \
  fail_boundary "install directory must not traverse symlinks outside the repository workspace"

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
  "$expected_artifact_url" --output "$archive"

printf '%s  %s\n' "$ANTHESIS_ARTIFACT_ARCHIVE_SHA256" "$archive" | sha256sum --check --strict
test "$(unzip -Z1 "$archive")" = "anthesis-lab-linux-x86_64.tar.gz"
unzip -q "$archive" -d "$work_dir/upload"

tarball="$work_dir/upload/anthesis-lab-linux-x86_64.tar.gz"
test -f "$tarball"
test "$(tar -tzf "$tarball" | sort)" = \
  "$(printf '%s\n' anthesis-lab anthesis-lab.sha256 | sort)"
mkdir -p "$work_dir/package"
tar -xzf "$tarball" -C "$work_dir/package" --no-same-owner --no-same-permissions

test "$(find "$work_dir/package" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 2
test -f "$work_dir/package/anthesis-lab"
test -f "$work_dir/package/anthesis-lab.sha256"
(
  cd "$work_dir/package"
  sha256sum --check --strict anthesis-lab.sha256
)

install -m 0755 "$work_dir/package/anthesis-lab" "$resolved_install_dir/anthesis-lab"
printf 'Verified binary SHA-256: '
sha256sum "$resolved_install_dir/anthesis-lab"
