#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#depend: base.sh

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
        fbar_line=$(fbfu_slim "$fbar_line")
        if [ "$fbar_line" == "" ];then
            continue
        fi
        $fbar_hook "$fbar_line" "$fbar_args"
        fbar_result=$?
        if [ "$fbar_result" !=  "0" ];then
            return 1
        fi
    done < $fbar_file
    return 0
}



