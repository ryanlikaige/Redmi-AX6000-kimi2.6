#!/bin/sh
# ============================================
# AX6000 U-BootMod 首次启动安全配置脚本
# 只设置基础功能，不修改网络/WiFi 配置
# ============================================

sleep 5

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

# 清理自身
rm -f /etc/uci-defaults/99-firstboot-setup.sh

exit 0
