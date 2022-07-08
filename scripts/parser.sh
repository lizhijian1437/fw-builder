#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#depend: base.sh jshn.sh

#@brief 按行遍历文件
#@param 文件路径
#@param 回调函数($1:一行的数据 $2:私有参数)
#@param 私有参数
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function fbfu_line_foreach {
    local fbar_file=$1
    local fbar_hook=$2
    local fbar_args=$3
    local fbar_line=""
    local fbar_result =""
    if [ ! -f "$fbar_file" ];then
        return 1
    fi
    while read fbar_line;do
        fbar_line=$(fbfu_string_slim "$fbar_line")
        if [ "$fbar_line" == "" ];then
            continue
        fi
        eval ${fbar_hook} \"${fbar_line}\" \"${fbar_args}\"
        fbar_result=$?
        if [ "$fbar_result" !=  "0" ];then
            return 1
        fi
    done < $fbar_file
    return 0
}

function fbfr_section {
    local fbar_i=1
    local fbar_file=$1
    local fbar_key=$2
    local fbar_section_left=$3
    local fbar_section_right=$4
    local fbar_nsl=0
    local fbar_nsr=0
    local fbar_sl_sum=0
    local fbar_sr_sum=0
    local fbar_value=""
    local fbar_line=""
    local fbar_stage=0
    local fbar_section_begin=0
    local fbar_section_end=0
    while read fbar_line;do
        fbar_line=$(fbfu_string_slim "$fbar_line")
        if [ "$fbar_line" == "" ];then
            fbar_i=$[ $fbar_i + 1 ]
            continue
        fi
        if [ "$fbar_stage" == "0" ];then
            local fbar_check_key=$(echo "$fbar_line" | grep "^${fbar_key}[[:space:]]*:=[[:space:]]*")
            if [ "$fbar_check_key" == "" ];then
                fbar_i=$[ $fbar_i + 1 ]
                continue
            fi
            fbar_stage=1
            fbar_value=$(echo "$fbar_line" | sed -e "s/^${fbar_key}[[:space:]]*:=[[:space:]]*\(.*\)/\1/")
            fbar_check_key=$(echo "$fbar_value" | grep "^\\${fbar_section_left}")
            if [ "$fbar_check_key" == "" ];then
                return 1
            fi
            fbar_section_begin=$fbar_i
            fbar_nsl=$(fbfu_string_symbol_num "$fbar_line" "$fbar_section_left")
            fbar_nsr=$(fbfu_string_symbol_num "$fbar_line" "$fbar_section_right")
            fbar_sl_sum=$[ "$fbar_sl_sum" + "$fbar_nsl" ]
            fbar_sr_sum=$[ "$fbar_sr_sum" + "$fbar_nsr" ]
            if [ "$fbar_sl_sum" == "$fbar_sr_sum" ];then
                fbar_section_end=$fbar_i
                break
            fi
            fbar_i=$[ $fbar_i + 1 ]
            continue
        elif [ "$fbar_stage" == "1" ];then
            fbar_nsl=$(fbfu_string_symbol_num "$fbar_line" "$fbar_section_left")
            fbar_nsr=$(fbfu_string_symbol_num "$fbar_line" "$fbar_section_right")
            fbar_sl_sum=$[ "$fbar_sl_sum" + "$fbar_nsl" ]
            fbar_sr_sum=$[ "$fbar_sr_sum" + "$fbar_nsr" ]
            if [ "$fbar_sl_sum" == "$fbar_sr_sum" ];then
                fbar_section_end=$fbar_i
                break
            fi
        fi
        fbar_i=$[ $fbar_i + 1 ]
    done < $fbar_file
    if [ "$fbar_section_begin" == "0" ] || [ "$fbar_section_end" == "0" ] || [ "$fbar_sl_sum" != "$fbar_sr_sum" ];then
        return 1
    fi
    sed -n "${fbar_section_begin},${fbar_section_end}p" "$fbar_file" | sed -e "s/^${fbar_key}[[:space:]]*:=[[:space:]]*//"
    return 0
}

function fbfu_parse_kv {
    local fbar_file=$1
    local fbar_key=$2
    local fbar_symbol=$3
    local fbar_line=$(cat $fbar_file | grep "^${fbar_key}[[:space:]]*${fbar_symbol}[[:space:]]*" | sed -n '1p')
    if [ "$fbar_line" == "" ];then
        return 1
    fi
    local fbar_value=$(echo "$fbar_line" | sed -e "s/^${fbar_key}[[:space:]]*${fbar_symbol}[[:space:]]*//")
    fbar_value=$(fbfu_string_slim "$fbar_value")
    echo "$fbar_value"
    return 0
}

function fbfr_parse_hook {
    local fbar_command=$1
    local fbar_temp_path=$2
    if [ -f "${fbar_temp_path}/__hook_sh" ];then
        rm -f ${fbar_temp_path}/__hook_sh
    fi
    mkdir -p ${fbar_temp_path}
    echo "$fbar_command" > ${fbar_temp_path}/__hook_sh
    chmod 755 ${fbar_temp_path}/__hook_sh
    ${fbar_temp_path}/__hook_sh
}

#@brief fb配置解析接口
#@param 文件路径
#@param 需要解析的key值
#@param 临时文件目录
#@return 若解析成功，返回解析的字符串
function fbfu_parse {
    local fbar_file=$1
    local fbar_key=$2
    local fbar_result=""
    local fbar_temp_path=$3
    local fbar_check_section=""
    local fbar_command=""
    if [ ! -f "$fbar_file" ] || [ "$fbar_key" == "" ];then
        return 1
    fi
    local fbar_alias=$(fbfu_parse_kv "$fbar_file" "$fbar_key" "->")
    if [ "$fbar_alias" != "" ];then
        fbar_key="$fbar_alias"
    fi
    local fbar_next=$(fbfu_parse_kv "$fbar_file" "__NEXT_CONFIG" ":=")
    if [  -f "$fbar_next" ];then
        fbar_value=$(fbfu_parse "$fbar_next" "$fbar_key" "$fbar_temp_path")
        fbar_result="$?"
        if [ "$fbar_result" != "1" ];then
            echo "$fbar_value"
            return "$fbar_result"
        fi
    fi
    local fbar_value=$(fbfu_parse_kv "$fbar_file" "$fbar_key" ":=")
    if [ "$fbar_value" == "" ];then
        return 1
    fi
    fbar_check_section=$(echo "$fbar_value" | grep '^\[')
    if [ "$fbar_check_section" != "" ];then
        fbar_value=$(fbfr_section "$fbar_file" "$fbar_key" "[" "]" | sed -e '1s/^\[//' | sed -e '$s/]$//')
        if [ "$fbar_value" == "" ];then
            return 1
        fi
        fbar_value=$(fbfu_convert_variable "$fbar_value")
        echo "$fbar_value"
        return 3
        
    fi
    fbar_check_section=$(echo "$fbar_value" | grep '^{')
    if [ "$fbar_check_section" != "" ];then
        if [ ! -d "$fbar_temp_path" ];then
            return 1
        fi
        fbar_value=$(fbfr_section "$fbar_file" "$fbar_key" "{" "}")
        if [ "$fbar_value" == "" ];then
            return 1
        else
            fbar_command=$(echo "$fbar_value" | sed -e '1s/^{//' | sed -e '$s/}$//')
            fbar_value=$(fbfr_parse_hook "$fbar_command" "$fbar_temp_path")
            echo "$fbar_value"
            return 4
        fi
    fi
    fbar_value=$(fbfu_convert_variable "$fbar_value")
    echo "$fbar_value"
    return 2
}

