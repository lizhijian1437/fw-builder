#!/bin/bash

function fbfr_trace {
    local fbar_value=$(fbfu_fbc_parse "TRACE")
    if [ "$fbar_value" != "" ];then
        fbfu_fbc_gen_hook "$fbar_value"
        . $FBAU_HOOK "$1"
    fi
}

function fbfr_tl_king {
    fbfr_trace "$1"
}

function fbfr_tl_attendant {
    fbfr_trace "$1"
}