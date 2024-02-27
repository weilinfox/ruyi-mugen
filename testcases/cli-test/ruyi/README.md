# RUYI 测试用例描述

| 测试套/软件包名 | 测试用例名 | 测试内容 |
| :-: | :-: | :-: |
| ruyi | ruyi\_test\_common | 基本命令测试 |
|  | ruyi\_test\_xdg | ``XDG_*_HOME`` 环境变量测试 |
|  | ruyi\_test\_venv | ``venv`` 命令测试 |
|  | ruyi\_test\_admin | ``admin`` 命令测试 |
|  | ruyi\_test\_cmake\_ninja | ``make`` 、 ``cmake`` 、 ``ninja`` 构建测试 |
|  | ruyi\_test\_qemu | QEMU 支持测试 |
|  | ruyi\_test\_xthead\_qemu | 平头哥 QEMU 支持测试 |
|  | ruyi\_test\_llvm | LLVM 支持测试 |
|  | ruyi\_test\_news | ``news`` 命令测试 |
|  | ruyi\_test\_device | ``device`` 命令测试 |
|  | ruyi\_test\_gnu-plct-rv64ilp32-elf | ``gnu-plct-rv64ilp32-elf`` 工具链测试 |

## ruyi\_test\_common 基本命令测试

该测试包含大部分基本的 RUYI 包管理器命令，包括 ``version`` 、 ``list`` 、 ``update`` 、 ``install`` 、 ``extract`` 、 ``self`` 等命令的基本使用和行为。

同时测试了 RUYI 对 ``https_proxy`` 和 ``http_proxy`` 环境变量的支持。

## ruyi\_test\_xdg XDG\_\*\_HOME 环境变量测试

RUYI 支持由 ``XDG_CACHE_HOME`` 、 ``XDG_DATA_HOME`` 和 ``XDG_STATE_HOME`` 指定文件目录，该测试检查 RUYI 对这些变量的支持情况。

## ruyi\_test\_venv venv 命令测试

RUYI ``venv`` 命令测试，该测试使用 gnu-plct 工具链建立 milkv-duo 编译环境，检查环境的激活和释放， ``$PS1`` 设置是否正常。

## ruyi\_test\_admin admin 命令测试

RUYI ``admin manifest`` 命令测试。

## ruyi\_test\_cmake\_ninja make 、cmake 、 ninja 构建测试

测试在 RUYI 编译环境中的项目构建工具调用。使用 gnu-plct-xthead 工具链 sipeed-lpi4a 配置构建 coremark 源码包，使用 gnu-plct 工具链 milkv-duo 配置构建 zlib-ng-2.1.5 。

## ruyi\_test\_qemu QEMU 支持测试

测试 qemu-user-riscv-upstream 虚拟机与 gnu-plct 工具链的组合，构建 hello, world 检查是否能够正常运行。

## ruyi\_test\_xthead\_qemu 平头哥 QEMU 支持测试

测试 qemu-user-riscv-xthead 虚拟机与 gnu-plct-xthead 工具链的组合，构建 hello, world 检查是否能够正常运行。

## ruyi\_test\_llvm LLVM 支持测试

测试 llvm-upstream 工具链与 gnu-plct 工具链 sysroot 的组合，构建 hello, world 检查是否能够正常运行。

## ruyi\_test\_news news 命令测试

RUYI ``news`` 命令测试。

## ruyi\_test\_device device 命令测试

RUYI ``device`` 命令测试，遍历所有镜像测试。

## ruyi\_test\_gnu-plct-rv64ilp32-elf gnu-plct-rv64ilp32-elf 工具链测试

RUYI gnu-plct-rv64ilp32-elf 工具链测试，验证工具链生成 32 位二进制，但是具有 64 位能力。

