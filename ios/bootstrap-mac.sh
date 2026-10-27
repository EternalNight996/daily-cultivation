#!/bin/bash
# 一键跑通：生成工程 → 模拟器构建 → 逻辑包单测
# 用法：在 Mac 上把本文件与 ios/ 放在一起，然后  bash bootstrap-mac.sh
# 结果写在 build-report.txt，可直接把文件内容贴回来。

set -o pipefail
cd "$(dirname "$0")"
REPORT="build-report.txt"
: > "$REPORT"

log() { echo "$@" | tee -a "$REPORT"; }

{
  echo "=== 环境 ==="
  sw_vers 2>&1
  echo "--- Xcode ---"; xcodebuild -version 2>&1
  echo "--- swift ---"; swift --version 2>&1
  echo "--- xcodegen ---"; command -v xcodegen || echo "MISSING"
  echo "--- 磁盘 ---"; df -h / | tail -1
} >> "$REPORT" 2>&1

if ! command -v xcodegen >/dev/null 2>&1; then
  if ! command -v brew >/dev/null 2>&1; then
    log "FATAL: 没有 xcodegen，也没有 Homebrew"
    log "先装 Homebrew：/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 2
  fi
  log "安装 xcodegen ..."
  brew install xcodegen >> "$REPORT" 2>&1 || { log "FATAL: brew install xcodegen 失败"; exit 2; }
fi

log "=== xcodegen generate ==="
xcodegen generate >> "$REPORT" 2>&1
GEN=$?

BUILD=999
if [ $GEN -eq 0 ]; then
  log "=== xcodebuild (Simulator, 免签名) ==="
  xcodebuild \
    -project DailyCultivation.xcodeproj \
    -scheme DailyCultivation \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath ./build \
    CODE_SIGNING_ALLOWED=NO \
    build >> "$REPORT" 2>&1
  BUILD=$?
fi

TEST=999
if [ -d TalismanKit ]; then
  log "=== swift test (TalismanKit) ==="
  ( cd TalismanKit && swift test >> "../$REPORT" 2>&1 )
  TEST=$?
fi

log ""
log "======================================"
log "GEN_EXIT=$GEN  BUILD_EXIT=$BUILD  TEST_EXIT=$TEST"
log "======================================"
if [ $BUILD -ne 0 ]; then
  log "=== 编译错误（最多 40 行） ==="
  grep -n "error:" "$REPORT" | head -40
fi
if [ $TEST -ne 0 ]; then
  log "=== 测试失败 ==="
  grep -nE "error:|failed" "$REPORT" | tail -20
fi
log "完整日志：$(pwd)/$REPORT"
