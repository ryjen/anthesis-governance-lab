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
allowed_keys=' ANTHESIS_REVISION ANTHESIS_RELEASE_REPOSITORY ANTHESIS_RELEASE_TAG ANTHESIS_RELEASE_ASSET ANTHESIS_RELEASE_ASSET_SHA256 ANTHESIS_BINARY_SHA256 ANTHESIS_PROVENANCE_SCHEMA ANTHESIS_CLI_VERSION '
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
  ANTHESIS_RELEASE_REPOSITORY \
  ANTHESIS_RELEASE_TAG \
  ANTHESIS_RELEASE_ASSET \
  ANTHESIS_RELEASE_ASSET_SHA256 \
  ANTHESIS_BINARY_SHA256 \
  ANTHESIS_PROVENANCE_SCHEMA \
  ANTHESIS_CLI_VERSION
do
  [[ -n "${metadata[$key]:-}" ]] || fail_boundary "artifact metadata is missing $key"
done

ANTHESIS_REVISION=${metadata[ANTHESIS_REVISION]}
ANTHESIS_RELEASE_REPOSITORY=${metadata[ANTHESIS_RELEASE_REPOSITORY]}
ANTHESIS_RELEASE_TAG=${metadata[ANTHESIS_RELEASE_TAG]}
ANTHESIS_RELEASE_ASSET=${metadata[ANTHESIS_RELEASE_ASSET]}
ANTHESIS_RELEASE_ASSET_SHA256=${metadata[ANTHESIS_RELEASE_ASSET_SHA256]}
ANTHESIS_BINARY_SHA256=${metadata[ANTHESIS_BINARY_SHA256]}
ANTHESIS_PROVENANCE_SCHEMA=${metadata[ANTHESIS_PROVENANCE_SCHEMA]}
ANTHESIS_CLI_VERSION=${metadata[ANTHESIS_CLI_VERSION]}

[[ "$ANTHESIS_REVISION" =~ ^[0-9a-f]{40}$ ]] || fail_boundary "Anthesis revision must be a full commit SHA"
[[ "$ANTHESIS_RELEASE_REPOSITORY" == 'hackelia-micrantha/anthesis-community' ]] || \
  fail_boundary "release repository is not the approved public distribution repository"
[[ "$ANTHESIS_RELEASE_TAG" == "anthesis-lab-$ANTHESIS_REVISION" ]] || \
  fail_boundary "release tag does not bind the pinned Anthesis revision"
[[ "$ANTHESIS_RELEASE_ASSET" == 'anthesis-lab-linux-x86_64.tar.gz' ]] || \
  fail_boundary "release asset is not the promoted Linux x86_64 package"
[[ "$ANTHESIS_RELEASE_ASSET_SHA256" =~ ^[0-9a-f]{64}$ ]] || \
  fail_boundary "release asset SHA-256 is malformed"
[[ "$ANTHESIS_BINARY_SHA256" =~ ^[0-9a-f]{64}$ ]] || \
  fail_boundary "binary SHA-256 is malformed"
[[ "$ANTHESIS_PROVENANCE_SCHEMA" == 'anthesis.release-provenance/v1' ]] || \
  fail_boundary "release provenance schema is unsupported"
[[ "$ANTHESIS_CLI_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
  fail_boundary "CLI version is malformed"

[[ ! -L "$repo_root/.anthesis" ]] || fail_boundary ".anthesis must not be a symlink"
command -v realpath >/dev/null || fail_boundary "realpath is required to validate the install path"
for command in curl sha256sum tar jq; do
  command -v "$command" >/dev/null || fail_boundary "$command is required"
done
resolved_install_dir="$(realpath -m -- "$install_dir")"
case "$resolved_install_dir" in
  "$repo_root"/*) ;;
  *) fail_boundary "install directory must remain inside the repository workspace" ;;
esac
mkdir -p "$resolved_install_dir"
[[ "$(cd "$resolved_install_dir" && pwd -P)" == "$resolved_install_dir" ]] || \
  fail_boundary "install directory must not traverse symlinks outside the repository workspace"

work_dir="$(mktemp -d "$repo_root/.anthesis/release.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
base_url="https://github.com/$ANTHESIS_RELEASE_REPOSITORY/releases/download/$ANTHESIS_RELEASE_TAG"
tarball="$work_dir/$ANTHESIS_RELEASE_ASSET"
checksum="$work_dir/$ANTHESIS_RELEASE_ASSET.sha256"
provenance="$work_dir/anthesis-lab-provenance.json"

printf 'Anthesis revision: %s\n' "$ANTHESIS_REVISION"
printf 'Public release: %s/%s\n' "$ANTHESIS_RELEASE_REPOSITORY" "$ANTHESIS_RELEASE_TAG"
printf 'Release asset SHA-256: %s\n' "$ANTHESIS_RELEASE_ASSET_SHA256"

curl --fail --location --proto '=https' --tlsv1.2 \
  "$base_url/$ANTHESIS_RELEASE_ASSET" --output "$tarball"
curl --fail --location --proto '=https' --tlsv1.2 \
  "$base_url/$ANTHESIS_RELEASE_ASSET.sha256" --output "$checksum"
curl --fail --location --proto '=https' --tlsv1.2 \
  "$base_url/anthesis-lab-provenance.json" --output "$provenance"

expected_checksum_line="$ANTHESIS_RELEASE_ASSET_SHA256  $ANTHESIS_RELEASE_ASSET"
[[ "$(cat "$checksum")" == "$expected_checksum_line" ]] || \
  fail_boundary "published checksum file does not match the immutable pin"
printf '%s  %s\n' "$ANTHESIS_RELEASE_ASSET_SHA256" "$tarball" | sha256sum --check --strict

jq -e \
  --arg schema "$ANTHESIS_PROVENANCE_SCHEMA" \
  --arg revision "$ANTHESIS_REVISION" \
  --arg repository "$ANTHESIS_RELEASE_REPOSITORY" \
  --arg tag "$ANTHESIS_RELEASE_TAG" \
  --arg asset "$ANTHESIS_RELEASE_ASSET" \
  --arg digest "$ANTHESIS_RELEASE_ASSET_SHA256" \
  '.schema == $schema and
   .source.repository == "hackelia-micrantha/anthesis" and
   .source.commit == $revision and
   .source.ref == "refs/heads/integration/governance-lab" and
   .distribution.repository == $repository and
   .distribution.tag == $tag and
   .artifact.name == $asset and
   .artifact.sha256 == $digest and
   .artifact.platform == "linux-x86_64" and
   .artifact.linkage == "musl-static" and
   .build.rust_toolchain == "1.88.0" and
   .build.workflow == "governance-lab-release"' \
  "$provenance" >/dev/null || fail_boundary "release provenance does not match the immutable pin"

test "$(tar -tzf "$tarball" | sort)" = \
  "$(printf '%s\n' anthesis-lab anthesis-lab.sha256 | sort)" || \
  fail_boundary "release archive contains unexpected members"
mkdir -p "$work_dir/package"
tar -xzf "$tarball" -C "$work_dir/package" --no-same-owner --no-same-permissions

test "$(find "$work_dir/package" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 2 || \
  fail_boundary "release package contains unexpected files"
test -f "$work_dir/package/anthesis-lab"
test -f "$work_dir/package/anthesis-lab.sha256"
[[ "$(cat "$work_dir/package/anthesis-lab.sha256")" == "$ANTHESIS_BINARY_SHA256  anthesis-lab" ]] || \
  fail_boundary "packaged binary checksum does not match the immutable pin"
(
  cd "$work_dir/package"
  sha256sum --check --strict anthesis-lab.sha256
)

install -m 0755 "$work_dir/package/anthesis-lab" "$resolved_install_dir/anthesis-lab"
version_report="$work_dir/version.json"
"$resolved_install_dir/anthesis-lab" version --format json >"$version_report"
jq -e \
  --arg version "$ANTHESIS_CLI_VERSION" \
  '.name == "anthesis-lab" and
   .version == $version and
   all(["anthesis.scenario/v1","anthesis.policy/v1","anthesis.lab-profile/v1","anthesis.decision/v1"][] as $contract;
     .supported_contracts | index($contract)
   )' "$version_report" >/dev/null || fail_boundary "installed CLI identity or contracts do not match the immutable pin"

printf 'Verified binary SHA-256: '
sha256sum "$resolved_install_dir/anthesis-lab"
