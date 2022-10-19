```text
HBase MapReduce编程
大数据>HBase
2022-07-29
https://picgo.kwcoder.club/202208/202207211953477.png
```

# HBase与MapReduce

HBase重新实现了Hadoop中的MapReduce框架：

- TableInputFormat：
  - 读取HBase中表的内容
  - 按照Region分割split，有多少个Region就有多少个split
- TableMapper：
  - 读取HBase表中的所有数据
  - map方法没执行一次，意味着读取一行数据，直到数据读取结束
- TableReducer：
  - 负责汇总，完成业务计算
  - 将结果以Put写入指定表中
- TableOutputFormat：将Put写入到指定表中


组合场景：

- Mapper + TableReducer：读取HDFS数据，写入HBase
- TableMapper + Reducer：读取HBase数据，写入HDFS
- TableMapper + TableReducer：读取HBase数据，写入HBase

# WordCount——输出到HBase

## 代码编写

词频内容

```text
hello world
hello hadoop
hello javascript
hello hbase
hello hbase phoenix
```

```java
import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.mapreduce.TableOutputFormat;
import org.apache.hadoop.hbase.mapreduce.TableReducer;
import org.apache.hadoop.hbase.util.Bytes;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;

public class WordCount1 {

    public static void main(String[] args) {

        try {
            Configuration conf = HBaseUtils.getConf();
            Connection connection = HBaseUtils.getConnection();
            Admin admin = HBaseUtils.getAdmin();
            // 创建表
            TableName wordcount = TableName.valueOf("wordcount");
            HBaseUtils.deleteTableIfExist(wordcount);
            admin.createTable(TableDescriptorBuilder
                    .newBuilder(wordcount)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.of(Bytes.toBytes("info")))
                    .build());

            // 设置写入表名，需要在设置Job之前设置
            conf.set(TableOutputFormat.OUTPUT_TABLE, wordcount.getNameAsString());

            Job job = Job.getInstance(conf, "wordcount");
            // 设置输入
            job.setInputFormatClass(TextInputFormat.class);
            FileInputFormat.setInputPaths(job, new Path("/wordcount"));
            // 设置Mapper
            job.setMapperClass(WordCountMapper.class);
            job.setMapOutputKeyClass(Text.class);
            job.setMapOutputValueClass(IntWritable.class);
            // 设置Reducer
            job.setReducerClass(WordCountReducer.class);
            // 设置输出
            job.setOutputFormatClass(TableOutputFormat.class);
            // 运行
            boolean flag = job.waitForCompletion(true);
            if (flag) {
                System.out.println("词频统计结束");
            }

            Table table = connection.getTable(wordcount);
            Scan scan = new Scan();
            ResultScanner results = table.getScanner(scan);
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("total_count"));
            HBaseUtils.show(results, family, cols);

        } catch (IOException | InterruptedException | ClassNotFoundException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

    private static class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {
        private Text outKey = new Text();
        private IntWritable outVal = new IntWritable(1);

        @Override
        protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, Text, IntWritable>.Context context) throws IOException, InterruptedException {
            String line = value.toString();
            if (StringUtils.isBlank(line)) {
                return;
            }
            StringTokenizer stringTokenizer = new StringTokenizer(line.trim());
            while (stringTokenizer.hasMoreTokens()) {
                outKey.set(stringTokenizer.nextToken());
                context.write(outKey, outVal);
            }
        }
    }

    private static class WordCountReducer extends TableReducer<Text, IntWritable, NullWritable> {
        byte[] family = Bytes.toBytes("info");
        byte[] col = Bytes.toBytes("total_count");

        @Override
        protected void reduce(Text key, Iterable<IntWritable> values, Reducer<Text, IntWritable, NullWritable, Mutation>.Context context) throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable value : values) {
                sum += value.get();
            }

            byte[] row = Bytes.toBytes(key.toString());
            byte[] total_count = Bytes.toBytes(String.valueOf(sum));

            Put put = new Put(row);
            put.addColumn(family, col, total_count);
            context.write(NullWritable.get(), put);
        }
    }
}

```

## 控制台输出

```text
词频统计结束
[hadoop	total_count:1]
[hbase	total_count:2]
[hello	total_count:5]
[javascript	total_count:1]
[phoenix	total_count:1]
[world	total_count:1]
```

# WordCount——完全HBase

## 代码编写

### HBase数据准备

```shell
hbase:002:0> create 'wordcount_src', 'content'
Created table wordcount_src
Took 0.7945 seconds                                                                               
=> Hbase::Table - wordcount_src
hbase:003:0> put 'wordcount_src', 1, 'content:line', 'hello world'
Took 0.5740 seconds                                                                               
hbase:004:0> put 'wordcount_src', 2, 'content:line', 'hello hadoop'
Took 0.0059 seconds                                                                               
hbase:005:0> put 'wordcount_src', 3, 'content:line', 'hello javascript'
Took 0.0057 seconds                                                                               
hbase:006:0> put 'wordcount_src', 4, 'content:line', 'hello hbase'
Took 0.0107 seconds                                                                               
hbase:007:0> put 'wordcount_src', 5, 'content:line', 'hello hbase phoenix'
Took 0.0042 seconds                                                                               
```

### Java代码

```java
import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.io.ImmutableBytesWritable;
import org.apache.hadoop.hbase.mapreduce.*;
import org.apache.hadoop.hbase.util.Bytes;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;

public class WordCount2 {

    public static void main(String[] args) {

        try {
            Configuration conf = HBaseUtils.getConf();
            Connection connection = HBaseUtils.getConnection();
            Admin admin = HBaseUtils.getAdmin();
            // 创建表
            TableName wordcount = TableName.valueOf("wordcount");
            HBaseUtils.deleteTableIfExist(wordcount);
            admin.createTable(TableDescriptorBuilder
                    .newBuilder(wordcount)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.of(Bytes.toBytes("info")))
                    .build());

            // 设置写入表名，需要在设置Job之前设置
            conf.set(TableOutputFormat.OUTPUT_TABLE, wordcount.getNameAsString());

            Job job = Job.getInstance(conf, "wordcount2");

            byte[] familyMapReduce = Bytes.toBytes("content");
            byte[] colMapReduce = Bytes.toBytes("line");
            Scan scanMapReduce = new Scan();
            scanMapReduce.addColumn(familyMapReduce, colMapReduce);
            TableMapReduceUtil.initTableMapperJob("wordcount_src", scanMapReduce, WordCountMapper.class, Text.class, IntWritable.class, job);
            TableMapReduceUtil.initTableReducerJob(wordcount.getNameAsString(), WordCountReducer.class, job);

            boolean flag = job.waitForCompletion(true);
            if (flag) {
                System.out.println("词频统计结束");
            }

            Table table = connection.getTable(wordcount);
            Scan scan = new Scan();
            ResultScanner results = table.getScanner(scan);
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("total_count"));
            HBaseUtils.show(results, family, cols);


        } catch (IOException | InterruptedException | ClassNotFoundException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

    private static class WordCountMapper extends TableMapper<Text, IntWritable> {
        private Text outKey = new Text();
        private IntWritable outVal = new IntWritable(1);

        @Override
        // 只有输出，没有输入
        protected void map(ImmutableBytesWritable key, Result value, Mapper<ImmutableBytesWritable, Result, Text, IntWritable>.Context context) throws IOException, InterruptedException {
            byte[] family = Bytes.toBytes("content");
            byte[] col = Bytes.toBytes("line");

            String line = null;
            if (value.containsColumn(family, col)) {
                line = Bytes.toString(value.getValue(family, col));
            }
            if (StringUtils.isBlank(line)) {
                return;
            }
            StringTokenizer stringTokenizer = new StringTokenizer(line.trim());
            while (stringTokenizer.hasMoreTokens()) {
                outKey.set(stringTokenizer.nextToken());
                context.write(outKey, outVal);
            }
        }
    }

    private static class WordCountReducer extends TableReducer<Text, IntWritable, NullWritable> {
        byte[] family = Bytes.toBytes("info");
        byte[] col = Bytes.toBytes("total_count");

        @Override
        protected void reduce(Text key, Iterable<IntWritable> values, Reducer<Text, IntWritable, NullWritable, Mutation>.Context context) throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable value : values) {
                sum += value.get();
            }

            byte[] row = Bytes.toBytes(key.toString());
            byte[] total_count = Bytes.toBytes(String.valueOf(sum));

            Put put = new Put(row);
            put.addColumn(family, col, total_count);
            context.write(NullWritable.get(), put);
        }
    }
}

```

## 控制台输出


```text
词频统计结束
[hadoop	total_count:1]
[hbase	total_count:2]
[hello	total_count:5]
[javascript	total_count:1]
[phoenix	total_count:1]
[world	total_count:1]
```