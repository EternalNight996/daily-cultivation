#!/bin/bash
# 一键跑通：有工程就直接构建，没有才去下载 xcodegen
# 用法：cd 到本文件夹，运行  bash run-me.sh

set -o pipefail
cd "$(dirname "$0")" || exit 1
REPORT="build-report.txt"
: > "$REPORT"
say() { echo "$@" | tee -a "$REPORT"; }

say "===== 1/4 检查 Xcode ====="
if ! xcode-select -p >/dev/null 2>&1; then
  say "❌ 还没装 Xcode。请先在 App Store 搜 Xcode 安装，装完再跑一次。"
  exit 1
fi
xcodebuild -version 2>&1 | tee -a "$REPORT"
say ""

GEN=0
if [ -d "DailyCultivation.xcodeproj" ]; then
  say "===== 2/4 已有工程，跳过 xcodegen ====="
else
  say "===== 2/4 生成工程（需要 xcodegen）====="
  XG=/tmp/dc-xcodegen
  if [ ! -x "$XG/bin/xcodegen" ]; then
    curl -L --retry 2 --max-time 300 -o /tmp/dc-xcodegen.zip \
      https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip 2>>"$REPORT"
    rm -rf "$XG"; mkdir -p "$XG"
    unzip -qo /tmp/dc-xcodegen.zip -d "$XG" 2>>"$REPORT"
    xattr -dr com.apple.quarantine "$XG" 2>/dev/null
  fi
  if [ -x "$XG/bin/xcodegen" ]; then
    "$XG/bin/xcodegen" generate 2>&1 | tee -a "$REPORT"
    GEN=${PIPESTATUS[0]}
  else
    say "❌ 没有工程，也下载不到 xcodegen（大概率是 GitHub 被墙）。"
    say "   办法：让 CI 生成一份工程给你（仓库里应该有 DailyCultivation.xcodeproj.zip）"
    exit 2
  fi
fi

say ""
say "===== 3/4 构建 ====="
xcodebuild \
  -project DailyCultivation.xcodeproj \
  -scheme DailyCultivation \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath ./build \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee -a "$REPORT" | grep -E "error:|BUILD" 
BUILD=${PIPESTATUS[0]}
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
say ""
say "看效果：open DailyCultivation.xcodeproj  →  选 iPhone 模拟器  →  ⌘R"
