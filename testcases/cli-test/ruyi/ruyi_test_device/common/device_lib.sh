#!/usr/bin/bash

# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more detaitest -f.

# #############################################
# @Author       :   KotorinMinami
# @Contributor  :   weilinfox
# @Contact      :   huangshuo4@gmail.com
# @Date         :   2024/1/29
# @License      :   Mulan PSL v2
# @Desc         :   ruyisdk mugen device libs
# #############################################

source "${OET_PATH}"/libs/locallibs/common_lib.sh
source "../common/common_lib.sh"

result_item=()

function test_ouput() {
    output=$(grep "$2" $1 | awk '{print $2}' | tail -1)
    if [[ "$output" == '(y/N)' ]]; then
        result_item=('y' 'n');
    elif [[ "$output" =~ (1-.) ]]; then
        result_item=($(seq ${output:0-2:1}));
    else
        result_item=('e');
    fi
}

function recursion_run() {
    local now_exec=$1
    local end_exec=$2

    if [[ ${#now_exec} -gt 100 ]]; then
        LOG_ERROR "Quit test due to $now_exec longer then 100"
        return 1
    fi

    if [[ "$end_exec" == "y" ]]; then
        nohup echo -e "$now_exec" | ruyi device provision 2>&1 | tee > /tmp/ruyi_device/output &
        SLEEP_WAIT 1m
        kill -9 $!
        sed "s/\x0D/\\n/g" /tmp/ruyi_device/output > /tmp/ruyi_device/output_e
        happy=n
        grep -A 20 'Saving to' /tmp/ruyi_device/output_e | grep '\[=' && echo -e "\nHappy hacking! 0 0" >> /tmp/ruyi_device/output && happy=y
        [ $happy = n ] && curl_out=$(grep -A 20 'Total' /tmp/ruyi_device/output_e | grep -A 20 'Received' | tail -15 | awk '{printf $4" "}')
        for i in $(echo $curl_out); do
            [[ $i =~ [0-9]+ && $i != '0' ]] && echo -e "\nHappy hacking! 0 0" >> /tmp/ruyi_device/output && happy=y && break
        done
        [ $happy = n ] && echo -e "\nHappy hacking! 0 1" >> /tmp/ruyi_device/output
        rm -f /tmp/ruyi_device/output_e
    elif [ ! -z "$end_exec" ] && [ "$end_exec" != "0" ]; then
        echo -e $now_exec | ruyi device provision 2>&1 > /tmp/ruyi_device/output
        ret=$?
        echo -e "\nHappy hacking! $(expr $end_exec - 1) $ret" >> /tmp/ruyi_device/output
    else
        echo -e $now_exec | ruyi device provision 2>&1 | grep --line-buffered -Ev '^$|#' > /tmp/ruyi_device/output
    fi

    grep 'Happy hacking!' /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        now_exec_f=$(echo -E "$now_exec" | sed 's/\\n//g')
        now_exec_f=$(echo -E "$now_exec_f" | sed 's$/$_$g')
        mv /tmp/ruyi_device/output /tmp/ruyi_device/output_${now_exec_f}
        rm /tmp/ruyi_device/output
        rm -rf "$(get_ruyi_dir)/distfiles/*"
        rm -rf "$(get_ruyi_data_dir)/blobs/*"
        return 0;
    fi

    ret=0
    grep "failed to fetch distfile" /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        recursion_run "$now_exec"
        ret=$(expr $ret + $?)
        return $ret;
    fi
    grep "Proceed with flashing" /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        rm -rf /tmp/ruyi_device/test
        touch /tmp/ruyi_device/test
        recursion_run "$now_exec\nn" 2
        ret=$(expr $ret + $?)
        recursion_run "$now_exec\ny" 2
        ret=$(expr $ret + $?)
        return $ret;
    fi
    grep "Please give the path for the target's whole disk" /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        rm -rf /tmp/ruyi_device/test
        touch /tmp/ruyi_device/test
        recursion_run "$now_exec\n/tmp/ruyi_device/test" 1
        ret=$(expr $ret + $?)
        return $ret;
    fi
    grep 'Proceed' /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/ruyi_device/output 'Proceed'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            [ $step = 'n' ] && recursion_run "$now_exec\n$step" "2"
            [ $step = 'y' ] && recursion_run "$now_exec\n$step" "y"
            # [[ $stop =~ [0-9]+ ]] && recursion_run "$now_exec\n$step"
        done
        return $ret;
    fi
    grep 'Choice' /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/ruyi_device/output 'Choice'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            [ $step != 'n' ]
            recursion_run "$now_exec\n$step" $?
            ret=$(expr $ret + $?)
        done
        return $ret;
    fi
    grep 'Continue' /tmp/ruyi_device/output
    if [[ $? -eq 0 ]]; then
        test_ouput /tmp/ruyi_device/output 'Continue'
        local next_step=(${result_item[@]})
        for step in ${next_step[@]}; do
            [ $step != 'n' ]
            recursion_run "$step" $?
            ret=$(expr $ret + $?)
        done
        return $ret;
    fi
    mv /tmp/ruyi_device/output /tmp/ruyi_device/output_${now_exec}

    return 1;
}

function test_res() {
    file=$1
    res=0

    ret=$(grep 'Happy hacking!' $file)
    res=$(expr $res + $?)

    ret_e=$(echo $ret | awk '{print $3}')
    ret_g=$(echo $ret | awk '{print $4}')

    ( [ $ret_e = 0 ] && [ $ret_g = 0 ] ) || ( [ $ret_e != 0 ] && [ $ret_g != 0 ] )
    res=$(expr $res + $?)

    return $res
}
