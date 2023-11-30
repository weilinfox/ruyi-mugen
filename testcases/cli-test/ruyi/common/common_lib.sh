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
# @Desc      :   ruyisdk mugen common libs
# #############################################

source "${OET_PATH}"/libs/locallibs/common_lib.sh

get_ruyi_dir() {
	ruyibase=$XDG_CACHE_HOME
	[ "$ruyibase" == "" ] && ruyibase=~/.cache/
	echo "$ruyibase"/ruyi
}

install_src_ruyi() {
	curl -L -o ruyi.tar.gz https://github.com/ruyisdk/ruyi/archive/refs/heads/main.tar.gz
	tar -zxvf ruyi.tar.gz
	pushd ruyi-main
	python -m venv --copies venv-ruyi
	source venv-ruyi/bin/activate
	pip install -i https://mirrors.bfsu.edu.cn/pypi/web/simple rich gitpython pyxdg
	export OLDPYTHONPATH="$PYTHON_PATH"
	export PYTHONPATH="$(pwd)"
	export RUYI_DEBUG=x
	rm -rf $(get_ruyi_dir)
}


remove_src_ruyi() {
	deactivate
	export PYTHONPATH="$OLDPYTHONPATH"
	export OLDPYTHONPATH=
	export RUYI_DEBUG=
	popd
	rm -f ruyi.tar.gz
	rm -rf ruyi-main
	rm -rf venv-ruyi
	rm -rf $(get_ruyi_dir)
}

install_ruyi() {
	arch='amd64'
	if [ "$(uname -m)" == "riscv64" ]; then arch='riscv64'; fi
	curl -L -o ruyi https://mirror.iscas.ac.cn/ruyisdk/ruyi/testing/ruyi.${arch}.20231126
	chmod +x ruyi
	ln -s $(realpath ruyi) /usr/bin/ruyi
	rm -rf $(get_ruyi_dir)

	DNF_INSTALL git tar xz zstd
	APT_INSTALL git tar xz-utils zstd
}

remove_ruyi() {
	rm -f ruyi
	rm -f /usr/bin/ruyi
	export RUYI_DEBUG=
	rm -rf $(get_ruyi_dir)
	PKG_REMOVE
}

