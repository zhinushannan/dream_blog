```text
HBase Java 过滤器
大数据>HBase
2022-07-27
https://picgo.kwcoder.club/202208/202207211953477.png
```



# HBase过滤器

## 过滤器简介

HBase过滤器可以提供多个纬度对数据进行筛选，类似于SQL中的WHERE条件。

过滤器可以根据如下纬度进行过滤：

- 行键
- 列簇
- 列
- 单元格
- 时间戳
- 组合过滤

## HBase过滤器使用方法

```java
// do something

TableName tableName = TableName.valueOf("表名");
Table table = connection.getTable(tableName);
Scan scan = new Scan();
Fitler filter = new xxx(...);
ResultScanner rows = table.getScanner(scan);

// do something

```

# 插入数据与编写工具类

## 导入数据

将巴西利亚天气中83377的数据导入HBase（[下载链接](https://picgo.kwcoder.club/202208/weather.csv)），并将生成的csv文件复制到`resources`目录下。

```java
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;

public class ImportData {

    public static void main(String[] args) {

        try {
            // 获取HBase 连接、Admin
            Connection connection = HBaseUtils.getConnection();
            Admin admin = HBaseUtils.getAdmin();

            // 创建表
            TableName tableName = TableName.valueOf(Bytes.toBytes("weather"));
            HBaseUtils.deleteTableIfExist(tableName);
            TableDescriptor tableDescriptor = TableDescriptorBuilder
                    .newBuilder(tableName)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.newBuilder(Bytes.toBytes("info")).build())
                    .build();
            admin.createTable(tableDescriptor);
            Table table = connection.getTable(tableName);

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            byte[] code = Bytes.toBytes("code");
            byte[] precipitation = Bytes.toBytes("precipitation");
            byte[] maxTemperature = Bytes.toBytes("maxTemperature");
            byte[] minTemperature = Bytes.toBytes("minTemperature");
            byte[] avgTemperature = Bytes.toBytes("avgTemperature");

            // 读取文件
            InputStreamReader reader = new InputStreamReader(Files.newInputStream(Paths.get("src/main/resources/weather.csv")));
            BufferedReader bufferedReader = new BufferedReader(reader);

            // 通过stream向HBase插入数据
            bufferedReader.lines().forEach(line -> {
                // 格式： code,date,precipitation,maxTemperature,minTemperature,avgTemperature
                String[] split = line.split(",");
                byte[] date = Bytes.toBytes(split[1]);

                // 以日期作为行键
                Put put = new Put(date);
                put.addColumn(family, code, Bytes.toBytes(split[0]));
                put.addColumn(family, precipitation, Bytes.toBytes(split[2]));
                put.addColumn(family, maxTemperature, Bytes.toBytes(split[3]));
                put.addColumn(family, minTemperature, Bytes.toBytes(split[4]));
                put.addColumn(family, avgTemperature, Bytes.toBytes(split[5]));

                try {
                    table.put(put);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        } catch (IOException e) {
            throw new RuntimeException(e);
        } finally {
            HBaseUtils.close();
        }
        
    }

}

```

## 编写工具类

在[上一篇文章](/p/20220726/)的`HBaseUtils.java`基础上，增加下列方法：

```java
    /**
     * 输出扫描结果（仅支持字符串格式）
     *
     * @param results 扫描结果
     * @param family  列簇
     * @param cols    列名列表
     */
    public static void show(ResultScanner results, byte[] family, List<byte[]> cols) {
        StringBuffer stringBuffer;

        for (Result result : results) {
            stringBuffer = new StringBuffer();

            String rowKey = Bytes.toString(result.getRow());

            stringBuffer.append("[").append(rowKey);

            for (byte[] c : cols) {
                String col = Bytes.toString(c);
                String val = Bytes.toString(result.getValue(family, c));
                stringBuffer.append("\t").append(col).append(":").append(val);
            }

            stringBuffer.append("]");
            System.out.println(stringBuffer);
        }
    }

```

# 基于行键的过滤器

## 代码编写

```java
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class RowKeyFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf(Bytes.toBytes("weather")));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));

            // 定义扫描器
            Scan scan = new Scan();

            // 定义比较器
            BinaryComparator comparator = new BinaryComparator(Bytes.toBytes("01/01/1966"));

            // 过滤查找行键为 "16/06/1981" 的Cell
            System.out.println("过滤查找行键等于 \"01/01/1966\" 的Cell==============");
            Filter filter = new RowFilter(CompareOperator.EQUAL, comparator);
            scan.setFilter(filter);
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);

            // 过滤查找行键小于 "16/06/1981" 的Cell
            System.out.println("\n过滤查找行键小于 \"01/01/1966\" 的Cell==============");
            filter = new RowFilter(CompareOperator.LESS, comparator);
            scan.setFilter(filter);
            results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);

            // 过滤查找行键满足 01/01/xxx1 的Cell
            System.out.println("\n过滤查找行键满足 01/01/xxx1(01/01/\\\\d+1$) 的Cell============");
            RegexStringComparator regexStringComparator = new RegexStringComparator("01/01/\\d+1$");
            filter = new RowFilter(CompareOperator.EQUAL, regexStringComparator);
            scan.setFilter(filter);
            results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);

            System.out.println("\n判断是否存在行键 02/29/2004 ============");
            // 只返回行键，通常用于判断某行键是否存在
            filter = new KeyOnlyFilter();
            scan.setFilter(filter);
            results = table.getScanner(scan);
            for (Result result : results) {
                if (Bytes.toString(result.getRow()).equals("02/29/2004")) {
                    System.out.println(true);
                }
            }
            System.out.println(false);

            // 过滤行键中包含 "1/01/1999" 子串的Cell
            System.out.println("\n过滤行键中包含 \"1/01/1999\" 子串的Cell ==============");
            SubstringComparator substringComparator = new SubstringComparator("1/01/1999");
            filter = new RowFilter(CompareOperator.EQUAL, substringComparator);
            scan.setFilter(filter);
            results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

}

```

## 控制台输出

```java
过滤查找行键等于 "01/01/1966" 的Cell==============
[01/01/1966	code:83377	precipitation:20	maxTemperature:27.8	minTemperature:17.5	avgTemperature:20.7]

过滤查找行键小于 "01/01/1966" 的Cell==============
[01/01/1963	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.7	avgTemperature:21.74]
[01/01/1964	code:83377	precipitation:3.2	maxTemperature:26	minTemperature:18	avgTemperature:20.84]
[01/01/1965	code:83377	precipitation:21.2	maxTemperature:24.7	minTemperature:16.6	avgTemperature:19.66]

过滤查找行键满足 01/01/xxx1(01/01/\\d+1$) 的Cell============
[01/01/1971	code:83377	precipitation:0	maxTemperature:30.3	minTemperature:18.5	avgTemperature:24.02]
[01/01/1981	code:83377	precipitation:5.6	maxTemperature:22.7	minTemperature:17.5	avgTemperature:19.32]
[01/01/1991	code:83377	precipitation:0	maxTemperature:25.4	minTemperature:16.6	avgTemperature:18.92]
[01/01/2001	code:83377	precipitation:22.8	maxTemperature:24.8	minTemperature:18.9	avgTemperature:20.52]
[01/01/2011	code:83377	precipitation:17.2	maxTemperature:24.6	minTemperature:17.8	avgTemperature:19.9]

判断是否存在行键 02/29/2004 ============
false

过滤行键中包含 "1/01/1999" 子串的Cell ==============
[01/01/1999	code:83377	precipitation:6.3	maxTemperature:25.7	minTemperature:17.2	avgTemperature:20.58]
[11/01/1999	code:83377	precipitation:0	maxTemperature:22.4	minTemperature:18.9	avgTemperature:19.7]
[21/01/1999	code:83377	precipitation:0	maxTemperature:29.5	minTemperature:17.9	avgTemperature:21.92]
[31/01/1999	code:83377	precipitation:0.6	maxTemperature:28.2	minTemperature:18	avgTemperature:21.66]

```

# 基于列簇的过滤器

## 代码编写

```java
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ResultScanner;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.filter.BinaryComparator;
import org.apache.hadoop.hbase.filter.RegexStringComparator;
import org.apache.hadoop.hbase.filter.SubstringComparator;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class FamilyFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf(Bytes.toBytes("weather")));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));

            Scan scan = new Scan();

            // 列簇名称为 "info"
            BinaryComparator binaryComparator = new BinaryComparator(Bytes.toBytes("info"));
            // 列簇名称包含 "fo"
            SubstringComparator substringComparator = new SubstringComparator("fo");
            // 列簇名称符合开头为 i 的正则规则
            RegexStringComparator regexStringComparator = new RegexStringComparator("^i");

            // FamilyFilter familyFilter = new FamilyFilter(CompareOperator.EQUAL, binaryComparator);
            // FamilyFilter familyFilter = new FamilyFilter(CompareOperator.EQUAL, substringComparator);
            // FamilyFilter familyFilter = new FamilyFilter(CompareOperator.EQUAL, regexStringComparator);
            scan.setFilter(familyFilter);
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

}

```

## 控制台输出

由于输出行过多，不便展示。

# 基于行的过滤器

## 代码编写

```java
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class RowFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf(Bytes.toBytes("weather")));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));

            Scan scan = new Scan();

            // 过滤出有包含 maxTemperature 列的行
            // BinaryComparator binaryComparator = new BinaryComparator(Bytes.toBytes("maxTemperature"));
            // Filter filter = new QualifierFilter(CompareOperator.EQUAL, binaryComparator);
            // 过滤出有包含子串 "Temp" 的列的行
            // SubstringComparator substringComparator = new SubstringComparator("Temp");
            // filter = new QualifierFilter(CompareOperator.EQUAL, substringComparator);
            // 过滤出有以 max 开头的列的行
            // RegexStringComparator comparator = new RegexStringComparator("^max");
            // filter = new QualifierFilter(CompareOperator.EQUAL, comparator);

            // scan.setFilter(filter);
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

}

```

## 控制台输出

由于输出行过多，不便展示。

# 基于单元格的过滤器

## 代码编写

```java
import javafx.scene.layout.HBox;
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ResultScanner;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.filter.Filter;
import org.apache.hadoop.hbase.filter.SingleColumnValueFilter;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class CellFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf(Bytes.toBytes("weather")));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));

            Scan scan = new Scan();
            // 分别指定 列簇、列名、比较方法、列值
            // 过滤出 info 列簇中，列名 maxTemperature 的值为 29 的单元格
            Filter filter = new SingleColumnValueFilter(
                    Bytes.toBytes("info"),
                    Bytes.toBytes("maxTemperature"),
                    CompareOperator.EQUAL,
                    Bytes.toBytes("29"));
            scan.setFilter(filter);
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

}

```

## 控制台输出

```text
[01/01/1963	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.7	avgTemperature:21.74]
[01/02/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.6	avgTemperature:22.52]
[01/02/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.8	avgTemperature:21.68]
[01/02/2017	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:22.84]
[01/03/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.6	avgTemperature:22.28]
[01/04/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.4	avgTemperature:22.36]
[01/05/2016	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:20.78]
[01/09/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.3	avgTemperature:22.02]
[01/09/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.2	avgTemperature:22.66]
[01/10/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:16	avgTemperature:22.56]
[01/11/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.6	avgTemperature:22.32]
[02/01/1972	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.52]
[02/02/1994	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.7]
[02/04/1968	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.58]
[02/04/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:22.88]
[02/05/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:21.92]
[02/08/2018	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:21.62]
[02/09/1961	code:83377	precipitation:0	maxTemperature:29	minTemperature:11.3	avgTemperature:20.86]
[02/10/1991	code:83377	precipitation:97	maxTemperature:29	minTemperature:17.3	avgTemperature:22.22]
[02/10/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.1	avgTemperature:21.34]
[02/10/2003	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.14]
[02/12/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:23.26]
[03/02/1984	code:83377	precipitation:12	maxTemperature:29	minTemperature:18.2	avgTemperature:23.12]
[03/03/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:23.5]
[03/09/1997	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.5	avgTemperature:21.72]
[03/09/2008	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:23.12]
[03/09/2016	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:22.56]
[03/10/1972	code:83377	precipitation:23.2	maxTemperature:29	minTemperature:18.3	avgTemperature:23.14]
[03/10/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:22.08]
[03/12/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.06]
[03/12/1993	code:83377	precipitation:7.4	maxTemperature:29	minTemperature:19.5	avgTemperature:23.94]
[04/01/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.7	avgTemperature:24.1]
[04/03/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.2	avgTemperature:22.68]
[04/04/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.72]
[04/08/1963	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.4	avgTemperature:20.8]
[04/08/1982	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:23.16]
[04/09/1976	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.6]
[04/10/1968	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:22.44]
[04/11/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:23.08]
[04/12/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.96]
[05/01/1970	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.6	avgTemperature:23.4]
[05/03/1967	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.5	avgTemperature:22.26]
[05/03/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.1]
[05/04/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.1	avgTemperature:23.1]
[05/04/1999	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.4	avgTemperature:23.44]
[05/05/1979	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:20.76]
[05/08/1979	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.72]
[05/08/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.68]
[05/08/2014	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.4	avgTemperature:21.88]
[05/09/2011	code:83377	precipitation:0	maxTemperature:29	minTemperature:13.5	avgTemperature:21.8]
[05/10/1962	code:83377	precipitation:1	maxTemperature:29	minTemperature:14.5	avgTemperature:22.06]
[05/10/1966	code:83377	precipitation:1.9	maxTemperature:29	minTemperature:18.5	avgTemperature:22.56]
[05/10/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:21.2]
[05/10/1997	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.8	avgTemperature:23.82]
[05/11/1974	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.92]
[05/11/1981	code:83377	precipitation:12.7	maxTemperature:29	minTemperature:17.4	avgTemperature:22.8]
[06/02/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.5	avgTemperature:22.46]
[06/02/1984	code:83377	precipitation:5.5	maxTemperature:29	minTemperature:18.4	avgTemperature:22.08]
[06/02/2005	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:22.8]
[06/03/1998	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.8	avgTemperature:23.78]
[06/04/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.56]
[06/04/1976	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.5	avgTemperature:22.38]
[06/05/2017	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.82]
[06/08/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:20.84]
[06/08/2015	code:83377	precipitation:0	maxTemperature:29	minTemperature:12.2	avgTemperature:20.2]
[06/09/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.2]
[06/12/2019	code:83377	precipitation:16.8	maxTemperature:29	minTemperature:19.4	avgTemperature:22.04]
[07/01/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.3	avgTemperature:22.98]
[07/02/2014	code:83377	precipitation:0	maxTemperature:29	minTemperature:20	avgTemperature:24.02]
[07/03/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.64]
[07/04/1999	code:83377	precipitation:0.2	maxTemperature:29	minTemperature:18.4	avgTemperature:23.04]
[07/08/1968	code:83377	precipitation:0	maxTemperature:29	minTemperature:14	avgTemperature:22.16]
[07/08/2002	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.12]
[07/09/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.3	avgTemperature:20.18]
[07/09/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:23.16]
[07/11/2004	code:83377	precipitation:0.6	maxTemperature:29	minTemperature:19.3	avgTemperature:22.72]
[08/02/1972	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:22.66]
[08/03/1993	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.1	avgTemperature:23.06]
[08/05/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.6	avgTemperature:22.72]
[08/07/2016	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:22.58]
[08/08/2008	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:22.54]
[08/09/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:23.28]
[08/10/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.3	avgTemperature:22.8]
[08/10/2003	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.6	avgTemperature:21.76]
[09/01/1975	code:83377	precipitation:7.5	maxTemperature:29	minTemperature:16	avgTemperature:21.48]
[09/01/2015	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.8	avgTemperature:24.26]
[09/02/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.9	avgTemperature:23.46]
[09/03/1980	code:83377	precipitation:2.2	maxTemperature:29	minTemperature:16	avgTemperature:21.84]
[09/08/1987	code:83377	precipitation:0	maxTemperature:29	minTemperature:13.1	avgTemperature:20.82]
[09/08/1991	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.7	avgTemperature:21.7]
[09/09/1964	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.7	avgTemperature:22.1]
[09/09/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.2	avgTemperature:21.6]
[09/09/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.86]
[09/10/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.44]
[09/10/2011	code:83377	precipitation:12	maxTemperature:29	minTemperature:17.8	avgTemperature:22.08]
[09/11/1981	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.2	avgTemperature:22.4]
[10/01/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:24.06]
[10/02/1970	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.2	avgTemperature:22.44]
[10/02/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.7	avgTemperature:23.96]
[10/02/2008	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:23.54]
[10/04/1987	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.28]
[10/05/2017	code:83377	precipitation:0	maxTemperature:29	minTemperature:13.9	avgTemperature:20.7]
[10/08/1972	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.3	avgTemperature:22.6]
[10/08/1991	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:22.36]
[10/08/1998	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:22.5]
[10/09/1972	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.36]
[10/09/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.9	avgTemperature:23.22]
[10/10/1965	code:83377	precipitation:3.2	maxTemperature:29	minTemperature:16	avgTemperature:22.16]
[10/11/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.5	avgTemperature:23.2]
[10/12/1993	code:83377	precipitation:1.2	maxTemperature:29	minTemperature:18.1	avgTemperature:22.66]
[10/12/1996	code:83377	precipitation:13	maxTemperature:29	minTemperature:16.9	avgTemperature:21.98]
[10/12/2012	code:83377	precipitation:13.2	maxTemperature:29	minTemperature:18	avgTemperature:22.74]
[11/01/1987	code:83377	precipitation:3	maxTemperature:29	minTemperature:17.9	avgTemperature:23.26]
[11/02/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.2	avgTemperature:23.16]
[11/02/2013	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:23.34]
[11/03/1968	code:83377	precipitation:0	maxTemperature:29	minTemperature:16	avgTemperature:22]
[11/03/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.8]
[11/04/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.04]
[11/04/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:22.92]
[11/04/1987	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:22.78]
[11/04/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:23.16]
[11/09/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.5	avgTemperature:21.62]
[11/09/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:13.2	avgTemperature:21.6]
[11/09/1981	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.4	avgTemperature:20.88]
[11/09/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.7	avgTemperature:23.12]
[11/09/1994	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.34]
[11/10/1973	code:83377	precipitation:0.2	maxTemperature:29	minTemperature:17.7	avgTemperature:22.18]
[11/11/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:18	avgTemperature:22.56]
[12/02/1991	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:22.68]
[12/02/2015	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.9	avgTemperature:24.1]
[12/02/2019	code:83377	precipitation:19	maxTemperature:29	minTemperature:19.3	avgTemperature:23.44]
[12/03/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.74]
[12/04/1969	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.36]
[12/04/1998	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.8	avgTemperature:23.74]
[12/04/2008	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.9	avgTemperature:22.5]
[12/08/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:11.2	avgTemperature:19.84]
[12/08/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:14	avgTemperature:22]
[12/09/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.3	avgTemperature:21.98]
[12/09/1981	code:83377	precipitation:0	maxTemperature:29	minTemperature:16	avgTemperature:21.72]
[12/10/1991	code:83377	precipitation:13	maxTemperature:29	minTemperature:18.6	avgTemperature:23.4]
[12/10/1995	code:83377	precipitation:2.9	maxTemperature:29	minTemperature:18.1	avgTemperature:20.76]
[12/11/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.8	avgTemperature:22.68]
[12/12/2010	code:83377	precipitation:3.3	maxTemperature:29	minTemperature:18.8	avgTemperature:23.42]
[13/08/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.3	avgTemperature:21.58]
[13/08/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.9	avgTemperature:21.82]
[13/08/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.9	avgTemperature:21.98]
[13/08/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.9	avgTemperature:23.3]
[13/08/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.9	avgTemperature:21.02]
[13/08/2011	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.12]
[13/08/2014	code:83377	precipitation:0	maxTemperature:29	minTemperature:12.8	avgTemperature:21.92]
[13/12/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.9	avgTemperature:23.84]
[14/01/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.7	avgTemperature:23.64]
[14/01/2009	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.4	avgTemperature:23.92]
[14/01/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:23.68]
[14/03/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:22.46]
[14/04/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.4	avgTemperature:23.6]
[14/09/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.2	avgTemperature:22.96]
[14/10/1966	code:83377	precipitation:5.9	maxTemperature:29	minTemperature:18.4	avgTemperature:23.08]
[14/11/2007	code:83377	precipitation:5.3	maxTemperature:29	minTemperature:17.2	avgTemperature:22.54]
[14/11/2009	code:83377	precipitation:0	maxTemperature:29	minTemperature:20.2	avgTemperature:24.4]
[14/12/1966	code:83377	precipitation:6.2	maxTemperature:29	minTemperature:18.8	avgTemperature:21.76]
[15/01/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:16	avgTemperature:22.72]
[15/01/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.2	avgTemperature:23.84]
[15/03/1981	code:83377	precipitation:0.9	maxTemperature:29	minTemperature:19.8	avgTemperature:23]
[15/03/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.2	avgTemperature:22.24]
[15/03/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.1	avgTemperature:22.26]
[15/05/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:22.72]
[15/07/1980	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:20.6]
[15/08/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.2	avgTemperature:22.4]
[15/08/2003	code:83377	precipitation:24.6	maxTemperature:29	minTemperature:15.3	avgTemperature:20.9]
[15/08/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.7	avgTemperature:21.46]
[15/09/1986	code:83377	precipitation:1.3	maxTemperature:29	minTemperature:17.3	avgTemperature:22.74]
[15/09/1999	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:22.16]
[15/11/2018	code:83377	precipitation:25.4	maxTemperature:29	minTemperature:18.2	avgTemperature:23.08]
[15/12/1964	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:22.86]
[16/02/1982	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.82]
[16/03/1970	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.66]
[16/09/1979	code:83377	precipitation:9.4	maxTemperature:29	minTemperature:17.6	avgTemperature:21.72]
[16/10/1970	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.8	avgTemperature:22.68]
[16/11/1972	code:83377	precipitation:0.5	maxTemperature:29	minTemperature:18.4	avgTemperature:21.6]
[17/01/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.9]
[17/02/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:18	avgTemperature:23.4]
[17/02/2006	code:83377	precipitation:1	maxTemperature:29	minTemperature:18.9	avgTemperature:23.64]
[17/08/2016	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.1	avgTemperature:21.78]
[17/09/1976	code:83377	precipitation:3.7	maxTemperature:29	minTemperature:15.4	avgTemperature:21.28]
[17/09/2002	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.36]
[17/10/2009	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:23.82]
[17/11/2013	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:22.18]
[18/01/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.94]
[18/01/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.6	avgTemperature:23.72]
[18/02/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.7	avgTemperature:22.62]
[18/03/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:22.86]
[18/04/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.44]
[18/08/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.5	avgTemperature:22.1]
[18/08/1976	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:20.8]
[18/08/1998	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:22.16]
[18/09/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:11.6	avgTemperature:20.64]
[18/09/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.5	avgTemperature:21.54]
[18/09/1994	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.6	avgTemperature:22.84]
[18/11/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:21.48]
[18/12/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.7	avgTemperature:22.76]
[19/01/1975	code:83377	precipitation:1.8	maxTemperature:29	minTemperature:18	avgTemperature:22.2]
[19/03/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.22]
[19/04/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.24]
[19/11/1974	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.88]
[20/02/1967	code:83377	precipitation:0.1	maxTemperature:29	minTemperature:17.8	avgTemperature:22.32]
[20/02/2006	code:83377	precipitation:6.4	maxTemperature:29	minTemperature:18.2	avgTemperature:22.08]
[20/08/1980	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.4]
[20/09/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:22.54]
[20/11/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.6	avgTemperature:21.56]
[20/11/2002	code:83377	precipitation:0.6	maxTemperature:29	minTemperature:17.3	avgTemperature:23.16]
[20/11/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:20.4	avgTemperature:23.32]
[20/11/2017	code:83377	precipitation:0.1	maxTemperature:29	minTemperature:19	avgTemperature:23.1]
[20/12/1981	code:83377	precipitation:0.3	maxTemperature:29	minTemperature:16.6	avgTemperature:22.24]
[20/12/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.8	avgTemperature:22.64]
[21/01/1967	code:83377	precipitation:14.5	maxTemperature:29	minTemperature:18.6	avgTemperature:22.6]
[21/01/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.02]
[21/01/2017	code:83377	precipitation:0.2	maxTemperature:29	minTemperature:18.3	avgTemperature:21.9]
[21/02/1985	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:23.48]
[21/02/2002	code:83377	precipitation:5.6	maxTemperature:29	minTemperature:18.9	avgTemperature:23.52]
[21/02/2013	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.9	avgTemperature:23.8]
[21/03/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.46]
[21/04/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:22.02]
[21/08/1967	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:21.68]
[21/08/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:23.28]
[21/09/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:19	avgTemperature:23.44]
[21/10/1961	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:22.96]
[21/10/1965	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:21.44]
[21/11/1962	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.9	avgTemperature:19.9]
[21/12/2017	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.3	avgTemperature:24.12]
[22/01/1967	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.76]
[22/01/1986	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.6	avgTemperature:23.96]
[22/01/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:22.56]
[22/02/1976	code:83377	precipitation:7.1	maxTemperature:29	minTemperature:18	avgTemperature:22.16]
[22/02/2009	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.2	avgTemperature:23.8]
[22/02/2017	code:83377	precipitation:0.3	maxTemperature:29	minTemperature:19	avgTemperature:22.76]
[22/03/1990	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.7	avgTemperature:22.58]
[22/07/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.6	avgTemperature:22.88]
[22/07/2009	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.6	avgTemperature:21.48]
[22/10/1972	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:22.98]
[22/10/2016	code:83377	precipitation:14.8	maxTemperature:29	minTemperature:17.9	avgTemperature:21.78]
[22/11/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:23.56]
[22/12/1970	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:22.62]
[23/02/1997	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.7	avgTemperature:24.24]
[23/02/2005	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.36]
[23/02/2011	code:83377	precipitation:6.2	maxTemperature:29	minTemperature:18	avgTemperature:22.5]
[23/05/2017	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.7	avgTemperature:25.22]
[23/08/1965	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.4	avgTemperature:21.04]
[23/08/1997	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.5	avgTemperature:21.96]
[23/09/1993	code:83377	precipitation:0.4	maxTemperature:29	minTemperature:17.9	avgTemperature:22.16]
[23/09/2001	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.3	avgTemperature:22.62]
[24/01/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:20	avgTemperature:23.9]
[24/03/1977	code:83377	precipitation:0.3	maxTemperature:29	minTemperature:17.7	avgTemperature:22.1]
[24/03/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.8	avgTemperature:22.6]
[24/09/1974	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.4]
[24/10/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.9	avgTemperature:23.38]
[24/10/2000	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:21.76]
[24/11/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.6	avgTemperature:23]
[25/02/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:23.6]
[25/03/1978	code:83377	precipitation:0	maxTemperature:29	minTemperature:16	avgTemperature:22.24]
[25/03/1998	code:83377	precipitation:0	maxTemperature:29	minTemperature:20.6	avgTemperature:22.9]
[25/07/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.7	avgTemperature:21.46]
[25/10/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.1	avgTemperature:22.56]
[25/10/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.1	avgTemperature:23.52]
[25/10/1997	code:83377	precipitation:47.1	maxTemperature:29	minTemperature:16.7	avgTemperature:22.88]
[25/11/1970	code:83377	precipitation:9.6	maxTemperature:29	minTemperature:17	avgTemperature:22.9]
[26/01/1999	code:83377	precipitation:0	maxTemperature:29	minTemperature:20.4	avgTemperature:23.3]
[26/02/1967	code:83377	precipitation:1.3	maxTemperature:29	minTemperature:16.3	avgTemperature:21.58]
[26/02/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.7	avgTemperature:23.12]
[26/02/2013	code:83377	precipitation:38.7	maxTemperature:29	minTemperature:18.9	avgTemperature:22.2]
[26/03/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:22.34]
[26/07/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:21.8]
[26/08/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:13.8	avgTemperature:22.04]
[26/09/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:21.52]
[26/09/1971	code:83377	precipitation:1.3	maxTemperature:29	minTemperature:14.5	avgTemperature:21.66]
[26/09/1997	code:83377	precipitation:5.2	maxTemperature:29	minTemperature:18.1	avgTemperature:22.12]
[26/10/1974	code:83377	precipitation:9.4	maxTemperature:29	minTemperature:17.2	avgTemperature:22.36]
[26/10/1995	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:24.22]
[27/02/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.32]
[27/03/1980	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.8	avgTemperature:22.48]
[27/03/1985	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.4	avgTemperature:23.32]
[27/05/2007	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.8	avgTemperature:22.56]
[27/07/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.5	avgTemperature:22.08]
[27/08/1996	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.8	avgTemperature:22.72]
[27/08/1999	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.1	avgTemperature:22.1]
[27/08/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.4	avgTemperature:22.48]
[27/08/2011	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.6	avgTemperature:22.58]
[27/11/2003	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:22.58]
[27/12/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:20.1	avgTemperature:24.02]
[28/01/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.5	avgTemperature:21.9]
[28/02/1974	code:83377	precipitation:4.6	maxTemperature:29	minTemperature:17	avgTemperature:21.68]
[28/02/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.4	avgTemperature:22.14]
[28/02/1996	code:83377	precipitation:8.1	maxTemperature:29	minTemperature:18.1	avgTemperature:23.74]
[28/02/2018	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.9	avgTemperature:22.64]
[28/07/2002	code:83377	precipitation:11.1	maxTemperature:29	minTemperature:15.5	avgTemperature:22.1]
[28/07/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.9	avgTemperature:22.22]
[28/10/1994	code:83377	precipitation:0.7	maxTemperature:29	minTemperature:17.7	avgTemperature:23.04]
[28/10/2016	code:83377	precipitation:7.2	maxTemperature:29	minTemperature:18.2	avgTemperature:21.7]
[28/11/1982	code:83377	precipitation:3.1	maxTemperature:29	minTemperature:17.5	avgTemperature:21.26]
[28/12/1972	code:83377	precipitation:23.3	maxTemperature:29	minTemperature:18.3	avgTemperature:23.24]
[29/02/1984	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.6	avgTemperature:23.92]
[29/03/1966	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.3	avgTemperature:22.78]
[29/08/1975	code:83377	precipitation:0	maxTemperature:29	minTemperature:14.7	avgTemperature:21.2]
[29/08/2013	code:83377	precipitation:0	maxTemperature:29	minTemperature:15	avgTemperature:22.2]
[29/09/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:22.24]
[29/09/1987	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.7	avgTemperature:23.42]
[29/09/2006	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.8	avgTemperature:23.26]
[29/10/2016	code:83377	precipitation:0.3	maxTemperature:29	minTemperature:18.9	avgTemperature:21.82]
[29/12/1997	code:83377	precipitation:5.6	maxTemperature:29	minTemperature:18.4	avgTemperature:22.02]
[30/01/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.1	avgTemperature:21.72]
[30/01/2010	code:83377	precipitation:4.2	maxTemperature:29	minTemperature:18.9	avgTemperature:24.08]
[30/03/1979	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.8	avgTemperature:22.36]
[30/07/1977	code:83377	precipitation:0	maxTemperature:29	minTemperature:13	avgTemperature:20.96]
[30/07/1980	code:83377	precipitation:0	maxTemperature:29	minTemperature:14	avgTemperature:21.24]
[30/08/1967	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.3	avgTemperature:21.98]
[30/08/1973	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.8	avgTemperature:22.02]
[30/08/1983	code:83377	precipitation:0	maxTemperature:29	minTemperature:15.6	avgTemperature:21.92]
[30/09/1965	code:83377	precipitation:1.1	maxTemperature:29	minTemperature:17.3	avgTemperature:22.66]
[30/10/2008	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:22.4]
[30/10/2015	code:83377	precipitation:16.9	maxTemperature:29	minTemperature:19.1	avgTemperature:22.3]
[30/11/2010	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.2	avgTemperature:22.56]
[30/12/2019	code:83377	precipitation:0	maxTemperature:29	minTemperature:20	avgTemperature:23.7]
[31/01/1988	code:83377	precipitation:0.7	maxTemperature:29	minTemperature:17.5	avgTemperature:23.06]
[31/03/1979	code:83377	precipitation:0	maxTemperature:29	minTemperature:17	avgTemperature:21.4]
[31/03/1988	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.8	avgTemperature:23.64]
[31/03/2015	code:83377	precipitation:0	maxTemperature:29	minTemperature:19.6	avgTemperature:22.38]
[31/08/1994	code:83377	precipitation:0	maxTemperature:29	minTemperature:17.9	avgTemperature:22.68]
[31/10/1977	code:83377	precipitation:0.8	maxTemperature:29	minTemperature:17.6	avgTemperature:22.24]
[31/10/1989	code:83377	precipitation:0	maxTemperature:29	minTemperature:16.1	avgTemperature:22.76]
[31/10/1993	code:83377	precipitation:0	maxTemperature:29	minTemperature:18.3	avgTemperature:23.12]
[31/10/2016	code:83377	precipitation:0.3	maxTemperature:29	minTemperature:18.4	avgTemperature:22.18]

Process finished with exit code 0


```

# 基于时间戳的过滤器

## 代码编写

```java
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ResultScanner;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.filter.Filter;
import org.apache.hadoop.hbase.filter.TimestampsFilter;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class TimestampFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf(Bytes.toBytes("weather")));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));
            
            Scan scan = new Scan();
            // 构建时间戳列表
            List<Long> timestamps = new ArrayList<>();
            timestamps.add(1658826058298L);
            Filter filter = new TimestampsFilter(timestamps);
            scan.setFilter(filter);
            // 返回所有版本
            scan.readAllVersions();
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }

}

```

## 控制台输出

```text
[01/04/1991	code:83377	precipitation:16.6	maxTemperature:24.2	minTemperature:18	avgTemperature:19.52]
```

# 组合过滤器

## 代码编写

```java
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ResultScanner;
import org.apache.hadoop.hbase.client.Scan;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.filter.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ListFilterExample {

    public static void main(String[] args) {

        try {
            Connection connection = HBaseUtils.getConnection();
            Table table = connection.getTable(TableName.valueOf("weather"));

            // 定义列簇和列
            byte[] family = Bytes.toBytes("info");
            List<byte[]> cols = new ArrayList<>();
            cols.add(Bytes.toBytes("code"));
            cols.add(Bytes.toBytes("precipitation"));
            cols.add(Bytes.toBytes("maxTemperature"));
            cols.add(Bytes.toBytes("minTemperature"));
            cols.add(Bytes.toBytes("avgTemperature"));

            Scan scan = new Scan();

            // 过滤包含子串 "04/1991" 的行键
            SubstringComparator rowKeySubstringComparator = new SubstringComparator("09/1991");
            RowFilter rowFilter = new RowFilter(CompareOperator.EQUAL, rowKeySubstringComparator);

            // 过滤最大温度大于24度的列
            ColumnValueFilter columnValueFilter = new ColumnValueFilter(
                    Bytes.toBytes("info"),
                    Bytes.toBytes("maxTemperature"),
                    CompareOperator.GREATER,
                    Bytes.toBytes("30.5"));

            // 求 与 条件：使用 FilterList.Operator.MUST_PASS_ALL，过滤器个数不限
            Filter filter = new FilterList(FilterList.Operator.MUST_PASS_ALL, rowFilter, columnValueFilter);
            scan.setFilter(filter);
            ResultScanner results = table.getScanner(scan);
            HBaseUtils.show(results, family, cols);

            // 输出行过多，不便展示
            // 求 或 条件：使用 FilterList.Operator.MUST_PASS_ONE，过滤器个数不限
            // filter = new FilterList(FilterList.Operator.MUST_PASS_ONE, rowFilter, columnValueFilter);
            // scan.setFilter(filter);
            // results = table.getScanner(scan);
            // HBaseUtils.show(results, family, cols);

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }
    }

}

```

## 控制台输出

```text
[13/09/1991	code:null	precipitation:null	maxTemperature:30.8	minTemperature:null	avgTemperature:null]
[25/09/1991	code:null	precipitation:null	maxTemperature:30.6	minTemperature:null	avgTemperature:null]
```



