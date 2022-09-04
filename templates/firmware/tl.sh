#!/bin/bash

function fbfr_search_arch {
    local fbar_release_file="${FBAU_ROOTFS_ROOT}/etc/openwrt_release"
    if [ -f "$fbar_release_file" ];then
        export FBAU_DEFAULT_ARCH=$(fbfu_parse_kv "$fbar_release_file" "DISTRIB_ARCH" "=" | sed -e "s/'//g")
    fi
    if [ "$FBAU_DEFAULT_ARCH" != "" ];then
        fbfu_info "DEFAULT_ARCH:${FBAU_DEFAULT_ARCH}"
    fi
}

function fbfr_FW_BUILD {
    local fbar_value="$1"
    local fbar_partition=$(fbfu_fbc_parse "FIRMWARE_OUTPUT" "${FBAR_TEMPLATE}/config/fw_build.n")
    local fbar_partition_table=$(fbfu_fbc_parse "PARTITION" "${FBAR_TEMPLATE}/config/fw_build.n")
    if [ -f "$fbar_partition" ];then
        rm -rf "$fbar_partition"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "FW_BUILD_BEGIN"
    fi
    if [ "$fbar_partition_table" != "" ];then
        fbfu_fbc_module "fw_build" "${FBAR_TEMPLATE}/config/fw_build.n"
    else
        fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]PARTITION NOT PROVIDED, NO IMAGE BUILD"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "FW_BUILD_FINISH"
    fi
}

function fbfr_PKG_INSTALL {
    local fbar_value="$1"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "PKG_INSTALL_BEGIN"
    fi
    if [ "$FBAU_DEFAULT_ARCH" != "" ];then
        fbfu_fbc_module "opkg_install" "${FBAR_TEMPLATE}/config/opkg.n"
    else
        fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]ARCH NOT PROVIDED, NO PACKAGE INSTALL"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "PKG_INSTALL_FINISH"
    fi
}

function fbfr_RMPKG {
    local fbar_value="$1"
    local fbar_ipk_version=$(fbfu_fbc_parse "PACKAGE_VERSION" "${FBAR_TEMPLATE}/config/ipk-build.n")
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "RMPKG_BEGIN"
    fi
    if [ "$FBAU_DEFAULT_ARCH" != "" ];then
        fbfu_fbc_module "opkg_rmpkg" "${FBAR_TEMPLATE}/config/opkg.n"
    else
        fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]ARCH NOT PROVIDED, NO PACKAGE REMOVE"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "RMPKG_FINISH"
    fi
}

function fbfr_tl_king {
    local fbar_value=""
    if [ "$1" == "IN" ];then
        local fbar_arch=$(fbfu_fbc_parse "ARCH" "${FBAR_TEMPLATE}/config/opkg.n")
        fbar_stage_args=$(fbfu_fbc_get "STAGE_ARGS")
        fbar_stage_args=$(fbfu_expand_list_init "$fbar_stage_args")
        FBAU_STAGE=$(fbfu_expand_list_get "$fbar_stage_args" "2")
        export FBAU_PACKAGE_OUT="${FBAU_CURRENT_NODE_BUILD}/out"
        export FBAU_ROOTFS_ROOT="${FBAU_CURRENT_NODE_BUILD}/rootfs"
        export FBAU_IPK_TO_ROOTFS="${FBAU_CURRENT_NODE_BUILD}/ipk_install"
        fbfu_fbc_set "TOOLCHAIN_BASE" "${FBAU_PROJECT}/toolchains"
        if [ "$fbar_arch" != "" ];then
            export FBAU_DEFAULT_ARCH="$fbar_arch"
            fbfu_info "DEFAULT_ARCH:${FBAU_DEFAULT_ARCH}"
        fi
        if [ "$FBAU_STAGE" == "" ];then
            if [ -d "$FBAU_PACKAGE_OUT" ];then
                rm -rf $FBAU_PACKAGE_OUT
            fi
            if [ -d "$FBAU_ROOTFS_ROOT" ];then
                rm -rf $FBAU_ROOTFS_ROOT
            fi
            if [ -d "$FBAU_IPK_TO_ROOTFS" ];then
                rm -rf $FBAU_IPK_TO_ROOTFS
            fi
        fi
        mkdir -p $FBAU_PACKAGE_OUT
        mkdir -p $FBAU_ROOTFS_ROOT
        mkdir -p $FBAU_IPK_TO_ROOTFS
        fbar_value=$(fbfu_fbc_parse "TRACE")
        if [ "$?" == "4" ];then
            fbfu_fbc_gen_hook "$fbar_value"
            . $FBAU_HOOK "INIT"
        fi
    elif [ "$1" == "OUT" ];then
#搜索ARCH
        if [ "$FBAU_DEFAULT_ARCH" == "" ];then
            fbfr_search_arch
        fi
        fbar_value=$(fbfu_fbc_parse "TRACE")
        if [ "$?" != "4" ];then
            fbar_value=""
        fi
#RMPKG阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "RMPKG" ];then
            fbfu_info "RMPKG"
            fbfr_RMPKG "$fbar_value"
        fi
#PKG_INSTALL阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "PKG_INSTALL" ];then
            fbfu_info "PKG_INSTALL"
            fbfr_PKG_INSTALL "$fbar_value"
        fi
#FW_BUILD阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "FW_BUILD" ];then
            fbfu_info "FW_BUILD"
            fbfr_FW_BUILD "$fbar_value"
        fi
    fi
}

function __fbfr_search_toolchain {
    local fbar_check_key=$(echo "$1" | grep "^TOOLCHAIN_")
    if [ "$fbar_check_key" != "" ];then
        local fbar_search_toolchain="$2/$4"
        if [ -f "${fbar_search_toolchain}/toolchain.sh" ];then
            export FBAU_TOOLCHAIN_DIR="$fbar_search_toolchain"
            . ${fbar_search_toolchain}/toolchain.sh
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

function fbfr_PKG_BUILD_clean {
    local fbar_ipk_out="${FBAU_IPK_WORKDIR}/ipk_out"
    local fbar_output=$(fbfu_fbc_parse "IPK_PACKAGE_OUT" "${FBAR_TEMPLATE}/config/ipk-build.n")
    local fbar_cache=$(fbfu_fbc_parse "PKG_CACHE")
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
    mkdir -p $FBAU_IPK_ROOT
}

function fbfr_PKG_BUILD {
    local fbar_value="$1"
    local fbar_ipk_version=$(fbfu_fbc_parse "PACKAGE_VERSION" "${FBAR_TEMPLATE}/config/ipk-build.n")
    fbfr_PKG_BUILD_clean
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "PKG_BUILD_BEGIN"
    fi
    if [ "$fbar_ipk_version" != "" ];then
        if [ "$fbar_ipk_rebuild" == "true" ];then
            fbfu_info "[${FBAU_CURRENT_NODE_NAME}]BUILD PACKAGE"
            fbfu_fbc_module "ipk_build" "${FBAR_TEMPLATE}/config/ipk-build.n"
        fi
    else
        fbfu_warn "[${FBAU_CURRENT_NODE_NAME}]NO VERSION IS PROVIDED, NO PACKAGE IS MADE"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "PKG_BUILD_FINISH"
    fi
}

function fbfr_check_ipk_build_vaild {
    local fbar_m=3
    local fbar_next=$(fbfu_expand_list_get "$fbar_stage_args" "$fbar_m")
    while [ "$fbar_next" != "" ];do
        if [ "$fbar_next" == "$FBAU_CURRENT_NODE_NAME" ];then
            return 1
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
        fbar_next=$(fbfu_expand_list_get "$fbar_stage_args" "$fbar_m")
    done
    return 0
}

function fbfr_tl_attendant {
    if [ "$1" == "OUT" ];then
        local fbar_value=""
        local fbar_toolchain=$(fbfu_fbc_parse "TOOLCHAIN")
        export FBAU_IPK_WORKDIR="${FBAU_CURRENT_NODE_BUILD}/ipk"
        export FBAU_IPK_ROOT="${FBAU_IPK_WORKDIR}/ipk_build"
        if [ "$FBAU_STAGE" != "" ];then
            if [ "$FBAU_STAGE" != "PKG_BUILD" ];then
                return
            else
                fbfr_check_ipk_build_vaild
                if [ "$?" != "1" ];then
                    return
                fi
            fi
        fi
#搜索ARCH
        if [ "$FBAU_DEFAULT_ARCH" == "" ];then
            fbfr_search_arch
        fi
#搜索工具链
        if [ "$fbar_toolchain" != "" ];then
            fbfu_fbc_foreach " __fbfr_search_toolchain" "$fbar_toolchain"
        fi
#IPK_BUILD阶段
        fbar_value=$(fbfu_fbc_parse "TRACE")
        if [ "$?" != "4" ];then
            fbar_value=""
        fi
        fbfr_PKG_BUILD "$fbar_value"
    fi
}