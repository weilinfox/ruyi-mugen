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
	[ -z "$ruyibase" ] && ruyibase=~/.cache/
	echo "$ruyibase"/ruyi
}

get_ruyi_data_dir() {
	ruyibase=$XDG_DATA_HOME
	[ -z "$ruyibase" ] && ruyibase=~/.local/share
	echo "$ruyibase"/ruyi
}

get_ruyi_state_dir() {
	ruyibase=$XDG_STATE_HOME
	[ -z "$ruyibase" ] && ruyibase=~/.local/state
	echo "$ruyibase"/ruyi
}

get_ruyi_config_dir() {
	ruyibase=$XDG_CONFIG_HOME
	[ -z "$ruyibase" ] && ruyibase=~/.config
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

remove_ruyi_data() {
	rm -rf $(get_ruyi_dir) $(get_ruyi_data_dir) $(get_ruyi_state_dir) $(get_ruyi_config_dir)
}

install_release_ruyi() {
	version="0.6.0"
	arch='amd64'
	larch="$(uname -m)"
	if [ "$larch"  == "riscv64" ]; then arch='riscv64'; fi
	if [ "$larch"  == "aarch64" ]; then arch='arm64'; fi
	curl -L -o ruyi https://mirror.iscas.ac.cn/ruyisdk/ruyi/releases/${version}/ruyi.${arch}
}

install_github_release_ruyi() {
	version="0.7.0-alpha.20240315"
	arch='amd64'
	larch="$(uname -m)"
	if [ "$larch"  == "riscv64" ]; then arch='riscv64'; fi
	if [ "$larch"  == "aarch64" ]; then arch='arm64'; fi
	curl -L -o ruyi https://github.com/ruyisdk/ruyi/releases/download/${version}/ruyi-${version}.${arch}
}

install_ruyi() {
	DNF_INSTALL "curl git tar bzip2 xz zstd unzip"
	APT_INSTALL "curl git tar bzip2 xz-utils zstd unzip"
	PACMAN_INSTALL "curl git tar bzip2 xz zstd unzip"

	#install_release_ruyi
	install_github_release_ruyi

	chmod +x ruyi
	ln -s $(realpath ruyi) /usr/bin/ruyi
	# remove_ruyi_data
}

remove_ruyi() {
	PKG_REMOVE

	remove_ruyi_data

	rm -f ruyi
	rm -f /usr/bin/ruyi
	export RUYI_DEBUG=
}

