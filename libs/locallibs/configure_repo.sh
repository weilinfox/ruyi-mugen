#! /usr/bin/bash

# Copyright (c) 2023 Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.

# #############################################
# @Author    :   zhanglu
# @Contact   :   m18409319968@163.com
# @Date      :   2023-07-12
# @License   :   Mulan PSL v2
# @Desc      :   common_functions
# ############################################
# shellcheck disable=SC1091,SC2154

source /etc/openEuler-latest
LANG=en_US.UTF-8
service_ip=121.36.84.172

if [ ! "${version_info}" ]; then
    version_info=${openeulerversion}
else
    LOG_INFO "Use the specified version."
fi
if [ ! "${test_repo}" ]; then
    official_repo=http://repo.openeuler.org
else
    LOG_INFO "Use the specified url."
fi

#Configure repo source
function cfg_openEuler_repo() {
    echo "[${version_info}_OS]
name=${version_info}_OS
baseurl=${official_repo}/${version_info}/OS/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_everything]
name=${version_info}_everything
baseurl=${official_repo}/${version_info}/everything/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/everything/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_source]
name=${version_info}_source
baseurl=${official_repo}/${version_info}/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_update]
name=${version_info}_update
baseurl=${official_repo}/${version_info}/update/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_update_source]
name=${version_info}_update_source
baseurl=${official_repo}/${version_info}/update/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
" >/etc/yum.repos.d/"${version_info}".repo

    if [ "${version_info}"x == "openEuler-20.03-LTS-SP1"x ]; then
        echo "[${version_info}_EPOL]
name=${version_info}_EPOL
baseurl=${official_repo}/${version_info}/EPOL/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_source]
name=${version_info}_EPOL_source
baseurl=${official_repo}/${version_info}/EPOL/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_update]
name=${version_info}_EPOL_update
baseurl=${official_repo}/${version_info}/EPOL/update/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_update_source]
name=${version_info}_EPOL_update_source
baseurl=${official_repo}/${version_info}/EPOL/update/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler" >>/etc/yum.repos.d/"${version_info}".repo
    else
        echo "[${version_info}_EPOL]
name=${version_info}_EPOL
baseurl=${official_repo}/${version_info}/EPOL/main/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_source]
name=${version_info}_EPOL_source
baseurl=${official_repo}/${version_info}/EPOL/main/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_update]
name=${version_info}_EPOL_update
baseurl=${official_repo}/${version_info}/EPOL/update/main/$(arch)/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler

[${version_info}_EPOL_update_source]
name=${version_info}_EPOL_update_source
baseurl=${official_repo}/${version_info}/EPOL/update/main/source/
enabled=1
gpgcheck=1
gpgkey=${official_repo}/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler" >>/etc/yum.repos.d/"${version_info}".repo
    fi
}

#Configure openEuler update test repo
function cfg_openEuler_update_test_repo() {
    test_update_repo=$(curl http://"${service_ip}"/repo.openeuler.org/"${version_info}"/"${version_info}"-update.json | grep dir | grep "[0-9]" | grep -v test | grep -v round | awk -F \" '{print $4}' | awk -F "/" '{print $1}' | sort | uniq | tail -n 1)
    test_EPOL_update_repo=$(curl http://"${service_ip}"/repo.openeuler.org/"${version_info}"/EPOL/"${version_info}"-update.json | grep dir | grep "[0-9]" | grep -v test | awk -F \" '{print $4}' | awk -F "/" '{print $1}' | sort | uniq | tail -n 1 | awk -F "|" '{print $1}')

    printf "
[${version_info}_%s]
name=${version_info}_%s
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/%s/$(arch)/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_update_repo}" "${test_update_repo}" "${test_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo

    printf "
[${version_info}_source_%s]
name=${version_info}_source_%s
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/%s/source/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_update_repo}" "${test_update_repo}" "${test_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo

    if [ "${version_info}"x == "openEuler-20.03-LTS-SP1"x ]; then
        if [ "${test_update_repo}"x == "${test_EPOL_update_repo}"x ]; then
            printf "
[${version_info}_EPOL_%s]
name=${version_info}_EPOL_%s
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/EPOL/%s/$(arch)/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo

            printf "
[${version_info}_EPOL_source_%s]
name=${version_info}_EPOL_source_%s
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/EPOL/%s/source/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo
        else
            printf "No ${version_info}_EPOL_%s repo" "$test_update_repo"
        fi
    else
        if [ "${test_update_repo}"x == "${test_EPOL_update_repo}"x ]; then
            printf "
[${version_info}_EPOL_%s]
name=${version_info}_EPOL_%s
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/EPOL/%s/main/$(arch)/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo

            printf "
[${version_info}_EPOL_source_%s]
name=${version_info}_EPOL_source_%s}
baseurl=http://${service_ip}/repo.openeuler.org/${version_info}/EPOL/%s/main/source/
enabled=1
gpgcheck=1
gpgkey=http://repo.openeuler.org/${version_info}/OS/$(arch)/RPM-GPG-KEY-openEuler
priority=1
" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" "${test_EPOL_update_repo}" >>/etc/yum.repos.d/"${version_info}".repo
        else
            printf "No ${version_info}_EPOL_%s repo" "${test_update_repo}"
        fi
    fi
}
