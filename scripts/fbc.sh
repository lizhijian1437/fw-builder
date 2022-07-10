#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#depend: base.sh
#请在fw-builder的环境中使用(build.sh)

#fbc接口，用于配置fw-builder内部参数,只能在env.sh中使用

#@brief fw-builder参数配置接口
#@param 需要设置的配置项
#@param 该配置项对应的值
#@param 0表示参数配置正常，1表示参数配置异常
function fbfu_fbc_set {
    local fbar_key=$1
    local fbar_value=$2
    fbfu_kvlist_set "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END" "$fbar_key" "$fbar_value"
    return $?
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
    __fbar_tmp_list=($FBAR_FBC_LIST)
    fbfu_kvlist_foreach "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END" "$1" "$2"
    return "$fbar_result"
}

