#!/usr/bin/env bash
set -euo pipefail

namespace="${DOCKERHUB_NAMESPACE:-${DOCKER_NAMESPACE:-ajeetraina777}}"
tag="${TAG:-latest}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="docker.io/$namespace/sbx-nemoclaw-kits"

# publish SPEC_DIR IMAGE_TAG README_FILE
# Stages a kit (spec.yaml + README + LICENSE), validates it, and pushes one tag.
publish() {
  local spec_dir="$1" image_tag="$2" readme="$3"
  local stage
  stage="$(mktemp -d /tmp/nemoclaw-kits-push.XXXXXX)"
  mkdir -p "$stage/nemoclaw"
  cp "$spec_dir/spec.yaml" "$stage/nemoclaw/spec.yaml"
  cp "$readme" "$stage/nemoclaw/README.md"
  cp "$repo_root/LICENSE" "$stage/nemoclaw/LICENSE"
  sbx kit validate "$stage/nemoclaw"
  sbx kit push "$stage/nemoclaw" "$image:$image_tag"
  rm -rf "$stage"
  echo "Pushed $image:$image_tag"
}

# Default kit (OpenClaw) at the repo root -> :$tag (default :latest).
publish "$repo_root" "$tag" "$repo_root/README.md"

# Per-agent kits under kits/ -> :<agent> (e.g. :openclaw, :hermes).
# Each tag uses its agent doc as the image README. Those docs use repo-relative
# links (e.g. ../kits/hermes); fine on GitHub, cosmetic-only on the Hub page.
for dir in "$repo_root"/kits/*/; do
  agent="$(basename "$dir")"
  readme="$repo_root/agents/$agent.md"
  [ -f "$readme" ] || readme="$repo_root/README.md"
  publish "$dir" "$agent" "$readme"
done
