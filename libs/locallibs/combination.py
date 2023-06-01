# -*- coding: utf-8 -*-
"""
 Copyright (c) [2021] Huawei Technologies Co.,Ltd.ALL rights reserved.
 This program is licensed under Mulan PSL v2.
 You can use it according to the terms and conditions of the Mulan PSL v2.
          http://license.coscl.org.cn/MulanPSL2
 THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 See the Mulan PSL v2 for more details.

 @Author  : saarloos
 @email   : 9090-90-90-9090@163.com
 @Date    : 2023-04-26 11:45:00
 @License : Mulan PSL v2
 @Version : 1.0
 @Desc    : 组合测试用例执行
"""

import subprocess
import json
import os
import sys
import argparse
import mugen_log
from shutil import copyfile

SCRIPT_PATH = os.path.dirname(os.path.abspath(__file__))
sys.path.append(SCRIPT_PATH)

OET_PATH = os.environ.get("OET_PATH")
if OET_PATH is None:
    mugen_log.logging("ERROR", "环境变量：OET_PATH不存在，请检查mugen框架.")
    sys.exit(1)

TEST_SUITE_PATH = os.path.join(OET_PATH, "suite2cases")
MUGEN_SH_PATH = os.path.join(OET_PATH, "mugen.sh")
QEMU_CTL_PATH = os.path.join(OET_PATH, "qemu_ctl.sh")
CONF_PATH = os.path.join(OET_PATH, "conf")
COMBINATION_PATH = os.path.join(OET_PATH, "combination")
COMBINATION_RESULT_PATH = os.path.join(OET_PATH, "combination_results")
MUGEN_RESULT_PATH = os.path.join(OET_PATH, "results")
TMP_DOWNLOAD_PATH = os.path.join(OET_PATH, "tmp_download")
COMBINATION_SCRIPT_PATH = os.path.join(OET_PATH, "run_combinations.sh")

def get_all_combinations():
    all_combinations = []
    all = os.listdir(os.path.join(OET_PATH, "combination"))
    for one in all:
        split_name = os.path.splitext(one)
        if split_name[-1] != ".json":
            continue
        all_combinations.append(os.path.join(COMBINATION_PATH, one))
    return all_combinations

def env_define_ok(env_dict:dict):
    if "name" not in env_dict:
        mugen_log.logging("WARN", "some env set not have name, will ignore it")
        return False
    if "type" not in env_dict:
        mugen_log.logging("WARN", "some env set not have type, will ignore it")
        return False
    if env_dict["type"] == "qemu" and (
        "kernal_img_path" not in env_dict or "initrd_path" not in env_dict or "qemu_type" not in env_dict):
        mugen_log.logging("WARN", "some qemu env set not have path info, will ignore it")
        return False
    if env_dict["type"] == "host" and ("ip" not in env_dict or "password" not in env_dict):
        mugen_log.logging("WARN", "some host env set not have ip or password info, will ignore it")
        return False
    return True

def analysis_env_part(env_infos:list):
    env_dict = {}
    has_qemu = False
    for one_env in env_infos:
        if not env_define_ok(one_env):
            continue
        env_dict[one_env["name"]] = {}
        for one_key in one_env.keys():
            if one_key == "name":
                continue
            env_dict[one_env["name"]][one_key] = one_env[one_key]
        if env_dict[one_env["name"]]["type"] == "qemu":
            if not os.path.exists(env_dict[one_env["name"]]["kernal_img_path"]):
                env_dict[one_env["name"]]["download_kernel"] = True
            if not os.path.exists(env_dict[one_env["name"]]["initrd_path"]):
                env_dict[one_env["name"]]["download_initrd"] = True
    return env_dict

def combination_define_ok(one_com:dict):
    if "name" not in one_com:
        mugen_log.logging("WARN", "some combination define not have name, will ignore it")
        return False
    if "testcases" not in one_com:
        mugen_log.logging("WARN", "some combination define not have testcases, will ignore it")
        return False
    if len(one_com["testcases"]) == 0:
        mugen_log.logging("WARN", "some combination define not have testcases, will ignore it")
        return False
    count = 0
    for one_case in one_com["testcases"]:
        if "testsuite" not in one_case:
            continue
        if not os.path.exists(os.path.join(TEST_SUITE_PATH, one_case["testsuite"] + ".json")):
            continue
        if "add" in one_case["testsuite"] and "del" in one_case["testsuite"]:
            continue
        count = count + 1
    if count == 0:
        mugen_log.logging("WARN", "some combination define testsuite name all not in testcase path, will ignore it")
        return False
    return True

def generate_suite_dir(com_dir_path:os.path, com_testcases:list):
    suffix_num = 0
    for one_case in com_testcases:
        new_suite_path = os.path.join(com_dir_path, one_case["testsuite"] + f'_{suffix_num}.json')
        suffix_num = suffix_num + 1
        old_suite_path = os.path.join(TEST_SUITE_PATH, one_case["testsuite"] + ".json")
        if not os.path.exists(old_suite_path):
            continue
        if "add" in one_case and "del" in one_case:
            continue
        if "add" in one_case and len(one_case["add"]) == 0:
            continue
        if "add" not in one_case and "del" not in one_case:
            copyfile(old_suite_path, new_suite_path)
            continue
        suite_json = {}
        with open(old_suite_path, "r", encoding="utf8") as rf:
            suite_json = json.load(rf)
        option_list = []
        add_case = True
        if "add" in one_case:
            if isinstance(one_case["add"], list):
                option_list.extend(one_case["add"])
            else:
                option_list.append(one_case["add"])
        elif "del" in one_case:
            add_case = False
            if isinstance(one_case["del"], list):
                option_list.extend(one_case["del"])
            else:
                option_list.append(one_case["del"])
        old_case = suite_json["cases"]
        suite_json["cases"] = []
        for one_old in old_case:
            if (add_case and one_old["name"] in option_list) or (
                not add_case and one_old["name"] not in option_list):
                 suite_json["cases"].append(one_old)   
        if  len(suite_json["cases"]) == 0:
            continue
        with open(new_suite_path, "w") as wf:
            json.dump(suite_json, wf, indent=4)

# 适用于嵌入式场景
def generate_sdk_set_script(sdk_path:str, env_name:str):
    sdk_script = ""
    tmp_sdk_path = sdk_path
    if sdk_path == "":
        mugen_log.logging("ERROR", "sdk path not set")
        return sdk_script + '\n echo "[ERROR]: sdk path not set!" \n'
    if not os.path.exists(sdk_path):
        tmp_sdk_path = os.path.join(TMP_DOWNLOAD_PATH, env_name)
        tmp_run_sdk_name = os.path.join(tmp_sdk_path, "sdk.sh")
        tmp_sdk_name = os.path.join(tmp_sdk_path, "sdk")
        sdk_script = sdk_script + f'wget --no-check-certificate {sdk_path} -O {tmp_run_sdk_name}\n' \
                                  f'sh {tmp_run_sdk_name} <<EOF\n' \
                                  f'{tmp_sdk_name}\n' \
                                  f'y\n' \
                                  f'EOF\n' 
        tmp_sdk_path = tmp_sdk_name
    sdk_script = sdk_script + f'source_path=$(find {tmp_sdk_path} -name "environment-setup-*")\n' + \
                              'source ${source_path}'
    return sdk_script                

def generate_execute_env_script(env_name_list:list, env_dict:dict):
    env_srcipt = ""
    start_qemu = False
    run_remote = False
    for one_env_name in env_name_list:
        one_env_dict = env_dict[one_env_name]
        if one_env_dict["type"] == "host":
            env_srcipt = env_srcipt + "\n" + f'bash {MUGEN_SH_PATH} -c'
            for one_key in one_env_dict.keys():
                if one_key == "type":
                    continue
                if one_key == "run_remote":
                    run_remote = True
                if isinstance(one_env_dict[one_key], bool):
                    env_srcipt = env_srcipt + " " + f'--{one_key}'
                else:
                    env_srcipt = env_srcipt + " " + f'--{one_key} "{one_env_dict[one_key]}"'
        elif one_env_dict["type"] == "qemu":
            start_qemu = True
            run_remote = True
            kernal_img_path = one_env_dict["kernal_img_path"]
            if "download_kernel" in one_env_dict:
                tmp_kernal_img_path = os.path.join(TMP_DOWNLOAD_PATH, one_env_name)
                tmp_kernal_img_name = os.path.join(tmp_kernal_img_path, "zImage")
                env_srcipt = env_srcipt + "\n" + f'mkdir -p {tmp_kernal_img_path}\n' \
                                                 f'wget --no-check-certificate {one_env_dict["kernal_img_path"]} -O {tmp_kernal_img_name}'
                kernal_img_path = tmp_kernal_img_name
            initrd_path = one_env_dict["initrd_path"]
            if "download_initrd" in one_env_dict:
                tmp_initrd_path = os.path.join(TMP_DOWNLOAD_PATH, one_env_name)
                tmp_initrd_name = os.path.join(tmp_kernal_img_path, "initd")
                env_srcipt = env_srcipt + "\n" + f'mkdir -p {tmp_initrd_path}\n' \
                                                 f'wget --no-check-certificate {one_env_dict["initrd_path"]} -O {tmp_initrd_name}'
                initrd_path = tmp_initrd_name
            env_srcipt = env_srcipt + "\n" + f'bash {QEMU_CTL_PATH} start --kernal_img_path {kernal_img_path} --initrd_path {initrd_path}'
            for one_key in one_env_dict.keys():
                if (one_key == "type" or 
                    one_key == "download_kernel" or 
                    one_key == "download_initrd"  or 
                    one_key == "kernal_img_path" or 
                    one_key == "initrd_path" or 
                    one_key == "sdk_path"):
                    continue
                if isinstance(one_env_dict[one_key], bool):
                    env_srcipt = env_srcipt + " " + f'--{one_key}'
                else:
                    env_srcipt = env_srcipt + " " + f'--{one_key} "{one_env_dict[one_key]}"'
            if "sdk_path" in one_env_dict:
                env_srcipt = env_srcipt + "\n" + generate_sdk_set_script(one_env_dict["sdk_path"], one_env_name)
    return env_srcipt, start_qemu, run_remote

def execute_env_combination_ok(one_exec:dict, env_dict:dict, combination_dict:dict):
    env_list = []
    env_list.extend(one_exec["env"])
    for one_env in env_list:
        if one_env not in env_dict:
            mugen_log.logging("ERROR", f'{one_exec["env"]} not in env config, ignore this execute')
            return False
    if not isinstance(one_exec["combination"], str):
        mugen_log.logging("ERROR", f'one execute can only config one combination, ignore this execute')
        return False
    if one_exec["combination"] not in combination_dict:
        mugen_log.logging("ERROR", f'{one_exec["combination"]} not in combination config, ignore this execute')
        return False
    return True

def generate_execute_script(env_dict:dict, combination_dict:dict, exec_list:list):
    execute_script = ""
    for one_exec in exec_list:
        if not execute_env_combination_ok(one_exec, env_dict, combination_dict):
            continue
        execute_script = execute_script + "\n" + f'echo "---run execute" \n' + \
                                                 f'bash {QEMU_CTL_PATH} stop\n' \
                                                 f'rm -rf {CONF_PATH}'
        env_script, start_qemu, run_remote = generate_execute_env_script(one_exec["env"], env_dict)
        execute_script = execute_script + "\n" + env_script + "\n"
        old_suite2case_path = os.path.join(OET_PATH, "suite2cases")
        new_suite2case_path = os.path.join(OET_PATH, "tmp_suite2cases")
        run_suite2case_path = combination_dict[one_exec["combination"]]
        run_suite2case_result_path = os.path.join(COMBINATION_RESULT_PATH, 
                                                  os.path.basename(run_suite2case_path))
        run_script = "-a -x"
        if run_remote:
            run_script = "-a -s"
        execute_script = execute_script + "\n" + f'mv {old_suite2case_path} {new_suite2case_path}\n' \
                                                 f'mv {run_suite2case_path} {old_suite2case_path}\n' \
                                                 f'bash {MUGEN_SH_PATH} -a -b\n' \
                                                 f'bash {MUGEN_SH_PATH} {run_script}\n' \
                                                 f'mkdir -p {run_suite2case_result_path}\n' \
                                                 f'cp -r {MUGEN_RESULT_PATH}/* {run_suite2case_result_path}\n' \
                                                 f'mv {old_suite2case_path} {run_suite2case_path}\n' \
                                                 f'mv {new_suite2case_path} {old_suite2case_path}\n'
        if start_qemu:
            execute_script = execute_script + f"bash {QEMU_CTL_PATH} stop\n" \
                                              f'rm -rf {TMP_DOWNLOAD_PATH}'
        execute_script = execute_script + "\n" + f'echo "---run execute end"\n'
    if execute_script == "":
        return 'echo "No ececute can run, please check config"', False
    return execute_script, True

def generate_combination_testsuit(combination_dict:dict, prefix:str):
    com_dict = {}
    for one_com in combination_dict:
        if not combination_define_ok(one_com):
            continue
        com_dir_path = os.path.join(OET_PATH, prefix + one_com["name"] + "_suite")
        com_dict[one_com["name"]] = com_dir_path
        try:
            if not os.path.exists(com_dir_path):
                os.makedirs(com_dir_path)
            generate_suite_dir(com_dir_path, one_com["testcases"])
        except Exception as e:
            mugen_log.logging("WARN", f'generate {one_com["name"]} testsuite dir fail, {e}')
            continue
    return com_dict

def generate_one_combination(combination:str, prefix:str):
    combination_path = combination
    all_script_ok = True
    if not os.path.exists(combination_path):
        return f'echo "[ERROR]: {combination} not find"', False
    json_info = {}
    with open(combination_path, "r") as f:
        try:
            json_info = json.load(f)
        except Exception as e:
            mugen_log.logging("WARN", f'analysis {combination} json file fail, message {e}')
            return f'echo "[ERROR]: {combination} json file can not analysis please check."', False
    if not isinstance(json_info, dict):
        mugen_log.logging("WARN", f'{combination} json file forment fail')
        return f'echo "[ERROR]: {combination} json file forment fail please check."', False
    run_script = ""
    do_execute = True
    do_env = True
    do_combination = True
    if "execute" not in json_info:
        mugen_log.logging("INFO", f'{combination} do not have execute part, only creat combination testsuites')
        run_script = run_script + f'echo "[WARN]: {combination} do not have execute part, only creat combination testsuites"\n'
        all_script_ok = False
        do_execute = False
    elif "env" not in json_info:
        mugen_log.logging("INFO", f'{combination} do not have env part, only creat combination testsuites')
        run_script = run_script + f'echo "[WARN]: {combination} do not have env part, only creat combination testsuites"\n'
        all_script_ok = False
        do_env = False
    elif "combination" not in json_info:
        mugen_log.logging("INFO", f'{combination} do not have combination part, script will do noting')
        run_script = run_script + f'echo "[ERROR]: {combination} do not have combination part, script will do noting"\n'
        all_script_ok = False
        do_combination = False
    env_dict = None
    if do_env :
        env_dict = analysis_env_part(json_info["env"])
    combination_dict = None
    if do_combination:
        combination_dict = generate_combination_testsuit(json_info["combination"], prefix)
    exec_list = []
    if do_execute:
        for one_execute in json_info["execute"]:
            if "env" not in one_execute or "combination" not in one_execute:
                mugen_log.logging("WARN", "execute define faile ignore it")
                continue
            exec_list.append(one_execute)
    run_script, all_script_ok = generate_execute_script(env_dict, combination_dict, exec_list)

    return run_script, all_script_ok


def generate_script(combinations:list):
    all_script = f'#!/usr/bin/bash\n\n' \
                 f'rm -rf {COMBINATION_RESULT_PATH}\n' \
                 f'mkdir -p {COMBINATION_RESULT_PATH}\n' 
    all_script_ok = True
    prefix_num = 0
    for one_combination in combinations:
        all_script = all_script + "\n" + f'#===run {one_combination} tests===\n' \
                                         f'echo "===run {one_combination} tests==="\n'
        run_script, script_ok = generate_one_combination(one_combination, 
                                                         f'tmp_{prefix_num}_{os.path.splitext(os.path.basename(one_combination))[0]}_')
        if not script_ok:
            all_script_ok = False
        all_script = all_script + run_script + f'\necho "===run {one_combination} tests end==="\n' \
                                               f'#===run {one_combination} tests end===\n'
        prefix_num = prefix_num + 1
    if not all_script_ok:
        all_script = all_script + 'echo "combination script not ok, please check"\n' \
                                  'exit 1\n'
    print("===generate script is: ")
    print(all_script)
    print(f'===script path{COMBINATION_SCRIPT_PATH}')
    with open(COMBINATION_SCRIPT_PATH, "w") as f:
        f.write(all_script)

def get_combination_results_info():
    info = {}
    all_run_combinations = os.listdir(COMBINATION_RESULT_PATH)
    max_combinations_name_len = 0
    max_suite_name_len = 0
    max_case_name_len = 0
    for one_comb in all_run_combinations:
        if max_combinations_name_len < len(one_comb):
            max_combinations_name_len = len(one_comb)
        info[one_comb] = {}
        all_suite = os.listdir(os.path.join(COMBINATION_RESULT_PATH, one_comb))
        for one_suite in all_suite:
            if max_suite_name_len < len(one_suite):
                max_suite_name_len = len(one_suite)
            info[one_comb][one_suite] = {}
            fail_path = os.path.join(COMBINATION_RESULT_PATH, one_comb, one_suite, "failed")
            succeed_path = os.path.join(COMBINATION_RESULT_PATH, one_comb, one_suite, "succeed")
            if os.path.exists(fail_path):
                info[one_comb][one_suite]["fail"] = os.listdir(fail_path)
                for one_case in info[one_comb][one_suite]["fail"]:
                    if max_case_name_len < len(one_case):
                        max_case_name_len = len(one_case)
            if os.path.exists(succeed_path):
                info[one_comb][one_suite]["succeed"] = os.listdir(succeed_path)
                for one_case in info[one_comb][one_suite]["succeed"]:
                    if max_case_name_len < len(one_case):
                        max_case_name_len = len(one_case)
    info["max_combinations_name_len"] = max_combinations_name_len
    info["max_suite_name_len"] = max_suite_name_len
    info["max_case_name_len"] = max_case_name_len
    return info

def add_space_to_str(old_str:str, total_len):
    i = len(old_str)
    new_str = old_str
    while i < total_len:
        new_str = new_str + ' '
        i = i + 1
    return new_str

def print_combination_info_results(result_info:dict):
    min_title = "| combination_name | testsuite_name | testcase_name | succeed |"
    title_forment = "|  |  |  | succeed |"
    one_line_len = len(title_forment) + result_info["max_combinations_name_len"] + result_info["max_suite_name_len"] + result_info["max_case_name_len"]
    if one_line_len <= len(title_forment):
        mugen_log.logging("ERROR", "combination results empty")
        return 1
    if one_line_len < len(min_title):
        one_line_len = len(min_title)
    comb_len = result_info["max_combinations_name_len"]
    suite_len = result_info["max_suite_name_len"]
    case_len = result_info["max_case_name_len"]
    result_len = len("succeed")
    print_str = '-'*one_line_len
    print_str = print_str + "\n" + "| %s | %s | %s | %s |"%(add_space_to_str("combination_name", comb_len),
                                                     add_space_to_str("testsuite_name", suite_len),
                                                     add_space_to_str("testcase_name", case_len),
                                                     add_space_to_str("result", result_len))
    print_str = print_str + "\n" + '-'*one_line_len
    fail_test_num = 0
    for one_comb in result_info.keys():
        if (one_comb == "max_combinations_name_len" or
            one_comb == "max_suite_name_len" or
            one_comb == "max_case_name_len"):
            continue
        for one_suite in result_info[one_comb].keys():
            if "succeed" in result_info[one_comb][one_suite]:
                for one_case in result_info[one_comb][one_suite]["succeed"]:
                    print_str = print_str + "\n" + "| %s | %s | %s | %s |"%(
                                                    add_space_to_str(one_comb, comb_len),
                                                    add_space_to_str(one_suite, suite_len),
                                                    add_space_to_str(one_case, case_len),
                                                    add_space_to_str("succeed", result_len))
            if "fail" in result_info[one_comb][one_suite]:
                for one_case in result_info[one_comb][one_suite]["fail"]:
                    fail_test_num += 1
                    print_str = print_str + "\n" + "| %s | %s | %s | %s |"%(
                                                    add_space_to_str(one_comb, comb_len),
                                                    add_space_to_str(one_suite, suite_len),
                                                    add_space_to_str(one_case, case_len),
                                                    add_space_to_str("fail", result_len))
    print_str = print_str + "\n" + '-'*one_line_len
    print_str = print_str + "\n"
    print(print_str)
    return fail_test_num

def print_combination_results():
    result_info = get_combination_results_info()
    return print_combination_info_results(result_info)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="manual to this script")
    parser.add_argument('combinations', nargs="*", help="combination names in combination dir")
    parser.add_argument("--run", "-r", action="store_true", help="run generace combination script")
    parser.add_argument("--all", "-a", action="store_true", help="run all combinations at combinations dir")
    parser.add_argument("--file", "-f", type=str, help="run combination file full path name, if not in combination dir")
    parser.add_argument("--dir", "-d", type=str, help="run combination file dir name, if not combination dir")
    parser.add_argument("--print", "-p", action="store_true", help="print combination test result")
    arge = parser.parse_args()
    if arge.print is not None and arge.print:
        if (arge.run is not None or
            arge.combinations is not None or
            arge.all is not None or
            arge.file is not None or
            arge.dir is not None):
            mugen_log.logging("WARN", "Only print combination run result")
        sys.exit(print_combination_results())

    combinations = []
    if arge.file is not None:
        if not os.path.exists(arge.file):
            mugen_log.logging("ERROR", "组合配置文件不存在")
            exit(1)
        combinations.append(arge.file)
    if arge.dir is not None:
        if os.path.exists(arge.file):
            mugen_log.logging("ERROR", "组合配置目录不存在")
            exit(1)
        all_files = os.listdir(arge.file)
        for one_file in all_files:
            if os.path.splitext(one_file)[-1] != ".json":
                continue
            combinations.append(os.path.join(arge.dir, one_file))
    for one_combinations in arge.combinations:
        tmp_name = one_combinations
        if os.path.splitext(tmp_name)[-1] != ".json":
            tmp_name = tmp_name + ".json"
        combinations.append(os.path.join(COMBINATION_PATH, tmp_name))
    if len(combinations) == 0 and not arge.all:
            mugen_log.logging("ERROR", "未配置需要执行的组合测试名")
    if arge.all:
        combinations.extend(get_all_combinations())
    generate_script(combinations)
    if arge.run is not None and arge.run:
        run_proc = subprocess.run(['sh', '-x', COMBINATION_SCRIPT_PATH])
        result_info = get_combination_results_info()
        result_fail_num = print_combination_info_results(result_info)
        sys.exit(run_proc.returncode + result_fail_num)
    sys.exit(0)
