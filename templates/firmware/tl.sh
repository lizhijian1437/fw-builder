#!/bin/bash

fbar_template_build="${FBAR_BUILD_DIR}/template"

function fbfr_search_arch {
    local fbar_release_file="${FBAU_ROOTFS_ROOT}/etc/openwrt_release"
    if [ -f "$fbar_release_file" ];then
        FBAU_DEFAULT_ARCH=$(fbfu_parse_kv "$fbar_release_file" "DISTRIB_ARCH" "=" | sed -e "s/'//g")
    fi
    if [ "$FBAU_DEFAULT_ARCH" != "" ];then
        fbfu_warn "DEFAULT_ARCH:${FBAU_DEFAULT_ARCH}"
    fi
}

function fbfr_FW_BUILD {
    local fbar_value="$1"
    local fbar_partition=$(fbfu_fbc_parse "FIRMWARE_OUTPUT" "${FBAR_TEMPLATE}/config/fw_build.n")
    if [ -f "$fbar_partition" ];then
        rm -rf "$fbar_partition"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "FW_BUILD_BEGIN"
    fi
    fbfu_fbc_module "fw_build" "${FBAR_TEMPLATE}/config/fw_build.n"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "FW_BUILD_FINISH"
    fi
}

function fbfr_OPKG_INSTALL {
    local fbar_value="$1"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "OPKG_INSTALL_BEGIN"
    fi
    fbfu_fbc_module "opkg_install" "${FBAR_TEMPLATE}/config/opkg.n"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "OPKG_INSTALL_FINISH"
    fi
}

function fbfr_OPKG_RMPKG {
    local fbar_value="$1"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "OPKG_RMPKG_BEGIN"
    fi
    fbfu_fbc_module "opkg_rmpkg" "${FBAR_TEMPLATE}/config/opkg.n"
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "OPKG_RMPKG_FINISH"
    fi
}

function fbfr_tl_king {
    if [ "$1" == "IN" ];then
        local fbar_value=""
        fbar_stage_args=$(fbfu_fbc_get "STAGE_ARGS")
        fbar_stage_args=$(fbfu_expand_list_init "$fbar_stage_args")
        FBAU_STAGE=$(fbfu_expand_list_get "$fbar_stage_args" "2")
        export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
        export FBAU_PACKAGE_OUT="${FBAU_NODE_BUILD_DIR}/out"
        export FBAU_ROOTFS_ROOT="${FBAU_NODE_BUILD_DIR}/rootfs"
        export FBAU_IPK_INSTALL_DIR="${FBAU_NODE_BUILD_DIR}/ipk_install"
        fbfu_fbc_set "TOOLCHAIN_BASE" "${FBAU_PROJECT}/toolchains"
        if [ "$FBAU_STAGE" == "" ];then
            if [ -d "$FBAU_PACKAGE_OUT" ];then
                rm -rf $FBAU_PACKAGE_OUT
            fi
            if [ -d "$FBAU_ROOTFS_ROOT" ];then
                rm -rf $FBAU_ROOTFS_ROOT
            fi
            if [ -d "$FBAU_IPK_INSTALL_DIR" ];then
                rm -rf $FBAU_IPK_INSTALL_DIR
            fi
        fi
        mkdir -p $FBAU_PACKAGE_OUT
        mkdir -p $FBAU_ROOTFS_ROOT
        mkdir -p $FBAU_IPK_INSTALL_DIR
    elif [ "$1" == "OUT" ];then
        export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
#搜索ARCH
        if [ "$FBAU_DEFAULT_ARCH" == "" ];then
            fbfr_search_arch
        fi
        fbar_value=$(fbfu_fbc_parse "TRACE")
#OPKG_RMPKG阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "OPKG_RMPKG" ];then
            fbfr_OPKG_RMPKG "$fbar_value"
        fi
#OPKG_INSTALL阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "OPKG_INSTALL" ];then
            fbfr_OPKG_INSTALL "$fbar_value"
        fi
#FW_BUILD阶段
        if [ "$FBAU_STAGE" == "" ] || [ "$FBAU_STAGE" == "OPKG_INSTALL" ];then
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

function fbfr_IPK_BUILD_clean {
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
    mkdir -p $FBAU_IPK_ROOT
}

function fbfr_IPK_BUILD {
    local fbar_value="$1"
    fbfr_IPK_BUILD_clean
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "IPK_BUILD_BEGIN"
    fi
    if [ "$fbar_ipk_rebuild" == "true" ];then
        fbfu_info "[${FBAU_CURRENT_NODE_NAME}]BUILD PACKAGE"
        fbfu_fbc_module "ipk_build" "${FBAR_TEMPLATE}/config/ipk-build.n"
    fi
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "IPK_BUILD_FINISH"
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
        export FBAU_NODE_BUILD_DIR="${fbar_template_build}/${FBAU_CURRENT_NODE_NAME}"
        export FBAU_IPK_WORKDIR="${FBAU_NODE_BUILD_DIR}/ipk"
        export FBAU_IPK_ROOT="${FBAU_IPK_WORKDIR}/ipk_build"
        if [ "$FBAU_STAGE" != "" ];then
            if [ "$FBAU_STAGE" != "IPK_BUILD" ];then
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
        fbfr_IPK_BUILD "$fbar_value"
    fi
}