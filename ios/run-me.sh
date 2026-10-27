#!/bin/bash
# 一条命令跑完全部：下载 xcodegen（不需要 brew）→ 生成工程 → 构建 → 单测
# 用法：cd 到本文件夹，运行  bash run-me.sh

set -o pipefail
cd "$(dirname "$0")" || exit 1
REPORT="build-report.txt"
: > "$REPORT"
say() { echo "$@" | tee -a "$REPORT"; }

say "===== 1/4 检查 Xcode ====="
if ! xcode-select -p >/dev/null 2>&1; then
  say "❌ 还没装 Xcode。请先在 App Store 搜 Xcode 安装（约 10GB），装完再跑一次。"
  exit 1
fi
xcodebuild -version 2>&1 | tee -a "$REPORT"
say ""

say "===== 2/4 准备 xcodegen（不装 brew）====="
XG=/tmp/dc-xcodegen
if [ ! -x "$XG/bin/xcodegen" ]; then
  say "下载中 ..."
  curl -L --retry 2 --max-time 300 -o /tmp/dc-xcodegen.zip \
    https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip 2>>"$REPORT"
  rm -rf "$XG"; mkdir -p "$XG"
  unzip -qo /tmp/dc-xcodegen.zip -d "$XG" 2>>"$REPORT"
  xattr -dr com.apple.quarantine "$XG" 2>/dev/null
fi
if [ -x "$XG/bin/xcodegen" ]; then
  say "✅ $("$XG/bin/xcodegen" --version 2>&1)"
else
  say "❌ xcodegen 下载失败。把本文件发回给我，我换方案。"
  exit 2
fi
say ""

say "===== 3/4 生成并构建 ====="
"$XG/bin/xcodegen" generate 2>&1 | tee -a "$REPORT"
GEN=${PIPESTATUS[0]}

BUILD=999
if [ "$GEN" -eq 0 ]; then
  xcodebuild \
    -project DailyCultivation.xcodeproj \
    -scheme DailyCultivation \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath ./build \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee -a "$REPORT" | grep -E "error:|warning: .*deprecated|BUILD" 
  BUILD=${PIPESTATUS[0]}
fi
say ""

say "===== 4/4 逻辑单测 ====="
TEST=999
if [ -d TalismanKit ]; then
  ( cd TalismanKit && swift test 2>&1 | tee -a "../$REPORT" | tail -5 )
  TEST=${PIPESTATUS[0]}
fi

say ""
say "========================================"
say "生成=$GEN  编译=$BUILD  单测=$TEST"
say "========================================"
if [ "$BUILD" -ne 0 ]; then
  say ""
  say "编译错误（前 30 条）："
  grep -n "error:" "$REPORT" | head -30
fi
say ""
say "日志：$(pwd)/$REPORT"
