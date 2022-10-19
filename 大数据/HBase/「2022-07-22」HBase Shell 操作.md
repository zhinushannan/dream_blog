```text
HBase Shell 操作
大数据>HBase
2022-07-22
https://picgo.kwcoder.club/202208/202207211953477.png
```





# 进入HBase Shell

```
hbase shell
```

# 命名空间操作

## 命名空间概述

**命名空间是表的逻辑分组，这种抽象为租户提供相关功能奠定了基础：**

* **配额管理：闲置一个命名空间可以使用的资源（Region或Table）**
* **命名空间安全管理：为多租户提供另一级别的安全管理**
* **RegionServer组：一个命名空间或一张表可以被固定到一张表上、也可以被固定到一组RegionServer上，从而保证了数据的隔离性**

## 命名空间管理

**列出所有命名空间：**

```
list_namespace
```

**新建命名空间：**

```
create_namespace 'name'
```

**删除命名空间（该命名空间必须为空，否则会报错）：**

```
drop_namespace 'name'
```

**修改命名空间（其中**`PROPERTY_NAME`是属性名，`PROPERTY_VALUE`是属性值）：

```
alter_namespace 'ns1', {METHOD => 'set', 'PROPERTY_NAME' => 'PROPERTY_VALUE'}
```

# 表

**列出所有表：**

```
list
```

**列出指定命名空间下的所有表：**

```
list_namespace_tables 'ns1'
```

**新建表（在**`ns1`命名空间中，创建`t1`表，创建`cf`列簇）：

```
create `ns1:t1`, 'cf'
```

**删除表（删除之前需要先禁用表，为了防止在删除时还有用户在写）：**

```
disable 'ns1:t1'
drop 'ns1:t1'
```

**插入数据（其中**`1001`和`1002`是行键）：

```
put 'ns1:t1', 1001, 'cf:col', 'column1'
put 'ns1:t1', 1001, 'cf:col2', 'column11'
put 'ns1:t1', 1002, 'cf:col', 'column2'
```

**删除数据：**

```
delete 'ns1:t1', 1001, 'cf:col'
delete 'ns1:t1', 1002, 'cf:col'
```

**修改数据：**

```
put 'ns1:t1', 1001, 'cf:col', 'column1_update'
```

**查询数据：**

```
# 全表扫描
scan 'ns1:t1'
# 查看前5条
scan 'n1:t1', {LIMIT => 5}
# 根据过滤条件扫描
scan 'n1:t1', {COLUMNS => 'cf'}
scan 'n1:t1', {COLUMNS => 'cf:col'}
scan 'n1:t1', {COLUMNS => ['cf:col', 'cf:col2']}
scan 'n1:t1', {COLUMNS => ['cf:col', 'cf:col2'], LIMIT => 5}
# 根据行键和列获取
get 'ns1:t1', 1001
get 'ns1:t1', 1001, 'cf'
get 'ns1:t1', 1001, 'cf:col'
```





