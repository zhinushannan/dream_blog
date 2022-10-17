```text
Docker Compose暴力入门
运维>Docker
2022-06-22
https://picgo.kwcoder.club/202206/202206211837629.png
```





# Docker Compose

Docker Compose是Docker官方的开源项目，负责实现对Docker容器集群的快速编排，可以管理多个Docker容器组成一个应用。
需要定义一个yaml文件docker-compose.yml，写好多个容器之间的调用关系，只要一个命令即可同时启动/关闭这些容器。

# Docker-Compose的功能

Docker建议每个容器中只运行一个服务，因为Docker容器本身占用资源极少，所以最好是将每个服务单独的分隔开来。但是这样就会面临同时需要部署多个服务，然后为每个服务单独写Dockerfile构建镜像、构建容器，工作非常繁琐。

而Docker-Compose允许用户通过一个单独的docker-compose.yml模版文件来定义一组相关联的应用容器为一个项目(project)。
这样就可以很容易的用一个配置文件定义一个多容器的应用，然后使用一条指令安装应用的所有依赖，完成构建。
Docker-Compose解决了容器与容器之间如何管理编排的问题。

# 官网

官网：[https://docs.docker.com/compose/compose-file/compose-file-v3/](https://docs.docker.com/compose/compose-file/compose-file-v3/)

官网下载：[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

<img src="https://picgo.kwcoder.club/202206/202206261624472.png" alt="4-1Docker-Compose官网" style="zoom:50%;" />

# 核心概念：一个文件两个要素

一个文件：docker-compose.yml
两个要素：

- 服务（service）：一个个应用容器实例，例如订单微服务、、库存为服务、mysql容器等。
- 工程（project）：由一组关联的应用容器组成的一个完成业务单元，在docker-compose.yml文件中定义。

工程 = 多个服务（容器应用实例）

# 三个步骤

1. 编写Dockerfile定义哥哥微服务应用并构建出对应的镜像文件
2. 使用docker-compose.yml定义一个完成业务但愿，安排好整体应用中的各个容器服务
3. 执行docker-compose up命令，启动并运行整个应用程序，完成一键部署上线

# 常用命令

```shell
docker-compose -h  # 查看帮助
docker-compose up  # 启动所有docker-compose服务
docker-compose up -d  # 启动所有docker-compose服务并后台运行
docker-compose down  # 停止并删除容器、网络、卷、镜像
docker-compose exec [id] bash # 进入容器实例内部
docker-compose ps  # 展示当前docker-compose编排过的运行的所有容器
docker-compose top  # 展示当前docker-compose编排过的容器进程

docker-compose logs [id]  # 查看容器输出日志
docker-compose config  # 检查配置
docker-compose config -q  # 检查配置，有问题输出
docker-compose restart  # 重启服务
docker-compose start  #  启动服务
docker-compose stop  # 停止服务
```

# docker-compose.yml

```yaml
version: "3"  # docker-compose 版本号

services:
  services1:  # 服务名
    image: image_name:tag  # 镜像
    container_name: container_name1  # 容器名
    ports:
      - "1111:1111"  # 端口映射 hostPort:containerPort
    volumes:
      - /test:/test  # 数据挂载卷 hostVolume:containerVolume
    networks:
      - test  # 网桥
    depends_on:
      - container_name2  # 依赖的容器

  service2:
    image: image_name:tag  # 镜像
    container_name: container_name2  # 容器名
    ports:
      - "1111:1111"  # 端口映射 hostPort:containerPort
    volumes:
      - /test:/test  # 数据挂载卷 hostVolume:containerVolume
    networks:
      - test  # 网桥

networks:
  test:

```

执行`docker-compose up`即可运行，执行`docker-compose stop`停止所有容器。

如上配置文件相当于：

```shell
docker network create test
docker run -d image_name:tag --name container_name1 --port 1111:1111 -v /test:/test --network test 
docker run -d image_name:tag --name container_name2 --port 1111:1111 -v /test:/test --network test 
```
