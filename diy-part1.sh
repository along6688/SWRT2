#!/bin/bash
# diy-part1.sh —— 在 feeds.conf / feeds.conf.default 生成之后、update 之前执行
# 目标：ImmortalWrt 25.12 + MT7981 闭源驱动，仅 AdGuardHome + EQOS

set -e

# 允许通过参数指定 openwrt 源码根目录
OWRT_ROOT="${1:-.}"
cd "$OWRT_ROOT"

# 1) 确保 25.12 源码树（如 actions 用的是 openwrt 主仓，可在此切换到 immortalwrt 25.12）
#    默认由 workflow 的 repository/ref 决定，这里只保证 feeds 指向 25.12 分支
if [ -f feeds.conf.default ]; then
    sed -i 's/^src-git packages .*/src-git packages https:\/\/github.com\/immortalwrt\/packages.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git luci .*/src-git luci https:\/\/github.com\/immortalwrt\/luci.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git routing .*/src-git routing https:\/\/github.com\/immortalwrt\/routing.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git telephony .*/src-git telephony https:\/\/github.com\/immortalwrt\/telephony.git;openwrt-25.12/' feeds.conf.default
fi

# 2) 追加 AdGuardHome 专用源（immortalwrt 官方 packages 里已含 AdGuardHome，这里仅作兜底）
if ! grep -q 'adguardhome' feeds.conf.default 2>/dev/null; then
    echo 'src-git adguardhome https://github.com/rufengsuixing/luci-app-adguardhome.git' >> feeds.conf.default
fi

# 3) 移除不需要的第三方仓库，避免误勾插件
sed -i '/helloworld/d;/kenzok8/d;/istoreos/d;/liuran001/d' feeds.conf.default 2>/dev/null || true

cat feeds.conf.default
