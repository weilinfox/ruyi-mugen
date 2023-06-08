#!/usr/bin/bash
# Copyright (c) [2021] Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
####################################
# @Author  : saarloos
# @email   : 9090-90-90-9090@163.com
# @Date    : 2023-06-06 15:12:00
# @License : Mulan PSL v2
# @Version : 1.0
# @Desc    :
#####################################

OET_PATH=$(
    cd "$(dirname "$0")"/../../ || exit 1
    pwd
)
export OET_PATH

source "${OET_PATH}"/libs/locallibs/common_lib.sh

DO_CLEAN_COUNT=0
NOT_DO_CLEAN_COUNT=0
TOTAL_CLEAN_COUNT=0

function clean_one_suite() {
    ((TOTAL_CLEAN_COUNT++))
    local test_suite=$1

    find_test_suite=$(find "$OET_PATH"/suite2cases -name "${test_suite}".json)
    [ -z "$find_test_suite" ] && {
        LOG_ERROR "In the suite2cases directory, Can't find the file of testsuite:${test_suite}."
        return 1
    }

    suite_path=$(python3 "${OET_PATH}"/libs/locallibs/suite_case.py --suite "$test_suite" --key path)
    if ! python3 "${OET_PATH}"/libs/locallibs/suite_case.py --suite "$test_suite" --key path >/dev/null 2>&1; then
        LOG_ERROR "find ${test_suite} test suite path fail"
        return 1
    fi
    test -d "$suite_path" || {
        LOG_ERROR "Path value:${suite_path} in a JSON file that does not exist in the environment."
        return 1
    }

    pushd "$suite_path" >/dev/null || return 1

    if [[ -f "./makefile" || -f "./Makefile" ]]; then
        LOG_INFO "do make for testsuite: ${test_suite}"
        if ! make clean; then
            LOG_ERROR "do make clean for testsuite: ${test_suite} fail"
            popd >/dev/null || return 1
            return 1
        fi
        ((DO_CLEAN_COUNT++))
    else
        if [[ $2 != "no_print" ]]; then
            LOG_INFO "This test suite $suite_path have no makefile or Makefile"
        fi
        ((NOT_DO_CLEAN_COUNT++))
    fi

    popd >/dev/null || return 1

    return 0
}

function clean_all() {
    test_suites=()
    while IFS='' read -r line; do test_suites+=("$line"); done < <(find "${OET_PATH}"/suite2cases/ -type f -name '*.json' | awk -F '/' '{print $NF}' | sed -e 's/.json$//g')
    test ${#test_suites[@]} -eq 0 && { 
        LOG_ERROR "Can't find recording about test_suites."
        return 1
    }

    do_error_count=0

    for test_suite in ${test_suites[*]}; do
        clean_one_suite "$test_suite" "no_print"
        if ! clean_one_suite "$test_suite" "no_print"; then
            LOG_ERROR "doing test suite $test_suite make fail"
            ((do_error_count++))
        fi
    done

    LOG_INFO "A total ${TOTAL_CLEAN_COUNT} test suite run make clean, ${DO_CLEAN_COUNT} had clean, ${NOT_DO_CLEAN_COUNT} no need clean, ${do_error_count} do clean fail"
    if [ "$do_error_count" -ne 0 ]; then
        exit 1
    fi

    exit 0
}

clean_all