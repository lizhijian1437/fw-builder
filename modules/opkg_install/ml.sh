#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

. ${FBAU_SCRIPTS}/base.sh
. ${FBAU_SCRIPTS}/jshn.sh
. ${FBAU_SCRIPTS}/parser.sh

fbar_config=$1
fbar_temp_path=$2
fbar_module_path=$3
fbar_opkg="${FBAU_BIN}/opkg"

mkdir -p $fbar_temp_path 1>/dev/null 2>&1
if [ ! -f "$fbar_config" ] || [ ! -d "$fbar_temp_path" ];then
    fbfu_error "[OPKG_INSTALL]args error"
    exit 1
fi

fbar_opkg_root=$(fbfu_parse "$fbar_config" "OPKG_INSTALL_ROOT" "$fbar_temp_path")
if [ ! -d "$fbar_opkg_root" ];then
    fbfu_error "[OPKG_INSTALL]please set OPKG_INSTALL_ROOT"
    exit 1
fi
fbfu_force_touch "${fbar_opkg_root}/var/lock/opkg.lock"

fbar_opkg_arch=$(fbfu_parse "$fbar_config" "OPKG_INSTALL_ARCH" "$fbar_temp_path")
if [ "$fbar_opkg_arch" == "" ];then
    fbfu_error "[OPKG_INSTALL]please set OPKG_INSTALL_ARCH"
    exit 1
fi

fbar_opkg_package_dir=$(fbfu_parse "$fbar_config" "OPKG_INSTALL_PACKAGE_DIR" "$fbar_temp_path")
if [ ! -d "$fbar_opkg_package_dir" ];then
    fbfu_error "[OPKG_INSTALL]please set OPKG_INSTALL_PACKAGE_DIR"
    exit 1
fi

function __fbar_install_package {
    local fbar_file=$1
    local fbar_file_name=${fbar_file##*/}
    local fbar_file_suffix=${fbar_file##*.}
    if [ "$fbar_file_suffix" == "ipk" ];then
        fbfu_info "[OPKG_INSTALL]install $fbar_file_name"
        $fbar_opkg -o "$fbar_opkg_root" -add-arch all:1 -add-arch noarch:1 -add-arch "$fbar_opkg_arch:100" install "$fbar_file" --nodeps
    fi
    return 0
}
fbfu_traverse_dir "$fbar_opkg_package_dir" "__fbar_install_package" "0" "2"
