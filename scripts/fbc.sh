#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#depend: base.sh
#请在fw-builder的环境中使用(build.sh)

#fbc接口，用于配置fw-builder内部参数

#@brief fw-builder参数配置接口
#@param 需要设置的配置项
#@param 该配置项对应的值
#@param 0表示参数配置正常，1表示参数配置异常
function fbfu_fbc_set {
    local fbar_key=$1
    local fbar_value=$2
    fbfu_kvlist_set "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END" "$fbar_key" "$fbar_value"
    return "$?"
}

#@brief fw-builder配置获取接口
#@param 需要获取的配置项
#@param 0表示配置获取正常，1表示获取配置异常
function fbfu_fbc_get {
    local fbar_key=$1
    local fbar_result=0
    local fbar_value=$(fbfu_kvlist_get "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END" "$fbar_key")
    fbar_result=$?
    echo "$fbar_value"
    return "$fbar_result"
}

#@brief fw-builder配置遍历接口
#@param 需要获取的配置项
#@param 回调函数($1:键 $2:值 $3:索引 $4:私有参数)
#@param 私有参数
#@return 若回调函数返回非0值，则会停止遍历，并且返回该值，否则会返回0
function fbfu_fbc_foreach {
    fbfu_kvlist_foreach "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END" "$1" "$2"
    return "$?"
}

function fbfr_module_search {
    local fbar_check_key=$(echo "$1" | grep "^MODULES_")
    if [ "$fbar_check_key" != "" ];then
        local fbar_search_module="$2/$4"
        if [ -f "${fbar_search_module}/${FBAR_MODULE_SUFFIX}" ];then
            echo "$fbar_search_module"
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

#@brief fw-builder模块调用接口
#@param 模块名
#@param 配置路径（默认是当前配置）
#@return 返回模块调用结果
function fbfu_fbc_module {
    local fbar_module=$(fbfu_fbc_foreach "fbfr_module_search" "$1")
    local fbar_config="$2"
    if [ ! -f "$fbar_config" ];then
        fbar_config="${FBAU_CURRENT_NODE}/${FBAR_NODE_SUFFIX}"
    fi
    if [ "$fbar_module" != "" ];then
        eval ${fbar_module}/${FBAR_MODULE_SUFFIX} \"${fbar_config}\" \"${FBAR_TEMP_DIR}\" \"${fbar_module}\"
        return "$?"
    else
        return 1
    fi
}

