```text
【wine】Deepin中使用exe（Ubuntu通用） 
工具
2022-05-08
https://picgo.kwcoder.club/202206/202206221615882.png
```






# 介绍与安装

Deepin系统虽然好用，但是有时我们需要的软件只有exe版本，不支持Linux，这个时候我们就需要向wine求助了。

Wine是一个开源兼容层，允许您在Linux，FreeBSD和MacOS等UNIX的操作系统上运行Windows应用程序。 Wine是“Wine Is Not an Emulator”的首字母缩写。 它将Windows系统调用转换为基于UNIX的操作系统条用，等效于POSIX调用，允许您将Windows程序无缝集成到桌面环境中。

> 事实上，并不是所有的exe都能通过wine执行，你可以把它理解为Windows的Docker镜像，是一个阉割版。

官网：[https://www.winehq.org/](https://www.winehq.org/)

我们可以通过点击wine官网上的下载去获取对应系统的安装方法：

<img src="https://picgo.kwcoder.club/202206/202206221622193.png" alt="4-1wine官网" style="zoom:67%;" />




# 使用

安装完之后，我们就可以正常使用了。对于普通的exe可执行程序来说，我们只需要执行如下命令即可：

```shell
wine xxx.exe
```

如果exe是一个安装包，我们同样通过上述命令执行安装（安装过程中所有配置最好遵守默认），安装完成之后，和Windows类似，会在`~/.wine/drive_c/Program Files`或`~/.wine/drive_c/Program Files (X86)`目录内创建安装目录（如果你选择安装的是C盘的话）；同时会在`~/.local/share/applications/wine/Programs`和`~/.config/menus/applications-merged`目录下生成对应的目录或文件。

以安装[zip_password_tool_setup.exe](http://www.zip-password-cracker.com/)为例：

<img src="https://picgo.kwcoder.club/202206/202206221622494.png" alt="4-2zip-password-tool安装1" style="zoom:67%;" />



然后一路傻瓜式安装，和Windows一样，不多赘述。

安装完就可以正常使用了，同时可以在应用列表中看到对应的图标：

<img src="https://picgo.kwcoder.club/202206/202206221623354.png" alt="4-2zip-password-tool安装2" style="zoom:67%;" />



# 卸载通过wine安装的应用

以zip_password_tool为例，卸载可以通过点击`Uninstall Zip Password Tool`程序进行卸载，但是可能会存在特殊情况，即卸载完成后，应用列表中依然存在，这个时候我们可以手动去卸载。

如图，找到这三个目录：

<img src="https://picgo.kwcoder.club/202206/202206221623816.png" alt="4-3zip-password-tool卸载" style="zoom:67%;" />




把和对应软件相关的目录和文件删除，即完全卸载完成（应用列表里也会消失）。
