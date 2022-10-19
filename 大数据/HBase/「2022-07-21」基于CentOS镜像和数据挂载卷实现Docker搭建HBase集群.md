```text
基于CentOS镜像和数据挂载卷实现Docker搭建HBase集群
大数据>HBase
2022-07-21
https://picgo.kwcoder.club/202208/202207211953477.png
```






# 前置准备

拥有三台具有Hadoop和Zookeeper的容器。

[基于CentOS7镜像和数据挂载卷实现Docker搭建Hadoop集群](/p/20220626/)
[基于CentOS镜像和数据挂载卷实现Docker搭建Zookeeper集群](/p/20220718/)

# 配置环境变量

将HBase放入数据挂载卷中，配置环境变量`/etc/profile`。

```shell
# hbase
export HBASE_HOME=/opt/module/hbase-2.4.13
export PATH=$PATH:$HBASE_HOME/bin
```

利用`rsync`远程拷贝一下：

```shell
rsync -v /etc/profile slave1:/etc/profile
rsync -v /etc/profile slave2:/etc/profile
```

配置完成后，`source /etc/profile`，执行`hbase version`查看是否配置成功。

# 配置HBase

## 修改`$HBASE_HOME/conf/hbase-env.sh`

修改其中的`JAVA_HOME`、`HBASE_LOG_DIR`、`HBASE_PID_DIR`、`HBASE_MANAGERS_ZK`（可在末尾直接添加）：

```shell
export JAVA_HOME=/opt/module/jdk1.8.0_333
export HBASE_LOG_DIR=/opt/module/hbase_dir/logs
export HBASE_PID_DIR=/opt/module/hbase_dir/pids
# 不使用内置的zookeeper
export HBASE_MANAGERS_ZK=false
```

## 修改`$HBASE_HOME/conf/hbase-site.xml`

在`configuration`标签中添加：

```xml
<property>
        <!-- 是不是一个分布式的 -->
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.tmp.dir</name>
        <value>/opt/hbase_dir</value>
    </property>
    <property>
        <name>hbase.unsafe.stream.capability.enforce</name>
        <value>false</value>
    </property>
    <!-- 在hdfs上存储路径 -->
    <property>
        <name>hbase.rootdir</name>
        <value>hdfs://master:9000/hbase</value>
    </property>
        <!-- zookeeper集群配置：通讯端口号 -->
    <property>
        <name>hbase.zookeeper.property.clientPort</name>
        <value>2181</value>
    </property>
    <!-- zookeeper集群配置：服务器列表 -->
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>master,slave1,slave2</value>
    </property>
    <!-- zookeeper集群配置：有效时间，建议稍长些 -->
    <property>
        <name>zookeeper.session.timeout</name>
        <value>120000</value>
    </property>
    
    <!-- WAL设置 -->
    <property>
        <name>hbase.wal.provider</name>
        <value>filesystem</value>
    </property>
```

## 修改`$HBASE_HOME/conf/regionservers`

内容为从机地址。

```text
slave1
slave2
```

## 拷贝包——避免运行时输出异常信息

将`$HBASE_HOME/lib/client-facing-thirdparty/`下的`htrace-core4-4.2.0-incubating.jar`拷贝至`$HBASE_HOME/lib/`目录。

# 启动集群

首先应当启动Hadoop和Zookeeper。

执行`start-hbase.sh`启动HBase集群，执行`stop-hbase.sh`关闭HBase集群。

> 注意：在启动HBase之前应当先启动Hadoop和Zookeeper，在关闭HBase时，应当先关闭HBase，再关闭Hadoop和Zookeeper。

运行成功后，打开[http://master:16010/master-status](http://master:16010/master-status)

![HBase_Web界面](https://picgo.kwcoder.club/202208/202207222037214.png)





