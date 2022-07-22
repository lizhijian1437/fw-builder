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
function fbfu_expand_list_init {
    local fbar_expand_list=$(echo "$1" | awk 'BEGIN{RS="|";} { print $0 }')
    local fbar_expand_list_sum=$(echo "$fbar_expand_list" | sed -n '$=')
    echo "$fbar_expand_list"
    return "$fbar_expand_list_sum"
}

#@brief 从扩展列表中取出值
#@param 扩展列表
#@param 需要取出值的序号
#@return 返回扩展列表
function fbfu_expand_list_get {
    local fbar_value=$(echo "$1" | sed -n "$2p")
    fbar_value=$(fbfu_string_slim "$fbar_value")
    fbfu_convert_variable "$fbar_value"
}

#@brief 遍历扩展列表
#@param 扩展列表
#@param 起始序号
#@param 结束序号
#@param 回调函数($1:值 $2:序号 $3:私有参数)
#@param 私有参数
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function fbfu_expand_list_foreach {
    local fbar_expand_list=$1
    local fbar_begin=$2
    local fbar_end=$3
    local fbar_hook=$4
    local fbar_args=$5
    local fbar_result=0
    while [ "$fbar_begin" -le "$fbar_end" ];do
        local fbar_next=$(fbfu_expand_list_get "$fbar_expand_list" "$fbar_begin")
        $fbar_hook "$fbar_next" "$fbar_begin" "$fbar_args"
        fbar_result="$?"
        if [ "$fbar_result" != "0" ];then
            return "$fbar_result"
        fi
        fbar_begin=$[ "$fbar_begin" + 1 ]
    done
    return 0
}

#@brief 缓存链表初始化
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
function fbfu_cache_list_init {
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    eval ${fbar_list}\[0\]=0
    eval ${fbar_sum}=1
    eval ${fbar_end}=0
}

#@brief 缓存链表获取一个索引
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
#@param 全局变量(返回下一个可用索引)
function fbfu_cache_list_next {
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    local fbar_next=$4
    eval local fbar_end_index=\$\{${fbar_end}\}
    eval local fbar_end_val=\"\$\{${fbar_list}\[${fbar_end_index}\]\}\"
    if [ "$fbar_end_index" != "0" ];then
        eval ${fbar_end}=${fbar_end_val}
        eval ${fbar_next}=${fbar_end_index}
        return 
    fi
    eval local fbar_next_index=\$\{${fbar_sum}\}
    eval ${fbar_sum}=\$\[ ${fbar_next_index} \+ 1 \]
    eval ${fbar_next}=${fbar_next_index}
}

#@brief 缓存链表删除一个索引
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
#@param 缓存链表需要删除的索引
function fbfu_cache_list_del {
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    local fbar_del_index=$4
    eval local fbar_end_index=\$\{${fbar_end}\}
    eval ${fbar_list}\[${fbar_del_index}\]=${fbar_end_index}
    eval ${fbar_end}=${fbar_del_index}
}

#@brief 键值链表初始化
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
function fbfu_kvlist_init {
    fbfu_cache_list_init "$1" "$2" "$3"
}

#@brief 遍历键值链表
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
#@param 回调函数($1:键 $2:值 $3:索引 $4:私有参数)
#@param 私有参数
function fbfu_kvlist_foreach {
    local fbar_m=1
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    local fbar_hook=$4
    local fbar_args=$5
    local fbar_result=""
    eval local fbar_sum_value=\$\{${fbar_sum}\}
    while [ "$fbar_m" -lt "$fbar_sum_value" ];do
        eval local fbar_next=\$\{${fbar_list}\[${fbar_m}\]\}
        local fbar_key=$(echo "$fbar_next" | sed -e 's/|.*$//')
        if [ "$fbar_key" == "$fbar_next" ];then
            fbar_m=$[ "$fbar_m" + 1 ]
            continue
        fi
        local fbar_value=$(echo "$fbar_next" | sed -e 's/^.*|//')
        $fbar_hook "$fbar_key" "$fbar_value" "$fbar_m" "$fbar_args"
        fbar_result="$?"
        if [ "$fbar_result" != "0" ];then
            return "$fbar_result"
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
    done
    return 0
}

function __fbfr_kvlist_search_key {
    if [ "$1" == "$4" ];then
        return "$3"
    fi
    return 0
}

#@brief 键值链表设置键值对
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
#@param 需要设置的键
#@param 需要设置的值
function fbfu_kvlist_set {
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    local fbar_key=$4
    local fbar_value=$5
    __fbar_kvlist_next=0
    fbfu_kvlist_foreach "$fbar_list" "$fbar_sum" "$fbar_end" "__fbfr_kvlist_search_key" "$fbar_key"
    __fbar_kvlist_next=$?
    if [ "$__fbar_kvlist_next" != "0" ];then
        if [ "$fbar_value" == "" ];then
            fbfu_cache_list_del "$fbar_list" "$fbar_sum" "$fbar_end" "$__fbar_kvlist_next"
            return
        fi
    else
        if [ "$fbar_value" == "" ];then
            return
        fi
        fbfu_cache_list_next "$fbar_list" "$fbar_sum" "$fbar_end" "__fbar_kvlist_next"
    fi
    eval ${fbar_list}\[${__fbar_kvlist_next}\]=\"${fbar_key}\|${fbar_value}\"
}

#@brief 获取键值链表中设置的值
#@param 全局数组(缓存链表的对象)
#@param 全局变量(缓存链表的大小)
#@param 全局变量(缓存链表的最后一个空节点)
#@param 需要获取的键
function fbfu_kvlist_get {
    local fbar_list=$1
    local fbar_sum=$2
    local fbar_end=$3
    local fbar_key=$4
    __fbar_kvlist_next=0
    fbfu_kvlist_foreach "$fbar_list" "$fbar_sum" "$fbar_end" "__fbfr_kvlist_search_key" "$fbar_key"
    __fbar_kvlist_next=$?
    if [ "$__fbar_kvlist_next" != "0" ];then
        eval local fbar_next=\$\{${fbar_list}\[${__fbar_kvlist_next}\]\}
        echo "$fbar_next" | sed -e 's/^.*|//'
    fi
}

#@brief 强制新建文件
#@param 文件路径
#@param 需要获取的键
function fbfu_force_touch {
    local fbar_file=$1
    local fbar_path=${fbar_file%/*}
    if [ "$fbar_file" == "" ];then
        return 1
    fi
    if [ "$fbar_path" != "" ];then
        mkdir -p "$fbar_path" 1>/dev/null 2>&1
        if [ ! -d "$fbar_path" ];then
            return 1
        fi
    fi
    touch $fbar_file 1>/dev/null 2>&1
    return "$?"
}

function __fbfr_traverse_dir {
    local fbar_dir=$1
    local fbar_hook=$2
    local fbar_current=$3
    local fbar_begin=$4
    local fbar_finish=$5
    local fbar_next=$[ "$fbar_current" + 1 ]
    local fbar_file=""
    local fbar_result=0
    if [ "$fbar_finish" != "" ];then
        if [ "$fbar_current" -gt "$fbar_finish"  ];then
            return 0
        fi
    fi
    for fbar_file in $(ls -a $fbar_dir);do
        local fbar_exec="true"
        local fbar_file_abs="${fbar_dir}/${fbar_file}"
        if [ "$fbar_file" != "." ] && [ "$fbar_file" != ".." ];then
            if [ "$fbar_current" -ge "$fbar_begin" ];then
                $fbar_hook "$fbar_file_abs" "$fbar_current" "$6"
                fbar_result="$?"
                if [ "$fbar_result" != "0" ];then
                    return "$fbar_result"
                fi
            fi
        fi
        if [ "$fbar_file" != "." ] && [ "$fbar_file" != ".." ] && [ -d "$fbar_file_abs" ];then
            __fbfr_traverse_dir "$fbar_file_abs" "$fbar_hook" "$fbar_next" "$fbar_begin" "$fbar_finish" "$6"
            fbar_result="$?"
            if [ "$fbar_result" != "0" ];then
                return "$fbar_result"
            fi
        fi
    done
    return 0
}

#@brief 遍历文件夹
#@param 文件夹路径
#@param 回调函数($1:文件路径 $2:层数 $3:私有参数)
#@param 开始层数(默认是0)
#@param 结束层数(默认是遍历全部)
#@param 私有参数
#@param 需要获取的键
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function fbfu_traverse_dir {
    local fbar_dir=$1
    local fbar_hook=$2
    local fbar_begin=$3
    local fbar_finish=$4
    if [ "$fbar_dir" == "" ] || [ "$fbar_hook" == "" ];then
        return 1
    fi
    if [ "$fbar_begin" == "" ];then
        fbar_begin=0
    fi
    __fbfr_traverse_dir "$fbar_dir" "$fbar_hook" "0" "$fbar_begin" "$fbar_finish" "$5"
    return "$?"
}

#@brief 生成填充文件 
#@param 文件大小
#@param 十六进制填充符号(0xff)
#@param 输出目录
function fbfu_fill_file {
    local fbar_size=$1
    local fbar_symbol=$2
    local fbar_output=$3
    if [ "$fbar_size" == "" ] || [ "$fbar_symbol" == "" ] || [ "$fbar_output" == "" ];then
        return 1
    fi
    local fbar_convert=$(echo "$fbar_symbol" |  sed -e "s/^0x//g")
    dd if=/dev/zero of=$fbar_output bs=$fbar_size count=1 1>/dev/null 2>&1
    if [ -f "$fbar_output" ];then
        sed -i "s/\x00/\x${fbar_convert}/g" $fbar_output
        return 0
    else
        return 1
    fi
}