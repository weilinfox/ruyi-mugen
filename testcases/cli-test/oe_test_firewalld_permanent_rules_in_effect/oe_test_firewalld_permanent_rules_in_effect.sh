#!/usr/bin/bash

# Copyright (c) 2022. Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
####################################
#@Author        :   wangxiaorou
#@Contact       :   wangxiaorou@uniontech.com
#@Date          :   2022-12-12
#@License       :   Mulan PSL v2
#@Desc          :   Permanent firewalld rules in effect
#####################################

source ${OET_PATH}/libs/locallibs/common_lib.sh

function run_test() {
    LOG_INFO "Start to run test."
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --state")" "running" 0 "firewalld.service not running"
    RichRule='rule family="ipv6" port port="11" protocol="tcp" mark set=11/11'
    P_SSH_CMD --node 2 --cmd "firewall-cmd --remove-rich-rule='${RichRule}'"
    P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --remove-rich-rule='${RichRule}'"
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --list-rich-rules" |grep -v ^$)" "" 0 "default runtime firewall rich rule check fail"
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --list-rich-rules" |grep -v ^$)" "" 0 "default permanent firewall rich rule check fail"

    P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --add-rich-rule='${RichRule}'"
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --list-rich-rules" |grep -v ^$)" "" 0 "add permanent firewall rich rule, runtime firewall rich rule check fail"
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --list-rich-rules" |grep -v ^$)" "${RichRule}" 0 "add permanent firewall rich rule, permanent firewall rich rule check fail"

    REMOTE_REBOOT 2 15
    sleep 30
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --list-rich-rules" |grep -v ^$)" "${RichRule}" 0 "after reboot, runtime firewall rich rule check fail"
    CHECK_RESULT "$(P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --list-rich-rules" |grep -v ^$)" "${RichRule}" 0 "after reboot, permanent firewall rich rule check fail"
    LOG_INFO "End to run test."
}

function post_test() {
    LOG_INFO "Start to restore the test environment."
    P_SSH_CMD --node 2 --cmd "firewall-cmd --remove-rich-rule='${RichRule}'"
    P_SSH_CMD --node 2 --cmd "firewall-cmd --permanent --remove-rich-rule='${RichRule}'"
    LOG_INFO "End to restore the test environment."
}

main "$@"
