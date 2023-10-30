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
    ruyi | grep usage
    CHECK_RESULT $? 0 1 "Check ruyi empty cmdline failed"
    ruyi -h | grep usage
    CHECK_RESULT $? 0 0 "Check ruyi help failed"
    ruyi list
    CHECK_RESULT $? 0 0 "Check ruyi empty list failed"
    [ -d $(get_ruyi_dir) ]
    CHECK_RESULT $? 0 0 "Check ruyi create cache directory failed"
    ruyi update
    CHECK_RESULT $? 0 0 "Check ruyi update failed"
    ruyi list | grep "Package declares"
    CHECK_RESULT $? 0 0 "Check ruyi list package failed"
    ruyi list | grep "Binary artifacts"
    CHECK_RESULT $? 0 0 "Check ruyi list artifacts failed"
    ruyi list | grep "Toolchain metadata"
    CHECK_RESULT $? 0 0 "Check ruyi list metadata failed"
    pkgname=$(ruyi list | grep -e "^## " | head -n 1 | awk '{last_word = $NF; sub(/.$/, "", last_word); print substr(last_word, 2, length(last_word) - 1)}')
    ruyi install $pkgname
    CHECK_RESULT $? 0 0 "Check ruyi install package failed"
    ruyi install $pkgname 2>&1 | grep "skipping already installed package $pkgname"
    CHECK_RESULT $? 0 0 "Check ruyi install duplicate package failed"
    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

