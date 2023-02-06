#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
 Copyright (c) [2023] Huawei Technologies Co.,Ltd.ALL rights reserved.
 This program is licensed under Mulan PSL v2.
 You can use it according to the terms and conditions of the Mulan PSL v2.
          http://license.coscl.org.cn/MulanPSL2
 THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 See the Mulan PSL v2 for more details.

 @Author  : saarloos
 @email   : 9090-90-90-9090@163.com
 @Date    : 2023-02-06 14:09:36
 @License : Mulan PSL v2
 @Version : 1.0
 @Desc    : 检查mugen测试套，测试名称是否重复(不区分大小写)
"""

import os
import sys
import json

suitecase_path = "suite2cases"
curr_path = os.getcwd()

def check_testsuite():
    suitecase_list = os.listdir(os.path.join(curr_path, suitecase_path))
    suitecase_set = {}
    repeat_list = []
    for one_suite in suitecase_list:
        lower_name = one_suite.lower()
        if lower_name not in suitecase_set:
            suitecase_set[lower_name] = 1
        else:
            repeat_list.append(one_suite)
            print("%s/%s had repeat from other suitecase name ignore case"%(curr_path, one_suite))
    return len(repeat_list)

def find_case(case_name, check_path):
    find_path = []
    if not os.path.exists(check_path):
        return [-1]

    all_files = os.listdir(check_path)
    for one_file in all_files:
        file_name = os.path.splitext(one_file)[0]
        if os.path.isdir(os.path.join(check_path, one_file)):
            find_path.extend(find_case(case_name, os.path.join(check_path, one_file)))
        else:
            if case_name.lower() == file_name.lower():
                find_path.append(os.path.join(check_path, one_file))
    
    return find_path

def check_one_suite(cases_names, case_path, suitename):
    repeat_case = []
    for one_case in cases_names:
        get_path = find_case(one_case["name"], case_path)
        if len(get_path) > 1:
            repeat_case.append(one_case)
            print("testsuite %s path has repeat case:"%suitename)
            for one_path in get_path:
                print("\trepeat patch name:%s"%one_path)
    return repeat_case

def check_testcase():
    suitecase_list = os.listdir(os.path.join(curr_path, suitecase_path))
    ret = 0
    for one_suite in suitecase_list:
        with open(os.path.join(curr_path, suitecase_path, one_suite), "r") as f:
            case_info = json.load(f)
            case_path = os.path.join(curr_path, "/".join(case_info["path"].split("/")[1:]))
            cases_names = case_info["cases"]
            if len(check_one_suite(cases_names, case_path, one_suite)) > 0:
                ret = 1
    return ret          

def main():
    suite_ret = check_testsuite()
    case_ret = check_testcase()

    return suite_ret + case_ret
    

if __name__ == "__main__":
    main()
