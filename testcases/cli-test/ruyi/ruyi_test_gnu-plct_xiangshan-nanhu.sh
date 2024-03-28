#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #####################################################
# @Author    :   weilinfox
# @Contact   :   caiweilin@iscas.ac.cn
# @Date      :   2024/03/28
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk gnu-plct xiangshan-nanhu test
# #####################################################

source "./common/common_lib.sh"

function pre_test() {
    LOG_INFO "Start environmental preparation."
    install_ruyi || LOG_ERROR "Install ruyi error"
    LOG_INFO "End of environmental preparation!"
}

function run_test() {
    LOG_INFO "Start to run test."

    ruyi update
    ruyi install gnu-plct
#    if [[ "$?" != "0" ]]; then
#        ruyi install gnu-plct 2>&1 | grep 'no binary'
#        if [[ "$?" == "0" ]]; then
#            LOG_INFO "No binary for current host, skip testing"
#        else
#            LOG_ERROR "gnu-plct installation failed"
#        fi
#        return 0
#    fi

    ruyi venv -t gnu-plct xiangshan-nanhu /tmp/mugen_test_venv
    CHECK_RESULT $? 0 0 "Check ruyi venv creation failed"
    cat > test.c << EOF
int main()
{
        int a = 1, b = 2, c = 3, ret;

        asm ("add.uw %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );          // zba
        asm ("orn %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );             // zbb
        asm ("clmul %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );           // zbc
        asm ("bclr %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );            // zbs
        asm ("pack %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );            // zbkb
        asm ("clmul %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );           // zbkc
        asm ("xperm8 %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );          // zbkx
        asm ("aes64dsm %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );        // zknd
        asm ("aes64es %0, %1, %2" :"=r"(ret) :"r"(a), "r"(b) );         // zkne
        asm ("sha512sig0 %0, %1" :"=r"(ret) :"r"(a) );                  // zknh
        asm ("sm4ed %0, %1, %2, 1" :"=r"(ret) :"r"(a), "r"(b) );        // zksed
        asm ("sm3p0 %0, %1" :"=r"(ret) :"r"(a) );                       // zksh
        // CFH                                                          // zicbom
        // CFH                                                          // zicboz

        return 0;
}
EOF
    CHECK_RESULT $? 0 0 "Check test.c creation failed"

    source /tmp/mugen_test_venv/bin/ruyi-activate

    riscv64-plct-linux-gnu-gcc -O2 -c -o test.o test.c
    CHECK_RESULT $? 0 0 "Check test.c compilation failed"

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

