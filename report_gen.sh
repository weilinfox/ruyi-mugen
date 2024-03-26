#!/usr/bin/bash
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
####################################
# @Author  : weilinfox
# @email   : caiweilin@iscas.ac.cn
# @Date    : 2024-03-26 13:18:31
# @License : Mulan PSL v2
# @Version : 1.0
# @Desc    : Generate test report
#####################################

OET_PATH=$(
    cd "$(dirname "$0")" || exit 1
    pwd
)

source ${OET_PATH}/testcases/cli-test/ruyi/common/common_lib.sh

report_name_js='{
"revyos-riscv64":	"RUYI_包管理_Container_RevyOS_riscv64_测试结果",
"debian12-x86_64":	"RUYI_包管理_QEMU_Debian12_x86_64_测试结果",
"debian12-aarch64":	"RUYI_包管理_QEMU_Debian12_aarch64_测试结果",
"debiansid-riscv64":	"RUYI_包管理_Container_Debiansid_riscv64_测试结果",
"ubuntu2204-x86_64":	"RUYI_包管理_QEMU_Ubuntu22.04_x86_64_测试结果",
"ubuntu2204-riscv64":	"RUYI_包管理_QEMU_Ubuntu22.04_riscv64_测试结果",
"fedora38-x86_64":	"RUYI_包管理_QEMU_Fedora38_x86_64_测试结果",
"fedora38-riscv64":	"RUYI_包管理_QEMU_Fedora38_riscv64_测试结果",
"oE2309-x86_64":	"RUYI_包管理_QEMU_openEuler23.09_x86_64_测试结果",
"oE2309-riscv64":	"RUYI_包管理_QEMU_openEuler23.09_riscv64_测试结果",
"archlinux-x86_64":	"RUYI_包管理_Container_Archlinux_x86_64_测试结果",
"archlinux-riscv64":	"RUYI_包管理_Container_Archlinux_riscv64_测试结果"
}'
ruyitest_repo="https://gitee.com/yunxiangluo/ruyisdk-test/tree/master/20240312"

tmpl_dir=${OET_PATH}/report_gen_tmpl
temp_dir=/tmp/ruyi_report
report_dir=${OET_PATH}/ruyi_report
report_name=`echo $report_name_js | jq -r .\"$1\"`

[ -z "$report_name" ] && {
	echo Unsupported distro
	exit -1
}

[ ! -f $tmpl_dir/26test_log.md ] && {
	echo 26test_log.md not appears
	exit -1
}

ruyi_testsuites=1
ruyi_testcases=`grep "use cases were executed, with" $tmpl_dir/26test_log.md | sed "s/^.* A total of \([0-9]*\) use cases were executed, .*$/\\1/"`
ruyi_success=`grep "use cases were executed, with" $tmpl_dir/26test_log.md | sed "s/^.* with \([0-9]*\) successes and .*$/\\1/"`
ruyi_failed=`grep "use cases were executed, with" $tmpl_dir/26test_log.md | sed "s/^.* successes and \([0-9]*\) failures\.$/\\1/"`
ruyi_timeout=`grep "The case exit by code 143" $tmpl_dir/26test_log.md | wc -l`
ruyi_conclusion="此处添加测试结论"

[ "$ruyi_failed"x = "0x" ] && ruyi_conclusion="没有发现问题"

[[ -d $temp_dir ]] && rm -rf $temp_dir
[[ -d $report_dir ]] && rm -rf $report_dir
mkdir $temp_dir $report_dir

export_ruyi_link

cp ${tmpl_dir}/*.md ${tmpl_dir}/$1/*.md $temp_dir/


for f in `ls ${temp_dir} | sort`; do
	echo Find template ${temp_dir}/$f
	cat ${temp_dir}/$f >> $report_dir/my
done

rm -rf $temp_dir

sed -i "s/{{ruyi_arch}}/$arch/g" $report_dir/my
sed -i "s/{{ruyi_version}}/$version/g" $report_dir/my
sed -i "s|{{ruyi_link}}|$ruyi_link|g" $report_dir/my
sed -i "s|{{ruyitest_repo}}|$ruyitest_repo|g" $report_dir/my
sed -i "s/{{ruyi_testsuites}}/$ruyi_testsuites/g" $report_dir/my
sed -i "s/{{ruyi_testcases}}/$ruyi_testcases/g" $report_dir/my
sed -i "s/{{ruyi_conclusion}}/$ruyi_conclusion/g" $report_dir/my
sed -i "s/{{ruyi_success}}/$ruyi_success/g" $report_dir/my
sed -i "s/{{ruyi_failed}}/$ruyi_failed/g" $report_dir/my
sed -i "s/{{ruyi_timeout}}/$ruyi_timeout/g" $report_dir/my

mv -v $report_dir/my $report_dir/$report_name.md

