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
# @Date      :   2023/11/28
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk device test
# #############################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    ruyi update
    expect >/dev/null <<EOF
        set timeout 10
        spawn ./ruyi device provision
        set i 0
        while {\$i < 10} {
            expect {
                "Continue? \(y/N\)" {
                    send "y\r"
                }
                "Choice? \(1-" {
                    send "1\r"
                }
                "Proceed? \(y/N\)" {
                    send "n\r"
                }
                eof {
                    catch wait result
                    exit [lindex \$result 3]
                }
            }
        }
EOF
    CHECK_RESULT $? 0 1 "Check ruyi device provision failed"

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

