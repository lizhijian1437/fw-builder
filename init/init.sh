#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#请勿手动使用该脚本

. ${FBAU_PF_SCRIPTS}/base.sh
. ${FBAU_PF_SCRIPTS}/parser.sh

export FBAU_PF_INIT="${FBAU_PF_ROOT}/init"
export FBAU_PF_STAGING="${FBAU_PF_INIT}/staging"
fbar_pf_patch="${FBAU_PF_INIT}/patch"

mkdir -p ${FBAU_PF_STAGING}

if [ ! -f "${FBAU_PF_BIN}/jshn" ] || [ ! -f "${FBAU_PF_SCRIPTS}/jshn.sh" ];then
    mkdir -p ${FBAU_PF_BIN}
    #json-c编译
    cd ${FBAU_PF_INIT}/json-c
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make;make install
    #libubox编译
    cp -f ${fbar_pf_patch}/libubox/* ${FBAU_PF_INIT}/libubox
    cd ${FBAU_PF_INIT}/libubox
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make;make install
    cp -f ${FBAU_PF_STAGING}/bin/jshn ${FBAU_PF_BIN}
    cp -f ${FBAU_PF_STAGING}/share/libubox/jshn.sh ${FBAU_PF_SCRIPTS}
    chmod 755 ${FBAU_PF_SCRIPTS}/jshn.sh
fi

if [ ! -f "${FBAU_PF_BIN}/opkg" ];then
    #opkg编译
    cp -rf ${fbar_pf_patch}/opkg/* ${FBAU_PF_INIT}/opkg
    cd ${FBAU_PF_INIT}/opkg
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make;make install
    cp -f ${FBAU_PF_STAGING}/bin/opkg-cl ${FBAU_PF_BIN}/opkg
fi




