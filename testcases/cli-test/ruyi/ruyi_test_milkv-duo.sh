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
# @Date      :   2024/10/10
# @License   :   Mulan PSL v2
# @Desc      :   milkv duo toolchains test
# ###################################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    if [[ "$(uname -m)" != "x86_64" ]]; then
        LOG_INFO "Not x86_64 host, skip test"
        return 0
    fi

    ruyi update
    ruyi install gnu-milkv-milkv-duo-bin gnu-milkv-milkv-duo-musl-bin gnu-milkv-milkv-duo-elf-bin

    ruyi venv -t gnu-milkv-milkv-duo-musl-bin -t gnu-milkv-milkv-duo-elf-bin --sysroot-from gnu-milkv-milkv-duo-musl-bin generic /tmp/mugen_test_venv0
    CHECK_RESULT $? 0 0 "Check ruyi venv0 creation failed"
    cat > test.c << EOF
int main() {return 0;}
EOF
    CHECK_RESULT $? 0 0 "Check test.c creation failed"

    source /tmp/mugen_test_venv0/bin/ruyi-activate

    riscv64-unknown-elf-gcc -O2 -o test.o test.c
    CHECK_RESULT $? 0 0 "Check test.c compilation elf failed"

    riscv64-unknown-linux-musl-cpp -O2 -o test.o test.c
    CHECK_RESULT $? 0 0 "Check test.c compilation musl failed"

    ruyi-deactivate

    ruyi venv -t gnu-milkv-milkv-duo-bin generic /tmp/mugen_test_venv1
    CHECK_RESULT $? 0 0 "Check ruyi venv1 creation failed"

    source /tmp/mugen_test_venv1/bin/ruyi-activate

    riscv64-unknown-linux-gnu-gcc -O2 -o test.o test.c
    CHECK_RESULT $? 0 0 "Check test.c compilation failed"

    ruyi-deactivate

    rm -f test.c test.o
    rm -rf /tmp/mugen_test_venv{0,1}

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

