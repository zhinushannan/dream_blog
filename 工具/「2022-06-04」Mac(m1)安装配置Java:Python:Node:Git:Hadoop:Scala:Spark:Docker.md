```text
Mac(m1)安装配置Java/Python/Node/Git/Hadoop/Scala/Spark/Docker
工具
2022-06-04
https://picgo.kwcoder.club/202206/202206221625026.png
```





# 前置要求

进入`~/`目录，查看是否存在`.bash_profile`文件，若不存在，则创建。
修改`~/.zshrc`文件，在最后一行添加`source ~/.bash_profile`。

解释：
在配置环境变量中，我们通常编辑`/etc/profile`，但是这是系统级别的文件，一旦损坏后果不堪设想，最好的方式是编辑用户级别的配置文件，即`~/.bash_profile`。但是在Mac中，开启终端时加载的是`~/.zshrc`，所以需要在`~/.zshrc`最后一行添加一条编译`~/.bash_profile`的命令，即`source ~/.bash_profile`。

当然也可以直接写在`~/.zshrc`中，但是里面有与基本环境有关系的东西，因此不建议在该文件中配置环境。

# Java

前往Oracle官网下载JDK：[官网](https://www.oracle.com/java/technologies/downloads/)

![1.oracle官网](https://picgo.kwcoder.club/202206/202206221625028.png)

下载完成之后直接一路傻瓜式安装。安装完成之后就可以使用`java` `javac` `java -version`等命令了。

正常情况下，安装完成后JDK的目录在`/Library/Java/JavaVirtualMachines/jdkXXX.jdk/Contents/Home`（其中XXX是JDK的版本号）下，编辑`~/.bash_profile`文件：

```shell
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_333.jdk/Contents/Home
CLASS_PATH="$JAVA_HOME/lib"
PATH=".$PATH:$JAVA_HOME/bin"

export JAVA_HOME
export PATH
export CLASS_PATH
```

然后执行`source ~/.bash_profile`即可。

# Python

前往官网下载自己需要的版本：[官网](https://www.python.org/downloads/)

下载完成后一路傻瓜式安装即可。
通常Python的安装目录在`/Library/Frameworks/Python.framework/Versions/3.9/`（其中3.9是安装的版本号）下，进入`bin`目录，找到对应的Python可执行文件，并配置环境变量：

![2.寻找python可执行文件](https://picgo.kwcoder.club/202206/202206221625538.png)



```shell
PATH="/Library/Frameworks/Python.framework/Versions/3.9/bin:${PATH}"
alias python39="/Library/Frameworks/Python.framework/Versions/3.9/bin/python3.9"
alias pip39="/Library/Frameworks/Python.framework/Versions/3.9/bin/pip3.9"
```

执行`source ~/.bash_profile`，并执行`python39 -V`和`pip39 -V`检查是否可用。

# Node

使用`nvm`工具安装nodejs。
执行下面任意一条命令即可安装`nvm`：

```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
```

在`~/.bash_profile`中配置：

```shell
# nvm (安装node的工具)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# nvm 国内镜像
export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs
```

执行`source ~/.bash_profile`，然后就可以通过nvm工具安装nodejs了，常用命令如下：

```shell
nvm ls-remote # 列出所有可用版本
nvm install <version> # 安装指定版本
nvm uninstall <version> # 卸载指定版本
nvm ls # 列出所有安装版本
nvm use <version> # 切换使用指定的版本
nvm current # 显示当前使用的版本
nvm alias default <version> # 设置默认的node版本
nvm deactivate # 解除当前版本绑定
```

使用nvm工具安装的node，其目录在`~/.nvm/versions/node/`。

执行`nvm install 【版本号】`，等待安装完成后，执行`node -v`和`npm -v`检查是否可用。

注意：建议安装14.17.1、15等适用于Mac m1的node。

如果安装12版本的，在运行vue项目时会出现如下报错：

```shell
/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/npm run dev

> vue-manage-system@5.1.0 dev /Users/zhinushannan/code/wanxiao_reported/vue-manage-system
> vite


<--- Last few GCs --->

[38157:0x120008000]       45 ms: Scavenge 9.6 (11.8) -> 9.3 (14.6) MB, 0.3 / 0.0 ms  (average mu = 1.000, current mu = 1.000) allocation failure
[38157:0x120008000]       53 ms: Scavenge 11.4 (14.6) -> 10.8 (19.6) MB, 0.4 / 0.0 ms  (average mu = 1.000, current mu = 1.000) allocation failure
[38157:0x120008000]       84 ms: Scavenge 14.9 (20.4) -> 13.3 (21.4) MB, 0.6 / 0.0 ms  (average mu = 1.000, current mu = 1.000) allocation failure


<--- JS stacktrace --->

FATAL ERROR: wasm code commit Allocation failed - process out of memory
1: 0x10485bf24 node::Abort() [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
2: 0x10485c088 node::OnFatalError(char const*, char const*) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
3: 0x104984754 v8::Utils::ReportOOMFailure(v8::internal::Isolate*, char const*, bool) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
4: 0x1049846d4 v8::internal::V8::FatalProcessOutOfMemory(v8::internal::Isolate*, char const*, bool) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
5: 0x104eeb1d4 v8::internal::wasm::WasmCodeManager::TryAllocate(unsigned long, void*) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
6: 0x104eebfe0 v8::internal::wasm::NativeModule::CreateEmptyJumpTableInRegion(unsigned int, v8::base::AddressRegion) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
7: 0x104eeb49c v8::internal::wasm::NativeModule::AddCodeSpace(v8::base::AddressRegion) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
8: 0x104eebe28 v8::internal::wasm::NativeModule::NativeModule(v8::internal::wasm::WasmEngine*, v8::internal::wasm::WasmFeatures const&, bool, v8::internal::VirtualMemory, std::__1::shared_ptr<v8::internal::wasm::WasmModule const>, std::__1::shared_ptr<v8::internal::Counters>, std::__1::shared_ptr<v8::internal::wasm::NativeModule>*) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
9: 0x104eee39c v8::internal::wasm::WasmCodeManager::NewNativeModule(v8::internal::wasm::WasmEngine*, v8::internal::Isolate*, v8::internal::wasm::WasmFeatures const&, unsigned long, bool, std::__1::shared_ptr<v8::internal::wasm::WasmModule const>) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
10: 0x104ef4c88 v8::internal::wasm::WasmEngine::NewNativeModule(v8::internal::Isolate*, v8::internal::wasm::WasmFeatures const&, unsigned long, bool, std::__1::shared_ptr<v8::internal::wasm::WasmModule const>) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
11: 0x104ef4bcc v8::internal::wasm::WasmEngine::NewNativeModule(v8::internal::Isolate*, v8::internal::wasm::WasmFeatures const&, std::__1::shared_ptr<v8::internal::wasm::WasmModule const>) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
12: 0x104ecc36c v8::internal::wasm::AsyncCompileJob::CreateNativeModule(std::__1::shared_ptr<v8::internal::wasm::WasmModule const>) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
13: 0x104ed55d0 v8::internal::wasm::AsyncCompileJob::PrepareAndStartCompile::RunInForeground(v8::internal::wasm::AsyncCompileJob*) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
14: 0x104ed5e4c v8::internal::wasm::AsyncCompileJob::CompileTask::RunInternal() [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
15: 0x1048bdfbc node::PerIsolatePlatformData::RunForegroundTask(std::__1::unique_ptr<v8::Task, std::__1::default_delete<v8::Task> >) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
16: 0x1048bd064 node::PerIsolatePlatformData::FlushForegroundTasksInternal() [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
17: 0x105051acc uv__async_io [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
18: 0x105063d80 uv__io_poll [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
19: 0x105051f74 uv_run [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
20: 0x104898854 node::NodeMainInstance::Run() [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
21: 0x10483514c node::Start(int, char**) [/Users/zhinushannan/.nvm/versions/node/v12.22.12/bin/node]
22: 0x1075c908c

Process finished with exit code 134 (interrupted by signal 6: SIGABRT)
```





# Git

Mac自带git，不需要额外安装。
首先查看本地git是否已经配置，执行`git config --global --list`命令，如果没配置，则执行以下命令进行配置：

```shell
git config --global user.name "github的用户名"
git config --global user.email "github的邮箱"
ssh-keygen -t rsa -C "github的邮箱" # 执行此条命令后需要连续按三次回车
cat ~/.ssh/id_rsa.pub # 查看公钥
```

在GitHub的`https://github.com/settings/keys`中新建`SSH KEY`，将公钥复制进去，保存后，执行`ssh -T git@github.com`命令，若出现`success`字样，则说明配置成功！

# Hadoop

首先去Hadoop官网下载需要版本的二进制包：[官网](https://hadoop.apache.org/releases.html)（或者也可以去国内镜像下载：[清华镜像](https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/stable/)）

![3.Hadoop官网](https://picgo.kwcoder.club/202206/202206221626335.png)



下载完成后解压到指定目录，我设置的目录是`~/environment`，然后将hadoop的目录配置到`~/.bash_profile`中：

```shell
export HADOOP_HOME=/Users/zhinushannan/environment/hadoop-3.3.3
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

执行`source ~/.bash_profile`，执行`hadoop`命令检查是否可用。

# Scala

进入Scala官网：[官网](https://www.scala-lang.org/download/)
下载第二代版本的二进制包：

![4.scala官网](https://picgo.kwcoder.club/202206/202206221626883.png)

![5.scala二进制包](https://picgo.kwcoder.club/202206/202206221626227.png)





下载完成后解压到指定目录，我设置的目录是`~/environment`，然后将scala的目录配置到`~/.bash_profile`中：

```shell
PATH="/Users/zhinushannan/environment/scala-2.12.15/bin:${PATH}"
```

执行`source ~/.bash_profile`，执行`scala`命令检查是否可用。

# Spark

进入Spark官网，根据安装的Hadoop版本选择Spark版本：[官网](https://spark.apache.org/downloads.html)

![6.spark官网](https://picgo.kwcoder.club/202206/202206221626374.png)



下载完成后解压到指定目录，我设置的目录是`~/environment`，然后将scala的目录配置到`~/.bash_profile`中：

```shell
export SPARK_HOME=/Users/zhinushannan/environment/spark-3.2.1-bin-hadoop3.2
export PATH=$PATH:$SPARK_HOME/bin
export PYSPARK_PYTHON=python39
```

其中python39是自己的python启动命令。

安装pyspark：`pip39 install pyspark`，执行`source ~/.bash_profile`，执行`pyspark`检查是否可用。

```shell
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 3.2.1
      /_/
```

# Docker

前往官网下载：[官网](https://docs.docker.com/desktop/mac/install/)，下载完成后将dmg文件拖入Application进行安装，安装完成后点击Docker图标运行Docker。



![7.docker](https://picgo.kwcoder.club/202206/202206221627178.png)





点击小鲸鱼图标，在Perferences中设置国内镜像：



![8.docker镜像](https://picgo.kwcoder.club/202206/202206221627374.png)





```shell
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "registry-mirrors": [
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```

点击`Apply & Restart`镜像源生效。

但是，此时是不能ping通Docker容器的，即无法与容器建立通信。如果有这个需求，需要做如下操作（提前安装好brew）。
安装`docker-connector`：

```shell
brew install wenjunxiao/brew/docker-connector
==> Downloading https://github.com/wenjunxiao/mac-docker-connector/releases/download/v3.1/docker-connector-darwin.tar.gz
==> Downloading from https://objects.githubusercontent.com/github-production-release-asset-2e65be/266031479/3f51cb4b-e37f-4f12-a492-5d057728562c?X-Amz-Algorithm=AWS4-HMAC-SHA25
######################################################################## 100.0%
==> Installing docker-connector from wenjunxiao/brew
==> Caveats
For the first time, you can add all the bridge networks of docker to the routing table by the following command:
  docker network ls --filter driver=bridge --format "{{.ID}}" | xargs docker network inspect --format "route {{range .IPAM.Config}}{{.Subnet}}{{end}}" >> /opt/homebrew/etc/docker-connector.conf
Or add the route of network you want to access to following config file at any time:
  /opt/homebrew/etc/docker-connector.conf
Route format is `route subnet`, such as:
  route 172.17.0.0/16
The route modification will take effect immediately without restarting the service.
You can also expose you docker container to other by follow settings in /opt/homebrew/etc/docker-connector.conf:
  expose 0.0.0.0:2512
  route 172.17.0.0/16 expose
Let the two subnets access each other through iptables:
  iptables 172.17.0.0+172.18.0.0

To start wenjunxiao/brew/docker-connector now and restart at startup:
  sudo brew services start wenjunxiao/brew/docker-connector
Or, if you don't want/need a background service you can just run:
  sudo docker-connector -config /opt/homebrew/etc/docker-connector.conf
==> Summary
🍺  /opt/homebrew/Cellar/docker-connector/3.1: 4 files, 5.3MB, built in 1 second
==> Running `brew cleanup docker-connector`...
Disable this behaviour by setting HOMEBREW_NO_INSTALL_CLEANUP.
Hide these hints with HOMEBREW_NO_ENV_HINTS (see `man brew`).

```

在日志中，可以看到`docker-connector`的配置文件在`/opt/homebrew/etc/docker-connector.conf`。确定自己电脑上的docker属于哪一个路由段（通常情况下是`172.17.0.1`），将对应的路由的注视去掉。

```shell
# addr 192.168.251.1/24
# mtu 1400
# host 127.0.0.1
# port 2511
route 172.17.0.0/16
# route 172.18.0.0/16
# iptables 172.17.0.0+172.18.0.0
# hosts /etc/hosts .local
# proxy 127.0.0.1:80:80
```

启动`docker-connector`服务：

```shell
sudo brew services start docker-connector
```

运行docker前端容器：

```shell
docker run -it -d --restart always --net host --cap-add NET_ADMIN --name connector wenjunxiao/mac-docker-connector
```

此时就可以尝试与容器建立通信。

`docker-connector`官方：[https://github.com/wenjunxiao/mac-docker-connector](https://github.com/wenjunxiao/mac-docker-connector)
