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

    ruyi --version | grep "$version"
    CHECK_RESULT $? 0 0 "Check ruyi version failed"
    ruyi 2>&1 |grep usage
    CHECK_RESULT $? 0 0 "Check ruyi empty cmdline help failed"
    ruyi -h | grep usage
    CHECK_RESULT $? 0 0 "Check ruyi help failed"
    ruyi list
    CHECK_RESULT $? 0 0 "Check ruyi empty list failed"
    [ -d $(get_ruyi_dir) ]
    CHECK_RESULT $? 0 0 "Check ruyi create cache directory failed"
    ruyi update
    CHECK_RESULT $? 0 0 "Check ruyi update failed"
    pkgcnt=$(ruyi list | grep -e "^* " | wc -l)
    CHECK_RESULT $pkgcnt 0 1 "Check ruyi list failed"
    ruyi list | grep "Package declares"
    CHECK_RESULT $? 0 1 "Check ruyi brief list failed"
    ruyi list --verbose | grep "Package declares"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose package failed"
    ruyi list --verbose | grep "Binary artifacts"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose artifacts failed"
    ruyi list --verbose | grep "Toolchain metadata"
    CHECK_RESULT $? 0 0 "Check ruyi list verbose metadata failed"

    ruyi list profiles
    CHECK_RESULT $? 0 0 "Check ruyi profile failed"

    pkgnames=$(ruyi list | grep -e "^* toolchain" | cut -d'/' -f 2)
    for p in $pkgnames; do
        s=$(ruyi list | awk '/\* / {if (f==1) f=2} /./ {if (f==1) {print $0}} /\* toolchain\/'$p'/ {if (f==0) f=1}' | grep -e "^  -" | grep -v "no binary for current host")
        if [ ! -z "$s" ]; then
            pkgname="$p"
            break
        fi
    done
    if [ -z "$pkgname" ]; then
        LOG_INFO "No supported binary package found"
    else
        http_proxy=http://wrong.proxy https_proxy=http://wrong.proxy ruyi install $pkgname
        CHECK_RESULT $? 0 1 "Check ruyi install package from wrong proxy failed"
        http_proxy=http://wrong.proxy https_proxy=http://wrong.proxy ruyi install $pkgname | grep "Basic connectivity problems"
        CHECK_RESULT $? 0 0 "Check ruyi install failure message failed"
        ruyi install $pkgname 2>&1 | grep "downloading"
        CHECK_RESULT $? 0 0 "Check ruyi install package failed"
        ruyi install $pkgname 2>&1 | grep "skipping already installed package"
        CHECK_RESULT $? 0 0 "Check ruyi install duplicate package failed"
        ruyi install name:$pkgname 2>&1 | grep "skipping already installed package"
        CHECK_RESULT $? 0 0 "Check ruyi install duplicate package by name failed"
    fi

    pkgname=$(ruyi list | grep -e "^* source" | head -n 1 | cut -d'/' -f 2)
    mkdir source-test && cd source-test
    ruyi extract $pkgname
    CHECK_RESULT $? 0 0 "Check ruyi extract failed"
    [ "$(ls)" != "" ]
    CHECK_RESULT $? 0 0 "Check ruyi extract dir not enpty failed"
    cd .. && rm -rf source-test

    ruyi self uninstall -y
    CHECK_RESULT $? 0 0 "Check ruyi self uninstall failed"
    ruyi version
    CHECK_RESULT $? 0 1 "Check ruyi uninstall exists failed"
    [ -d ~/.cache/ruyi ]
    CHECK_RESULT $? 0 0 "Check ruyi cache dir exists failed"
    [ -d ~/.local/share/ruyi ]
    CHECK_RESULT $? 0 0 "Check ruyi data dir exists failed"
    [ -d ~/.local/state/ruyi ]
    CHECK_RESULT $? 0 0 "Check ruyi state dir exists failed"

    install_ruyi
    ruyi self uninstall --purge -y
    CHECK_RESULT $? 0 0 "Check ruyi self purge failed"
    ruyi version
    CHECK_RESULT $? 0 1 "Check ruyi purge exists failed"
    [ -d ~/.cache/ruyi ]
    CHECK_RESULT $? 0 1 "Check ruyi purge cache dir exists failed"
    [ -d ~/.local/share/ruyi ]
    CHECK_RESULT $? 0 1 "Check ruyi purge data dir exists failed"
    [ -d ~/.local/state/ruyi ]
    CHECK_RESULT $? 0 1 "Check ruyi purge state dir exists failed"

    LOG_INFO "End of the test."
}

function post_test() {
    LOG_INFO "start environment cleanup."
    remove_ruyi
    LOG_INFO "Finish environment cleanup!"
}

main "$@"

