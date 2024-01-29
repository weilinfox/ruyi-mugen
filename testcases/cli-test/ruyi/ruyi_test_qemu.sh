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
# @Date      :   2023/12/04
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk qemu test
# #############################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    mkdir qemu_test
    cd qemu_test

    ruyi update

    pe=$(ruyi list | awk '/\* / {if (f==1) f=2} /./ {if (f==1) {print $0}} /\* emulator\/qemu-user-riscv-upstream/ {if (f==0) f=1}' | grep -e "^  -" | grep -v "no binary for current host")
    if [ -z "$pe" ]; then
        LOG_INFO "No qemu-user-riscv-upstream available for current host $(uname -m), skip"
        exit 0
    fi

    ruyi install gnu-plct qemu-user-riscv-upstream
    CHECK_RESULT $? 0 0 "Check ruyi toolchain install failed"
    ruyi venv -t gnu-plct -e qemu-user-riscv-upstream milkv-duo venv
    CHECK_RESULT $? 0 0 "Check ruyi venv creation failed"

    . venv/bin/ruyi-activate

    cat > hello_ruyi.c << EOF
#include <stdio.h>

int main()
{
    printf("hello, ruyi");

    return 0;
}
EOF

    riscv64-plct-linux-gnu-gcc hello_ruyi.c -o hello_ruyi.o
    CHECK_RESULT $? 0 0 "Check ruyi compilation failed"
    ruyi-qemu ./hello_ruyi.o | grep "hello, ruyi"
    CHECK_RESULT $? 0 0 "Check ruyi emulation failed"

    ruyi-deactivate
    cd ..
    rm -rf qemu_test

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

