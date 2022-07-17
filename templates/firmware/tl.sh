#!/bin/bash

fbar_template_build="${FBAR_BUILD_DIR}/template"

function fbfr_search_arch {
    local fbar_release_file="${FBAU_ROOTFS_ROOT}/etc/openwrt_release"
    if [ -f "$fbar_release_file" ];then
        FBAU_DEFAULT_ARCH=$(fbfu_parse_kv "$fbar_release_file" "DISTRIB_ARCH" "=" | sed -e "s/'//g")
    fi
    if [ "$FBAU_DEFAULT_ARCH" == "" ];then
        fbfu_warn "unKnown arch"
    fi
}

function fbar_king_init {
    export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
    export FBAU_PACKAGE_OUT="${FBAU_NODE_BUILD_DIR}/out"
    export FBAU_ROOTFS_ROOT="${FBAU_NODE_BUILD_DIR}/rootfs"
    if [ -d "$FBAU_PACKAGE_OUT" ];then
        rm -rf $FBAU_PACKAGE_OUT
    fi
    mkdir -p $FBAU_PACKAGE_OUT
    if [ -d "$FBAU_ROOTFS_ROOT" ];then
        rm -rf $FBAU_ROOTFS_ROOT
    fi
    mkdir -p $FBAU_ROOTFS_ROOT
}

function fbar_tl_king {
    if [ "$1" == "INIT" ];then
        fbar_king_init
    fi
}

function fbar_attendant_env {
    export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
    export FBAU_IPK_DIR="${FBAU_NODE_BUILD_DIR}/ipk"
    if [ "$FBAU_DEFAULT_ARCH" == "" ];then
        fbfr_search_arch
    fi
    local fbar_ipk_out="${FBAU_IPK_DIR}/__ipk_out"
    local fbar_out=$(fbfu_fbc_parse "IPK_PACKAGE_OUT" "${FBAR_TEMPLATE}/config/ipk-build.n")
    local fbar_cache=$(fbfu_fbc_parse "IPK_CACHE")
    fbar_ipk_rebuild="true"
    if [ "$fbar_cache" == "true" ] && [ -f "${fbar_ipk_out}/__ipk_build_ok" ];then
        fbar_ipk_rebuild="false"
        mkdir -p "$fbar_out"
        if [ -d "$fbar_out" ];then
            cp ${fbar_ipk_out}/*.ipk "$fbar_out"
            fbfu_info "[${FBAU_CURRENT_NODE_NAME}]CACHE PACKAGE"
        else
            fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]${fbar_out} not exist"
        fi
    else
        if [ -d "$FBAU_IPK_DIR" ];then
            rm -rf $FBAU_IPK_DIR
        fi
    fi
    mkdir -p $FBAU_IPK_DIR
}

function fbar_tl_attendant {
    if [ "$1" == "ENV" ];then
        fbar_attendant_env
    elif [ "$1" == "START" ];then
        if [ "$fbar_ipk_rebuild" == "true" ];then
            fbfu_fbc_module "ipk_build" "${FBAR_TEMPLATE}/config/ipk-build.n"
        fi
    fi
}