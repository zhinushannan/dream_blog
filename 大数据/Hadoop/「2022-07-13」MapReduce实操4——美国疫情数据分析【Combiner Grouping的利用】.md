```text
MapReduce实操4——美国疫情数据分析【Combiner Grouping的利用】
大数据>Hadoop
2022-07-13
https://picgo.kwcoder.club/202206/202206261620161.png
```




# 数据集及其说明

数据来源：[和鲸社区 - 美国各州各城市2019新型冠状病毒-COVID19数据](https://www.heywhale.com/mw/dataset/5e844c33246a590036b97646/file)

选择`us-counties.csv`数据集。

数据集说明

| date | county | state | fips | cases  | deaths |
| :--: | :----: | :---: | :--: | :----: | :----: |
| 日期 |   县   |  州   | 编码 | 确诊数 | 死亡数 |


# 需求

根据数据集，统计每个县累计确诊数、死亡数，并先按照州名的自然排序排序，再按照州下辖县的确诊数排序。

# 思路分析

首先实体类需要有四个属性，分别为州、县、确诊数、死亡数。

在Mapper阶段要组合实体类对象，由于数据量庞大（140万行），必须在Map阶段进行合并，否则会因为传输导致效率大幅下降。
在合并时，可以参考的思路是将每个县的确诊数和死亡数计算出来。但是考虑到需要在reduce阶段排序，所以输出的键类型为实体类比较合适。但是这样的话，在归并阶段由于每个对象都不一样而导致无法将相同县合并。这里可以使用Combiner阶段的Grouping分组，使用方法和Reduce阶段的分组相同，将同一个县的数据归位一组进行Combiner。

在reduce阶段，首先对内容进行排序，然后可以直接输出。

# 编码实现

> 阅读下面代码时，请注意看注释。

## 实体类：`CovidWritable.java`

```java
package club.kwcoder.covid;

import org.apache.hadoop.io.WritableComparable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.util.Objects;

public class CovidWritable implements WritableComparable<CovidWritable> {

    private String state;
    private String county;
    private Integer cases;
    private Integer deaths;

    @Override
    public int compareTo(CovidWritable o) {
        // 若比较对象为null，则自身大
        if (null == o) {
            return 1;
        }
        // 若州不一样，则比较州
        if (!this.state.equals(o.state)) {
            return this.state.compareTo(o.state);
        }
        // 若州一样，则比较县
        return this.county.compareTo(o.county);
        // map()结束时总确诊数还没有计算，因此没必要比较
    }

    /**
     * Hadoop序列化
     * @param out <code>DataOuput</code> to serialize this object into.
     * @throws IOException
     */
    @Override
    public void write(DataOutput out) throws IOException {
        out.writeUTF(state);
        out.writeUTF(county);
        out.writeInt(cases);
        out.writeInt(deaths);
    }

    /**
     * Hadoop反序列化
     * @param in <code>DataInput</code> to deseriablize this object from.
     * @throws IOException
     */
    @Override
    public void readFields(DataInput in) throws IOException {
        this.state = in.readUTF();
        this.county = in.readUTF();
        this.cases = in.readInt();
        this.deaths = in.readInt();
    }

    /**
     * 建造者模式构建对象
     */
    public static class Builder {
        private String state;
        private String county;
        private Integer cases;
        private Integer deaths;

        public Builder setState(String state) {
            this.state = state;
            return this;
        }

        public Builder setCounty(String county) {
            this.county = county;
            return this;
        }

        public Builder setCases(Integer cases) {
            this.cases = cases;
            return this;
        }

        public Builder setDeaths(Integer deaths) {
            this.deaths = deaths;
            return this;
        }

        Builder() {
        }

        CovidWritable build() {
            return new CovidWritable(this);
        }

    }

    public CovidWritable(Builder builder) {
        this.state = builder.state;
        this.county = builder.county;
        this.cases = builder.cases;
        this.deaths = builder.deaths;
    }

    @Override
    public String toString() {
        return state + '\t' + county + '\t' + "\t" + cases + "\t" + deaths;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        CovidWritable that = (CovidWritable) o;

        if (!Objects.equals(state, that.state)) return false;
        if (!Objects.equals(county, that.county)) return false;
        if (!Objects.equals(cases, that.cases)) return false;
        return Objects.equals(deaths, that.deaths);
    }

    @Override
    public int hashCode() {
        int result = state != null ? state.hashCode() : 0;
        result = 31 * result + (county != null ? county.hashCode() : 0);
        result = 31 * result + (cases != null ? cases.hashCode() : 0);
        result = 31 * result + (deaths != null ? deaths.hashCode() : 0);
        return result;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public String getCounty() {
        return county;
    }

    public void setCounty(String county) {
        this.county = county;
    }

    public Integer getCases() {
        return cases;
    }

    public void setCases(Integer cases) {
        this.cases = cases;
    }

    public Integer getDeaths() {
        return deaths;
    }

    public void setDeaths(Integer deaths) {
        this.deaths = deaths;
    }

    public CovidWritable(String state, String county, Integer cases, Integer deaths) {
        this.state = state;
        this.county = county;
        this.cases = cases;
        this.deaths = deaths;
    }

    public CovidWritable() {
    }
}


```

## Mapper阶段

### Mapper类：`CovidMapper.java`

```java
package club.kwcoder.covid;

import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class CovidMapper extends Mapper<LongWritable, Text, CovidWritable, NullWritable> {

    private final CovidWritable.Builder builder = new CovidWritable.Builder();

    @Override
    protected void map(LongWritable key, Text value, Mapper<LongWritable, Text, CovidWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        String line = value.toString();
        // 排除空行
        if (StringUtils.isBlank(line)) {
            return;
        }
        // 排除首行
        if (key.get() == 0L && line.startsWith("date")) {
            return;
        }
        // 切分与排除非法数据
        String[] items = line.split(",", 6);
        if (items.length != 6) {
            return;
        }
        for (String item : items) {
            if (StringUtils.isBlank(item)) {
                return;
            }
        }
        // 构建对象并输出
        CovidWritable outKey = builder
                .setState(items[2])
                .setCounty(items[1])
                .setCases(Integer.parseInt(items[4]))
                .setDeaths(Integer.parseInt(items[5])).build();
        context.write(outKey, NullWritable.get());
    }
}


```

### 归并分组类：`CovidCombinerGrouping.java`

```java
package club.kwcoder.covid;

import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class CovidCombinerGrouping extends WritableComparator {

    public CovidCombinerGrouping() {
        super(CovidWritable.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {
        // 当属于同一县时，归位一组
        return ((CovidWritable) a).getCounty().compareTo(((CovidWritable) b).getCounty());
    }
}

```

### 归并类：`CovidCombiner.java`

```java
package club.kwcoder.covid;

import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class CovidCombiner extends Reducer<CovidWritable, NullWritable, CovidWritable, NullWritable> {

    private final CovidWritable.Builder outKeyBuild = new CovidWritable.Builder();

    @Override
    protected void reduce(CovidWritable key, Iterable<NullWritable> values, Reducer<CovidWritable, NullWritable, CovidWritable, NullWritable>.Context context) throws IOException, InterruptedException {
        String state = "", county = "";
        Integer cases = 0, deaths = 0;

        // 累加确诊数、死亡数
        for (NullWritable ignored : values) {
            if (state.equals("")) {
                state = key.getState();
                county = key.getCounty();
            }
            cases += key.getCases();
            deaths += key.getDeaths();
        }

        // 构建对象并输出
        CovidWritable build = outKeyBuild
                .setState(state)
                .setCounty(county)
                .setCases(cases)
                .setDeaths(deaths)
                .build();

        context.write(build, NullWritable.get());

    }
}


```

## Reducer阶段

### 自定义排序：`CovidSortByCaseASC.java`

```java
package club.kwcoder.covid;

import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.io.WritableComparator;

public class CovidSortByCaseASC extends WritableComparator {

    public CovidSortByCaseASC() {
        super(CovidWritable.class, true);
    }

    @Override
    public int compare(WritableComparable a, WritableComparable b) {
        CovidWritable a1 = (CovidWritable) a;
        CovidWritable b1 = (CovidWritable) b;

        // 当州不同时，根据州名的字典顺序排序
        if (!a1.getState().equals(b1.getState())) {
            return a1.getState().compareTo(b1.getState());
        }

        // 当州相同时，根据确诊数降序排序
        return -Integer.compare(((CovidWritable) a).getCases(), ((CovidWritable) b).getCases());
    }
}

```

### Reducer类：`CovidReducer.java`


```java
package club.kwcoder.covid;

import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class CovidReducer extends Reducer<CovidWritable, NullWritable, CovidWritable, NullWritable> {



    @Override
    protected void reduce(CovidWritable key, Iterable<NullWritable> values, Reducer<CovidWritable, NullWritable, CovidWritable, NullWritable>.Context context) throws IOException, InterruptedException {

        context.write(key, NullWritable.get());

    }
}


```

## 运行类：`CovidRunner.java`

```java
package club.kwcoder.covid;

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
import org.apache.hadoop.yarn.webapp.hamlet2.Hamlet;

import java.io.IOException;

public class CovidRunner {

    public static void main(String[] args) throws IOException, InterruptedException, ClassNotFoundException {

        Configuration conf = new Configuration();
        FileSystem hdfs = FileSystem.get(conf);

        Path input = new Path("/covid");
        Path output = new Path("/covid_result");

        if (hdfs.exists(output)) {
            hdfs.delete(output, true);
        }

        // 配置Job
        Job job = Job.getInstance(conf, "covid");
        job.setJarByClass(CovidRunner.class);
        // 配置输入
        job.setInputFormatClass(TextInputFormat.class);
        FileInputFormat.setInputPaths(job, input);
        // 配置Mapper类
        job.setMapperClass(CovidMapper.class);
        job.setMapOutputKeyClass(CovidWritable.class);
        job.setMapOutputValueClass(NullWritable.class);
        // 设置Combiner阶段的分组
        job.setCombinerKeyGroupingComparatorClass(CovidCombinerGrouping.class);
        // 设置Combiner
        job.setCombinerClass(CovidCombiner.class);
        // 设置自定义排序
        job.setSortComparatorClass(CovidSortByCaseASC.class);
        // 配置Reducer类
        job.setReducerClass(CovidReducer.class);
        job.setOutputKeyClass(CovidWritable.class);
        job.setOutputValueClass(NullWritable.class);
        // 配置输出
        job.setOutputFormatClass(TextOutputFormat.class);
        FileOutputFormat.setOutputPath(job, output);
        // 运行
        boolean flag = job.waitForCompletion(true);
        if (flag) {
            System.out.println("covid process success");
        }

    }

}


```


