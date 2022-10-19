```text
基于CentOS镜像和数据挂载卷实现Docker搭建Zookeeper集群
运维>Zookeeper
2022-07-18
https://picgo.kwcoder.club/202208/202207201246242.png
```

# 实现原理

以三台server的Zookeeper集群为例，在搭建时，需要如下条件：

1. 启动三台机器
2. 三台机器要相互和自身免密登录
3. 每台机器要有Java和Zookeeper环境，并且拥有相同的Zookeeper配置文件

基于这个条件，构建一个已经安装好相关软件的CentOS7镜像。


# 基于centos:7镜像搭建Hadoop集群

## 构建预装必要软件的、可登录的CentOS7容器

```dockerfile
# 基于CentOS7镜像
FROM centos:7

MAINTAINER zhinushannan<zhinushannan@gmail.com>

# 设置root用户的登录密码
ENV ROOT_PASSWORD 12345678
# 设置时区
ENV TIMEZONE Asia/Shanghai
# 设置Hadoop的工作目录
ENV ZOOKEEPER_DATA_DIR /opt/zookeeper_dir
ENV ZOOKEEPER_LOGS_DIR /opt/zookeeper_dir/logs

# 安装rsync、vim、openssh-server、openssh-clients、net-tools，并配置ssh登录密码，创建工作目录
RUN yum install -y rsync vim openssh-server openssh-clients net-tools && \
    echo $ROOT_PASSWORD | passwd --stdin root && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone && \
    mkdir -p $HADOOP_NAME_DIR $ZOOKEEPER_LOGS_DIR

# 容器启动时，启动sshd服务
CMD ["/usr/sbin/sshd", "-D"]

# 监听22端口
EXPOSE 22

```

## 使用docker-compose群起固定IP的Zookeeper集群


```shell
version: "2.6"  # docker-compose 版本号

services:
  server1:  # 服务名
    image: centos_zookeeper  # 镜像
    container_name: server1  # 容器名
    hostname: server1
    volumes:
      - /Users/zhinushannan/code/zookeeper/module:/opt/module
    networks:
      test:
        ipv4_address: 172.18.0.2

  server2:  # 服务名
    image: centos_zookeeper  # 镜像
    container_name: server2  # 容器名
    hostname: server2
    volumes:
      - /Users/zhinushannan/code/zookeeper/module:/opt/module
    networks:
      test:
        ipv4_address: 172.18.0.3

  server3:  # 服务名
    image: centos_zookeeper  # 镜像
    container_name: server3  # 容器名
    hostname: server3
    volumes:
      - /Users/zhinushannan/code/zookeeper/module:/opt/module
    networks:
      test:
        ipv4_address: 172.18.0.4

networks:
   test:
      ipam:
         config:
           - subnet: 172.18.0.0/16

```


# 配置免密登录


## 配置`hosts`文件

参考文章：[浅谈hosts文件](https://dream.kwcoder.club/p/20220706/)

修改`server1`、`server2`、`server3`以及宿主机的`hosts`文件：

```text
# hadoop
172.18.0.2	server1
172.18.0.3	server2
172.18.0.4	server3
```



## 配置免密登录

在每一台机器上生成公钥私钥`ssh-keygen -t rsa`，执行这个命令之后，需要连续按三次回车。

在每一台机器人上执行如下命令，将公钥拷贝到需要免密登录的机器上，从而实现免密登录。需要按照提示输入对方用户的登录密码。

```shell
ssh-copy-id server1
ssh-copy-id server2
ssh-copy-id server3
```


# 配置环境

## 拷贝相关软件

将适合自己架构的Java和Zookeeper解压并拷贝进相关目录。

## 配置环境变量

通过ssh登录其中一台机器，修改`/etc/profile`文件，在最后添加：

```shell
# java
export JAVA_HOME=/opt/module/jdk1.8.0_333
export HRE_HOME=$JAVA_HOME:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH

# zookeeper
export ZOOKEEPER_HOME=/opt/module/zookeeper-3.8.0
export PATH=$PATH:$ZOOKEEPER_HOME/bin
```

添加完成后编译一下该文件，执行`java -version`指令检测java是否配置成功。
在终端输入`zk`，双击`TAB`键，检测zookeeper是否配置成功。

成功后利用`rsync`工具将环境配置文件拷贝到其他机器上：

```shell
rsync -v /etc/profile slave1:/etc/profile
rsync -v /etc/profile slave2:/etc/profile
```

进入其他机器编译环境配置文件，并检测环境是否生效。

# 配置Zookeeper

进入`$ZOOKEEPER_HOME/conf`，复制配置文件`cp zoo_sample.cfg zoo.cfg`，编辑`zoo.cfg`：
修改`dataDir`的值为Dockerfile中的`ZOOKEEPER_LOGS_DIR`，在末尾添加：

```shell
server.1=server1:2888:3888
server.2=server2:2888:3888
server.3=server3:2888:3888

```

最后添加的是zookeeper服务器列表，格式为`server.n=host:port:port`，其中第一个port是follower和leader通信的端口号，第二个port是选举端口号。

修改`logback.xml`文件，将其中的`<property name="zookeeper.log.dir" value="" />`的值修改为Dockerfile中定义的`ZOOKEEPER_LOGS_DIR`，并且将ROLLINGFILE的配置注释取消。

进入`$ZOOKEEPER_HOME/bin`，修改`zkEnv.sh`，将其中的`ZOO_LOG_DIR`的值修改为Dockerfile中定义的`ZOOKEEPER_LOGS_DIR`。

进入Zookeeper的工作目录，即Dockerfile中定义的`ZOOKEEPER_DATA_DIR`，创建`myid`文件，三台机器都要创建，并且其中的内容为自己的服务器编号，即`zoo.cfg`文件中的服务器列表`server.n=host:port:port`中的`n`。

# 编写一键启动/停止脚本

在`$ZOOKEEPER_HOME/bin`目录下，新建`zk-startall.sh`和`zk-stopall.sh`，内容分别为：

```shell
#!/bin/sh

echo "starting zkServer..."
ssh master "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh start"
ssh slave1 "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh start"
ssh slave2 "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh start"
echo "done"
```

```shell
#!/bin/sh

echo "starting zkServer..."
ssh master "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh stop"
ssh slave1 "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh stop"
ssh slave2 "source /etc/profile;$ZOOKEEPER_HOME/bin/zkServer.sh stop"
echo "done"
```

给这两个脚本授予执行权限：

```shell
chmod u+x zk-startall.sh zk-stopall.sh
```

# 启动集群

使用`zk-startall.sh`脚本一键启动zookeeper集群，启动后可以通过`jps`命令查看java进程，会有`QuorumPeerMain`进程。

执行`zkServer.sh status`，查看当前服务器的角色。