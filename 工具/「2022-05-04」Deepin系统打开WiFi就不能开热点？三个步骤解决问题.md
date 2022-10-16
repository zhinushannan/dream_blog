```text
Deepin系统打开WiFi就不能开热点？三个步骤解决问题
工具
2022-05-04
https://picgo.kwcoder.club/202206/202206221615882.png
```

Deepin工具：
<a href="/p/20220502/" target="_blank">【转载】Deepin 20.5系统外接扩展屏幕不显示？安装配置NVIDIA显卡驱动</a>
<a href="/p/20220503/" target="_blank">【转载】Deepin系统安装Go/Java8/Node/Maven/Docker环境</a>
<a href="/p/20220504/" target="_blank">Deepin系统打开WiFi就不能开热点？三个步骤解决问题</a>
<a href="/p/20220508/" target="_blank">【wine】Deepin中使用exe（Ubuntu通用）</a>


# 第一步：准备

## 查看是否支持AP模式

```shell
iw list
```

<img src="https://picgo.kwcoder.club/202206/202206221618244.png" alt="3-1是否支持AP模式" style="zoom:67%;" />

## 安装create_ap

找一个目录，安装create_ap。

```shell
git clone https://github.com/oblique/create_ap
cd create_ap
sudo make install
```

## 连接WiFi并查看网卡名称

<img src="https://picgo.kwcoder.club/202206/202206221619302.png" alt="3-2网卡名称" style="zoom:67%;" />

# 第二步：创建虚拟网卡并设置MAC地址

```shell
sudo iw dev [上一步骤获得的网卡名称] interface add [你想要创建的虚拟网卡的名称] type __ap
sudo ip link set dev [创建的网卡名称] address [任意的MAC地址]
```

例如：

```shell
sudo iw dev wlo1 interface add wlan1 type __ap
sudo ip link set dev wlan1 address 22:33:aa:dd:66:00
```

其中`22:33:aa:dd:66:00`是虚拟网卡的MAC地址，可以随便填写，如果有冲突随意更换。

# 第三步：使用create_ap创建热点

```shell
sudo create_ap -c 11 [虚拟网卡名称] [有线网卡名称] [热点名] [热点密码（大于等于8位）]
```

有线网卡名称可以通过`ifconfig`命令去查询，但是需要筛选，最简单的方法是给自己电脑插上网线，和无线网卡一样查找：

<img src="https://picgo.kwcoder.club/202206/202206221619786.jpg" alt="3-3有线网卡名称" style="zoom:67%;" />

例如：

```shell
sudo create_ap -c 11 wlan1 enp7s0 zhinushannan-deepin 12345678
```

上面这条命令依赖于终端，当终端关闭时热点就断开了，可以通过`nohup`后台运行。

```shell
sudo nohup create_ap -c 11 wlan1 enp7s0 zhinushannan-deepin 12345678 & 
```

# 常见问题

在我操作的过程中只遇到了一个问题，就是设备冲突，后续遇到新的问题会继续更新。

## 设备冲突

<img src="https://picgo.kwcoder.club/202206/202206221620739.png" alt="3-4设备冲突" style="zoom:67%;" />

解决方案，查询设备占用，杀死进程：

<img src="https://picgo.kwcoder.club/202206/202206221620292.png" alt="3-5杀死进程" style="zoom: 50%;" />
