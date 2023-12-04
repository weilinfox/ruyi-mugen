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
    export XDG_CACHE_HOME=~/.cache/test
    export XDG_DATA_HOME=~/.local/share/test
    mkdir $XDG_CACHE_HOME $XDG_DATA_HOME
    xdg_ruyi_dir="$XDG_CACHE_HOME"/ruyi
    xdg_ruyi_data_dir="$XDG_DATA_HOME"/ruyi
    default_ruyi_dir=~/.cache/ruyi
    default_ruyi_data_dir=~/.local/share/ruyi

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
    pkgname=$(ruyi list | grep -e "^* toolchain" | head -n 1 | cut -d'/' -f 2)
    ruyi install $pkgname
    CHECK_RESULT $? 0 0 "Check ruyi install package failed"
    ruyi install $pkgname 2>&1 | grep "skipping already installed package"
    CHECK_RESULT $? 0 0 "Check ruyi install duplicate package failed"

    [ -d $xdg_ruyi_dir ]
    CHECK_RESULT $? 0 0 "Check ruyi create xdg based cache directory failed"
    [ -d $default_ruyi_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi create default cache directory failed"
    [ -d $xdg_ruyi_data_dir ]
    CHECK_RESULT $? 0 0 "Check ruyi create xdg based data directory failed"
    [ -d $default_ruyi_data_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi create default data directory failed"

    ruyi self uninstall --purge -y
    CHECK_RESULT $? 0 0 "Check ruyi xdg self purge failed"
    [ -d $xdg_ruyi_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi xdg purge cache dir exists failed"
    [ -d $xdg_ruyi_data_dir ]
    CHECK_RESULT $? 0 1 "Check ruyi xdg purge data dir exists failed"

    rm -rf $XDG_CACHE_HOME
    rm -rf $XDG_DATA_HOME
    export XDG_CACHE_HOME=
    export XDG_DATA_HOME=

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

