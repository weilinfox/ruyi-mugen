## mugen 测试

### 测试环境说明

+ 由于 mugen 本身依赖 expect、 psmisc、 ping、 make、 python3、 python3-paramiko、 python3-six，故 mugen 自动化测试不能测试 RUYI 对这些软件包的依赖
+ 由于 mugen 自身的特性，测试用例运行的顺序是随机的
