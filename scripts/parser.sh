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
function fbfu_file_line_foreach {
    local fbar_file=$1
    local fbar_hook=$2
    local fbar_args=$3
    local fbar_line=""
    local fbar_result=""
    if [ ! -f "$fbar_file" ];then
        return 1
    fi
    while read fbar_line || [ "$fbar_line" != "" ];do
        fbar_line=$(fbfu_string_slim "$fbar_line")
        if [ "$fbar_line" == "" ];then
            continue
        fi
        $fbar_hook "$fbar_line" "$fbar_args"
        fbar_result=$?
        if [ "$fbar_result" !=  "0" ];then
            return "$fbar_result"
        fi
    done < $fbar_file
    return 0
}

#@brief 按行遍历字符串
#@param 需要遍历的字符串
#@param 回调函数($1:一行的数据 $2:私有参数)
#@param 私有参数
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function fbfu_string_line_foreach {
    local fbar_m=1
    local fbar_string=$1
    local fbar_hook=$2
    local fbar_args=$3
    local fbar_line=""
    local fbar_result=""
    local fbar_line_sum=$(echo "$fbar_string" | sed -n '$=')
    if [ "$fbar_line_sum" == "0" ];then
        return 1
    fi
    while [ "$fbar_m" -le "$fbar_line_sum" ];do
        fbar_line=$(echo "$fbar_string" | sed -n "${fbar_m}p")
        fbar_line=$(fbfu_string_slim "$fbar_line")
        if [ "$fbar_line" == "" ];then
            fbar_m=$[ "$fbar_m" + 1 ]
            continue
        fi
        $fbar_hook "$fbar_line" "$fbar_args"
        fbar_result=$?
        if [ "$fbar_result" !=  "0" ];then
            return "$fbar_result"
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
    done
    return 0
}

#@brief 解析段文件
#@param 文件路径
#@param 需要解析的key值
#@param 段左符号
#@param 段右符号
#@return 若解析成功，返回解析的字符串
function fbfu_parse_section {
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
    while read fbar_line || [ "$fbar_line" != "" ];do
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

#@brief 解析键值对文件
#@param 文件路径
#@param 需要解析的key值
#@return 若解析成功，返回解析的字符串
function fbfu_parse_kv {
    local fbar_file=$1
    local fbar_key=$2
    local fbar_symbol=$3
    local fbar_line=$(cat $fbar_file | grep "^${fbar_key}[[:space:]]*${fbar_symbol}[[:space:]]*" | sed -n '1p')
    if [ "$fbar_line" == "" ];then
        return 1
    fi
    local fbar_value=$(echo "$fbar_line" | sed -e "s/^${fbar_key}[[:space:]]*${fbar_symbol}[[:space:]]*//")
    fbfu_string_slim "$fbar_value"
    return 0
}

#@brief fb配置解析接口
#@param 文件路径
#@param 需要解析的key值
#@param 临时文件目录
#@return 若解析成功，返回解析的字符串
#@note 0表示成功，1表示解析失败，2表示字符串，3表示数组，4表示hook
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
    fbar_next=$(fbfu_convert_variable "$fbar_next")
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
        fbar_value=$(fbfu_parse_section "$fbar_file" "$fbar_key" "[" "]")
        if [ "$fbar_value" == "" ];then
            return 1
        else
            echo "$fbar_value" | sed -e '1s/^\[//' | sed -e '$s/]$//'
            return 3
        fi
    fi
    fbar_check_section=$(echo "$fbar_value" | grep '^{')
    if [ "$fbar_check_section" != "" ];then
        if [ ! -d "$fbar_temp_path" ];then
            return 1
        fi
        fbar_value=$(fbfu_parse_section "$fbar_file" "$fbar_key" "{" "}")
        if [ "$fbar_value" == "" ];then
            return 1
        else
            echo "$fbar_value" | sed -e '1s/^{//' | sed -e '$s/}$//'
            return 4
        fi
    fi
    fbfu_convert_variable "$fbar_value"
    return 2
}

function fbar_init_partition_struct {
    fbar_partition_begin=()
    fbar_partition_end=()
    fbar_partition_source=()
    fbar_partition_args=()
    fbar_partition_sum=1
}

function fbar_init_partition {
    local fbar_list=""
    local fbar_list_sum=0
    local fbar_note=$(echo "$1" | grep "^#")
    if [ "$fbar_note" != "" ];then
        return 0
    fi
    fbar_list=$(expand_list_init "$1")
    fbar_list_sum="$?"
    if [ "$fbar_list_sum" -lt "2" ];then
        return 0
    fi
    local fbar_address=$(expand_list_get "$fbar_list" "1")
    local fbar_source=$(expand_list_get "$fbar_list" "2")
    if [ "$fbar_address" == "" ] || [ "$fbar_source" == "" ];then
        return 0
    fi
    if [ "$fbar_address" == "FILL" ];then
        local fbar_check_source=$(echo "$fbar_source" | grep "0x[0-9a-f][0-9a-f]")
        if [ "$fbar_check_source" == "" ];then
            return 0
        fi
        if [ "$__fbar_partition_last_type" == "FILL" ];then
            return 0
        fi
        fbar_partition_begin[$fbar_partition_sum]="FILL"
        fbar_partition_end[$fbar_partition_sum]="FILL"
        fbar_partition_source[$fbar_partition_sum]="$fbar_source"
        fbar_partition_args[$fbar_partition_sum]="$1"
        __fbar_partition_last_type="FILL"
        fbar_partition_sum=$[ "$fbar_partition_sum" + 1 ]
        return 0
    else
        local fbar_source_size=0
        local fbar_addr_num=$(printf %d "$fbar_address")
        if [ -f "$fbar_source" ];then
            fbar_source_size=$(ls -l $fbar_source 2>/dev/null | awk '{print $5}')
            if [ "$fbar_source_size" == "0" ];then
                return 0
            fi
            fbar_partition_source[$fbar_partition_sum]="$fbar_source"
        else
            return 0
        fi
        fbar_partition_begin[$fbar_partition_sum]="$fbar_addr_num"
        fbar_partition_end[$fbar_partition_sum]=$[ "$fbar_addr_num" + "$fbar_source_size" - 1 ] 
        fbar_partition_args[$fbar_partition_sum]="$1"
        __fbar_partition_last_type="FILE"
        fbar_partition_sum=$[ "$fbar_partition_sum" + 1 ]
        return 0
    fi
}

function fbfr_fill_partition {
    local fbar_m=1
    local fbar_gate=$[ "$fbar_partition_sum" - 1 ]
    while [ "$fbar_m" -lt "$fbar_gate" ];do
        local fbar_last=$[ "$fbar_m" - 1 ]
        local fbar_next=$[ "$fbar_m" + 1 ]
        local fbar_current_begin="${fbar_partition_begin[$fbar_m]}"
        local fbar_current_end="${fbar_partition_end[$fbar_m]}"
        if [ "$fbar_current_begin" == "FILL" ];then
            local fbar_last_end="${fbar_partition_end[$fbar_last]}"
            fbar_partition_begin[$fbar_m]=$[ "$fbar_last_end" + 1 ]
        fi
        if [ "$fbar_current_end" == "FILL" ];then
            local fbar_next_begin="${fbar_partition_begin[$fbar_next]}"
            if [ "$fbar_next_begin" == "END" ];then
                fbar_partition_end[$fbar_m]="END"
            else
                fbar_partition_end[$fbar_m]=$[ "$fbar_next_begin" - 1 ]
            fi
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
    done
}

function fbfr_check_partition {
    local fbar_m=1
    local fbar_gate=$[ "$fbar_partition_sum" - 1 ]
    while [ "$fbar_m" -lt "$fbar_gate" ];do
        local fbar_last=$[ "$fbar_m" - 1 ]
        local fbar_last_end="${fbar_partition_end[$fbar_last]}"
        while [ "$fbar_last_end" != "-1" ];do
            if [ "$fbar_last_end" != "IGNORE" ];then
                break;
            fi
            fbar_last=$[ "$fbar_last" - 1 ]
            fbar_last_end="${fbar_partition_end[$fbar_last]}"
        done
        local fbar_current_begin="${fbar_partition_begin[$fbar_m]}"
        local fbar_current_end="${fbar_partition_end[$fbar_m]}"
        local fbar_current_source="${fbar_partition_source[$fbar_m]}"
        if [ "$fbar_current_end" == "END" ];then
            return 0
        fi
        if [ "$fbar_current_begin" -gt "$fbar_current_end" ];then
            if [ -f "$fbar_current_source" ];then
                fbar_partition_end[$fbar_m]="${fbar_current_end}|ERROR"
                return 1
            else
                fbar_partition_begin[$fbar_m]="IGNORE"
                fbar_partition_end[$fbar_m]="IGNORE"
                fbar_m=$[ "$fbar_m" + 1 ]
                continue;
            fi
        fi
        if [ "$fbar_last_end" != "-1" ];then
            if [ "$fbar_current_begin" -le "$fbar_last_end" ];then
                fbar_partition_begin[$fbar_m]="${fbar_current_begin}|ERROR"
                return 1
            fi
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
    done
    return 0
}

function fbfu_json_partition {
    local fbar_m=1
    local fbar_gate=$[ "$fbar_partition_sum" - 1 ]
    json_init
    json_add_array "partition"
    while [ "$fbar_m" -lt "$fbar_gate" ];do
        local fbar_begin="${fbar_partition_begin[$fbar_m]}"
        local fbar_end="${fbar_partition_end[$fbar_m]}"
        local fbar_source="${fbar_partition_source[$fbar_m]}"
        local fbar_args="${fbar_partition_args[$fbar_m]}"
        if [ "$fbar_end" == "IGNORE" ];then
            fbar_m=$[ "$fbar_m" + 1 ]
            continue
        fi
        if [ "$fbar_end" == "END" ];then
            break
        fi
        json_add_object "$fbar_m"
        json_add_string "begin" "$fbar_begin"
        json_add_string "end" "$fbar_end"
        json_add_string "source" "$fbar_source"
        json_add_string "args" "$fbar_args"
        json_close_object
        fbar_m=$[ "$fbar_m" + 1 ]
    done
    json_close_array
    json_dump
}

#@brief 解析分区表
#@param 分区表
#@return 解析完成后以json格式返回
function fbfu_parse_partition {
    local fbar_result=0
    local fbar_partition=$1
    if [ "$fbar_partition" == "" ];then
        return 1
    fi
    fbar_init_partition_struct
    fbar_partition_begin[0]="BEGIN"
    fbar_partition_end[0]=-1
    fbfu_string_line_foreach "$fbar_partition" "fbar_init_partition"
    fbar_partition_begin[$fbar_partition_sum]="END"
    fbar_partition_end[$fbar_partition_sum]=-1
    fbar_partition_sum=$[ $fbar_partition_sum + 1]
    if [ "$fbar_partition_sum" -le "2" ];then
        return 1
    fi
    fbfr_fill_partition
    fbfr_check_partition
    fbar_result="$?"
    fbfu_json_partition
    return "$fbar_result"
}