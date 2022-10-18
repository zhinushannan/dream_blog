```text
Spring Boot Logback 日志配置
2022-06-27
Java
https://picgo.kwcoder.club/202206/202206271820902.png
```





# Spring Boot原生日志

默认情况下，Spring Boot会用Logback来记录日志，并用INFO级别输出到控制台。
启动一个SpringBoot项目，会出现如下日志：

```shell
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v2.3.7.RELEASE)

2022-06-27 14:53:34.390  INFO 66389 --- [  restartedMain] c.e.l.LogbackStudyApplication            : Starting LogbackStudyApplication on zhinushannan-deMacBook-Air.local with PID 66389 (/Users/zhinushannan/code/druid-study/logback-study/target/classes started by zhinushannan in /Users/zhinushannan/code/druid-study/logback-study)
2022-06-27 14:53:34.402  INFO 66389 --- [  restartedMain] c.e.l.LogbackStudyApplication            : No active profile set, falling back to default profiles: default
2022-06-27 14:53:34.459  INFO 66389 --- [  restartedMain] .e.DevToolsPropertyDefaultsPostProcessor : Devtools property defaults active! Set 'spring.devtools.add-properties' to 'false' to disable
2022-06-27 14:53:34.459  INFO 66389 --- [  restartedMain] .e.DevToolsPropertyDefaultsPostProcessor : For additional web related logging consider setting the 'logging.level.web' property to 'DEBUG'
2022-06-27 14:53:35.580  INFO 66389 --- [  restartedMain] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8080 (http)
2022-06-27 14:53:35.586  INFO 66389 --- [  restartedMain] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2022-06-27 14:53:35.586  INFO 66389 --- [  restartedMain] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.41]
2022-06-27 14:53:35.653  INFO 66389 --- [  restartedMain] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2022-06-27 14:53:35.653  INFO 66389 --- [  restartedMain] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1194 ms
2022-06-27 14:53:35.958  INFO 66389 --- [  restartedMain] o.s.s.concurrent.ThreadPoolTaskExecutor  : Initializing ExecutorService 'applicationTaskExecutor'
2022-06-27 14:53:36.088  INFO 66389 --- [  restartedMain] o.s.b.d.a.OptionalLiveReloadServer       : LiveReload server is running on port 35729
2022-06-27 14:53:36.125  INFO 66389 --- [  restartedMain] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2022-06-27 14:53:36.142  INFO 66389 --- [  restartedMain] c.e.l.LogbackStudyApplication            : Started LogbackStudyApplication in 2.087 seconds (JVM running for 3.039)

```

在上述日志中，包括：

- 时间：2022-06-27 14:53:34.390
- 日志等级：INFO
- 进程ID：66389
- 分隔符：---
- 线程名：由中括号包起来的[  restartedMain]
- Logger名：通常是源代码的类名c.e.l.LogbackStudyApplication
- 日志内容：冒号后面的`Starting LogbackStudyApplication on zhinushannan-deMacBook-Air.local with PID 66389 (/Users/zhinushannan/code/druid-study/logback-study/target/classes started by zhinushannan in /Users/zhinushannan/code/druid-study/logback-study)`





# 日志输出

默认情况下，Spring Boot以INFO级别将日志输出到控制台，不会写到日志文件。
用户可以自定义修改日志等级和输出方式。

## 级别控制

### 日志等级

日志级别从低到高分为TRACE < DEBUG < INFO < WARN < ERROR < FATAL，如果设置为WARN，则低于WARN的信息都不会输出。
Spring Boot中默认配置INFO级别，即ERROR、WARN和INFO级别的日志输出到控制台。

### 修改全局等级

修改日志等级的方式：

- 打成jar包，在执行时指定：
  - `java -jar springTest.jar --trace`
  - `java -jar springTest.jar --debug`
  - `java -jar springTest.jar --info`
  - `java -jar springTest.jar --warn`
  - `java -jar springTest.jar --error`
  - `java -jar springTest.jar --fatal`

- 在`application.properties`中指定：
  - `trace=true`
  - `debug=true`
  - `info=true`
  - `warn=true`
  - `error=true`
  - `fatal=true`

### 修改指定日志等级

在`application.properties`中指定：`logging.level.[包名/类全名]=[level]`


## 文件输出

在`application.properties`中指定：

- 设置文件全路径，日志将输出到文件中：`logging.file.name=[file]`
- 设置目录，日志将输出到文件夹：`logging.file.path=[path]`，如果只设置此项，则会在对应文件夹下生成`spring.log`日志文件


# 自定义日志配置

在`resources`目录下新建`logback.xml`文件，或在`application.properties`中通过`logging.config=`指定配置文件的路径。

配置文件的结构为：
{% mermaid %}
graph LR
A[configuration]
A --> contextName
A --> property
A --> appender
A --> logger
A --> root
{% endmermaid %}

## 根结点`configuration`

包含属性：

- scan：当此属性设置为true时，配置文件如果发生改变，将会被重新加载，默认值为true
- scanPeriod：设置监测配置文件是否有修改的时间间隔，单位默认时毫秒。当scan为true时，此属性生效，默认时间间隔为1分钟。
- debug：当此属性设置为true时，将打印logback内部日志信息，实时查看logback运行状态。默认值为false。


```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <!--其他配置省略-->
</configuration>
```

## 子节点`contextName`

用来设置上下文名称，每个logger都关联到logger上下文，默认上下文名称为default。但可以使用<contextName>设置成其他名字，用于区分不同应用程序的记录。一旦设置，不能修改。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <contextName>anotherName</contextName>
  <!--其他配置省略-->
</configuration>
```

## 子节点`property`

用于定义变量供下文引用。

```xml
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <property name="context_name" value="anotherName" />
  <contextName>${context_name}</contextName>
  <!--其他配置省略-->
</configuration>
```

## 子节点`appender`

appender用来格式化日志输出节点，有俩个属性name和class，class用来指定哪种输出策略，常用就是控制台输出策略和文件输出策略。


```xml
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <property name="context_name" value="anotherName" />
  <contextName>${context_name}</contextName>

  <!--输出到控制台-->
  <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <!--输出到文件-->
  <appender name="file" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>${log.path}/logback.%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
      <totalSizeCap>1GB</totalSizeCap>
    </rollingPolicy>
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>
  
  <!--其他配置省略-->
</configuration>
```

在encoder中，参数如下：

- %d : 输出日志的时间点的日期或时间，可以在其后指定格式，如：%d{yyyy-MM-dd HH:mm:ss.SSS}
- %p : 输出日志的优先级，DEBUG、INFO、WARN、ERROR、FATAL
- %c : 输出日志的发生所在类全名
- %M : 输出日志的发生所在的方法名
- %l : 输出日志的发生位置，即在代码中的行数
- %t : 输出日志的所属线程名
- %m : 输出代码中指定的消息
- %r : 输出应用自启动到输出该log信息耗费的毫秒数
- %n : 输出一个回车换行符

其中%-5level表示输出日志的级别，并且使用5个字符靠左对齐。


在rollingPolicy中：

- <fileNamePattern>${log.path}/logback.%d{yyyy-MM-dd}.log</fileNamePattern>定义了日志的切分方式——把每一天的日志归档到一个文件中
- <maxHistory>30</maxHistory>表示只保留最近30天的日志，以防止日志填满整个磁盘空间。同理，可以使用%d{yyyy-MM-dd_HH-mm}来定义精确到分的日志切分方式
- <totalSizeCap>1GB</totalSizeCap>用来指定日志文件的上限大小，例如设置为1GB的话，那么到了这个值，就会删除旧的日志

## 子节点root

root节点是必选节点，用来指定最基础的日志输出级别，只有一个level属性，用来设置打印级别，大小写无关：TRACE, DEBUG, INFO, WARN, ERROR, ALL 和 OFF，不能设置为INHERITED或者同义词NULL。
默认是DEBUG。可以包含零个或多个元素，标识这个appender将会添加到这个logger。

```xml
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <property name="context_name" value="anotherName" />
  <contextName>${context_name}</contextName>

  <!--输出到控制台-->
  <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <!--输出到文件-->
  <appender name="file" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>${log.path}/logback.%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
      <totalSizeCap>1GB</totalSizeCap>
    </rollingPolicy>
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="debug">
    <appender-ref ref="console" />
    <appender-ref ref="file" />
  </root>
  
  <!--其他配置省略-->
</configuration>
```

## 子节点logger

<logger>用来设置某一个包或者具体的某一个类的日志打印级别、以及指定<appender>。<logger>仅有一个name属性，一个可选的level和一个可选的addtivity属性。

```xml
<configuration scan="true" scanPeriod="60 seconds" debug="false">
  <property name="context_name" value="anotherName" />
  <contextName>${context_name}</contextName>

  <!--输出到控制台-->
  <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <!--输出到文件-->
  <appender name="file" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>${log.path}/logback.%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
      <totalSizeCap>1GB</totalSizeCap>
    </rollingPolicy>
    <encoder>
      <pattern>%d{HH:mm:ss.SSS} %contextName [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>

  <root level="debug">
    <appender-ref ref="console" />
    <appender-ref ref="file" />
  </root>

  <logger name="club.kwcoder.test.controller.TestController" level="WARN" additivity="false">
    <appender-ref ref="console"/>
  </logger>
  
  <!--其他配置省略-->
</configuration>
```

- 控制club.kwcoder.test.controller.TestController类的日志打印，打印级别为“WARN”
- additivity属性为false，表示此logger的打印信息不再向上级传递
- 指定了名字为“console”的appender。

如果把additivity属性设置为true，则会在控制台打印两次，因为打印信息向上级传递，logger本身打印一次，root接到后又打印一次。