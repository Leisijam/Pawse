#!/bin/bash
# Pawse 打包脚本：构建发布版 .app 并打成 zip，供 GitHub Releases 分发
# 用法：在 Pawse 目录下执行  bash package.sh
set -euo pipefail
cd "$(dirname "$0")"

VERSION="1.0.0"
APP_NAME="Pawse"
SRC_ICON="Icon/appPic.png"
BUILD_DIR="build"

echo "==> 1/5 生成圆角图标并打包成 AppIcon.icns（多尺寸：16~1024）"
rm -rf .iconbuild
mkdir -p .iconbuild/AppIcon.iconset

# 先裁成 macOS 圆角图标（Big Sur 标准圆角，四角透明）
ROUNDED=".iconbuild/appIcon_rounded.png"
python3 Icon/make_rounded_icon.py "$SRC_ICON" "$ROUNDED"

# 从圆角图缩放生成各尺寸
for s in 16 32 128 256 512; do
  sips -z "$s" "$s" "$ROUNDED" --out ".iconbuild/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
done
for s in 32 64 256 512 1024; do
  n=$((s / 2))
  sips -z "$s" "$s" "$ROUNDED" --out ".iconbuild/AppIcon.iconset/icon_${n}x${n}@2x.png" >/dev/null
done
iconutil -c icns .iconbuild/AppIcon.iconset -o .iconbuild/AppIcon.icns

echo "==> 2/5 编译发布版"
swift build -c release

echo "==> 3/5 组装 .app"
APP="$BUILD_DIR/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/Pawse "$APP/Contents/MacOS/$APP_NAME"
cp .iconbuild/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
# SPM 的 Bundle.module 在 app 根目录找资源 bundle，必须放这里
cp -R .build/release/Pawse_Pawse.bundle "$APP/Pawse_Pawse.bundle"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Pawse</string>
    <key>CFBundleDisplayName</key>
    <string>Pawse</string>
    <key>CFBundleIdentifier</key>
    <string>com.pawse.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>Pawse</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "==> 4/5 移除隔离属性（避免首次打开被拦截）"
xattr -cr "$APP"

echo "==> 5/5 打包 zip"
cd "$BUILD_DIR"
rm -f "$APP_NAME-v$VERSION-macOS.zip"
ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-v$VERSION-macOS.zip"
cd ..

echo ""
echo "✅ 完成：$APP   （大小 $(du -sh "$APP" | cut -f1)）"
echo "✅ zip：$BUILD_DIR/$APP_NAME-v$VERSION-macOS.zip   （大小 $(du -sh "$BUILD_DIR/$APP_NAME-v$VERSION-macOS.zip" | cut -f1)）"
