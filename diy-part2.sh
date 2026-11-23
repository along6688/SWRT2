#!/bin/bash
# diy-part2.sh —— 在 feeds install 之后、make 之前执行
# 纯净版：108M 大分区 + 闭源 MTK 无线驱动 + 基础 LuCI，不装任何插件
set -e

OWRT_ROOT="${1:-.}"
cd "$OWRT_ROOT"

# ---------- 1. 108M 大分区适配（hanwckf bl-mt798x uboot / NMBM）----------
DEVICE_DTS="target/linux/mediatek/dts/mt7981b-qihoo-360t7.dts"
if [ -f "$DEVICE_DTS" ]; then
    # firmware 分区扩到 0x6e00000 (110MiB)，起始 0x580000
    sed -i 's/reg = <0x[0-9a-fA-F]* 0x[0-9a-fA-F]*>;.*$/reg = <0x580000 0x6e00000>;/' "$DEVICE_DTS" || true
fi

# 镜像大小上限：允许大分区固件
[ -f .config ] && sed -i 's/^# CONFIG_TARGET_PER_DEVICE_ROOTFS is not set/CONFIG_TARGET_PER_DEVICE_ROOTFS=y/' .config || true
echo 'CONFIG_TARGET_KERNEL_PARTSIZE=32' >> .config
echo 'CONFIG_TARGET_ROOTFS_PARTSIZE=256' >> .config
echo 'CONFIG_TARGET_ROOTFS_SQUASHFS=y' >> .config

# ---------- 2. 强制选中闭源 MTK 无线驱动（关键）----------
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

# ---------- 3. 仅基础 LuCI（Web 管理界面，非插件）----------
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-ssl=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_LUCI_LANG_zh_Hans=y
EOF

# ---------- 4. 显式关闭所有常见插件，保证纯净 ----------
for p in adguardhome eqos ssr-plus passwall openclash v2raya zerotier frpc \
         alist filetransfer smartdns mosdns istorex dockerman docker \
         shadowsocksr-libev xray-core sing-box trojan naiveproxy; do
    sed -i "/^CONFIG_PACKAGE_luci-app-${p}=/d" .config 2>/dev/null || true
    echo "CONFIG_PACKAGE_luci-app-${p}=n" >> .config
done
sed -i "/^CONFIG_PACKAGE_AdGuardHome=/d" .config 2>/dev/null || true
echo "CONFIG_PACKAGE_AdGuardHome=n" >> .config

# ---------- 5. 让配置生效，处理依赖 ----------
make defconfig

echo "===== diy-part2.sh done ====="
grep -E '^(CONFIG_PACKAGE_kmod-mtwifi|CONFIG_PACKAGE_kmod-mt7981-firmware)=' .config || true
