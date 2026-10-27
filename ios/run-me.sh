#!/bin/bash
# ============================================================
#  每日一道符 · 本地构建
#  用法：bash run-me.sh
#  产物：build-report.txt（摘要）、build.log / test.log（原始日志）
# ============================================================

set -o pipefail
cd "$(dirname "$0")" || exit 1

REPORT="build-report.txt"
BUILDLOG="build.log"
TESTLOG="test.log"
: > "$REPORT"

# ---------- 颜色（非终端时自动关闭）----------
if [ -t 1 ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  G=$'\033[32m'; RED=$'\033[31m'; Y=$'\033[33m'; C=$'\033[36m'
else
  B=''; D=''; R=''; G=''; RED=''; Y=''; C=''
fi

hr()   { printf '%s\n' "----------------------------------------------------------------------"; }
line() { printf '%s\n' "$@" | tee -a "$REPORT"; }
step() { echo "" | tee -a "$REPORT"; hr | tee -a "$REPORT"; \
         printf "${B}${C}[%s/%s] %s${R}\n" "$1" "$2" "$3" | tee -a "$REPORT"; hr | tee -a "$REPORT"; }
ok()   { printf "  ${G}✅ %s${R}\n" "$1" | tee -a "$REPORT"; }
bad()  { printf "  ${RED}❌ %s${R}\n" "$1" | tee -a "$REPORT"; }
info() { printf "  ${D}%s${R}\n" "$1" | tee -a "$REPORT"; }
warn() { printf "  ${Y}⚠️  %s${R}\n" "$1" | tee -a "$REPORT"; }

START=$(date +%s)

echo "" | tee -a "$REPORT"
printf "${B}======================================================================${R}\n" | tee -a "$REPORT"
printf "${B}   每日一道符 · V1 构建                            $(date '+%H:%M:%S')${R}\n" | tee -a "$REPORT"
printf "${B}======================================================================${R}\n" | tee -a "$REPORT"

# ---------- 1/5 环境 ----------
step 1 5 "环境检查"
line "  macOS   : $(sw_vers -productVersion) ($(uname -m))"
if ! xcode-select -p >/dev/null 2>&1; then
  bad "没有 Xcode"
  info "请先在 App Store 安装 Xcode（约 10GB），装完重新运行本脚本"
  exit 1
fi
line "  Xcode   : $(xcodebuild -version 2>/dev/null | head -1)"
line "  工程    : $( [ -d "DailyCultivation.xcodeproj" ] && echo "已存在（跳过 xcodegen）" || echo "缺失" )"
line "  磁盘    : $(df -h . | tail -1 | awk '{print $4" 可用"}')"

# ---------- 2/5 工程 ----------
step 2 5 "准备工程"
GEN=0
if [ -d "DailyCultivation.xcodeproj" ]; then
  ok "工程已就绪，不需要 xcodegen"
else
  XG=/tmp/dc-xcodegen
  if [ ! -x "$XG/bin/xcodegen" ]; then
    info "本地没有工程，尝试下载 xcodegen（约 20MB）…"
    curl -L --retry 2 --max-time 300 -o /tmp/dc-xcodegen.zip \
      https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip >> "$REPORT" 2>&1
    rm -rf "$XG"; mkdir -p "$XG"
    unzip -qo /tmp/dc-xcodegen.zip -d "$XG" >> "$REPORT" 2>&1
    xattr -dr com.apple.quarantine "$XG" 2>/dev/null
  fi
  if [ -x "$XG/bin/xcodegen" ]; then
    "$XG/bin/xcodegen" generate >> "$REPORT" 2>&1
    GEN=$?
  fi
  if [ $GEN -ne 0 ] || [ ! -d "DailyCultivation.xcodeproj" ]; then
    bad "工程缺失，且下载 xcodegen 失败（GitHub release 域名通常被墙）"
    info "解决：git pull 一次（仓库里已提交生成好的 .xcodeproj）"
    info "或者用 ToDesk 传 DailyCultivation-ios.zip 过来解压"
    exit 2
  fi
  ok "工程已生成"
fi

# ---------- 3/5 构建 ----------
step 3 5 "编译（模拟器 · 免签名）"
info "预计 30–90 秒，屏幕只显示进度，完整输出在 build.log"
: > "$BUILDLOG"

( xcodebuild \
    -project DailyCultivation.xcodeproj \
    -scheme DailyCultivation \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath ./build \
    CODE_SIGNING_ALLOWED=NO \
    build > "$BUILDLOG" 2>&1 ) &
PID=$!
printf "  "
while kill -0 $PID 2>/dev/null; do printf "${D}.${R}"; sleep 2; done
wait $PID
BUILD=$?
printf "\n"

if [ $BUILD -eq 0 ]; then
  ok "编译成功"
  ERRCOUNT=0
else
  ERRCOUNT=$(grep -c "error:" "$BUILDLOG" 2>/dev/null || echo 0)
  bad "编译失败（$ERRCOUNT 个 error）"
  echo "" | tee -a "$REPORT"
  printf "${RED}   ── 错误列表 ─────────────────────────────────────────${R}\n" | tee -a "$REPORT"
  grep "error:" "$BUILDLOG" | sed 's|.*/ios/|  ios/|' | head -20 | tee -a "$REPORT"
  echo "" | tee -a "$REPORT"
  info "完整日志：$(pwd)/$BUILDLOG"
fi

# ---------- 4/5 单测 ----------
step 4 5 "逻辑单测"
TEST=999
if [ -d TalismanKit ]; then
  : > "$TESTLOG"
  ( cd TalismanKit && swift test > "../$TESTLOG" 2>&1 )
  TEST=$?
  PASSED=$(grep -oE "Executed [0-9]+ tests?, with [0-9]+ failures" "../$TESTLOG" | tail -1)
  if [ $TEST -eq 0 ]; then
    ok "${PASSED:-全部通过}"
  else
    bad "单测失败"
    grep -E "error:|failed" "../$TESTLOG" | head -10 | tee -a "$REPORT"
    info "完整日志：$(pwd)/$TESTLOG"
  fi
else
  skip=1
  warn "找不到 TalismanKit 目录，跳过单测"
fi

# ---------- 5/5 结果 ----------
step 5 5 "结果"
SECS=$(( $(date +%s) - START ))
if [ $BUILD -eq 0 ] && { [ $TEST -eq 0 ] || [ "${skip:-0}" = "1" ]; }; then
  printf "${B}${G}\n"
  printf "        ██████  全部通过  （用时 %ss）\n" "$SECS"
  printf "${R}\n" | tee -a "$REPORT"
  ok "编译通过 · 单测通过"
  echo "" | tee -a "$REPORT"
  printf "${B}   看效果：${R}\n" | tee -a "$REPORT"
  printf "     open DailyCultivation.xcodeproj      ${D}# 选 iPhone 模拟器，⌘R${R}\n" | tee -a "$REPORT"
  echo "" | tee -a "$REPORT"
  exit 0
else
  printf "${B}${RED}\n"
  printf "        ██████  未通过  （用时 %ss）\n" "$SECS"
  printf "${R}\n" | tee -a "$REPORT"
  if [ $BUILD -ne 0 ]; then bad "编译：失败（$ERRCOUNT 个 error）"; else ok "编译：通过"; fi
  if [ $TEST -ne 0 ] && [ "${skip:-0}" != "1" ]; then bad "单测：失败"; else ok "单测：通过"; fi
  echo "" | tee -a "$REPORT"
  info "把上面「错误列表」整段发我，或直接发 build.log"
  exit 1
fi
