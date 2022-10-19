```text
MapReduce理论与实操1——WordCount
大数据>Hadoop
2022-07-10
https://picgo.kwcoder.club/202206/202206261620161.png
```






# MapReduce概述

## MapReduce定义

MapReduce是一个分布式并行计算框架，其核心功能是将用户编写的业务逻辑代码和自带默认组件整合成一个完整的分布式运算程序，在一个Hadoop集群上并发运行。

## MapReduce优缺点

优点

- 易于编程：通过实现一些接口即可完成一个分布式程序，并且可以分布到大量的廉价机的机器上运行。
- 易扩展性：当资源不足时，可以很容易的增加机器来扩展计算能力。
- 高容错性：一台计算机器挂掉，可以把该机器上的计算任务转移到另一个节点上运行，不至于导致任务运行失败。
- 适合海量数据离线处理：可以实现上千台服务器集群并发工作，提供数据处理能力。

缺点：

- 不擅长实时计算：无法在毫秒或者秒级内返回结果。
- 不擅长流式计算：MapReduce的输入数据只能是静态的，不支持动态的流式数据。
- 不擅长DAG（有向图）计算：MapReduce每个任务的输出结果都会写入磁盘，当一个程序依赖于另一个程序时，会需要进行大量的IO，导致性能降低。


## MapReduce核心思想

MapReduce的核心思想是分而治之，将一个大的任务分割为若干小任务并分配给各个节点进行运算，最终进行汇总统计，写入磁盘。

MapReduce提供了Map和Reduce接口。


### MapReduce案例——以做菜为例（非标准菜谱）

番茄炒蛋步骤：

1. 切番茄、打鸡蛋
2. 下锅

Map（映射）阶段：切番茄和打鸡蛋。在这个过程中，如果发现有坏番茄或坏鸡蛋，要将其剔除；将挑选出来的好番茄切开、好鸡蛋打开。这个过程中，输入的是一堆没有挑选的番茄和鸡蛋，输出的是挑选好的、切好的和打好的番茄和鸡蛋。

Reduce（化简）阶段：下锅，把材料倒进锅里，出锅。



![1mr核心思想](https://picgo.kwcoder.club/202206/202207142022111.png)



一个完整的MapReduce程序在分布式运行时有三个实例进程：

1. `MRAppMaster`：负责为整个程序的过程调度及状态协调
2. `MapTask`：负责Map阶段的整个数据处理流程
3. `Reduce`：负责Reduce阶段整个数据处理流程

## MapReduce编程规范

用户编写的程序分为：Mapper、Reducer和Runner。

### Mapper类

用户自定义的Mapper类要继承`org.apache.hadoop.mapreduce.Mapper`类：

- `map()`：Map阶段的业务逻辑写在该方法中。
- `setup()`：Map任务执行前，对相关变量或资源的集中初始化工作，只执行一次
- `cleanup()`：Map任务执行结束后，对相关变量或资源的集中回收工作，只执行一次
- `run()`：该方法调用了上述三个方法，用户不必重写。

```java
package org.apache.hadoop.mapreduce;

public class Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT> {

  public abstract class Context
    implements MapContext<KEYIN,VALUEIN,KEYOUT,VALUEOUT> {
  }
  
  protected void setup(Context context
                       ) throws IOException, InterruptedException {
    // NOTHING
  }

  @SuppressWarnings("unchecked")
  protected void map(KEYIN key, VALUEIN value, 
                     Context context) throws IOException, InterruptedException {
    context.write((KEYOUT) key, (VALUEOUT) value);
  }

  protected void cleanup(Context context
                         ) throws IOException, InterruptedException {
    // NOTHING
  }
  
  public void run(Context context) throws IOException, InterruptedException {
    setup(context);
    try {
      while (context.nextKeyValue()) {
        map(context.getCurrentKey(), context.getCurrentValue(), context);
      }
    } finally {
      cleanup(context);
    }
  }
}


```


### Reducer类

用户自定义的Reducer类要继承类：

- `reduce()`：Reduce阶段的业务逻辑写在该方法中。
- `setup()`：Map任务执行前，对相关变量或资源的集中初始化工作，只执行一次
- `cleanup()`：Map任务执行结束后，对相关变量或资源的集中回收工作，只执行一次
- `run()`：该方法调用了上述三个方法，用户不必重写。

```java
package org.apache.hadoop.mapreduce;

public class Reducer<KEYIN,VALUEIN,KEYOUT,VALUEOUT> {

  public abstract class Context 
    implements ReduceContext<KEYIN,VALUEIN,KEYOUT,VALUEOUT> {
  }

  protected void setup(Context context
                       ) throws IOException, InterruptedException {
    // NOTHING
  }

  @SuppressWarnings("unchecked")
  protected void reduce(KEYIN key, Iterable<VALUEIN> values, Context context
                        ) throws IOException, InterruptedException {
    for(VALUEIN value: values) {
      context.write((KEYOUT) key, (VALUEOUT) value);
    }
  }

  protected void cleanup(Context context
                         ) throws IOException, InterruptedException {
    // NOTHING
  }

  public void run(Context context) throws IOException, InterruptedException {
    setup(context);
    try {
      while (context.nextKey()) {
        reduce(context.getCurrentKey(), context.getValues(), context);
        // If a back up store is used, reset it
        Iterator<VALUEIN> iter = context.getValues().iterator();
        if(iter instanceof ReduceContext.ValueIterator) {
          ((ReduceContext.ValueIterator<VALUEIN>)iter).resetBackupStore();        
        }
      }
    } finally {
      cleanup(context);
    }
  }
}


```

### Runner类

相当于YARN集群的客户端，用于提交整个程序到YARN集群，提交的事封装了MapReduce程序相关运行参数的`Job`对象。

> 注意：Map阶段的输出是Reduce阶段的输入

# WordCount案例（词频统计案例）

将该文件保存在HDFS的`/wc_src/wc.txt`中。

```text
Java Hadoop Scala
Python Java Python
Scala HBase Hello World
Hive Hbase Java Python Java
```

## WordCount编码与解析

### Mapper类

`WordCountMapper.java`

```java
package club.kwcoder.wordcount;

import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;
import java.util.StringTokenizer;

public class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {

    /*
    每输入一行数据就会执行一次map方法，就需要使用一次Text对象和IntWritable对象，
    如果反复创建，会导致消耗大量虚拟机资源。
    因此可以将这两个对象作为成员属性，只进行一次初始化，通过set方法修改其中的值。
     */
    private final Text TEXT = new Text();
    private final IntWritable INT = new IntWritable(1);

    @Override
    protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Text, IntWritable>.Context context) throws IOException, InterruptedException {
        // Text对象反序列化为String
        String word = value.toString();
        // 清洗数据：判断该行是否为空行
        if (StringUtils.isBlank(word)) {
            return;
        }
        // 分割数据，得到词的StringTokenizer对象
        StringTokenizer words = new StringTokenizer(word);
        // 将词写入context，供Reduce接收
        while (words.hasMoreTokens()) {
            TEXT.set(words.nextToken());
            context.write(TEXT, INT);
        }
    }
}

```

#### map

在Map阶段，Map的输入是按块来输入的，这里模拟上述文本被分割为两个块来叙述。

输入数据时，文本按行读入程序，对于上述文本，会输入四次，即调用四次`map()`函数。
输入的数据是键值对，其键是该行首个字符在文件中的位置，值是该行的字符串。

输入数据后，需要对文本进行切分，其读取是按行读取，所以输出的结果是对行处理过后的数据。
在输入第一行后，输出的结果可以模拟为：

```text
<Java, 1>
<Hadoop, 1>
<Scala, 1>
```

在输入第二行后，输出结果可以模拟为：

```text
<Python, 1>
<Java, 1>
<Python, 1>
```

其余两行省略。

#### 排序

在输出后，会进行一次排序，排序规则是以块为单位、以键的排序规则决定的，在该程序中，键的类型为`Text`，其排序规则为（自然排序）：

```java
@Override
public int compare(byte[] b1, int s1, int l1,
                   byte[] b2, int s2, int l2) {
  int n1 = WritableUtils.decodeVIntSize(b1[s1]);
  int n2 = WritableUtils.decodeVIntSize(b2[s2]);
  return compareBytes(b1, s1+n1, l1-n1, b2, s2+n2, l2-n2);
}
```

因此第一块的输出结果为：

```text
<Hadoop, 1>
<Java, 1>
<Java, 1>
<Python, 1>
<Python, 1>
<Scala, 1>
```



#### 归并

此时如果将排序的结果直接传输给Reduce，需要大量的网络资源，因此在将数据输出给Reduce之前，要进行一次归并，归并的原则是在同一块内根据相同的键进行归并。

因此第一块的归并结果为：

```text
<Java, 2>
<Hadoop, 1>
<Scala, 1>
<Python, 2>
```

示意图如下：



![4map](https://picgo.kwcoder.club/202206/202207142024064.png)



## Reducer类

### 排序

在执行Reduce之前，需要对Map阶段的结果进行一次排序，排序规则为：对在同一分区内的输出结果，进行排序，然后将值并在一起。
设定：这两块属于同一分区，则其排序的结果为（该结果为reduce()方法的输入参数）：

```text
<Hbase, <1>>
<HBase, <1>>
<Hadoop, <1>>
<Hello, <1>>
<Hive, <1>>
<Java, <2, 2>>
<Python, <1>>
<Scala, <2>>
<World, <1>>
```

示意图如下：



![5reduce](https://picgo.kwcoder.club/202206/202207142024133.png)




### Reducer类

`WordCountReducer.java`

```java
package club.kwcoder.wordcount;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class WordCountReducer extends Reducer<Text, IntWritable, Text, IntWritable> {

    private final IntWritable INT = new IntWritable();

    @Override
    protected void reduce(Text key, Iterable<IntWritable> values, Reducer<Text, IntWritable, Text, IntWritable>.Context context) throws IOException, InterruptedException {
        // 对相同的键进行统计
        int sum = 0;
        for (IntWritable value : values) {
            sum += value.get();
        }
        // 写出结果
        INT.set(sum);
        context.write(key, INT);
    }

}
```

## Runner类

```java
package club.kwcoder.wordcount;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

import java.io.IOException;

public class WordCountRunner {

    public static void main(String[] args) throws IOException, InterruptedException, ClassNotFoundException {
        // 加载配置
        Configuration conf = new Configuration();

        // 获取HDFS对象
        FileSystem hdfs = FileSystem.get(conf);

        // 配置输入输出路径
        Path input = new Path("/wc_src/wc.txt");
        Path output = new Path("/wc_result");

        // 如果输出路径存在，需要删除（当输出路径存在时，程序会报错）
        if (hdfs.exists(output)) {
            hdfs.delete(output, true);
        }

        // 构建Job任务
        Job job = Job.getInstance(conf, "WordCount");
        // 设置运行类
        job.setJarByClass(WordCountRunner.class);
        // 设置输入
        job.setInputFormatClass(TextInputFormat.class);
        FileInputFormat.setInputPaths(job, input);
        // 设置Mapper类及其输出的键值类型
        job.setMapperClass(WordCountMapper.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(IntWritable.class);
        // 设置Reducer类
        job.setReducerClass(WordCountReducer.class);
        // 配置输出的键值类型
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);
        // 设置输出
        job.setOutputFormatClass(TextOutputFormat.class);
        FileOutputFormat.setOutputPath(job, output);
        // 运行
        boolean flag = job.waitForCompletion(true);
        if (flag) {
            System.out.println("word count success");
        }
        hdfs.close();

    }

}
```


## WordCount本地运行

在本地运行Runner类时，是没有调用集群的计算框架的，是通过本地模拟出的计算效果。

## WordCount集群运行

将该项目打包，放在服务器上执行，是调用集群进行计算的。



![2mvn_package](https://picgo.kwcoder.club/202206/202207142023095.png)



执行`hadoop jar hadoop_study-1.0-SNAPSHOT.jar club.kwcoder.wordcount.WordCountRunner`。



![3wc_res](https://picgo.kwcoder.club/202206/202207142023338.png)

# WordCount面向对象

在WordCount案例中，巧合的是输出的参数恰好是两个，即单词和频率，而在真实的场景中，需要产生的参数往往很多，这时就需要对象的出现。
相较于上一种方法，面向对象方法需要额外实现一个实体类。

实体类`WordCountWritable.java`

```java
package club.kwcoder.wordcount2;

import org.apache.hadoop.io.WritableComparable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class WordCountWritable implements WritableComparable<WordCountWritable> {

    // 定义属性
    private String word;
    private Integer count;

    // 省略空参构造、满参构造、getter/setter、equals、hashCode

    /**
     * 重写比较器，用于Map阶段的排序
     *
     * @param o the object to be compared.
     * @return
     */
    @Override
    public int compareTo(WordCountWritable o) {
        return this.word.compareTo(o.getWord());
    }

    /**
     * Hadoop序列化
     *
     * @param out <code>DataOuput</code> to serialize this object into.
     * @throws IOException
     */
    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(this.word);
        out.writeInt(this.count);
    }

    /**
     * Hadoop 反序列化
     * ！！！注意：！！！先被序列化的先反序列化
     * @param in <code>DataInput</code> to deseriablize this object from.
     * @throws IOException
     */
    @Override
    public void readFields(DataInput in) throws IOException {
        // ！！！注意：！！！先被序列化的先反序列化
        this.word = in.readUTF();
        this.count = in.readInt();
    }

    @Override
    public String toString() {
        return word + '\t' + count;
    }

}

```


`WordCountMapper.java`

```java
package club.kwcoder.wordcount2;

import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;
import java.util.StringTokenizer;

public class WordCountMapper extends Mapper<LongWritable, Text, Text, WordCountWritable> {

    private final Text TEXT = new Text();
    private final WordCountWritable w = new WordCountWritable();

    @Override
    protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Text, WordCountWritable>.Context context) throws IOException, InterruptedException {
        String line = value.toString();
        if (StringUtils.isBlank(line)) {
            return;
        }
        StringTokenizer st = new StringTokenizer(line);
        while (st.hasMoreTokens()) {
            String word = st.nextToken();
            TEXT.set(word);
            w.setWord(word);
            w.setCount(1);
            context.write(TEXT, w);
        }
    }
}


```

`WordCountReducer.java`

```java
package club.kwcoder.wordcount2;

import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class WordCountReducer extends Reducer<Text, WordCountWritable, WordCountWritable, NullWritable> {

    private final WordCountWritable w = new WordCountWritable();
    
    @Override
    protected void reduce(Text key, Iterable<WordCountWritable> values, Reducer<Text, WordCountWritable, WordCountWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        int sum = 0;
        for (WordCountWritable v : values) {
            sum += v.getCount();
        }
        w.setWord(key.getWord());
        w.setCount(sum);
        // 因为没必要输出键，所以可以输出null的Hadoop序列化对象
        context.write(w, NullWritable.get());
    }
}


```

`WordCountRunner.java`

```java
package club.kwcoder.wordcount2;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

import java.io.IOException;

public class WordCountRunner {

    public static void main(String[] args) throws IOException, InterruptedException, ClassNotFoundException {
        Configuration conf = new Configuration();
        FileSystem hdfs = FileSystem.get(conf);
        Path input = new Path("/wc_src/wc.txt");
        Path output = new Path("/wc_result");
        if (hdfs.exists(output)) {
            hdfs.delete(output, true);
        }

        Job job = Job.getInstance(conf, "WordCount");
        job.setJarByClass(club.kwcoder.wordcount.WordCountRunner.class);
        job.setInputFormatClass(TextInputFormat.class);
        FileInputFormat.setInputPaths(job, input);
        job.setMapperClass(WordCountMapper.class);
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(WordCountWritable.class);
        job.setReducerClass(WordCountReducer.class);
        job.setOutputKeyClass(WordCountWritable.class);
        job.setOutputValueClass(NullWritable.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        FileOutputFormat.setOutputPath(job, output);
        boolean flag = job.waitForCompletion(true);
        if (flag) {
            System.out.println("word count success");
        }
        hdfs.close();

    }

}


```


