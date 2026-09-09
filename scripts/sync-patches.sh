#!/usr/bin/env bash
# Regenerate patches/ from a mautic checkout (a *-custom patch branch) and
# stamp patches/.base-version, which the Dockerfile and workflow verify
# against MAUTIC_VERSION. Prevents bumping the Mautic version without
# regenerating the whole-file overlays (which would silently revert upstream
# changes in the overlaid files).
#
# Usage: scripts/sync-patches.sh <path-to-mautic-checkout> <mautic-version>
#   e.g. scripts/sync-patches.sh ~/Projects/mautic 7.2.0
set -euo pipefail

SRC=${1:?path to mautic checkout (on the *-custom patch branch)}
VER=${2:?mautic version the patch branch is rebased onto, e.g. 7.2.0}
cd "$(dirname "$0")/.."

# Refuse to sync from a branch that is not actually based on the given tag.
if ! git -C "$SRC" merge-base --is-ancestor "$VER" HEAD 2>/dev/null; then
  echo "ERROR: $SRC HEAD does not contain tag $VER — rebase the patch branch first." >&2
  exit 1
fi

# Keep this map in sync with the COPY block in the Dockerfile.
declare -A MAP=(
  [PRedisConnectionHelper.php]=app/bundles/CoreBundle/Helper/PRedisConnectionHelper.php
  [BuilderSubscriber.php]=app/bundles/EmailBundle/EventListener/BuilderSubscriber.php
  [ContactFinder.php]=app/bundles/EmailBundle/MonitoredEmail/Search/ContactFinder.php
  [FormApiController.php]=app/bundles/FormBundle/Controller/Api/FormApiController.php
  [PublicController.php]=app/bundles/PageBundle/Controller/PublicController.php
  [CampaignApiController.php]=app/bundles/CampaignBundle/Controller/Api/CampaignApiController.php
  [CampaignConfig.php]=app/bundles/CampaignBundle/Config/config.php
)

for dst in "${!MAP[@]}"; do
  cp "$SRC/${MAP[$dst]}" "patches/$dst"
  echo "synced patches/$dst"
done

SHA=$(git -C "$SRC" rev-parse --short=10 HEAD)
echo "$VER mautic@$SHA synced=$(date -u +%F)" > patches/.base-version
echo "wrote patches/.base-version: $(cat patches/.base-version)"
