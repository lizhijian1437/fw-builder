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

mkdir -p $fbar_temp_path 1>/dev/null 2>&1
if [ ! -f "$fbar_config" ] || [ ! -d "$fbar_temp_path" ];then
    fbfu_error "[FW_BUILD]args error"
    exit 1
fi

fbar_fw_temp_path="${fbar_temp_path}/fw_build"
mkdir -p $fbar_fw_temp_path

fbar_partition=$(fbfu_parse "$fbar_config" "PARTITION" "$fbar_temp_path")
if [ "$fbar_partition" == "" ];then
    fbfu_error "[FW_BUILD]please set PARTITION"
    exit 1
fi

fbar_output=$(fbfu_parse "$fbar_config" "FIRMWARE_OUTPUT" "$fbar_temp_path")
fbfu_force_touch "$fbar_output"
if [ ! -f "$fbar_output" ];then
    fbfu_error "[FW_BUILD]FIRMWARE_OUTPUT error"
    exit 1
fi

fbar_firmware_size=$(fbfu_parse "$fbar_config" "FIRMWARE_SIZE" "$fbar_temp_path")
fbar_json_partition=$(fbfu_parse_partition "$fbar_partition" "$fbar_firmware_size")
fbar_result="$?"
if [ "$fbar_result" == "1" ];then
    fbfu_error "[FW_BUILD]parse PARTITION error"
    fbfu_error "${fbar_json_partition}"
    exit 1
fi

function fbfr_json_get_value {
    json_get_var "__fbar_json_var" "$1"
    echo "$__fbar_json_var"
}

function __fbfr_analysis_partition {
    json_select "$2"
    local fbar_begin=$(fbfr_json_get_value "begin")
    local fbar_end=$(fbfr_json_get_value "end")
    local fbar_begin_hex="0x$(printf %x ${fbar_begin})"
    local fbar_end_hex="0x$(printf %x ${fbar_end})"
    local fbar_size=$[ "$fbar_end" - "$fbar_begin" + 1 ]
    local fbar_source=$(fbfr_json_get_value "source")
    local fbar_target="$fbar_source"
    if [ ! -f "$fbar_source" ];then
        fbar_target="${fbar_fw_temp_path}/fill"
        fbfu_fill_file "$fbar_size" "$fbar_source" "$fbar_target"
        echo "begin:${fbar_begin_hex} end:${fbar_end_hex} target:FILL_${fbar_source} size:${fbar_size}"
    else
        echo "begin:${fbar_begin_hex} end:${fbar_end_hex} target:${fbar_target} size:${fbar_size}"
    fi
    ${FBAU_SCRIPTS}/sec_replace.pl -i "$fbar_target" -o "$fbar_output" -a "$fbar_begin"
    json_select ..
}

json_load "$fbar_json_partition"
echo "partition:"
json_for_each_item "__fbfr_analysis_partition" "partition"
