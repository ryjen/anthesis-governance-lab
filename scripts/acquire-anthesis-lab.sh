#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
artifact_env="$repo_root/.anthesis/cli-artifact.env"
install_dir="${1:-$repo_root/.anthesis/bin}"

trusted_source_repository='hackelia-micrantha/anthesis'
trusted_source_ref='refs/heads/integration/governance-lab'
trusted_sigstore_identity='https://github.com/hackelia-micrantha/anthesis/.github/workflows/governance-lab-release.yml@refs/heads/integration/governance-lab'
trusted_sigstore_issuer='https://token.actions.githubusercontent.com'

fail_boundary() {
  echo "$1" >&2
  exit 3
}

[[ -f "$artifact_env" && ! -L "$artifact_env" ]] || \
  fail_boundary "artifact metadata must be a regular, non-symlink file"

declare -A metadata=()
allowed_keys=' ANTHESIS_REVISION ANTHESIS_RELEASE_REPOSITORY ANTHESIS_RELEASE_TAG ANTHESIS_TARBALL_NAME ANTHESIS_TARBALL_SHA256 ANTHESIS_BINARY_SHA256 ANTHESIS_CLI_VERSION ANTHESIS_SIGSTORE_REQUIRED '
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
  ANTHESIS_TARBALL_NAME \
  ANTHESIS_TARBALL_SHA256 \
  ANTHESIS_BINARY_SHA256 \
  ANTHESIS_CLI_VERSION \
  ANTHESIS_SIGSTORE_REQUIRED
do
  [[ -n "${metadata[$key]:-}" ]] || fail_boundary "artifact metadata is missing $key"
done

ANTHESIS_REVISION=${metadata[ANTHESIS_REVISION]}
ANTHESIS_RELEASE_REPOSITORY=${metadata[ANTHESIS_RELEASE_REPOSITORY]}
ANTHESIS_RELEASE_TAG=${metadata[ANTHESIS_RELEASE_TAG]}
ANTHESIS_TARBALL_NAME=${metadata[ANTHESIS_TARBALL_NAME]}
ANTHESIS_TARBALL_SHA256=${metadata[ANTHESIS_TARBALL_SHA256]}
ANTHESIS_BINARY_SHA256=${metadata[ANTHESIS_BINARY_SHA256]}
ANTHESIS_CLI_VERSION=${metadata[ANTHESIS_CLI_VERSION]}
ANTHESIS_SIGSTORE_REQUIRED=${metadata[ANTHESIS_SIGSTORE_REQUIRED]}

[[ "$ANTHESIS_REVISION" =~ ^[0-9a-f]{40}$ ]] || fail_boundary "Anthesis revision must be a full commit SHA"
[[ "$ANTHESIS_RELEASE_REPOSITORY" == 'hackelia-micrantha/anthesis-community' ]] || \
  fail_boundary "release repository is not the trusted public distribution repository"
[[ "$ANTHESIS_RELEASE_TAG" == "anthesis-lab-${ANTHESIS_REVISION}" ]] || \
  fail_boundary "release tag does not match the pinned Anthesis revision"
[[ "$ANTHESIS_TARBALL_NAME" == 'anthesis-lab-linux-x86_64.tar.gz' ]] || \
  fail_boundary "tarball name is not the promoted Linux x86_64 package"
[[ "$ANTHESIS_TARBALL_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail_boundary "tarball SHA-256 is malformed"
[[ "$ANTHESIS_BINARY_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail_boundary "binary SHA-256 is malformed"
[[ "$ANTHESIS_CLI_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail_boundary "CLI version is malformed"
[[ "$ANTHESIS_SIGSTORE_REQUIRED" == 'true' || "$ANTHESIS_SIGSTORE_REQUIRED" == 'false' ]] || \
  fail_boundary "Sigstore requirement must be true or false"

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

work_dir="$(mktemp -d "$repo_root/.anthesis/release.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
base_url="https://github.com/${ANTHESIS_RELEASE_REPOSITORY}/releases/download/${ANTHESIS_RELEASE_TAG}"
tarball="$work_dir/$ANTHESIS_TARBALL_NAME"
checksum="$work_dir/${ANTHESIS_TARBALL_NAME}.sha256"
provenance="$work_dir/anthesis-lab-provenance.json"

printf 'Anthesis revision: %s\n' "$ANTHESIS_REVISION"
printf 'Public release: %s/%s\n' "$ANTHESIS_RELEASE_REPOSITORY" "$ANTHESIS_RELEASE_TAG"

assets=("$ANTHESIS_TARBALL_NAME" "${ANTHESIS_TARBALL_NAME}.sha256" anthesis-lab-provenance.json)
if [[ "$ANTHESIS_SIGSTORE_REQUIRED" == 'true' ]]; then
  command -v cosign >/dev/null || fail_boundary "cosign is required for the pinned signed release"
  assets+=("${ANTHESIS_TARBALL_NAME}.sigstore.json" "${ANTHESIS_TARBALL_NAME}.sha256.sigstore.json" anthesis-lab-provenance.json.sigstore.json)
fi
for asset in "${assets[@]}"; do
  curl --fail --location --proto '=https' --tlsv1.2 "$base_url/$asset" --output "$work_dir/$asset"
done

verify_sigstore_bundle() {
  local blob="$1"
  local bundle="$2"
  cosign verify-blob \
    --bundle "$bundle" \
    --certificate-identity "$trusted_sigstore_identity" \
    --certificate-oidc-issuer "$trusted_sigstore_issuer" \
    --certificate-github-workflow-repository "$trusted_source_repository" \
    --certificate-github-workflow-ref "$trusted_source_ref" \
    --certificate-github-workflow-sha "$ANTHESIS_REVISION" \
    "$blob" >/dev/null || fail_boundary "Sigstore verification failed for $(basename "$blob")"
}

if [[ "$ANTHESIS_SIGSTORE_REQUIRED" == 'true' ]]; then
  verify_sigstore_bundle "$tarball" "${tarball}.sigstore.json"
  verify_sigstore_bundle "$checksum" "${checksum}.sigstore.json"
  verify_sigstore_bundle "$provenance" "${provenance}.sigstore.json"
fi

printf '%s  %s\n' "$ANTHESIS_TARBALL_SHA256" "$tarball" | sha256sum --check --strict
expected_checksum_line="$ANTHESIS_TARBALL_SHA256  $ANTHESIS_TARBALL_NAME"
[[ "$(tr -d '\r\n' < "$checksum")" == "$expected_checksum_line" ]] || \
  fail_boundary "release checksum asset does not match the pinned tarball identity"

jq -e \
  --arg repository "$trusted_source_repository" \
  --arg revision "$ANTHESIS_REVISION" \
  --arg source_ref "$trusted_source_ref" \
  --arg distribution "$ANTHESIS_RELEASE_REPOSITORY" \
  --arg tag "$ANTHESIS_RELEASE_TAG" \
  --arg artifact "$ANTHESIS_TARBALL_NAME" \
  --arg digest "$ANTHESIS_TARBALL_SHA256" \
  --arg workflow_identity "$trusted_sigstore_identity" \
  --argjson sigstore_required "$ANTHESIS_SIGSTORE_REQUIRED" \
  '.schema == "anthesis.release-provenance/v1" and
   .source.repository == $repository and
   .source.commit == $revision and
   (if $sigstore_required then .source.ref == $source_ref else true end) and
   .distribution.repository == $distribution and
   .distribution.tag == $tag and
   .artifact.name == $artifact and
   .artifact.sha256 == $digest and
   .artifact.platform == "linux-x86_64" and
   .artifact.linkage == "musl-static" and
   .build.workflow == "governance-lab-release" and
   (if $sigstore_required then .build.workflow_identity == $workflow_identity else true end)' \
  "$provenance" >/dev/null || fail_boundary "release provenance does not match the pinned source and artifact identity"

test "$(tar -tzf "$tarball" | sort)" = "$(printf '%s\n' anthesis-lab anthesis-lab.sha256 | sort)"
mkdir -p "$work_dir/package"
tar -xzf "$tarball" -C "$work_dir/package" --no-same-owner --no-same-permissions
test "$(find "$work_dir/package" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 2
test -f "$work_dir/package/anthesis-lab"
test -f "$work_dir/package/anthesis-lab.sha256"
(cd "$work_dir/package" && sha256sum --check --strict anthesis-lab.sha256)
printf '%s  %s\n' "$ANTHESIS_BINARY_SHA256" "$work_dir/package/anthesis-lab" | sha256sum --check --strict

version_json="$($work_dir/package/anthesis-lab version --format json)"
jq -e \
  --arg version "$ANTHESIS_CLI_VERSION" \
  '.name == "anthesis-lab" and
   .version == $version and
   (.supported_contracts | sort) == ([
     "anthesis.decision/v1",
     "anthesis.evaluation-request/v1",
     "anthesis.evidence-bundle/v1",
     "anthesis.evidence-bundle-verification/v1",
     "anthesis.lab-profile/v1",
     "anthesis.policy/v1",
     "anthesis.request-binding/v1",
     "anthesis.scenario/v1"
   ] | sort)' <<<"$version_json" >/dev/null || \
  fail_boundary "binary identity or supported contract set does not match the pin"

install -m 0755 "$work_dir/package/anthesis-lab" "$resolved_install_dir/anthesis-lab"
printf 'Verified binary SHA-256: '
sha256sum "$resolved_install_dir/anthesis-lab"
