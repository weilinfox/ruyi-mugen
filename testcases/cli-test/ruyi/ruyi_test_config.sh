#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #########################################
# @Author    :   weilinfox
# @Contact   :   caiweilin@iscas.ac.cn
# @Date      :   2024/03/05
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk config file test
# #########################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    cfg_d=`get_ruyi_config_dir`
    cfg_f="$cfg_d"/config.toml
    cc_dir=`get_ruyi_dir`/packages-index
    cc_td=/tmp/ruyi_config_test

    [ ! -d "$cfg_d" ] && mkdir -p $cfg_d
    [ -d "$cc_td" ] && rm -rf "$cc_td"

    cat >"$cfg_f" <<EOF
[repo]
local = "$cc_td"
EOF
    ruyi update
    CHECK_RESULT $? 0 0 "Check ruyi update failed"
    [ -d "$cc_td" ]
    CHECK_RESULT $? 0 0 "Check ruyi local failed"
    [ -d "$cc_dir" ]
    CHECK_RESULT $? 0 1 "Check ruyi orig local failed"
    rm -rf "$cc_td"

    wr=wrong_magic
    cat >"$cfg_f" <<EOF
[repo]
remote = "https://$wr"
EOF
    ruyi update 2>&1 | grep "$wr"
    CHECK_RESULT $? 0 0 "Check ruyi remote failed"
    cat >"$cfg_f" <<EOF
[repo]
branch = "$wr"
EOF
    ruyi update 2>&1 | grep "$wr"
    CHECK_RESULT $? 0 0 "Check ruyi branch failed"

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

