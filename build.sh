#!/bin/bash

#fbfu 公有函数
#fbfr 私有函数
#fbau 公有参数
#fbar 私有参数

fbar_root=$(dirname $(readlink -f $0))
fbar_bin="${fbar_root}/bin"
export FBAU_PROJECT=$(pwd)
export FBAU_SCRIPTS="${fbar_root}/scripts"

. ${FBAU_SCRIPTS}/base.sh

. ${fbar_root}/init/init.sh
if [ "$?" != "0" ];then
    fbfu_error "$0: environment init failed"
    exit 1
fi

if [ "$PATH" == "" ];then
    export PATH="$fbar_bin"
else
    export PATH="${PATH}:${fbar_bin}"
fi

. ${FBAU_SCRIPTS}/jshn.sh
. ${FBAU_SCRIPTS}/parser.sh
. ${FBAU_SCRIPTS}/fbc.sh

fbar_node_suffix="fwb.n"
fbar_template_suffix="tl.sh"
fbar_module_suffix="ml.sh"
FBAR_BUILD_DIR="${FBAU_PROJECT}/build"
FBAR_TEMP_DIR="${FBAR_BUILD_DIR}/tmp"
fbar_hook="${FBAR_BUILD_DIR}/tmp/__hook_sh"
fbar_main_node="${FBAU_PROJECT}/${fbar_node_suffix}"
fbar_nodes_dir="${FBAU_PROJECT}/nodes"
fbar_modules_dir="${fbar_root}/modules"
fbar_templates_dir="${fbar_root}/templates"
fbar_node_temp="${FBAR_TEMP_DIR}/node"
fbar_node_chain="${fbar_node_temp}/chain"

if [  ! -f "${fbar_main_node}" ];then
    fbfu_error "please provide ${fbar_main_node}"
    exit 1
fi

function fbfr_fbc_init {
    FBAR_FBC_LIST=()
    FBAR_FBC_LIST_SUM=1
    FBAR_FBC_END=0
    fbfu_kvlist_init "FBAR_FBC_LIST" "FBAR_FBC_LIST_SUM" "FBAR_FBC_END"
    fbfu_fbc_set "NPATH_BASE" "$fbar_nodes_dir"
    fbfu_fbc_set "MODULES_BASE" "$fbar_modules_dir"
    fbfu_fbc_set "TEMPLATES_BASE" "$fbar_templates_dir"
}

fbfr_fbc_init

function fbfr_node_search {
    local fbar_check_key=$(echo "$1" | grep "^NPATH_")
    if [ "$fbar_check_key" != "" ];then
        local fbar_search_file="$2/$4/${fbar_node_suffix}"
        if [ -f "$fbar_search_file" ];then
            echo "$fbar_search_file"
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

function fbfr_gen_hook {
    echo "$1" > $fbar_hook
    if [ "$?" != "0" ];then
        exit 1
    fi
}

function fbfr_handle_node {
    local fbar_m=0
    local fbar_value=""
    local fbar_next_node=$1
    local fbar_custom_path=${fbar_next_node%/*}
    local fbar_node_name=${fbar_custom_path##*/}
    if [ -f "${fbar_node_chain}/${fbar_node_name}" ];then
        fbfu_warn "NODE: ${fbar_node_name} repeat"
        return 0
    fi
    fbfu_info "NODE: ${fbar_node_name} start"
    fbar_value=$(fbfu_parse "$fbar_next_node" "TRACE_ON" "$FBAR_TEMP_DIR")
    if [ "$?" == "4" ];then
        fbfr_gen_hook "$fbar_value"
        . $fbar_hook "$fbar_custom_path" "START"
    fi
    touch "${fbar_node_chain}/${fbar_node_name}"
    FBAR_CURRENT_NODE="$fbar_next_node"
    if [ "$FBAR_TEMPLATE" != "" ];then
        if [ "$fbar_next_node" == "$fbar_main_node" ];then
            fbar_tl_king "ON"
        else
            fbar_tl_attendant "ON"
        fi
    fi
    local fbar_node_depend=($(fbfu_parse "$fbar_next_node" "DEPEND" "$FBAR_TEMP_DIR"))
    local fbar_rdsize=${#fbar_node_depend[@]}
    fbfu_info "NODE: ${fbar_node_name} --> ${fbar_node_depend[@]}"
    while [ "$fbar_m" -lt "$fbar_rdsize" ];do
        local fbar_next_depend=${fbar_node_depend[$fbar_m]}
        local fbar_next_depend_node=$(fbfu_fbc_foreach "fbfr_node_search" "$fbar_next_depend")
        if [ "$fbar_next_depend_node" == "" ];then
            fbfu_warn "NODE: ${fbar_next_depend} not exist"
        else
            fbfr_handle_node "$fbar_next_depend_node"
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
    done
    if [ "$FBAR_TEMPLATE" != "" ];then
        if [ "$fbar_next_node" == "$fbar_main_node" ];then
            fbar_tl_king "OFF"
        else
            fbar_tl_attendant "OFF"
        fi
    fi
    fbar_value=$(fbfu_parse "$fbar_next_node" "TRACE_OFF" "$FBAR_TEMP_DIR")
    if [ "$?" == "4" ];then
        fbfr_gen_hook "$fbar_value"
        . $fbar_hook "$fbar_custom_path" "STOP"
    fi
    return 0
}

function fbfr_template_search {
    local fbar_check_key=$(echo "$1" | grep "^TEMPLATES_")
    if [ "$fbar_check_key" != "" ];then
        local fbar_search_template="$2/$4"
        local fbar_template_sh="${fbar_search_template}/${fbar_template_suffix}"
        if [ -f "${fbar_template_sh}" ];then
            . $fbar_template_sh
            FBAR_TEMPLATE="$fbar_search_template"
            return 1
        else
            return 0
        fi
    else
        return 0
    fi
}

function fbfr_import_template {
    local fbar_value=$(fbfu_parse "$fbar_main_node" "TEMPLATE" "$FBAR_TEMP_DIR")
    if [ "$fbar_value" == "" ];then
        return
    fi
    fbfu_fbc_foreach "fbfr_template_search" "$fbar_value"
}

function fbfr_node_frame {
    if [ -d "$fbar_node_temp" ];then
        rm -rf "$fbar_node_temp"
        if [ "$?" != "0" ];then
            fbfu_error "remove ${fbar_node_temp} error"
            exit 1
        fi
    fi
    mkdir -p $fbar_node_chain
    fbfr_import_template
    fbfr_handle_node "$fbar_main_node"
}

fbfr_node_frame