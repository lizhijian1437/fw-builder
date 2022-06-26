#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#@brief 相对路径转换
#@param 绝对路径
#@param 相对路径
#@return 转换后的路径（如果本身是绝对路径则直接返回）
function fbfu_convert_relative_path {
    local fbar_m=0
    local fbar_absolute=$1
    local fbar_relative=$2
    local fbar_check=$(echo "$fbar_relative" | grep "^/")
    if [ "$fbar_check" != "" ];then
        echo "$fbar_relative"
        return 0
    fi
    fbar_check=$(echo "$fbar_absolute" | grep "^/")
    if [ "$fbar_check" == "" ];then
        return 1
    fi
    local fbar_absolute_array=($(echo "$fbar_absolute" | sed -e "s/\// /g"))
    local fbar_relative_array=($(echo "$fbar_relative" | sed -e "s/\// /g"))
    local fbar_absolute_len=${#fbar_absolute_array[@]}
    local fbar_relative_len=${#fbar_relative_array[@]}
    if [ "$fbar_absolute_len" == "0" ] || [ "$fbar_relative_len" == "0" ];then
        return 1
    fi
    local fbar_next_relative=""
    local fbar_next_absolute=$[ $fbar_absolute_len - 1 ]
    while [ "$fbar_m" -lt "$fbar_relative_len" ];do
        fbar_next_relative=${fbar_relative_array[$fbar_m]}
        if [ "$fbar_next_relative" == "." ];then
            continue
        elif [ "$fbar_next_relative" == ".." ];then
            if [ "$fbar_next_absolute" == "0" ];then
                return 1
            fi
            unset fbar_absolute_array[$fbar_next_absolute]
            fbar_next_absolute=$[ $fbar_next_absolute - 1 ]
        else
            fbar_next_absolute=$[ $fbar_next_absolute + 1] 
            fbar_absolute_array[$fbar_next_absolute]=$fbar_next_relative
        fi
        fbar_m=$[ $fbar_m + 1 ]
    done
    local fbar_convert_result=$(echo "${fbar_absolute_array[*]}" | sed -e "s/ /\//g")
    echo "/${fbar_convert_result}"
    return 0
}

#@brief 删除字符串前后空白字符
#@param 字符串
#@return 转换后的字符串
function fbfu_string_slim {
    echo "$1" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//"
}

#@brief 计算字符串中某个符号的个数
#@param 字符串
#@param 符号
#@return 个数
function fbfu_string_symbol_num {
    local fbar_p=$(echo "$1" | sed -e "s/[^$2]//g")
    echo ${#fbar_p}
}