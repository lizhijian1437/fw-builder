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
            fbar_m=$[ $fbar_m + 1 ]
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

#@brief 检查字符串中是否有变量
#@param 字符串
#@return true表示有变量，false表示无变量
#@note 限定变量必须为${...}格式，并且变量名只能由字母、数字以及_-组成
function fbfu_check_variable {
    local fbar_check=$(echo "$1" | grep '\${[A-Za-z0-9_-]*}')
    if [ "$fbar_check" == "" ];then
        echo "false"
        return 0
    else
        echo "true"
        return 1
    fi
}

#@brief 转换字符串中的变量
#@param 字符串
#@return 转换后的字符串
#@note 限定变量必须为${...}格式，并且变量名只能由字母、数字以及_-组成
function fbfu_convert_variable {
    local fbar_check=$(fbfu_check_variable "$1")
    if [ "$fbar_check" == "false" ];then
        echo "$1"
        return 0
    else
        eval echo \"$1\"
        return 1
    fi    
}

#@brief 打印消息
#@param 需要打印的消息
function fbfu_info {
    local content="[INFO]  $(date '+%Y-%m-%d %H:%M:%S') $@"
    echo -e "\033[32m${content}\033[0m"
}

#@brief 打印警告
#@param 需要打印的消息
function fbfu_warn {
    local content="[WARN]  $(date '+%Y-%m-%d %H:%M:%S') $@"
    echo -e "\033[33m${content}\033[0m"
}

#@brief 打印异常
#@param 需要打印的消息
function fbfu_error {
    local content="[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $@"
    echo -e "\033[31m${content}\033[0m"
}


#@brief 初始化扩展列表,格式"VALUE1|VALUE2|VALUE3"
#@param 参数字符串
#@return 返回扩展列表，以及列表中值的数量
function expand_list_init {
    local fbar_expand_list=$(echo "$1" | awk 'BEGIN{RS="|";} { print $0 }')
    local fbar_expand_list_sum=$(echo "$fbar_expand_list" | sed -n '$=')
    echo "$fbar_expand_list"
    return "$fbar_expand_list_sum"
}

#@brief 从扩展列表中取出值
#@param 扩展列表
#@param 需要取出值的序号
#@return 返回扩展列表
function expand_list_get {
    echo "$1" | sed -n "$2p"
}

#@brief 遍历扩展列表
#@param 扩展列表
#@param 起始序号
#@param 结束序号
#@param 回调函数($1:值 $2:序号 $3:私有参数)
#@param 私有参数
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function expand_list_foreach {
    local fbar_expand_list=$1
    local fbar_begin=$2
    local fbar_end=$3
    local fbar_hook=$4
    local fbar_args=$5
    local fbar_result=0
    while [ "$fbar_begin" -le "$fbar_end" ];do
        local fbar_next=$(expand_list_get "$fbar_expand_list" "$fbar_begin")
        eval "${fbar_hook} \"${fbar_next}\" \"${fbar_begin}\" \"${fbar_args}\""
        fbar_result="$?"
        if [ "$fbar_result" != "0" ];then
            return "$fbar_result"
        fi
        fbar_begin=$[ "$fbar_begin" + 1 ]
    done
    return 0
}