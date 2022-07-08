#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#pframe的绝对路径
export FBAU_PF_ROOT=$(dirname $(readlink -f $0))
export FBAU_PF_SCRIPTS="${FBAU_PF_ROOT}/scripts"
export FBAU_PF_BIN="${FBAU_PF_ROOT}/bin"
fbar_plugin_path="${FBAU_PF_ROOT}/plugins"

if [ "$PATH" == "" ];then
    export PATH="${FBAU_PF_BIN}"
else
    export PATH="${PATH}:${FBAU_PF_BIN}"
fi

. ${FBAU_PF_SCRIPTS}/base.sh

#初始化pframe环境
${FBAU_PF_ROOT}/init/init.sh
if [ "$?" != "0" ];then
    fbfu_error "$0: environment init failed"
    exit 1
fi

fbar_work=$(pwd)

. ${FBAU_PF_SCRIPTS}/jshn.sh
. ${FBAU_PF_SCRIPTS}/parser.sh

fbar_usage="Usage: $0 [ -f custom config ] [ -p plugin ] [ -t temp directory ]"

while getopts :f:p:t: opt
do
    case "$opt" in
        f) 
            export FBAU_CUSTOM_CONFIG=$(fbfu_convert_relative_path "$fbar_work" "$OPTARG")
            ;;
        p)
            export FBFU_EXEC_PLUGIN_NAME=$OPTARG
            fbar_plugin_exec="${fbar_plugin_path}/$OPTARG/exec.sh"
            ;;
        t)
            export FBAU_TEMP_DIR=$(fbfu_convert_relative_path "$fbar_work" "$OPTARG")
            ;;
        *) 
            echo "$fbar_usage"
            exit 1
            ;;
    esac
done

if [ ! -f "$FBAU_CUSTOM_CONFIG" ];then
    fbfu_error "$0: custom config [${FBAU_CUSTOM_CONFIG}] not found"
    exit 1
fi

if [ ! -f "$fbar_plugin_exec" ];then
    fbfu_error "$0: plugin [${FBFU_EXEC_PLUGIN_NAME}] not found"
    exit 1
fi

mkdir -p "$FBAU_TEMP_DIR"

$fbar_plugin_exec