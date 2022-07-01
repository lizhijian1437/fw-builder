#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#pframe的绝对路径
export FBAU_PF_ROOT=$(dirname $(readlink -f $0))
export FBAU_PF_SCRIPTS="${FBAU_PF_ROOT}/scripts"
export FBAU_PF_BIN="${FBAU_PF_ROOT}/bin"
if [ "$PATH" == "" ];then
    export PATH="${FBAU_PF_BIN}"
else
    export PATH="${PATH}:${FBAU_PF_BIN}"
fi

. ${FBAU_PF_SCRIPTS}/base.sh

#初始化pframe环境
${FBAU_PF_ROOT}/init/init.sh
if [ "$?" != "0" ];then
    exit 1
fi

. ${FBAU_PF_SCRIPTS}/jshn.sh
. ${FBAU_PF_SCRIPTS}/parser.sh
