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
    export FBAU_IPK_INSTALL_DIR="${FBAU_NODE_BUILD_DIR}/ipk_install"
    local fbar_partiton=$(fbfu_fbc_parse "FIRMWARE_OUTPUT" "${FBAR_TEMPLATE}/config/fw_build.n")
    if [ -f "$fbar_partition" ];then
        rm -rf "$fbar_partition"
    fi
    if [ -d "$FBAU_PACKAGE_OUT" ];then
        rm -rf $FBAU_PACKAGE_OUT
    fi
    mkdir -p $FBAU_PACKAGE_OUT
    if [ -d "$FBAU_ROOTFS_ROOT" ];then
        rm -rf $FBAU_ROOTFS_ROOT
    fi
    mkdir -p $FBAU_ROOTFS_ROOT
    if [ -d "$FBAU_IPK_INSTALL_DIR" ];then
        rm -rf $FBAU_IPK_INSTALL_DIR
    fi
    mkdir -p $FBAU_IPK_INSTALL_DIR
}

function fbar_king_env {
    export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
}

function fbar_tl_king {
    if [ "$1" == "INIT" ];then
        fbar_king_init
    elif [ "$1" == "ENV" ];then
        fbar_king_env
    elif [ "$1" == "START" ];then
        if [ "$FBAU_DEFAULT_ARCH" == "" ];then
            fbfr_search_arch
        fi
        fbfu_fbc_module "opkg_rmpkg" "${FBAR_TEMPLATE}/config/opkg.n"
        fbfu_fbc_module "opkg_install" "${FBAR_TEMPLATE}/config/opkg.n"
        fbfu_fbc_module "fw_build" "${FBAR_TEMPLATE}/config/fw_build.n"
    fi
}

function fbar_attendant_env {
    export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
    export FBAU_IPK_WORKDIR="${FBAU_NODE_BUILD_DIR}/ipk"
    export FBAU_IPK_ROOT="${FBAU_IPK_WORKDIR}/ipk_build"
    if [ "$FBAU_DEFAULT_ARCH" == "" ];then
        fbfr_search_arch
    fi
    local fbar_ipk_out="${FBAU_IPK_WORKDIR}/ipk_out"
    local fbar_output=$(fbfu_fbc_parse "IPK_PACKAGE_OUT" "${FBAR_TEMPLATE}/config/ipk-build.n")
    local fbar_cache=$(fbfu_fbc_parse "IPK_CACHE")
    fbar_ipk_rebuild="true"
    if [ "$fbar_cache" == "true" ] && [ -f "${fbar_ipk_out}/ipk_build_ok" ];then
        fbar_ipk_rebuild="false"
        mkdir -p "$fbar_output"
        if [ -d "$fbar_output" ];then
            cp ${fbar_ipk_out}/*.ipk "$fbar_output"
            fbfu_info "[${FBAU_CURRENT_NODE_NAME}]CACHE PACKAGE"
        else
            fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]${fbar_output} not exist"
        fi
    else
        if [ -d "$FBAU_IPK_WORKDIR" ];then
            rm -rf $FBAU_IPK_WORKDIR
        fi
    fi
    mkdir -p $FBAU_IPK_WORKDIR
    mkdir -p $FBAU_IPK_ROOT
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