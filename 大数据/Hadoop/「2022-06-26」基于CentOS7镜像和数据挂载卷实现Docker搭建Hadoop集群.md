```text
基于CentOS7镜像和数据挂载卷实现Docker搭建Hadoop集群
大数据>Hadoop
2022-06-26
https://picgo.kwcoder.club/202206/202206261620161.png
```






# 实现原理

以一主二从的Hadoop集群为例，在搭建时，需要如下条件：

1. 启动三台机器
2. 三台机器要相互和自身免密登录
3. 每台机器都要有Java和Hadoop的环境，并且Hadoop的配置文件也要相同

基于这个条件，构建一个已经安装好相关软件的CentOS7镜像。
在启动镜像时，设置数据挂载卷到指定目录，作为Java、Hadoop以及以后的Storm、Hive等大数据框架放置的位置。这样，可以实现通过修改宿主机上的配置文件，同步修改三台机器上的配置文件和软件。
同时，通过rsync工具可以实现对`.bashrc`等环境配置的文件进行跨机器拷贝。

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
ENV HADOOP_NAME_DIR /opt/hadoop_dir/name
ENV HADOOP_DATA_DIR /opt/hadoop_dir/data
ENV HADOOP_LOG_DIR /opt/hadoop_dir/logs
ENV HADOOP_PID_DIR /opt/hadoop_dir/pids
ENV HADOOP_TMP_DIR /opt/hadoop_dir/temp

# 安装rsync、vim、openssh-server、openssh-clients、net-tools，并配置ssh登录密码，创建工作目录
RUN yum install -y rsync vim openssh-server openssh-clients net-tools && \
    echo $ROOT_PASSWORD | passwd --stdin root && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone && \
    mkdir -p $HADOOP_NAME_DIR $HADOOP_DATA_DIR $HADOOP_LOG_DIR $HADOOP_PID_DIR $HADOOP_TMP_DIR

# 容器启动时，启动sshd服务
CMD ["/usr/sbin/sshd", "-D"]

# 监听22端口
EXPOSE 22

```

## 集群部署规划



|   IP地址   | 主机名 |   角色   |
| :--------: | :----: | :------: |
| 172.18.0.2 | master | NameNode |
| 172.18.0.3 | slave1 | DataNode |
| 172.18.0.4 | slave2 | DataNode |





## 使用docker-compose群起固定IP的Hadoop集群

```shell

version: "2.6"  # docker-compose 版本号

services:
  master:  # 服务名
    image: centos_ssh:7  # 镜像
    container_name: master  # 容器名
    hostname: master
    volumes:
      - /Users/zhinushannan/docker/taxi_dispatch/data/module:/opt/module
      - /Users/zhinushannan/docker/taxi_dispatch/data/master_dir:/opt/work_dir
    networks:
      test:
        ipv4_address: 172.18.0.2

  slave1:
    image: centos_ssh:7
    container_name: slave1
    hostname: slave1
    volumes:
      - /Users/zhinushannan/docker/taxi_dispatch/data/module:/opt/module
      - /Users/zhinushannan/docker/taxi_dispatch/data/slave1_dir:/opt/work_dir
    networks:
      test:
        ipv4_address: 172.18.0.3

  slave2:
    image: centos_ssh:7
    container_name: slave2
    hostname: slave2
    volumes:
      - /Users/zhinushannan/docker/taxi_dispatch/data/module:/opt/module
      - /Users/zhinushannan/docker/taxi_dispatch/data/slave2_dir:/opt/work_dir
    networks:
      test:
        ipv4_address: 172.18.0.4
  
  mysql_hadoop:
    image: mysql/mysql-server:5.7
    container_name: mysql_hadoop
    hostname: mysql_hadoop
    volumes:
      - /Users/zhinushannan/docker/taxi_dispatch/data/var-lib-mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: hadoop
    networks:
      test:
        ipv4_address: 172.18.0.5


networks:
   test:
      ipam:
         config:
           - subnet: 172.18.0.0/16


```

# 配置免密登录


## 配置`hosts`文件

参考文章：[浅谈hosts文件](https://dream.kwcoder.club/p/20220706/)

修改`master`、`slave1`、`slave2`以及宿主机的`hosts`文件：

```text
# hadoop
172.18.0.2	master
172.18.0.3	slave1
172.18.0.4	slave2
```


## 配置免密登录

在每一台机器上生成公钥私钥`ssh-keygen -t rsa`，执行这个命令之后，需要连续按三次回车。

在每一台机器人上执行如下命令，将公钥拷贝到需要免密登录的机器上，从而实现免密登录。需要按照提示输入对方用户的登录密码。

```shell
ssh-copy-id master
ssh-copy-id slave1
ssh-copy-id slave2
```

# 配置环境

## 拷贝相关软件

将适合自己架构的Java和Hadoop解压并拷贝进相关目录。

![2数据挂载卷](https://picgo.kwcoder.club/202206/202206261621308.png)

## 配置环境变量

通过ssh登录其中一台机器，修改`/etc/profile`文件，在最后添加：

```shell
# java
export JAVA_HOME=/opt/module/jdk1.8.0_333
export HRE_HOME=$JAVA_HOME:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export PATH=$JAVA_HOME/bin:$PATH

# hadoop
export HADOOP_HOME=/opt/module/hadoop-3.3.1
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
```

添加完成后编译一下该文件，执行`java -version`和`hadoop version`指令检测是否配置成功。

利用`rsync`工具将环境配置文件拷贝到其他机器上：

```shell
rsync -v /etc/profile slave1:/etc/profile
rsync -v /etc/profile slave2:/etc/profile
```

进入其他机器编译环境配置文件，并检测环境是否生效。

# 配置Hadoop

## 配置文件说明

Hadoop 配置文件分两类：默认配置文件和自定义配置文件，只有用户想修改某一默认配置值时，才需要修改自定义配置文件，更改相应属性值。

## 默认配置文件

|  要获取的默认文件  |      文件存放在Hadoop的jar包中的位置       |
| :----------------: | :----------------------------------------: |
|  core-default.xml  |  hadoop-common-3.3.1.jar/core-default.xml  |
|  hdfs-default.xml  |   hadoop-hdfs-3.3.1.jar/hdfs-default.xml   |
|  yarn-default.xml  |   hadoop-yarn-3.3.1.jar/yarn-default.xml   |
| mapred-default.xml | hadoop-mapred-3.3.1.jar/mapred-default.xml |


## 自定义配置文件

`core-site.xml`、`hdfs-site.xml`、`yarn-site.xml`、`mapred-site.xml`四个配置文件存放在`$HADOOP_HOME/etc/hadoop`这个路径上，用户可以根据项目需求重新进行修改配置。

## 修改配置文件

### 配置`$HADOOP_HOME/etc/hadoop/hadoop-env.sh`

设置hadoop运行所需环境变量

修改其中的：

```shell
export JAVA_HOME=/opt/module/jdk1.8.0_333/  # jdk存储目录，根据自己的机器来填写
export HADOOP_LOG_DIR=/opt/hadoop_dir/logs  # 日志存储目录，根据dockerfile中的环境变量填写
export HADOOP_PID_DIR=/opt/hadoop_dir/pids  # pid文件存储目录，根据dockerfile中的环境变量填写

# 如下内容追加在文件末尾（运行用户设置）
# user
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root
export YARN_RESOURCEMANEGER_USER=root
export YARN_NODEMANEGER_USER=root
```

### 配置`$HADOOP_HOME/etc/hadoop/workers`

设置数据节点服务器（datanode）的主机信息

```shell
slave1
slave2
```

### 配置``$HADOOP_HOME/etc/hadoop/core-site.xml`

配置hadoop集群的全局参数

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <!-- 指定NameNode的地址 -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://master:9000</value>
    </property>

    <!-- 指定hadoop数据的存储目录，根据dockerfile填写 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop_dir/temp</value>
    </property>
  
    <!-- 用户代理机制：表示root用户可以代理主机上的所有用户 -->
    <property>
        <name>hadoop.proxyuser.root.hosts</name>
        <value>*</value>
    </property>
  
    <!-- 用户代理机制：表示root组可以代理主机上的所有组 -->
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>

</configuration>
```

### 配置`$HADOOP_HOME/etc/hadoop/hdfs-site.xml`

设置HDFS（hadoop分布式文件系统）参数

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    
    <!-- NameNode 原数据存储位置 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop_dir/name</value>
    </property>
  
  	<!-- DataNode在本地磁盘存放block的位置 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop_dir/data</value>
    </property>
  
    <!-- 备份数：即在文件被写入的时候，每一块将要被复制多少份  -->
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>

  	<!-- secondary namenode HTTP服务器地址和端口 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>master:9001</value>
    </property>
  
  	<!-- 是否允许在namenode和datanode中启用WebHDFS (REST API) -->
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>  
  
    <!-- 当为true时，则允许HDFS的检测，当为false时，则关闭HDFS的检测，但不影响其它HDFS的其它功能。 -->
    <property>
        <name>dfs.permissions</name>
        <value>false</value>
    </property>  

    <!-- namenode HTTP服务器地址和端口 -->
    <property>
        <name>dfs.http.address</name>
        <value>0.0.0.0:50070</value>
    </property>  

</configuration>
```

### 配置`$HADOOP_HOME/etc/hadoop/yarn-site.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <!-- 指定MR走shuffle -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>

    <!-- 指定ResourceManager的地址-->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>master</value>
    </property>

</configuration>
```

### 配置`$HADOOP_HOME/etc/hadoop/mapred-site.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <!-- 指定MapReduce程序运行在Yarn上 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
  
    <!-- yarn运行时参数 -->
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>  
  
    <!-- map 运行时参数 -->
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
  
    <!-- reduce 运行时参数 -->
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>  
  
</configuration>
```


# 启动集群与案例

## 启动集群

在机器master上：
初始化`namenode`：

```shell
hdfs namenode -format
```

启动集群：

```shell
start-all.sh
```

启动历史服务器：

```shell
mapred --daemon start historyserver
```

停止集群：

```shell
stop-all.sh
```

停止历史服务器：

```shell
mapred --daemon stop historyserver
```

> 注意：如果需要重新格式化，最好将`hadoop_dir`文件夹删除！

## WEB端界面查看

### 数据节点服务器 - NameNode

[http://master:50070](http://master:50070)

![3namenode_web](https://picgo.kwcoder.club/202206/202207071001178.png)

>  注意：不要通过IP访问，否则将无法通过WEB端上传文件。

### 资源管理服务器 - ResourceManager

[http://master:8088/](http://master:8088/)

![4all_application](https://picgo.kwcoder.club/202206/202207071004255.png)



### 历史服务器 - JobHistory

[http://master:19888/](http://master:19888/)

![image-20220707100615842](https://picgo.kwcoder.club/202206/202207071006860.png)



## WordCount案例



![6浏览器文件管理](https://picgo.kwcoder.club/202206/202207071011825.png)





进入浏览器端的文件管理，创建demo文件夹，并上传一个纯文本文件：



![7创建demo](https://picgo.kwcoder.club/202206/202207071014493.png)

![8上传文件](https://picgo.kwcoder.club/202206/202207071016804.png)



在终端中执行：

```shell
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.1.jar wordcount /demo /wc
```

> 解释：运行Hadoop的jar包案例，给`hadoop-mapreduce-examples-3.3.1.jar`传递参数`wordcount`表示使用词频统计案例，`/demo`指的是待统计的文件的位置，`/wc`指的是结果输出目录，结果输出目录不能存在，否则会报错。

等待运行完成后，在终端执行如下命令查看结果：

```shell
hdfs dfs -cat /wc/*
```

> 解释：查看`hdfs`中的`/wc`目录下所有的文件

# 常见错误解决

## 提示没有JAVA_HOME

在`$HADOOP_HOME/etc/hadoop/hadoop-env.sh`中的`export JAVA_HOME=`后手动填写`JAVA_HOME`的值。

## 启动HDFS报错

```shell
[root@8609fa1a900d hadoop-3.3.1]# sbin/start-dfs.sh
Starting namenodes on [hadoop01]
ERROR: Attempting to operate on hdfs namenode as root
ERROR: but there is no HDFS_NAMENODE_USER defined. Aborting operation.
Starting datanodes
ERROR: Attempting to operate on hdfs datanode as root
ERROR: but there is no HDFS_DATANODE_USER defined. Aborting operation.
Starting secondary namenodes [hadoop03]
ERROR: Attempting to operate on hdfs secondarynamenode as root
ERROR: but there is no HDFS_SECONDARYNAMENODE_USER defined. Aborting operation.
2022-06-26 08:08:02,653 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
```

在 `$HADOOP_HOME/sbin` 路径下，将 `start-dfs.sh` 、 `stop-dfs.sh` 两个文件顶部添加以下参数

```shell
HDFS_DATANODE_USER=root
HADOOP_SECURE_DN_USER=hdfs
HDFS_NAMENODE_USER=root
HDFS_SECONDARYNAMENODE_USER=root
```

## 启动YARN报错

```shell
[root@0fd5f4a17b7d hadoop-3.3.1]# start-yarn.sh
Starting resourcemanager
ERROR: Attempting to operate on yarn resourcemanager as root
ERROR: but there is no YARN_RESOURCEMANAGER_USER defined. Aborting operation.
Starting nodemanagers
ERROR: Attempting to operate on yarn nodemanager as root
ERROR: but there is no YARN_NODEMANAGER_USER defined. Aborting operation.
```

在`start-yarn.sh`，`stop-yarn.sh`顶部添加以下参数：

```shell
YARN_RESOURCEMANAGER_USER=root
HADOOP_SECURE_DN_USER=yarn
YARN_NODEMANAGER_USER=root
```

# 完全删除集群

```shell
# 停止容器
docker stop hadoop01 hadoop02 hadoop03
# 删除容器
docker rm hadoop01 hadoop02 hadoop03
# 删除网络
docker network rm hadoop_test
# 删除数据卷（或者保留供下次使用）
rm -r /Users/zhinushannan/code/hadoop/module
```

