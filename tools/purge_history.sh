#!/bin/bash
# 从历史里抹掉大文件（原始图 / 旧截图 / 非 iOS 图标 / artifacts）
# 注意：必须用 :(glob) 路径，否则 * 会跨目录匹配，误删嵌套目录里的正常资产
set +e
git rm -r --cached --ignore-unmatch --quiet artifacts >/dev/null 2>&1
git rm --cached --ignore-unmatch --quiet ':(glob)assets/*.png' >/dev/null 2>&1
git rm -r --cached --ignore-unmatch --quiet ':(glob)assets/app-icons/desktop' ':(glob)assets/app-icons/android' ':(glob)assets/app-icons/web' >/dev/null 2>&1
git rm --cached --ignore-unmatch --quiet ':(glob)assets/app-icons/*.png' >/dev/null 2>&1
git rm --cached --ignore-unmatch --quiet ':(glob)prototype/screens/*.png' >/dev/null 2>&1
git rm --cached --ignore-unmatch --quiet ':(glob)assets/art/preview.png' >/dev/null 2>&1
exit 0
