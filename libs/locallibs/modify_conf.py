# -*- coding: utf-8 -*-
"""
 Copyright (c) 2023. Huawei Technologies Co.,Ltd.ALL rights reserved.
 This program is licensed under Mulan PSL v2.
 You can use it according to the terms and conditions of the Mulan PSL v2.
          http://license.coscl.org.cn/MulanPSL2
 THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 See the Mulan PSL v2 for more details.

 @Author  : ga_beng_cui
 @email   : liujingjing25812@163.com
 @Date    : 2023-10-09 14:54:21
 @License : Mulan PSL v2
 @Version : 1.0
 @Desc    : 生成测试环境配置
"""

import sys
import os
import json
import socket
import subprocess
import argparse
import paramiko

SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))
sys.path.append(SCRIPT_PATH)

import mugen_log


def write_conf(suite, conf, key, value, run_remote=False, copy_all=True):
    """写入测试用例的配置

    Args:
        suite ([str]): 测试用例的测试套
        conf ([str]):  测试用例的配置文件
        key ([str]):   测试用例的变量
        value ([str]): 测试用例的参数
    """
    if suite is None:
        mugen_log.logging("error", "必要参数suite存在缺失.")
        sys.exit(1)

    oet_path = os.environ.get("OET_PATH")
    if oet_path is None:
        mugen_log.logging("error", "环境变量：OET_PATH不存在，请检查mugen框架.")
        sys.exit(1)

    cmd="find " + oet_path + "/testcases -name " + suite
    suite_path = subprocess.getoutput(cmd)
    cmd="sed -i 's#" + key + "=.*#" + key + "=\"" + value + "\"#g' " + suite_path + "/" + conf
    subprocess.getoutput(cmd)

    sys.exit(0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="manual to this script")
    parser.add_argument("--suite", type=str, default=None)
    parser.add_argument("--conf", type=str, default=None)
    parser.add_argument("--key", type=str, default=None)
    parser.add_argument("--value", type=str, default=None)
    parser.add_argument("--run_remote", action='store_true')
    parser.add_argument("--put_all", action='store_true')

    args = parser.parse_args()
    write_conf(args.suite, args.conf, args.key, args.value, args.run_remote, args.put_all)
