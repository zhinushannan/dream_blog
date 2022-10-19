```text
Hive客户端——shell、beeline、dbeaver
大数据>Hive
2022-08-09
https://picgo.kwcoder.club/202208/202208161604333.png
```

众多数据库客户端支持hive，除了hive shell、beeline官方自带的，dbeaver、datagrip等均支持hive数据库连接。

# hive shell

在服务器执行`hive shell`打开hive shell客户端，执行`exit;`退出客户端。

```shell
[root@master ~]# hive shell
SLF4J: Class path contains multiple SLF4J bindings.
SLF4J: Found binding in [jar:file:/opt/module/hbase-2.4.13/lib/client-facing-thirdparty/slf4j-reload4j-1.7.33.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: Found binding in [jar:file:/opt/module/hadoop-3.3.1/share/hadoop/common/lib/slf4j-log4j12-1.7.30.jar!/org/slf4j/impl/StaticLoggerBinder.class]
SLF4J: See http://www.slf4j.org/codes.html#multiple_bindings for an explanation.
SLF4J: Actual binding is of type [org.slf4j.impl.Reload4jLoggerFactory]
2022-08-16 18:39:43,266 INFO  [main] conf.HiveConf: Found configuration file file:/opt/module/hive-3.1.3/conf/hive-site.xml
2022-08-16 18:39:44,041 WARN  [main] util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
2022-08-16 18:39:44,510 WARN  [main] conf.HiveConf: HiveConf of name hive.enforce.bucketing does not exist
2022-08-16 18:39:46,564 WARN  [main] conf.HiveConf: HiveConf of name hive.enforce.bucketing does not exist
Hive Session ID = 46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:39:46,588 INFO  [main] SessionState: Hive Session ID = 46b7010e-bad4-4cad-8915-a4a547aab547

Logging initialized using configuration in file:/opt/module/hive-3.1.3/conf/hive-log4j2.properties Async: true
2022-08-16 18:39:46,723 INFO  [main] SessionState: 
Logging initialized using configuration in file:/opt/module/hive-3.1.3/conf/hive-log4j2.properties Async: true
2022-08-16 18:39:49,752 INFO  [main] session.SessionState: Created HDFS directory: /tmp/hive/root/46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:39:49,776 INFO  [main] session.SessionState: Created local directory: /opt/hive_dir/46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:39:49,780 INFO  [main] session.SessionState: Created HDFS directory: /tmp/hive/root/46b7010e-bad4-4cad-8915-a4a547aab547/_tmp_space.db
2022-08-16 18:39:49,820 INFO  [main] conf.HiveConf: Using the default value passed in for log id: 46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:39:49,820 INFO  [main] session.SessionState: Updating thread name to 46b7010e-bad4-4cad-8915-a4a547aab547 main
2022-08-16 18:39:49,915 WARN  [46b7010e-bad4-4cad-8915-a4a547aab547 main] conf.HiveConf: HiveConf of name hive.enforce.bucketing does not exist
2022-08-16 18:39:51,106 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] metastore.HiveMetaStoreClient: Trying to connect to metastore with URI thrift://master:9083
2022-08-16 18:39:51,134 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] metastore.HiveMetaStoreClient: Opened a connection to metastore, current connections: 1
2022-08-16 18:39:51,217 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] metastore.HiveMetaStoreClient: Connected to metastore.
2022-08-16 18:39:51,217 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] metastore.RetryingMetaStoreClient: RetryingMetaStoreClient proxy=class org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient ugi=root (auth:SIMPLE) retries=1 delay=1 lifetime=0
Hive Session ID = 52f8fdb1-67e6-4cf2-a5f5-ed4f25cec143
2022-08-16 18:39:51,484 INFO  [pool-7-thread-1] SessionState: Hive Session ID = 52f8fdb1-67e6-4cf2-a5f5-ed4f25cec143
Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.
2022-08-16 18:39:51,490 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] CliDriver: Hive-on-MR is deprecated in Hive 2 and may not be available in the future versions. Consider using a different execution engine (i.e. spark, tez) or using Hive 1.X releases.
2022-08-16 18:39:51,499 INFO  [pool-7-thread-1] session.SessionState: Created HDFS directory: /tmp/hive/root/52f8fdb1-67e6-4cf2-a5f5-ed4f25cec143
2022-08-16 18:39:51,507 INFO  [pool-7-thread-1] session.SessionState: Created local directory: /opt/hive_dir/52f8fdb1-67e6-4cf2-a5f5-ed4f25cec143
2022-08-16 18:39:51,512 INFO  [pool-7-thread-1] session.SessionState: Created HDFS directory: /tmp/hive/root/52f8fdb1-67e6-4cf2-a5f5-ed4f25cec143/_tmp_space.db
2022-08-16 18:39:51,587 INFO  [pool-7-thread-1] metadata.HiveMaterializedViewsRegistry: Materialized views registry has been initialized
hive> show databases;
2022-08-16 18:40:08,181 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] conf.HiveConf: Using the default value passed in for log id: 46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:40:08,404 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Compiling command(queryId=root_20220816184008_9c0d8e3e-2830-4003-9b47-67571aa470bb): show databases
2022-08-16 18:40:09,026 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Semantic Analysis Completed (retrial = false)
2022-08-16 18:40:09,118 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Returning Hive schema: Schema(fieldSchemas:[FieldSchema(name:database_name, type:string, comment:from deserializer)], properties:null)
2022-08-16 18:40:09,313 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] exec.ListSinkOperator: Initializing operator LIST_SINK[0]
2022-08-16 18:40:09,334 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Completed compiling command(queryId=root_20220816184008_9c0d8e3e-2830-4003-9b47-67571aa470bb); Time taken: 1.01 seconds
2022-08-16 18:40:09,335 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] reexec.ReExecDriver: Execution #1 of query
2022-08-16 18:40:09,335 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Executing command(queryId=root_20220816184008_9c0d8e3e-2830-4003-9b47-67571aa470bb): show databases
2022-08-16 18:40:09,355 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Starting task [Stage-0:DDL] in serial mode
2022-08-16 18:40:09,360 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] exec.DDLTask: results : 1
2022-08-16 18:40:09,429 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: Completed executing command(queryId=root_20220816184008_9c0d8e3e-2830-4003-9b47-67571aa470bb); Time taken: 0.094 seconds
OK
2022-08-16 18:40:09,429 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] ql.Driver: OK
2022-08-16 18:40:09,443 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] Configuration.deprecation: mapred.input.dir is deprecated. Instead, use mapreduce.input.fileinputformat.inputdir
2022-08-16 18:40:09,607 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] mapred.FileInputFormat: Total input files to process : 1
2022-08-16 18:40:09,693 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] exec.ListSinkOperator: RECORDS_OUT_INTERMEDIATE:0, RECORDS_OUT_OPERATOR_LIST_SINK_0:1, 
default
Time taken: 1.108 seconds, Fetched: 1 row(s)
2022-08-16 18:40:09,693 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] CliDriver: Time taken: 1.108 seconds, Fetched: 1 row(s)
2022-08-16 18:40:09,693 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] conf.HiveConf: Using the default value passed in for log id: 46b7010e-bad4-4cad-8915-a4a547aab547
2022-08-16 18:40:09,693 INFO  [46b7010e-bad4-4cad-8915-a4a547aab547 main] session.SessionState: Resetting thread name to  main
hive> 
```

# beeline

beeline是官方比较推荐的客户端，在终端执行`beeline -u jdbc:hive2://[host]:10000`进入beeline客户端，执行`!exit`退出客户端。

```shell
[root@master ~]# beeline -u jdbc:hive2://master:10000
Connecting to jdbc:hive2://master:10000
2022-08-16 18:58:40,586 WARN  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: HiveConf of name hive.enforce.bucketing does not exist
2022-08-16 18:58:40,615 INFO  [HiveServer2-Handler-Pool: Thread-39] thrift.ThriftCLIService: Client protocol version: HIVE_CLI_SERVICE_PROTOCOL_V10
2022-08-16 18:58:40,663 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Created HDFS directory: /tmp/hive/anonymous/df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,670 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Created local directory: /opt/hive_dir/df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,673 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Created HDFS directory: /tmp/hive/anonymous/df0b9db4-9d53-4ae5-a585-07a0c2ddc232/_tmp_space.db
2022-08-16 18:58:40,692 INFO  [HiveServer2-Handler-Pool: Thread-39] metastore.HiveMetaStoreClient: Trying to connect to metastore with URI thrift://master:9083
2022-08-16 18:58:40,693 INFO  [HiveServer2-Handler-Pool: Thread-39] metastore.HiveMetaStoreClient: Opened a connection to metastore, current connections: 2
2022-08-16 18:58:40,707 WARN  [HiveServer2-Handler-Pool: Thread-39] security.ShellBasedUnixGroupsMapping: unable to return groups for user anonymous
2022-08-16 18:58:40,715 INFO  [HiveServer2-Handler-Pool: Thread-39] metastore.HiveMetaStoreClient: Connected to metastore.
2022-08-16 18:58:40,715 INFO  [HiveServer2-Handler-Pool: Thread-39] metastore.RetryingMetaStoreClient: RetryingMetaStoreClient proxy=class org.apache.hadoop.hive.ql.metadata.SessionHiveMetaStoreClient ugi=anonymous (auth:PROXY) via root (auth:SIMPLE) retries=1 delay=1 lifetime=0
2022-08-16 18:58:40,749 INFO  [HiveServer2-Handler-Pool: Thread-39] session.HiveSessionImpl: Operation log session directory is created: /opt/hive_dir/df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,751 INFO  [HiveServer2-Handler-Pool: Thread-39] service.CompositeService: Session opened, SessionHandle [df0b9db4-9d53-4ae5-a585-07a0c2ddc232], current sessions:1
2022-08-16 18:58:40,816 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,816 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:40,818 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,818 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:40,906 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,906 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:40,906 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,906 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
Connected to: Apache Hive (version 3.1.3)
Driver: Hive JDBC (version 3.1.3)
Transaction isolation: TRANSACTION_REPEATABLE_READ
2022-08-16 18:58:40,912 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,912 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:40,939 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:40,939 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
Beeline version 3.1.3 by Apache Hive
0: jdbc:hive2://master:10000> show databases;
2022-08-16 18:58:44,257 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:44,257 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:44,278 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] operation.OperationManager: Adding operation: OperationHandle [opType=EXECUTE_STATEMENT, getHandleIdentifier()=fb5eabea-492f-4e87-93bb-e4f3512c03be]
2022-08-16 18:58:44,383 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] ql.Driver: Compiling command(queryId=root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3): show databases
2022-08-16 18:58:45,306 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] ql.Driver: Semantic Analysis Completed (retrial = false)
2022-08-16 18:58:45,401 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] ql.Driver: Returning Hive schema: Schema(fieldSchemas:[FieldSchema(name:database_name, type:string, comment:from deserializer)], properties:null)
2022-08-16 18:58:45,550 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] exec.ListSinkOperator: Initializing operator LIST_SINK[0]
2022-08-16 18:58:45,566 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] ql.Driver: Completed compiling command(queryId=root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3); Time taken: 1.235 seconds
2022-08-16 18:58:45,567 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,567 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,637 INFO  [HiveServer2-Background-Pool: Thread-44] reexec.ReExecDriver: Execution #1 of query
2022-08-16 18:58:45,638 INFO  [HiveServer2-Background-Pool: Thread-44] ql.Driver: Executing command(queryId=root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3): show databases
2022-08-16 18:58:45,652 INFO  [HiveServer2-Background-Pool: Thread-44] ql.Driver: Starting task [Stage-0:DDL] in serial mode
2022-08-16 18:58:45,663 INFO  [HiveServer2-Background-Pool: Thread-44] sqlstd.SQLStdHiveAccessController: Created SQLStdHiveAccessController for session context : HiveAuthzSessionContext [sessionString=df0b9db4-9d53-4ae5-a585-07a0c2ddc232, clientType=HIVESERVER2]
2022-08-16 18:58:45,664 INFO  [HiveServer2-Background-Pool: Thread-44] exec.DDLTask: results : 1
2022-08-16 18:58:45,735 INFO  [HiveServer2-Background-Pool: Thread-44] ql.Driver: Completed executing command(queryId=root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3); Time taken: 0.097 seconds
OK
2022-08-16 18:58:45,735 INFO  [HiveServer2-Background-Pool: Thread-44] ql.Driver: OK
2022-08-16 18:58:45,802 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,802 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,806 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,806 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,890 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,890 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,896 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,896 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,933 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:45,933 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:45,945 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] Configuration.deprecation: mapred.input.dir is deprecated. Instead, use mapreduce.input.fileinputformat.inputdir
2022-08-16 18:58:46,143 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] mapred.FileInputFormat: Total input files to process : 1
2022-08-16 18:58:46,217 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] exec.ListSinkOperator: RECORDS_OUT_INTERMEDIATE:0, RECORDS_OUT_OPERATOR_LIST_SINK_0:1, 
2022-08-16 18:58:46,217 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,217 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,219 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,219 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,219 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,219 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
+----------------+
| database_name  |
+----------------+
| default        |
2022-08-16 18:58:46,220 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,220 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,220 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,220 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
+----------------+
1 row selected (2.009 seconds)
2022-08-16 18:58:46,221 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,221 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,221 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,221 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,241 INFO  [HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,241 INFO  [HiveServer2-Handler-Pool: Thread-39] session.SessionState: Updating thread name to df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39
2022-08-16 18:58:46,241 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] operation.OperationManager: Closing operation: OperationHandle [opType=EXECUTE_STATEMENT, getHandleIdentifier()=fb5eabea-492f-4e87-93bb-e4f3512c03be]
2022-08-16 18:58:46,241 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] operation.OperationManager: Removed queryId: root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3 corresponding to operation: OperationHandle [opType=EXECUTE_STATEMENT, getHandleIdentifier()=fb5eabea-492f-4e87-93bb-e4f3512c03be]
2022-08-16 18:58:46,243 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] operation.Operation: Closing operation log /opt/hive_dir/df0b9db4-9d53-4ae5-a585-07a0c2ddc232/root_20220816185844_042d8bd9-f4b9-4e3a-9a18-0216b03d16f3 without delay
2022-08-16 18:58:46,243 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] conf.HiveConf: Using the default value passed in for log id: df0b9db4-9d53-4ae5-a585-07a0c2ddc232
2022-08-16 18:58:46,243 INFO  [df0b9db4-9d53-4ae5-a585-07a0c2ddc232 HiveServer2-Handler-Pool: Thread-39] session.SessionState: Resetting thread name to  HiveServer2-Handler-Pool: Thread-39

```


# dbeaver



![3-1dbeaver连接hive](https://picgo.kwcoder.club/202208/202208161906531.png)



点击完成即可创建链接。