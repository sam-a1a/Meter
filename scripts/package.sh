#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

mkdir -p dist
xcodebuild -quiet \
  -project Meter.xcodeproj \
  -scheme Meter \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  'ARCHS=arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="build/DerivedData/Build/Products/Release/Meter.app"
codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict "$app_path"

archive_path="dist/Meter-v1.0.0-macos.zip"
image_path="dist/Meter-v1.0.0-macos.dmg"
staging_path="dist/dmg-staging"
rm -f "$archive_path" "$image_path" dist/SHA256SUMS.txt
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"

rm -rf "$staging_path"
mkdir -p "$staging_path"
ditto "$app_path" "$staging_path/Meter.app"
ln -s /Applications "$staging_path/Applications"
hdiutil create -volname Meter -srcfolder "$staging_path" -format UDZO -ov "$image_path"
rm -rf "$staging_path"
(cd dist && shasum -a 256 "$(basename "$archive_path")" "$(basename "$image_path")" > SHA256SUMS.txt)

echo "Created $archive_path and $image_path"
