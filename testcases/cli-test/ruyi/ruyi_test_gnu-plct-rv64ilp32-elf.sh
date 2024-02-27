#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# ###################################################
# @Author    :   weilinfox
# @Contact   :   caiweilin@iscas.ac.cn
# @Date      :   2024/02/27
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk gnu-plct-rv64ilp32-elf test
# ###################################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    ruyi update
    ruyi install gnu-plct-rv64ilp32-elf
    if [[ "$?" != "0" ]]; then
        ruyi install gnu-plct-rv64ilp32-elf 2>&1 | grep 'no binary'
        if [[ "$?" == "0" ]]; then
            LOG_INFO "No binary for current host, skip testing"
        else
            LOG_ERROR "gnu-plct-rv64ilp32-elf installation failed"
        fi
        return 0
    fi

    ruyi venv -t gnu-plct-rv64ilp32-elf --without-sysroot baremetal-rv64ilp32 /tmp/mugen_test_venv
    CHECK_RESULT $? 0 0 "Check ruyi venv creation failed"
    cat > test.c << EOF
long long add(long long *a, long long b) { return *a + b; }                                                                                                                                                                             
void check(int);                                                                                                                                                                                                                        
void checkSizes(void) { check(sizeof(int)); check(sizeof(long)); check(sizeof(long long)); check(sizeof(void *)); }
EOF
    CHECK_RESULT $? 0 0 "Check test.c creation failed"

    source /tmp/mugen_test_venv/bin/ruyi-activate

    riscv64-plct-elf-gcc -O2 -c -o test.o test.c
    CHECK_RESULT $? 0 0 "Check test.c compilation failed"

    riscv64-plct-elf-readelf -h test.o | grep 32
    CHECK_RESULT $? 0 0 "Check test.o 32bit failed"

    riscv64-plct-elf-objdump -dw test.o | grep a0
    CHECK_RESULT $? 0 0 "Check test.o 64bit reg failed"

    ruyi-deactivate
    rm -f test.c test.o
    rm -rf /tmp/mugen_test_venv

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

