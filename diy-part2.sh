#!/bin/bash
# diy-part2.sh —— 在 feeds install 之后、make 之前执行
# 目标：108M 大分区 uboot（hanwckf bl-mt798x）+ AdGuardHome + EQOS，闭源 MTK 无线驱动

set -e

# 允许通过参数指定 openwrt 源码根目录
OWRT_ROOT="${1:-.}"
cd "$OWRT_ROOT"

# ---------- 1. 108M 大分区适配（hanwckf bl-mt798x uboot / NMBM）----------
# 360T7 默认 flash 布局是 32M/44M，108M uboot 下需要把固件 size 拉到 ~110MB
DEVICE_DTS="target/linux/mediatek/dts/mt7981b-qihoo-360t7.dts"
if [ -f "$DEVICE_DTS" ]; then
    # 分区尺寸：firmware 分区扩到 0x6e00000 (110MiB)
    sed -i 's/reg = <0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>;.*$/reg = <0x580000 0x6e00000>;/' "$DEVICE_DTS" || true
fi

# 镜像大小上限：跳过 sysupgrade 大小检查，允许大分区固件
[ -f .config ] && sed -i 's/^# CONFIG_TARGET_PER_DEVICE_ROOTFS is not set/CONFIG_TARGET_PER_DEVICE_ROOTFS=y/' .config || true
echo 'CONFIG_TARGET_KERNEL_PARTSIZE=32' >> .config
echo 'CONFIG_TARGET_ROOTFS_PARTSIZE=256' >> .config
echo 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' >> .config

# ---------- 2. 强制选中闭源 MTK 无线驱动（关键）----------
# 25.12 MT7981 闭源路径：kmod-mtwifi + kmod-mt7981-firmware
cat >> .config <<'EOF'
CONFIG_PACKAGE_kmod-mt7981-firmware=y
CONFIG_PACKAGE_kmod-mtwifi=y
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_PACKAGE_kmod-cfg80211=y
CONFIG_PACKAGE_kmod-mac80211=y
CONFIG_PACKAGE_MAC80211_MESH=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_wpad-mesh-openssl=y
CONFIG_PACKAGE_wpa-supplicant=y
CONFIG_DRIVER_11AX_SUPPORT=y
# 关闭开源 mt76 驱动，避免与闭源冲突
CONFIG_PACKAGE_kmod-mt76=n
CONFIG_PACKAGE_kmod-mt76x2=n
CONFIG_PACKAGE_kmod-mt7915e=n
CONFIG_PACKAGE_kmod-mt7986-firmware=n
EOF

# ---------- 3. AdGuardHome ----------
cat >> .config <<'EOF'
CONFIG_PACKAGE_AdGuardHome=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_luci-i18n-adguardhome-zh-cn=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_dnsmasq=n
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_curl=y
EOF

# ---------- 4. EQOS（智能 QoS / 网速控制）----------
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci-app-eqos=y
CONFIG_PACKAGE_luci-i18n-eqos-zh-cn=y
CONFIG_PACKAGE_iproute2=y
CONFIG_PACKAGE_tc-tiny=n
CONFIG_PACKAGE_kmod-sched=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-sched-connmark=y
CONFIG_PACKAGE_kmod-act-connmark=y
CONFIG_PACKAGE_kmod-ifb=y
EOF

# ---------- 5. 界面基础（仅中文基础 + argon 主题）----------
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-opkg-zh-cn=y
CONFIG_LUCI_LANG_zh_Hans=y
EOF

# ---------- 6. 关掉常见冗余插件，保证固件干净 ----------
for p in ssr-plus passwall openclash v2raya zerotier frpc alist filetransfer \
         smartdns mosdns istorex dockerman docker shadowsocksr-libev \
         xray-core sing-box trojan naiveproxy; do
    sed -i "/^CONFIG_PACKAGE_luci-app-${p}=/d" .config 2>/dev/null || true
    echo "CONFIG_PACKAGE_luci-app-${p}=n" >> .config
done

# ---------- 7. 让新追加的 =y 生效，处理依赖 ----------
make defconfig

echo "===== diy-part2.sh done ====="
grep -E '^(CONFIG_PACKAGE_AdGuardHome|CONFIG_PACKAGE_luci-app-adguardhome|CONFIG_PACKAGE_luci-app-eqos|CONFIG_PACKAGE_kmod-mtwifi|CONFIG_PACKAGE_kmod-mt7981-firmware)=' .config || true
