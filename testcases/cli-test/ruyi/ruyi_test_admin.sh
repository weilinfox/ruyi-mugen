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
# @Date      :   2023/11/30
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk admin test
# #############################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    test_file=ruyi_test_admin.sh
    ruyi admin checksum $test_file
    CHECK_RESULT $? 0 0 "Check ruyi admin manifest failed"
    ruyi admin checksum --format json $test_file
    CHECK_RESULT $? 0 0 "Check ruyi admin manifest json format failed"
    ruyi admin checksum --format toml $test_file
    CHECK_RESULT $? 0 0 "Check ruyi admin manifest toml format failed"
    ruyi admin checksum --format toml $test_file >test.toml
    ruyi admin format-manifest ./test.toml
    CHECK_RESULT $? 0 0 "Check ruyi admin format-manifest toml format failed"
    rm test.toml

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

