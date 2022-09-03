#!/bin/bash

function fbfr_trace {
    local fbar_value=$(fbfu_fbc_parse "TRACE")
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "$1"
    fi
}

function fbfr_check_node_vaild {
    local fbar_m=2
    local fbar_next=$(fbfu_expand_list_get "$fbar_nodes_args" "$fbar_m")
    while [ "$fbar_next" != "" ];do
        if [ "$fbar_next" == "$FBAU_CURRENT_NODE_NAME" ];then
            return 1
        fi
        fbar_m=$[ "$fbar_m" + 1 ]
        fbar_next=$(fbfu_expand_list_get "$fbar_nodes_args" "$fbar_m")
    done
    return 0
}

function fbfr_tl_king {
    fbar_nodes_args=$(fbfu_fbc_get "NODES_ARGS")
    fbar_nodes_args=$(fbfu_expand_list_init "$fbar_nodes_args")
    if [ "$fbar_nodes_args" != "" ];then
        fbfr_check_node_vaild
        if [ "$?" != "1" ];then
            return
        fi
    fi
    fbfr_trace "$1"
}

function fbfr_tl_attendant {
    if [ "$fbar_nodes_args" != "" ];then
        fbfr_check_node_vaild
        if [ "$?" != "1" ];then
            return
        fi
    fi
    fbfr_trace "$1"
}