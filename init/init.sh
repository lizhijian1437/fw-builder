#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

#请勿手动使用该脚本

export FBAU_PF_INIT="${fbar_root}/init"
export FBAU_PF_STAGING="${FBAU_PF_INIT}/staging"
fbar_pf_patch="${FBAU_PF_INIT}/patch"

mkdir -p ${FBAU_PF_STAGING}

#初始化所有submodule
cd $fbar_root
git submodule init
git submodule update
if [ "$?" != "0" ];then
    fbfu_error "git submodule update failed"
    exit 1
fi

if [ ! -f "${FBAU_BIN}/jshn" ] || [ ! -f "${FBAU_SCRIPTS}/jshn.sh" ];then
    mkdir -p ${FBAU_BIN}
    #json-c编译
    cd ${FBAU_PF_INIT}/json-c
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make -j8;make install
    #libubox编译
    cp -f ${fbar_pf_patch}/libubox/* ${FBAU_PF_INIT}/libubox
    cd ${FBAU_PF_INIT}/libubox
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make -j8;make install
    cp -f ${FBAU_PF_STAGING}/bin/jshn ${FBAU_BIN}
    cp -f ${FBAU_PF_STAGING}/share/libubox/jshn.sh ${FBAU_SCRIPTS}
    chmod 755 ${FBAU_SCRIPTS}/jshn.sh
fi

if [ ! -f "${FBAU_BIN}/opkg" ];then
    #opkg编译
    cp -rf ${fbar_pf_patch}/opkg/* ${FBAU_PF_INIT}/opkg
    cd ${FBAU_PF_INIT}/opkg
    cmake . -DCMAKE_INSTALL_PREFIX=${FBAU_PF_STAGING}
    make -j8;make install
    cp -f ${FBAU_PF_STAGING}/bin/opkg-cl ${FBAU_BIN}/opkg
fi

cd ${FBAU_PROJECT}




