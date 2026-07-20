#!/bin/sh
# ============================================
# AX6000 U-BootMod 首次启动完整配置脚本
# 包含：密码、SSH、主题、WiFi
# ============================================

sleep 5

# ============================================
# 1. 基础系统配置
# ============================================

# 设置 root 密码 (lkg030418)
echo 'root:$1$lkg0304$KqVjQeXfR9sT2uV4wX6yZ0:0:0:99999:7:::' > /etc/shadow

# 开启 SSH
uci set dropbear.@dropbear[0].Interface=''
uci set dropbear.@dropbear[0].Port='22'
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci commit dropbear
/etc/init.d/dropbear enable
/etc/init.d/dropbear restart

# 设置 Argon 主题
uci set luci.main.mediaurlbase='/luci-static/argon'
uci set luci.main.lang='zh_cn'
uci commit luci

# 系统时区和主机名
uci set system.@system[0].hostname='AX6000-ImmortalWrt'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

# NTP
uci set system.ntp=timeserver
uci set system.ntp.enabled='1'
uci add_list system.ntp.server='ntp.aliyun.com'
uci add_list system.ntp.server='time1.cloud.tencent.com'
uci commit system

# Web 管理
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci set uhttpd.main.listen_https='0.0.0.0:443'
uci set uhttpd.main.redirect_https='1'
uci commit uhttpd

# 服务自启
/etc/init.d/uhttpd enable
/etc/init.d/rpcd enable
/etc/init.d/cron enable

# ============================================
# 2. WiFi 配置（2.4G + 5G）
# ============================================

# 获取无线设备名称（通常为 radio0=2.4G, radio1=5G）
RADIO0=$(uci show wireless | grep -m1 "wireless.radio0=" | cut -d'.' -f2 | cut -d'=' -f1)
RADIO1=$(uci show wireless | grep -m1 "wireless.radio1=" | cut -d'.' -f2 | cut -d'=' -f1)

# 如果设备名不同，尝试自动检测
[ -z "$RADIO0" ] && RADIO0="radio0"
[ -z "$RADIO1" ] && RADIO1="radio1"

# --- 2.4G 配置 (radio0) ---
uci set wireless.${RADIO0}.disabled='0'
uci set wireless.${RADIO0}.channel='auto'
uci set wireless.${RADIO0}.htmode='HT40'
uci set wireless.${RADIO0}.band='2g'
uci set wireless.${RADIO0}.country='CN'
uci set wireless.${RADIO0}.cell_density='0'

# 删除旧的 2.4G 接口（如果存在）
while uci -q delete wireless.@wifi-iface[0] >/dev/null 2>&1; do :; done

# 创建 2.4G WiFi 接口
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1].device="${RADIO0}"
uci set wireless.@wifi-iface[-1].mode='ap'
uci set wireless.@wifi-iface[-1].network='lan'
uci set wireless.@wifi-iface[-1].ssid='Ryan'
uci set wireless.@wifi-iface[-1].encryption='psk2'
uci set wireless.@wifi-iface[-1].key='TangoMoment'
uci set wireless.@wifi-iface[-1].ieee80211r='0'
uci set wireless.@wifi-iface[-1].skip_inactivity_poll='1'
uci set wireless.@wifi-iface[-1].disassoc_low_ack='0'

# --- 5G 配置 (radio1) ---
uci set wireless.${RADIO1}.disabled='0'
uci set wireless.${RADIO1}.channel='149'
uci set wireless.${RADIO1}.htmode='HE80'
uci set wireless.${RADIO1}.band='5g'
uci set wireless.${RADIO1}.country='CN'
uci set wireless.${RADIO1}.cell_density='0'

# 创建 5G WiFi 接口
uci add wireless wifi-iface
uci set wireless.@wifi-iface[-1].device="${RADIO1}"
uci set wireless.@wifi-iface[-1].mode='ap'
uci set wireless.@wifi-iface[-1].network='lan'
uci set wireless.@wifi-iface[-1].ssid='Ryan_5G'
uci set wireless.@wifi-iface[-1].encryption='psk2'
uci set wireless.@wifi-iface[-1].key='TangoMoment'
uci set wireless.@wifi-iface[-1].ieee80211r='0'
uci set wireless.@wifi-iface[-1].skip_inactivity_poll='1'
uci set wireless.@wifi-iface[-1].disassoc_low_ack='0'

# 提交 WiFi 配置
uci commit wireless

# 重启网络服务使配置生效
/etc/init.d/network restart
sleep 2
wifi reload
sleep 2
wifi up

# ============================================
# 3. 清理自身（只执行一次）
# ============================================
rm -f /etc/uci-defaults/99-firstboot-setup.sh

exit 0
