#!/bin/bash
# diy-part1.sh —— 在 feeds.conf.default 生成之后、feeds update 之前执行
# 纯净版：只用 ImmortalWrt 25.12 官方源，不追加任何第三方插件源
set -e

OWRT_ROOT="${1:-.}"
cd "$OWRT_ROOT"

if [ -f feeds.conf.default ]; then
    # 锁定官方 25.12 分支
    sed -i 's/^src-git packages .*/src-git packages https:\/\/github.com\/immortalwrt\/packages.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git luci .*/src-git luci https:\/\/github.com\/immortalwrt\/luci.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git routing .*/src-git routing https:\/\/github.com\/immortalwrt\/routing.git;openwrt-25.12/' feeds.conf.default
    sed -i 's/^src-git telephony .*/src-git telephony https:\/\/github.com\/immortalwrt\/telephony.git;openwrt-25.12/' feeds.conf.default
    # 删除任何第三方插件源（含 adguardhome / openclash / kenzok8 / helloworld 等）
    sed -i '/adguardhome/Id; /openclash/Id; /helloworld/Id; /kenzok8/Id; /istoreos/Id; /liuran001/Id; /small/Id; /passwall/Id' feeds.conf.default
fi

echo "===== diy-part1.sh 处理后的 feeds.conf.default ====="
cat feeds.conf.default
