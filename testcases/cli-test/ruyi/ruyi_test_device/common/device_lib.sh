#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #############################################
# @Author    :   KotorinMinami
# @Contact   :   huangshuo4@gmail.com
# @Date      :   2024/1/29
# @License   :   Mulan PSL v2
# @Desc      :   ruyisdk mugen device libs
# #############################################

source "${OET_PATH}"/libs/locallibs/common_lib.sh

result_item=()

function test_ouput() {
    output=$(grep "$2" $1 | awk '{print $2}')
    if [[ "$output" == '(y/N)' ]]; then
        result_item=('y' 'n');
    elif [[ "$output" =~ (1-.) ]]; then
        result_item=($(seq ${output:0-2:1}));
    else
        result_item=('y' 'n');
    fi
}

function recursion_run() {
    local now_exec=$1
    
    echo -e $now_exec | ruyi device provision | grep -Ev '^$|#' | tail -5 > /tmp/output

    grep 'Happy hacking!' /tmp/output
    if [[ $? -eq 0 ]]; then
        mv /tmp/output /tmp/output_${now_exec}
        return 0;
    fi
    grep 'Proceed' /tmp/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/output 'Proceed'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            recursion_run "$now_exec\n$step"
        done
        return 0;
    fi
    grep "Please give the path for the target's whole disk" /tmp/output
    if [[ $? -eq 0 ]]; then
        rm -rf /tmp/test
        touch /tmp/test
        recursion_run "$now_exec\n/tmp/test"
        return 0;
    fi
    grep 'Choice' /tmp/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/output 'Choice'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            recursion_run "$now_exec\n$step"
        done
        return 0;
    fi
    grep 'Continue' /tmp/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/output 'Continue'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            recursion_run "$now_exec\n$step"
        done
        return 0;
    fi
    mv /tmp/output /tmp/output_${now_exec}
    return 1;           

}

function test_res() {
    file=$1
    res=0
    grep 'Happy hacking!' $file
    res=$(expr $res + $?)
    return $res
}



