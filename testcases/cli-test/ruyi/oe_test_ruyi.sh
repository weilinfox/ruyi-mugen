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
# @Date      :   2023/10/24
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk common tests
# #############################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    ruyi
    CHECK_RESULT $? 0 1 "Check ruyi empty cmdline failed"
    ruyi 2>&1 |grep usage
    CHECK_RESULT $? 0 0 "Check ruyi empty cmdline help failed"
    ruyi -h | grep usage
    CHECK_RESULT $? 0 0 "Check ruyi help failed"
    ruyi list
    CHECK_RESULT $? 0 0 "Check ruyi empty list failed"
    [ -d $(get_ruyi_dir) ]
    CHECK_RESULT $? 0 0 "Check ruyi create cache directory failed"
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
    pkgname=$(ruyi list | grep -e "^* " | head -n 1 | cut -d' ' -f 2)
    ruyi install $pkgname
    CHECK_RESULT $? 0 0 "Check ruyi install package failed"
    ruyi install $pkgname 2>&1 | grep "skipping already installed package $pkgname"
    CHECK_RESULT $? 0 0 "Check ruyi install duplicate package failed"
    ruyi install name:$pkgname 2>&1 | grep "skipping already installed package $pkgname"
    CHECK_RESULT $? 0 0 "Check ruyi install duplicate package by name failed"

    ruyi list profiles
    CHECK_RESULT $? 0 0 "Check ruyi profile"
    proname=$(ruyi list profiles | head -n 1)
    ruyi venv --toolchain $pkgname $proname test-venv 2>&1 | grep "The virtual environment is now created."
    CHECK_RESULT $? 0 0 "Check ruyi venv install failed"
    [ -f ./test-venv/bin/ruyi-activate ]
    CHECK_RESULT $? 0 0 "Check ruyi venv activate file failed"
    oldps1="$PS1"
    source ./test-venv/bin/ruyi-activate
    echo "$PS1" | grep test-venv
    CHECK_RESULT $? 0 0 "Check activate ruyi venv PS1 failed"
    ruyi-deactivate
    [ "$oldps1" == "$PS1" ]
    CHECK_RESULT $? 0 0 "Check deactivate ruyi venv PS1 failed"
    rm -rf test-venv

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

