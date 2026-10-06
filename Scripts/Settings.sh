#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/mediatek/filogic/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#修改opkg软件源为南京大学镜像站
LAST_LINE=$(awk '/exit 0/{print NR}' $(find ./package/emortal/default-settings/files/ -type f -name "99-default-settings"))
sed -i "${LAST_LINE}"'i\sed -i '\"s,https://downloads.immortalwrt.org,https://mirror.nju.edu.cn/immortalwrt,g\"' "/etc/opkg/distfeeds.conf"' $(find ./package/emortal/default-settings/files/ -type f -name "99-default-settings")

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# 在 Settings.sh 末尾添加
# 设置 root 密码（请把下面的哈希换成你自己生成的完整哈希）
sed -i 's|root::0:0:99999:7:::|root:$6$k5/jSZXlG2ccfxre$KPkdaJuT/Q.quOuVea8myEWDQHlAV7U0iwQgvalS1MqgolIUQkZXgkkOrm5yERDVsRK2lmglBfvTp5zD34SnA/:0:0:99999:7:::|' package/base-files/files/etc/shadow
# 有的源码默认是 root:::0:99999:7::: 这种格式，也可以再加一行保险：
sed -i 's|root:::0:99999:7:::|root:$6$nGHByk4aU1uwrmhG$rPOWogpHtWEh1W2SpvmwS4rjvNGGrjFFNhZKvxUGc13hKyzCZLivFQs1YQJvGooe/FeH0rzk8RS.TpfCH0JtQ/::0:99999:7:::|' package/base-files/files/etc/shadow

echo "===== 修改后的 shadow 内容 ====="
grep '^root:' package/base-files/files/etc/shadow
