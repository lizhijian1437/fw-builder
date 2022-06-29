#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#pframe的绝对路径
export FBAU_PF_ROOT=$(dirname $(readlink -f $0))
export FBAU_PF_SCRIPTS="${FBAU_PF_ROOT}/scripts"
export FBAU_PF_BIN="${FBAU_PF_ROOT}/bin"

. ${FBAU_PF_SCRIPTS}/base.sh
. ${FBAU_PF_SCRIPTS}/parser.sh

#初始化pframe环境
${FBAU_PF_ROOT}/init/init.sh

