```text
【源码级】butterfly魔改
其他
2022-05-05
https://picgo.kwcoder.club/202206/202206251419847.png
```

# 首页文章使用新标签页打开

官方没有提供解决方案，但是可以通过修改源码的方式进行修改。
找到主题下的`layout/includes/mixins/post-ui.pug`，在第16行、第19行添加`target="_blank"`即可实现。



![1.post-ui.pug文件](https://picgo.kwcoder.club/202206/202206251419808.png)

# 标签、分类页使用新标签打开

官方没有提供解决方案，但是可以通过修改源码的方式进行修改。
找到主题下的`layout/includes/mixins/article-sort.pug`，在第19行添加`target="_blank"`即可实现。



![2.article-sort.pug文件](https://picgo.kwcoder.club/202206/202206251419669.png)

# 魔改Valine评论【支持cave-draw画图】

## 准备工作

效果如图，即可以在评论区使用画图工具：

![3.cave-draw效果图](https://picgo.kwcoder.club/202206/202206251420408.png)

插件项目地址：[为你的评论表单添加一个画图板](https://github.com/flatblowfish/cave-draw)

进入项目第之后后，使用`CTRL+F`搜索`Valine`



![4.cave-draw项目地址](https://picgo.kwcoder.club/202206/202206251420652.png)



## 【进入正题】

### 第一步：Valine.min.js操作

下载[Valine.min.js](https://cdn.jsdelivr.net/npm/valine/dist/Valine.min.js)，放在source下的一个目录，我放的是`npm/valine/dist/`目录，如图：



![5.Valine.min.js目录](https://picgo.kwcoder.club/202206/202206251420157.png)



下载完成之后，将该文件格式化一下，通过搜索工具搜索定位到如图位置，并在函数的第一行添加：

```javascript
if ("data:image/" == e.substr(0, 11)) return true;
```



![6.js文件修改](https://picgo.kwcoder.club/202206/202206251420356.png)



在`_config.yml`文件中修改编译跳过的文件（因为文件太长了，如果不跳过的话会被编译，从而丢失后半段代码）



![7.配置文件修改](https://picgo.kwcoder.club/202206/202206251421580.png)



修改完之后最好检查一下`localhost:4000/npm/valine/dist/Valine.min.js`是否和源文件一样。

### 第二步：修改主题代码

找到主题目录下的`butterfly/layout/includes/third-party/comments/valine.pug`文件，原文件这幅模样：

```pug
- let emojiMaps = '""'
if site.data.valine
  - emojiMaps = JSON.stringify(site.data.valine)

script.
  function loadValine () {
    function initValine () {
      const valine = new Valine(Object.assign({
        el: '#vcomment',
        appId: '#{theme.valine.appId}',
        appKey: '#{theme.valine.appKey}',
        avatar: '#{theme.valine.avatar}',
        serverURLs: '#{theme.valine.serverURLs}',
        emojiMaps: !{emojiMaps},
        path: window.location.pathname,
        visitor: #{theme.valine.visitor}
      }, !{JSON.stringify(theme.valine.option)}))
    }

    if (typeof Valine === 'function') initValine() 
    else getScript('!{url_for(theme.CDN.valine)}').then(initValine)
  }

  if ('!{theme.comments.use[0]}' === 'Valine' || !!{theme.comments.lazyload}) {
    if (!{theme.comments.lazyload}) btf.loadComment(document.getElementById('vcomment'),loadValine)
    else setTimeout(loadValine, 0)
  } else {
    function loadOtherComment () {
      loadValine()
    }
  }
```

需要修改成这样：

```pug
- let emojiMaps = '""'
if site.data.valine
  - emojiMaps = JSON.stringify(site.data.valine)

script.
  new CaveDraw({
    ele: '#veditor',
    special: 'valine',
    openBtn: {
      style: 'background-color:#b37ba4;color:white;',
      hoverStyle: 'background-color: #49d0c0;'
    },
    canvasStyle: 'cursor:crosshair;background:whitesmoke;/*margin-bottom:5px;border-radius:0px;*/'
  })

  var valine = new Valine();
  valine.init({
    el: '#vcomment',
    appId: '#{theme.valine.appId}',
    appKey: '#{theme.valine.appKey}',
    avatar: '#{theme.valine.avatar}',
    serverURLs: '#{theme.valine.serverURLs}',
    emojiMaps: !{emojiMaps},
    path: window.location.pathname,
    visitor: #{theme.valine.visitor}
  });

```

在这个过程中，参数并没有发生变化，只是改变了Valine实例创建的方式（从原来的构造更换成了new）。同时，在创建Valine实例前，创建CaveDraw对象。

在`source/css/`（没有css目录自行创建）目录下创建`cavedraw.css`文件，内容如下：

```css
.brush-detail p {
    line-height: 1em!important;
}
.v[data-class="v"] .veditor {
    max-height: 17em;
}
```

修改`_config.butterfly.yml`配置文件（通过搜索找到对应的位置修改）：

```yaml
inject:
  head:
  # - <link rel="stylesheet" href="/xxx.css">
    - <link rel="stylesheet" href="/css/cavedraw.css" >
    - <script src="https://cdn.jsdelivr.net/gh/flatblowfish/cave-draw/dist/cave-draw.min.js"></script>
    - <script src="/npm/valine/dist/Valine.min.js"></script>
  bottom:
  # - <script src="xxxx"></script>

CDN:
  valine: /npm/valine/dist/Valine.min.js
```

完结撒花！！！！！！！