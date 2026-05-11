#!/usr/bin/env bash
# Bootstrap the v2 repo by adding every submodule pinned to the SHA it
# was at on logos-modules@bump at the time of bootstrap (2026-05-11).
# Idempotent — re-running on an existing repo skips submodules that
# are already present.
#
# Run this ONCE after pushing the v2 repo to GitHub, from inside a
# clone of the repo. It commits each `git submodule add` so the final
# `git push` ships a complete tree.
#
# Usage:
#   ./scripts/bootstrap-submodules.sh

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# repo|url|sha
modules=(
  "logos-accounts-module|https://github.com/logos-co/logos-accounts-module|a419d24945cbed127667a4a2a92770839294decb"
  "logos-accounts-ui|https://github.com/logos-co/logos-accounts-ui|e6c3faa6e3ea842a26e071ed555732381b9f51f0"
  "logos-blockchain-module|https://github.com/logos-blockchain/logos-blockchain-module|08bd849d5a4d331d7c206cdd291105c95147dc12"
  "logos-blockchain-ui|https://github.com/logos-blockchain/logos-blockchain-ui|9c8e434900b6cf5c9a3dd837276fa3b3bf461f60"
  "logos-chat-module|https://github.com/logos-co/logos-chat-module|7a166d8ba3fcff8418ac1eaff50257d49c847a9e"
  "logos-chat-ui|https://github.com/logos-co/logos-chat-ui|46d1a52ed30d82ad6bb36f5a47045df87a029947"
  "logos-delivery-module|https://github.com/logos-co/logos-delivery-module|0c346c0c2ab2404c11a62cd6c385e806e8465434"
  "logos-execution-zone-module|https://github.com/logos-blockchain/logos-execution-zone-module|62829623257d98b18a8c10a30801a4f10d1681dd"
  "logos-execution-zone-wallet-ui|https://github.com/logos-blockchain/logos-execution-zone-wallet-ui|648bc85722bd7661faa24934e07f9df2f75c3a58"
  "logos-storage-module|https://github.com/logos-co/logos-storage-module|b1d82a32c1ba27e20d07b7ed8555fd45b02adb4e"
  "logos-storage-ui|https://github.com/logos-co/logos-storage-ui|ef1f82c76f052edeb5692271525f8fc33922b494"
  "logos-wallet-module|https://github.com/logos-co/logos-wallet-module|6ef4ca0ed8263745c8356570963b5f7ff293e65d"
  "logos-wallet-ui|https://github.com/logos-co/logos-wallet-ui|12853f5bec6f20fa7616013ecae9cfd237d56cfe"
)

mkdir -p submodules

for m in "${modules[@]}"; do
  IFS='|' read -r repo url sha <<< "$m"
  path="submodules/$repo"

  if [ -d "$path/.git" ] || [ -f "$path/.git" ]; then
    echo "skip: $repo (already present)"
    continue
  fi

  echo "==> $repo @ $sha"
  git submodule add "$url" "$path"
  ( cd "$path" && git fetch --depth 1 origin "$sha" && git checkout "$sha" )
done

echo
echo "All submodules added. Review with:"
echo "  git status"
echo "  git submodule status"
echo
echo "Then commit and push:"
echo "  git add .gitmodules submodules/"
echo "  git commit -m 'Bootstrap submodules from logos-modules@bump'"
echo "  git push"
