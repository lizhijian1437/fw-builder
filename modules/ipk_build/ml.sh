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
fbar_ipk_build="${fbar_module_path}/ipkg-build"

mkdir -p $fbar_temp_path 1>/dev/null 2>&1
if [ ! -f "$fbar_config" ] || [ ! -d "$fbar_temp_path" ];then
    fbfu_error "[IPK]args error"
    exit 1
fi

fbar_root=$(fbfu_parse "$fbar_config" "IPK_PACKAGE_ROOT" "$fbar_temp_path")
if [ ! -d "$fbar_root" ];then
    fbfu_error "[IPK]please set IPK_PACKAGE_ROOT"
    exit 1
fi
fbar_control="${fbar_root}/CONTROL/control"

fbar_out=$(fbfu_parse "$fbar_config" "IPK_PACKAGE_OUT" "$fbar_temp_path")
mkdir -p $fbar_out 1>/dev/null 2>&1
if [ ! -d "$fbar_out" ];then
    fbfu_error "[IPK]please set IPK_PACKAGE_OUT"
    exit 1
fi

if [ ! -f "$fbar_control" ];then
    fbfu_force_touch "$fbar_control"
    if [ ! -f "$fbar_control" ];then
        fbfu_error "[IPK]can't create control file"
        exit 1
    fi
    fbar_package_name=$(fbfu_parse "$fbar_config" "IPK_PACKAGE_NAME" "$fbar_temp_path")
    if [ "$fbar_package_name" == "" ];then
        fbfu_error "[IPK]please provide package name"
        exit 1
    fi
    fbar_package_version=$(fbfu_parse "$fbar_config" "IPK_PACKAGE_VERSION" "$fbar_temp_path")
    if [ "$fbar_package_version" == "" ];then
        fbfu_error "[IPK]please provide package version"
        exit 1
    fi
    fbar_arch=$(fbfu_parse "$fbar_config" "IPK_PACKAGE_ARCH" "$fbar_temp_path")
    if [ "$fbar_arch" == "" ];then
        fbfu_error "[IPK]please provide package arch"
        exit 1
    fi
    chmod 755 $fbar_control 1>/dev/null 2>&1
    echo "Architecture: $fbar_arch" >> $fbar_control
    echo "Package: $fbar_package_name" >> $fbar_control
    echo "Version: $fbar_package_version" >> $fbar_control
    echo "$fbar_package_name $fbar_package_version $fbar_arch"
fi

function fbar_required_field
{
    local fbar_field=$1
    grep "^${fbar_field}:" < $fbar_control | sed -e "s/^[^:]*:[[:space:]]*//" | sed -n '1p'
}

fbar_package_name=$(fbar_required_field "Package")
if [ "$fbar_package_name" == "" ];then
    fbfu_error "[IPK]please provide package name"
    exit 1
fi

fbar_package_version=$(fbar_required_field "Version")
if [ "$fbar_package_version" == "" ];then
    fbfu_error "[IPK]please provide package version"
    exit 1
fi

fbar_arch=$(fbar_required_field "Architecture")
if [ "$fbar_arch" == "" ];then
    fbfu_error "[IPK]please provide package arch"
    exit 1
fi

fbar_ipk_out="${fbar_root}/__ipk_out"
fbar_ipk_name="${fbar_package_name}_${fbar_arch}_${fbar_package_version}.ipk"
mkdir -p $fbar_ipk_out
$fbar_ipk_build -O "$fbar_ipk_name" "${fbar_root}" "${fbar_ipk_out}"
fbar_result="$?"
if [ -f "${fbar_ipk_out}/${fbar_ipk_name}" ];then
    chmod 755 ${fbar_ipk_out}/${fbar_ipk_name} 1>/dev/null 2>&1
    cp ${fbar_ipk_out}/${fbar_ipk_name} ${fbar_out} 1>/dev/null 2>&1
    fbfu_force_touch "${fbar_ipk_out}/__ipk_build_ok"
fi
exit "$fbar_result"