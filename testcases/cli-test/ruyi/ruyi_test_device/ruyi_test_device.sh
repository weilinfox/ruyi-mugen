#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #############################################
# @Author       :   KotorinMinami
# @Contributor  :   weilinfox
# @Contact      :   huangshuo4@gmail.com
# @Date         :   2023/11/28
# @License      :   Mulan PSL v2
# @Desc         :   ruyisdk device smoke test
# #############################################

source "./common/device_lib.sh"
source "../common/common_lib.sh"

EXECUTE_T=1440m

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    mkdir /tmp/ruyi_device
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    ruyi update

    recursion_run ''
    CHECK_RESULT $? 0 0 "Check recursion run failed"

    ls_output=($(ls /tmp/ruyi_device/output*))
    for file in ${ls_output[@]}
    do
        test_res $file
        CHECK_RESULT $? 0 0 "Check file $file failed"
    done

    rm -rf /tmp/ruyi_device/test
    tar zcf "${OET_PATH}"/logs/ruyi/ruyi_test_device/$(date +'%Y-%m-%d-%H:%M:%S').tar.gz /tmp/ruyi_device
    CHECK_RESULT $? 0 0 "Backup temp log file $file failed"

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    rm -rf /tmp/ruyi_device
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"
