```text
Hive WordCount
大数据>Hive
2022-08-10
https://picgo.kwcoder.club/202208/202208161604333.png
```

# 创建表

```sql
use default;

drop table if exists book;
drop table if exists wordcount;

create table book
(
    line STRING
);

create table wordcount
(
    word  STRING,
    count int
);
```

# 导入数据

在服务器的`/root`目录下新建文件`book.txt`，内容为：

```text
use default;
drop table if exists book;
drop table if exists wordcount;
create table book
(
    line STRING
);
create table wordcount
(
    word  STRING,
    count int
);
```

```sql
load data local inpath '/root/book.txt' overwrite into table book;

select * from book;
```

查询结果：


|               c0_               |
| :-----------------------------: |
|          use default;           |
|   drop table if exists book;    |
| drop table if exists wordcount; |
|        create table book        |
|                (                |
|           line STRING           |
|               );                |
|     create table wordcount      |
|                (                |
|       "    word  STRING,"       |
|            count int            |
|               );                |


# 统计词频

## 切分单词

```sql
select split(line, ' ') as word from book;
```

|                          word                           |
| :-----------------------------------------------------: |
|                "[""use"",""default;""]"                 |
|   "[""drop"",""table"",""if"",""exists"",""book;""]"    |
| "[""drop"",""table"",""if"",""exists"",""wordcount;""]" |
|            "[""create"",""table"",""book""]"            |
|                        "[""(""]"                        |
|       "["""","""","""","""",""line"",""STRING""]"       |
|                       "["");""]"                        |
|         "[""create"",""table"",""wordcount""]"          |
|                        "[""(""]"                        |
|    "["""","""","""","""",""word"","""",""STRING,""]"    |
|        "["""","""","""","""",""count"",""int""]"        |
|                       "["");""]"                        |


查询到的结果是按照每行的分割得到的列表。

## 行列置换：将数组转为N行数据

```sql
select explode(split(line, ' ')) as word from book;
```

|    word    |
| :--------: |
|    use     |
|  default;  |
|    drop    |
|   table    |
|     if     |
|   exists   |
|   book;    |
|    drop    |
|   table    |
|     if     |
|   exists   |
| wordcount; |
|   create   |
|   table    |
|    book    |
|     (      |
|     ""     |
|     ""     |
|     ""     |
|     ""     |
|    line    |
|   STRING   |
|     );     |
|   create   |
|   table    |
| wordcount  |
|     (      |
|     ""     |
|     ""     |
|     ""     |
|     ""     |
|    word    |
|     ""     |
| "STRING,"  |
|     ""     |
|     ""     |
|     ""     |
|     ""     |
|   count    |
|    int     |
|     );     |


## 聚合查询：统计每个单词的数量

> 需要授权：`hdfs dfs -chmod -R 777 /tmp`

```sql
select word, count(*) as count
from (select explode(split(line, ' ')) as word from book) t
group by word
order by count desc;
```

|    word    | count |
| :--------: | :---: |
|            |  13   |
|   table    |   4   |
|    \);     |   2   |
|     \(     |   2   |
|   create   |   2   |
|     if     |   2   |
|   exists   |   2   |
|    drop    |   2   |
| wordcount; |   1   |
| wordcount  |   1   |
|    word    |   1   |
|    use     |   1   |
|    line    |   1   |
|    int     |   1   |
|   count    |   1   |
|   book;    |   1   |
|    book    |   1   |
|  STRING,   |   1   |
|   STRING   |   1   |
|  default;  |   1   |


# 插入数据

```sql
insert into table wordcount
select word, count(*) as count
from (select explode(split(line, ' ')) as word from book) t
group by word
order by count desc;

select * from wordcount;
```

|    word    | count |
| :--------: | :---: |
|            |  13   |
|   table    |   4   |
|    \);     |   2   |
|     \(     |   2   |
|   create   |   2   |
|     if     |   2   |
|   exists   |   2   |
|    drop    |   2   |
| wordcount; |   1   |
| wordcount  |   1   |
|    word    |   1   |
|    use     |   1   |
|    line    |   1   |
|    int     |   1   |
|   count    |   1   |
|   book;    |   1   |
|    book    |   1   |
|  STRING,   |   1   |
|   STRING   |   1   |
|  default;  |   1   |