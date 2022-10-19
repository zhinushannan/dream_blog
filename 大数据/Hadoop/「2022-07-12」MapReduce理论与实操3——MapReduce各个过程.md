```text
MapReduce理论与实操3——MapReduce各个过程
大数据>Hadoop
2022-07-12
https://picgo.kwcoder.club/202206/202206261620161.png
```




# 数据集：1949-1951某些天数的最高温度

```text
1949-10-01 14:21:02	34
1949-10-02 14:01:02	36
1950-01-01 11:21:02	32
1950-10-01 12:21:02	37
1949-11-02 14:01:02	37
1951-12-01 12:21:02	23
1950-10-02 12:21:02	41
1950-10-03 12:21:02	27
1951-07-01 12:21:02	45
1951-07-02 12:21:02	46
1950-11-13 12:21:02	37
1951-08-08 12:21:02	48
1949-07-07 14:01:02	39
1949-05-05 14:01:02	32
1951-03-03 12:21:02	22
```

# 【阶段1：自动排序】需求1：将如上数据集按照"年份   温度"格式输出，并按照先年份、再温度的顺序排序

## 实体类`HotWritable.java`

```java
package com.neuedu.hot;

import org.apache.hadoop.io.WritableComparable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.util.Objects;

public class HotWritable implements WritableComparable<HotWritable> {

    private Integer year;
    private Float hot;
    
    // 省略空参构造、满参构造、setter、getter、equals、hashcode

    @Override
    public void write(DataOutput out) throws IOException {
        out.writeInt(year);
        out.writeFloat(hot);
    }

    @Override
    public void readFields(DataInput in) throws IOException {
        this.year = in.readInt();
        this.hot = in.readFloat();
    }

    @Override
    public int compareTo(HotWritable other) {
        // 比null大
        if (other == null) {
            return  1;
        }
        // 年份不同时，只比较年份，升序
        if (!Objects.equals(this.year, other.year)) {
            return Integer.compare(this.year,other.year);
        }
        // 年份相同时，比较温度，升序
        return Float.compare(this.hot, other.hot);
    }

    @Override
    public String toString() {
        return year + "\t" + hot;
    }

}

```

## Mapper类`HotMapper.java`

```java
import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class HotMapper extends Mapper<LongWritable, Text, HotWritable, NullWritable> {

    @Override
    protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, HotWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        // 数据校验
        String line = value.toString();
        if (StringUtils.isBlank(line)) {
            return;
        }
        String[] items = line.split("\t");
        if (items.length != 2) {
            return;
        }
        // 取年份、取温度
        String year = items[0].substring(0, 4);
        String hot = items[1];
        // 实例化自定 义实体类
        HotWritable h = new HotWritable(Integer.parseInt(year), Float.parseFloat(hot));
        context.write(h, NullWritable.get());
    }
}

```

## Reducer类：`HotReducer.java`

```java
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class HotReducer extends Reducer<HotWritable, NullWritable, HotWritable, NullWritable> {

    @Override
    protected void reduce(HotWritable key, Iterable<NullWritable> values, Reducer<HotWritable, NullWritable, HotWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        context.write(key, NullWritable.get());
    }

}

```

## Runner类：`HotRunner.java`

```java
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;

public class HotRunner {

    public static void main(String[] args) {
        try {
            Configuration conf = new Configuration();
            FileSystem hdfs = FileSystem.get(conf);
            // 定义输入目录
            String input = "/hot";
            // 定义输出目录
            String output = "/hot_result";
            Path outputPath = new Path(output);
            // 输出不能存在，否则会有异常
            if (hdfs.exists(outputPath)) {
                hdfs.delete(outputPath, true);
            }
            // 构建Job任务
            Job job = Job.getInstance(conf, "every year hot");
            // 设置运行类
            job.setJarByClass(HotRunner.class);
            // 设置输入
            job.setInputFormatClass(TextInputFormat.class);
            FileInputFormat.setInputPaths(job, input);
            // 设置Mapper
            job.setMapperClass(HotMapper.class);
            job.setMapOutputKeyClass(HotWritable.class);
            job.setMapOutputValueClass(NullWritable.class);
            // 设置Reducer
            job.setReducerClass(HotReducer.class);
            job.setOutputKeyClass(HotWritable.class);
            job.setOutputValueClass(NullWritable.class);
            // 设置输出
            job.setOutputFormatClass(TextOutputFormat.class);
            FileOutputFormat.setOutputPath(job, outputPath);
            // 运行
            boolean flag = job.waitForCompletion(true);
            // 提示
            if (flag) {
                System.out.println("每年最高温度统计运行结束");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}


```

## 输出结果

```text
1949	32.0
1949	34.0
1949	36.0
1949	37.0
1949	39.0
1950	27.0
1950	32.0
1950	37.0
1950	41.0
1951	22.0
1951	23.0
1951	45.0
1951	46.0
1951	48.0
```

## 解释

### Map阶段

1. 文件以KV形式输入，键为该行首字符在整个文件中的位置，即游标，所以键为`LongWritable`，值为`Text`。
2. Map阶段对数据进行清洗和预处理，输出键`HotWritable`、值`NullWritable`。
3. 在`map()`方法执行结束后，会根据键进行自动排序，规则为键中的`compareTo()`方法，这也是为什么作为键的实体类必须实现`WritableComparable`而不是`Writable`的原因。

### Reduce阶段

1. 接收Map阶段的结果，键`HotWritable`、值`NullWritable`。
2. 将结果写入文件。

# 【阶段3：分区】需求2：将气温数据以年为单位输出到文件中

当需要对输出的结果分批处理时，可以通过设置分区的方式。
在ReduceTask中，一个分区就会产生一个Reduce，一个Reduce就会产生一个文件。

## 分区类：`HotPartitioner.java`

```java
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Partitioner;

public class HotPartitioner extends Partitioner<HotWritable, NullWritable> {

    @Override
    public int getPartition(HotWritable hotWritable, NullWritable nullWritable, int numPartitions) {
        // 自定义分区算法
        // 1949 - 1940 = 9, 9 % 3 = 0
        // 1950 - 1940 = 10, 10 % 3 = 1
        // 1951 - 1940 = 11, 11 % 3 = 2
        return (hotWritable.getYear() - 1940) % numPartitions;
    }
}


```

## 修改Runner类：

在设置Reduce类之前，添加：

```java
// 设置reduceTask数量和分区类算法
job.setNumReduceTasks(3);
job.setPartitionerClass(HotPartitioner.class);

```

## 输出结果

`part-r-00000`

```text
1949	32.0
1949	34.0
1949	36.0
1949	37.0
1949	39.0

```

`part-r-00001`

```text
1950	27.0
1950	32.0
1950	37.0
1950	41.0

```

`part-r-00002`

```text
1951	22.0
1951	23.0
1951	45.0
1951	46.0
1951	48.0

```

## 解释

1. 为什么要设置NumReduceTasks和PartitionerClass？

> 分区数等于ReduceTask数量，一个分区会产生一个ReduceTask，会输出一个文件

2. 分区算法类的键值设置规则：分区是分Map结束后的数据，所以键值设置应当是Map输出的键值类型
3. 分区算法需要注意的：分区算法不宜复杂，复杂会导致运行效率快速下降
4. 分区是Reduce阶段的最先执行的，即先将数据划分好，再执行reduce

# 【阶段4：自定义排序】需求3：将分区之后的数据按照温度降序排列

## 自定义排序类：`HotSortASC.java`

```java
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class HotSortASC extends WritableComparator {

    public HotSortASC() {
        super(HotWritable.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {
        return -Float.compare(((HotWritable) a).getHot(), ((HotWritable) b).getHot());
    }
}


```

## 在Runner类中，做出如下修改：

在设置分区后、设置Reduce之前，添加：

```java
// 设置自定义排序
job.setSortComparatorClass(HotSortASC.class);

```

## 解释

1. 为什么要在空构造中调用`super(Class<? extends WritableComparable> keyClass, boolean createInstances)`方法

> 需要告诉排序器需要排序的实体类是谁，然后根据该类进行反射，反序列化构造出Java对象

2. 排序在分区之后，分区将每一个reduce需要处理的数据分号之后，通过排序的方式将数据进行排序，再交给reduce方法，保证了根据分区算法切分的数据由同一个reduce处理。

# 【阶段5：自定义分组】需求4：在输出结果中指保留温度最大的数据

## 观察

将`reduce`方法修改为如下：

```java
@Override
protected void reduce(HotWritable key, Iterable<NullWritable> values, Reducer<HotWritable, NullWritable, HotWritable, NullWritable>.Context context) throws IOException, InterruptedException {
    Iterator<NullWritable> iterator = values.iterator();
    System.out.println(Iterators.size(iterator));
}

```

其作用是输出每次调用`reduce`方法时，值迭代器中有多少条数据。

观察输出，可以发现有三部分：

```text
1
1
1
1
1
```

```text
1
2
1
1
```

```text
1
1
1
1
1
```

出现这样的现象，原因是Map阶段处理出的结果是以键是否相同分组，即一条数据为一组。
一组数据代表需要执行一次`reduce()`方法，在这种情况下，如果我们截断`reduce()`的写入，规定每次只向外写出一条数据的方式是不可行的，因为1949年需要调用五次`reduce()`方法，1950年需要调用四次`reduce()`方法，1951年需要调用五次`reduce()`方法，那么根据只写第一条的原则，最后会分别输出5条、4条、5条数据，不符合需求设计。

## 思考

如果我们可以保证同一年份属于同一组，那么就意味着同一年份只执行一次`reduce()`方法，这个时候我们再去截断数据。

## 编写分组类：`HotGrouping.java`

```java
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class HotGrouping extends WritableComparator {

    public HotGrouping() {
        super(HotWritable.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {
        return Integer.compare(((HotWritable) a).getYear(), ((HotWritable) b).getYear());
    }
}

```

## 修改Runner类

在设置排序之后、设置Reduce之前添加如下代码：

```java
// 设置分组
job.setGroupingComparatorClass(HotGrouping.class);

```

## 执行

倘若`reduce()`方法中依然是输出值迭代器的数据数量，会发现在控制台输出三个5，这便是三个分区的数据数量。

修改`reduce()`方法为即可正常执行：

```java
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class HotReducer extends Reducer<HotWritable, NullWritable, HotWritable, NullWritable> {

    @Override
    protected void reduce(HotWritable key, Iterable<NullWritable> values, Reducer<HotWritable, NullWritable, HotWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        context.write(key, NullWritable.get());
    }

}

```

## 解释

在分组的排序算法中，等于0的属于同一组，即根据排序条件判断相等的为同一组，同一组的数据是由同一个`reduce()`方法执行。

# 【阶段2：归并】

## WordCount案例

在WordCount案例中，在`map()`方法中添加输出语句，将每次输出的数据打印：

```java
StringTokenizer words = new StringTokenizer(word);
while (words.hasMoreTokens()) {
    TEXT.set(words.nextToken());
    context.write(TEXT, INT);
    System.out.println(TEXT + "===" + INT);
}
```

可以发现在控制台会出现如下输出：

```text
Java===1
Hadoop===1
Scala===1
Python===1
Java===1
Python===1
Scala===1
HBase===1
Hello===1
World===1
Hive===1
Hbase===1
Java===1
Python===1
Java===1
```

可以发现有许多重复的键值，如果可以将这些键值在Map阶段进行简单的合并一下，将会极大的降低需要传输的数据量，从而提高执行效率。

## 归并类：`WordCountCombiner.java`

```java
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class WordCountCombiner extends Reducer<Text, IntWritable, Text, IntWritable> {

    private static IntWritable outVal = new IntWritable();
    
    @Override
    protected void reduce(Text key, Iterable<IntWritable> values, Reducer<Text, IntWritable, Text, IntWritable>.Context context) throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable value : values) {
            sum += value.get();
        }
        outVal.set(sum);
        context.write(key, outVal);
    }
}


```

在Runner类中的设置Mapper之后、设置Reduce之前添加：

```java
// 设置归并
job.setCombinerClass(WordCountCombiner.class);

```

如果在`WordCountCombiner.java`的`reduce()`方法的最后一行将输出结果打印，会发现结果为：

```text
HBase===1
Hadoop===1
Hbase===1
Hello===1
Hive===1
Java===4
Python===3
Scala===2
World===1
```

可以发现已经将重复的键值合并。

## 解释

1. Combiner执行时机是在Map的最后一个阶段
2. 输入键值：Combiner归并的是`map()`方法的输出，因此输入键值应当和`map()`方法的输出类型相同
3. 输出键值：Combiner归并只是对数据做一次汇总，不会再对数据进行修改或映射，因此输出类型应当保持不变，即`map()`的输出类型


# 总结

我们已经知道，在MapReduce中，分为两个部分执行，分别是Map和Reduce，在Map和Reduce内部有更为详细的划分。

## Map阶段

1. 在Map阶段，第一步做的是输入数据。输入数据直接进入`map()`函数进行处理，处理后的数据根据键的自动排序规则进行排序输出。即`map()`函数是整个并行计算的开头。
2. 经过排序后，会对数据进行归并处理，归并是对`map()`输出的数据做合并（仅仅是合并！！），因此归并阶段接收的数据就是`map()`方法输出的数据，因此类型也应当保持和`map()`方法一致。而归并做的仅仅是合并，只是为了方便网络传输，不会对数据进行再次修改，因此输出类型不应当被改变，即应当是`map()`方法的输出类型。

## Reduce阶段

1. 在接收到Map阶段处理的数据后，首先要经过Partition分区，按照指定的规则将数据分成指定的份数，并将指定分区分配给指定的reduce
2. 在分区结束后，在分区内按照指定规则排序
3. 排序结束后，根据指定分组规则进行分组，同一组的数据会被汇总进入同一个reduce方法
4. 执行`reduce()`方法，输出结果到磁盘。即`reduce()`方法是整个并行计算的结束。

