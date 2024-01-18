#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #############################################
# @Author    :   weilinfox
# @Contact   :   caiweilin@iscas.ac.cn
# @Date      :   2023/10/30
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk file location tests
# #############################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."
    export XDG_CACHE_HOME=~/.cache/ruyi_mugen_test
    export XDG_DATA_HOME=~/.local/share/ruyi_mugen_test
    export XDG_STATE_HOME=~/.local/state/ruyi_mugen_test
    mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
    xdg_ruyi_dir="$XDG_CACHE_HOME"/ruyi
    xdg_ruyi_data_dir="$XDG_DATA_HOME"/ruyi
    xdg_ruyi_state_dir="$XDG_STATE_HOME"/ruyi
    default_ruyi_dir=~/.cache/ruyi
    default_ruyi_data_dir=~/.local/share/ruyi
    default_ruyi_state_dir=~/.local/state/ruyi

    ruyi list
    CHECK_RESULT $? 0 0 "Check ruyi empty list failed"
    ruyi update
    CHECK_RESULT $? 0 0 "Check ruyi update failed"
    pkgcnt=$(ruyi list | grep -e "^* " | wc -l)
    CHECK_RESULT $pkgcnt 0 1 "Check ruyi list failed"
    ruyi list | grep "Package declares"
    CHECK_RESULT $? 0 1 "Check ruyi brief list failed"
    ruyi list --verbose | grep "Package declares"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose package failed"
    ruyi list --verbose | grep "Binary artifacts"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose artifacts failed"
    ruyi list --verbose | grep "Toolchain metadata"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose metadata failed"

    ruyi news list
    CHECK_RESULT $? 0 0 "Check ruyi news list failed"

    pkgnames=$(ruyi list | grep -e "^* toolchain" | cut -d'/' -f 2)
    for p in $pkgnames; do
        s=$(ruyi list | awk '/\* / {if (f==1) f=2} /./ {if (f==1) {print $0}} /\* toolchain\/'$p'/ {if (f==0) f=1}' | grep -e "^  -" | grep -v "no binary for current host")
        if [ ! -z "$s" ]; then
            pkgname="$p"
            break
        fi
    done
    if [ -z "$pkgname" ]; then
        LOG_INFO "No supported binary package found"
    else
        ruyi install $pkgname
        CHECK_RESULT $? 0 0 "Check ruyi install package failed"
        ruyi install $pkgname 2>&1 | grep "skipping already installed package"
        CHECK_RESULT $? 0 0 "Check ruyi install duplicate package failed"
    fi

    [ -d $xdg_ruyi_dir ]
    CHECK_RESULT $? 0 0 "Check ruyi create xdg based cache directory failed"
    [ -d $default_ruyi_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi create default cache directory failed"
    [ -d $xdg_ruyi_data_dir ]
    CHECK_RESULT $? 0 0 "Check ruyi create xdg based data directory failed"
    [ -d $default_ruyi_data_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi create default data directory failed"
    [ -d $xdg_ruyi_state_dir ]
    CHECK_RESULT $? 0 0 "Check ruyi create xdg based state directory failed"
    [ -d $default_ruyi_state_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi create default state directory failed"

    ruyi self uninstall --purge -y
    CHECK_RESULT $? 0 0 "Check ruyi xdg self purge failed"
    [ -d $xdg_ruyi_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi xdg purge cache dir exists failed"
    [ -d $xdg_ruyi_data_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi xdg purge data dir exists failed"
    [ -d $xdg_ruyi_state_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi xdg purge state dir exists failed"

    rm -rf "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME"
    export XDG_CACHE_HOME=
    export XDG_DATA_HOME=
    export XDG_STATE_HOME=

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

