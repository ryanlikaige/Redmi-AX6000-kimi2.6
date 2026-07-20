#!/bin/sh
# ============================================
# AX6000 U-BootMod 首次启动配置
# ImmortalWrt v25.12.1 (内核6.6)
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
# 2. WiFi 配置（适配 6.6 内核驱动）
# ============================================

# 等待无线设备就绪
sleep 3

# 获取无线设备
RADIO0="radio0"
RADIO1="radio1"

# 检查设备是否存在
if ! uci -q get wireless.${RADIO0} >/dev/null 2>&1; then
    logger -t firstboot "Warning: radio0 not found, waiting..."
    sleep 5
fi

# --- 2.4G 配置 ---
if uci -q get wireless.${RADIO0} >/dev/null 2>&1; then
    uci set wireless.${RADIO0}.disabled='0'
    uci set wireless.${RADIO0}.channel='auto'
    uci set wireless.${RADIO0}.htmode='HE40'
    uci set wireless.${RADIO0}.band='2g'
    uci set wireless.${RADIO0}.country='CN'
    uci set wireless.${RADIO0}.cell_density='0'
    
    # 删除旧的 2.4G 接口
    uci -q delete wireless.default_${RADIO0}
    
    # 创建 2.4G 接口
    uci set wireless.default_${RADIO0}=wifi-iface
    uci set wireless.default_${RADIO0}.device="${RADIO0}"
    uci set wireless.default_${RADIO0}.mode='ap'
    uci set wireless.default_${RADIO0}.network='lan'
    uci set wireless.default_${RADIO0}.ssid='Ryan'
    uci set wireless.default_${RADIO0}.encryption='sae-mixed'
    uci set wireless.default_${RADIO0}.key='TangoMoment'
    uci set wireless.default_${RADIO0}.ieee80211r='0'
fi

# --- 5G 配置 ---
if uci -q get wireless.${RADIO1} >/dev/null 2>&1; then
    uci set wireless.${RADIO1}.disabled='0'
    uci set wireless.${RADIO1}.channel='149'
    uci set wireless.${RADIO1}.htmode='HE80'
    uci set wireless.${RADIO1}.band='5g'
    uci set wireless.${RADIO1}.country='CN'
    uci set wireless.${RADIO1}.cell_density='0'
    
    # 删除旧的 5G 接口
    uci -q delete wireless.default_${RADIO1}
    
    # 创建 5G 接口
    uci set wireless.default_${RADIO1}=wifi-iface
    uci set wireless.default_${RADIO1}.device="${RADIO1}"
    uci set wireless.default_${RADIO1}.mode='ap'
    uci set wireless.default_${RADIO1}.network='lan'
    uci set wireless.default_${RADIO1}.ssid='Ryan_5G'
    uci set wireless.default_${RADIO1}.encryption='sae-mixed'
    uci set wireless.default_${RADIO1}.key='TangoMoment'
    uci set wireless.default_${RADIO1}.ieee80211r='0'
fi

# 提交 WiFi 配置
uci commit wireless

# 重启网络
/etc/init.d/network restart
sleep 3
wifi reload
sleep 2
wifi up

# ============================================
# 3. 清理
# ============================================
rm -f /etc/uci-defaults/99-firstboot-setup.sh

exit 0
