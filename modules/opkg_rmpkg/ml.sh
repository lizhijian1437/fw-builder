#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

. ${FBAU_SCRIPTS}/base.sh
. ${FBAU_SCRIPTS}/parser.sh

fbar_config=$1
fbar_temp_path=$2
fbar_module_path=$3
fbar_opkg="${FBAU_BIN}/opkg"

mkdir -p $fbar_temp_path 1>/dev/null 2>&1
if [ ! -f "$fbar_config" ] || [ ! -d "$fbar_temp_path" ];then
    fbfu_error "[OPKG_RMPKG]args error"
    exit 1
fi

fbar_opkg_root=$(fbfu_parse "$fbar_config" "OPKG_RMPKG_ROOT" "$fbar_temp_path")
if [ ! -d "$fbar_opkg_root" ];then
    fbfu_error "[OPKG_RMPKG]please set OPKG_RMPKG_ROOT"
    exit 1
fi
fbfu_force_touch "${fbar_opkg_root}/var/lock/opkg.lock"

fbar_opkg_arch=$(fbfu_parse "$fbar_config" "OPKG_RMPKG_ARCH" "$fbar_temp_path")
if [ "$fbar_opkg_arch" == "" ];then
    fbfu_error "[OPKG_RMPKG]please set OPKG_RMPKG_ARCH"
    exit 1
fi

fbar_m=0
fbar_opkg_remove_list=($(fbfu_parse "$fbar_config" "OPKG_RMPKG_LIST" "$fbar_temp_path"))
fbar_opkg_remove_list_size=${#fbar_opkg_remove_list[@]}
while [ "$fbar_m" -lt "$fbar_opkg_remove_list_size" ];do
    fbar_next="${fbar_opkg_remove_list[$fbar_m]}"
    fbfu_info "[OPKG_RMPKG]remove ${fbar_next}"
    $fbar_opkg -o "$fbar_opkg_root" -add-arch all:1 -add-arch noarch:1 -add-arch "$fbar_opkg_arch:100" remove "$fbar_next"
    fbar_m=$[ "$fbar_m" + 1 ]
done
exit 0

