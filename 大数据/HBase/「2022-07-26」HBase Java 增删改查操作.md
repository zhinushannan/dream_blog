```text
HBase Java 增删改查操作
大数据>HBase
2022-07-26
https://picgo.kwcoder.club/202208/202207211953477.png
```





# 添加依赖

```

    <dependency>
        <groupId>org.apache.hbase</groupId>
        <artifactId>hbase-client</artifactId>
        <version>2.4.8</version>
    </dependency>
    
    <dependency>
        <groupId>org.apache.hbase</groupId>
        <artifactId>hbase-server</artifactId>
        <version>2.4.8</version>
    </dependency>

```

# 命名空间的创建、删除与查看

## 原理

**创建命名空间时，不能与已存在的命名空间有重名，否则会创建失败。**
**因此在创建命名空间之前，需要检查命名空间是否存在。**

**如果需要删除命名空间，应当保证命名空间内没有表。**
**删除表之前应当保证表的状态处于禁用状态。**

## 代码

```

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.NamespaceDescriptor;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Admin;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

public class CreateNameSpace {

    public static void main(String[] args) {

        Configuration conf;
        Connection connection = null;
        Admin admin = null;
        try {
            // 获取HBaseConfiguration、HBase连接、HBase Admin对象
            conf = HBaseConfiguration.create();
            connection = ConnectionFactory.createConnection(conf);
            admin = connection.getAdmin();

            // 打印当前已存在的命名空间
            String[] namespacesExist = admin.listNamespaces();
            System.out.println("代码开始运行，当前命名空间有：" + Arrays.toString(namespacesExist));

            // 获取所有命名空间
            String[] namespaces = admin.listNamespaces();
            List<String> namespaceList = Arrays.asList(namespaces);
            /*
            构建命名空间：
            1、构建命名空间字符串
            2、检查是否已存在，已存在则删除
            3、创建命名空间
             */
            String namespaceName = "mydb";
            if (namespaceList.contains(namespaceName)) {
                // 根据命名空间获取表
                TableName[] tableNames = admin.listTableNamesByNamespace(namespaceName);
                for (TableName tableName : tableNames) {
                    // 禁用和删除表
                    admin.disableTable(tableName);
                    admin.deleteTable(tableName);
                }
                // 删除命名空间
                admin.deleteNamespace(namespaceName);

                namespacesExist = admin.listNamespaces();
                System.out.println(namespaceName + "命名空间已删除，当前命名空间有：" + Arrays.toString(namespacesExist));
            } else {
                System.out.println(namespaceName + "命名空间不存在，继续运行");
            }


            // 构建并创建命名空间
            NamespaceDescriptor namespaceDescriptor = NamespaceDescriptor.create(namespaceName).build();
            admin.createNamespace(namespaceDescriptor);

            // 打印当前已存在的命名空间
            namespacesExist = admin.listNamespaces();
            System.out.println("程序运行结束，当前命名空间有：" + Arrays.toString(namespacesExist));

        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            // 关闭连接
            if (admin != null) {
                try {
                    admin.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (connection != null) {
                try {
                    connection.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

    }

}

```

## 输出结果

```

代码开始运行，当前命名空间有：[default, hbase, mydb, test]
mydb命名空间已删除，当前命名空间有：[default, hbase, test]
程序运行结束，当前命名空间有：[default, hbase, mydb, test]

```

## 工具类提取

**在上述代码中，有许多可以单独提取的功能，我们将其单独抽取为工具类，为后续代码编写作准备。**

```
package util;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Admin;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;

import java.io.IOException;
import java.util.Objects;

public abstract class HBaseUtils {

    /**
     * HBase 配置对象
     */
    private static Configuration conf = null;

    /**
     * HBase 连接
     */
    private static Connection connection = null;

    /**
     * HBase admin
     */
    private static Admin admin = null;

    /**
     * 获取HBase conf
     */
    public static Configuration getConf() {
        if (null == conf) {
            conf = HBaseConfiguration.create();
        }
        return conf;
    }

    /**
     * 获取HBase connection
     */
    public static Connection getConnection() throws IOException {
        if (null == connection) {
            connection = ConnectionFactory.createConnection(getConf());
        }
        return connection;
    }

    /**
     * 获取HBase admin
     */
    public static Admin getAdmin() throws IOException {
        if (null == admin) {
            admin = getConnection().getAdmin();
        }
        return admin;
    }

    /**
     * 根据namespace获取表名列表
     */
    public static TableName[] getTableNameByNamespace(String namespace) {
        try {
            return getAdmin().listTableNamesByNamespace(namespace);
        } catch (IOException e) {
            return null;
        }
    }

    /**
     * 如果表名存在，则根据表名对象删除表
     */
    public static void deleteTableIfExist(TableName tableName) throws IOException {
        if (admin.tableExists(tableName)) {
            getAdmin().disableTable(tableName);
            getAdmin().deleteTable(tableName);
        }
    }

    /**
     * 如果命名空间存在，则根据命名空间名称删除命名空间
     */
    public static void deleteNamespaceIfExist(String namespace) throws IOException {
        TableName[] tableNameByNamespace = getTableNameByNamespace(namespace);
        if (null != tableNameByNamespace && Objects.requireNonNull(tableNameByNamespace).length != 0) {
            for (TableName tableName : tableNameByNamespace) {
                deleteTableIfExist(tableName);
            }
        }
    }

    /**
     * 关闭连接
     * @param admin
     * @param connection
     */
    public static void close(Admin admin, Connection connection) {
        if (null != admin) {
            try {
                admin.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            admin = null;
        }
        if (null != connection) {
            try {
                connection.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            connection = null;
        }
    }

}
```

# 表的创建、删除与查看

## 代码

```

import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.IOException;
import java.util.Arrays;

public class CreateTable {

    public static void main(String[] args) {

        try {
            // 获取Admin
            Admin admin = HBaseUtils.getAdmin();

            // 构建表，创建在mydb命名空间下
            TableName tableName = TableName.valueOf(Bytes.toBytes("mydb:stu"));

            // 如果表存在，则删除
            HBaseUtils.deleteTableIfExist(tableName);

            // 构建列簇
            ColumnFamilyDescriptor columnFamilyDescriptor = ColumnFamilyDescriptorBuilder
                    .newBuilder(Bytes.toBytes("info"))
                    .build();

            // 构建表
            TableDescriptor tableDescriptor = TableDescriptorBuilder.newBuilder(tableName)
                    .setColumnFamily(columnFamilyDescriptor)
                    .build();

            admin.createTable(tableDescriptor);

            // 列出所有表
            for (String namespace : admin.listNamespaces()) {
                System.out.println(Arrays.toString(HBaseUtils.getTableNameByNamespace(namespace)));
            }

            HBaseUtils.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

}

```

## 输出结果

```
[]
[hbase:meta, hbase:namespace]
[mydb:stu]
[]
```

# 数据的添加、修稿、删除与查看

## 代码

```

import org.apache.hadoop.hbase.*;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.util.Bytes;
import util.HBaseUtils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Scanner;

public class Crud {

    public static void main(String[] args) {

        Connection connection = null;
        Admin admin = null;
        try {
            // 获取连接对象和Admin
            connection = HBaseUtils.getConnection();
            admin = HBaseUtils.getAdmin();

            // 构建表
            TableName tableName = TableName.valueOf(Bytes.toBytes("mydb:stu"));
            Table table = connection.getTable(tableName);

            // 若表不存在，退出
            HBaseUtils.deleteTableIfExist(tableName);
            TableDescriptor tableDescriptor = TableDescriptorBuilder
                    .newBuilder(tableName)
                    .setColumnFamily(ColumnFamilyDescriptorBuilder.of(Bytes.toBytes("info")))
                    .build();
            admin.createTable(tableDescriptor);

            // 构建列簇和列
            byte[] family = Bytes.toBytes("info");
            byte[] col1 = Bytes.toBytes("name");
            byte[] col2 = Bytes.toBytes("age");
            byte[] col3 = Bytes.toBytes("sex");

            // 构建put对象并添加到表中
            // 构建：行键1001，列name："zhangsan"，列age：18，列sex："m"
            Put put1 = new Put(Bytes.toBytes(1001));
            put1.addColumn(family, col1, Bytes.toBytes("zhangsan"));
            put1.addColumn(family, col2, Bytes.toBytes(18));
            put1.addColumn(family, col3, Bytes.toBytes("m"));
            table.put(put1);

            // 构建：行键1002，列name："lisi"，列age：22，列sex："m"
            Put put2 = new Put(Bytes.toBytes(1002));
            put2.addColumn(family, col1, Bytes.toBytes("lisi"));
            put2.addColumn(family, col2, Bytes.toBytes(22));
            put2.addColumn(family, col3, Bytes.toBytes("m"));
            table.put(put2);

            // 构建：行键1003，列name："hanmeimei"，列age：不设置，列sex："f"
            Put put3 = new Put(Bytes.toBytes(1003));
            put3.addColumn(family, col1, Bytes.toBytes("hanmeimei"));
            put3.addColumn(family, col3, Bytes.toBytes("f"));
            table.put(put3);

            // 全表扫描
            System.out.println("全表扫描=============");
            Scan scan = new Scan();
            ResultScanner rows = table.getScanner(scan);
            // 遍历行
            for (Result row : rows) {
                StringBuilder content = null;
                // 遍历单元
                for (Cell cell : row.rawCells()) {
                    // 行键
                    int rowKeyRead = Bytes.toInt(CellUtil.cloneRow(cell));
                    // 列簇
                    String familyRead = Bytes.toString(CellUtil.cloneFamily(cell));
                    // 列
                    String colRead = Bytes.toString(CellUtil.cloneQualifier(cell));
                    // 值
                    String valRead = Bytes.toString(CellUtil.cloneValue(cell));
                    if (colRead.equals("age")) {
                        // 因为age在存储时是int型
                        valRead = String.valueOf(Bytes.toInt(CellUtil.cloneValue(cell)));
                    }
                    if (null == content) {
                        content = new StringBuilder(rowKeyRead + "\t");
                    }
                    content.append(familyRead).append(":").append(colRead).append(":").append(valRead).append("\t");
                }
                System.out.println(content);
            }

            // 更新1003的年龄
            put3.addColumn(family, col2, Bytes.toBytes(24));
            table.put(put3);
            System.out.println("\n更新1003的年龄后，使用另一种方法进行全表扫描==========");
            scan = new Scan();
            rows = table.getScanner(scan);
            // 遍历行
            for (Result row : rows) {
                StringBuilder content = new StringBuilder();
                // 获取行键，因为行键是int型，所以使用toInt
                int rowKey = Bytes.toInt(row.getRow());
                // 获取name列的值
                String name = Bytes.toString(row.getValue(family, col1));
                // 获取age列的值
                int age = Bytes.toInt(row.getValue(family, col2));
                // 获取性别列的值
                String sex = Bytes.toString(row.getValue(family, col3));

                // 拼接结果
                content.append(rowKey).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col1)).append(":").append(name).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col2)).append(":").append(age).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col3)).append(":").append(sex);

                System.out.println(content);
            }

            //更新1002年龄
            put2.addColumn(family, col2, Bytes.toBytes(26));
            table.put(put2);
            // 获取更新后的1002的信息
            System.out.println("\n获取1002的信息================");
            Get get = new Get(Bytes.toBytes(1002));
            get.addColumn(family, col1);
            get.addColumn(family, col2);
            get.addColumn(family, col3);
            Result row = table.get(get);
            // 遍历单元
            StringBuilder content = null;
            for (Cell cell : row.rawCells()) {
                // 行键
                int rowKeyRead = Bytes.toInt(CellUtil.cloneRow(cell));
                // 列簇
                String familyRead = Bytes.toString(CellUtil.cloneFamily(cell));
                // 列
                String colRead = Bytes.toString(CellUtil.cloneQualifier(cell));
                // 值
                String valRead = Bytes.toString(CellUtil.cloneValue(cell));
                if (colRead.equals("age")) {
                    // 因为age在存储时是int型
                    valRead = String.valueOf(Bytes.toInt(CellUtil.cloneValue(cell)));
                }
                if (null == content) {
                    content = new StringBuilder(rowKeyRead + "\t");
                }
                content.append(familyRead).append(":").append(colRead).append(":").append(valRead).append("\t");
            }
            System.out.println(content);

            // 使用另一种方法获取1002
            System.out.println("\n使用另一种方法获取1002==============");
            content = new StringBuilder();
            // 获取行键，因为行键是int型，所以使用toInt
            int rowKey = Bytes.toInt(row.getRow());
            // 获取name列的值
            String name = Bytes.toString(row.getValue(family, col1));
            // 获取age列的值
            int age = Bytes.toInt(row.getValue(family, col2));
            // 获取性别列的值
            String sex = Bytes.toString(row.getValue(family, col3));

            // 拼接结果
            content.append(rowKey).append("\t")
                    .append(Bytes.toString(family)).append(":").append(Bytes.toString(col1)).append(":").append(name).append("\t")
                    .append(Bytes.toString(family)).append(":").append(Bytes.toString(col2)).append(":").append(age).append("\t")
                    .append(Bytes.toString(family)).append(":").append(Bytes.toString(col3)).append(":").append(sex);

            System.out.println(content);


            // 根据行键范围查询：1001-1002
            System.out.println("\n根据行键范围查询：1001-1002=============");
            scan = new Scan();
            // 指定范围
            scan.withStartRow(Bytes.toBytes(1001));
            scan.withStopRow(Bytes.toBytes(1002), true);  // 第二个参数表示是否包含，默认为false
            ResultScanner rowsRange = table.getScanner(scan);
            // 遍历行
            for (Result rowRange : rowsRange) {
                content = new StringBuilder();
                // 获取行键，因为行键是int型，所以使用toInt
                rowKey = Bytes.toInt(rowRange.getRow());
                // 获取name列的值
                name = Bytes.toString(rowRange.getValue(family, col1));
                // 获取age列的值
                age = Bytes.toInt(rowRange.getValue(family, col2));
                // 获取性别列的值
                sex = Bytes.toString(rowRange.getValue(family, col3));

                // 拼接结果
                content.append(rowKey).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col1)).append(":").append(name).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col2)).append(":").append(age).append("\t")
                        .append(Bytes.toString(family)).append(":").append(Bytes.toString(col3)).append(":").append(sex);

                System.out.println(content);
            }
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            HBaseUtils.close();
        }

    }
    
}

```

## 输出结果

```

全表扫描=============
1001info:age:18info:name:zhangsaninfo:sex:m
1002info:age:22info:name:lisiinfo:sex:m
1003info:name:hanmeimeiinfo:sex:f

更新1003的年龄后，使用另一种方法进行全表扫描==========
1001info:name:zhangsaninfo:age:18info:sex:m
1002info:name:lisiinfo:age:22info:sex:m
1003info:name:hanmeimeiinfo:age:24info:sex:f

获取1002的信息================
1002info:age:26info:name:lisiinfo:sex:m

使用另一种方法获取1002==============
1002info:name:lisiinfo:age:26info:sex:m

根据行键范围查询：1001-1002=============
1001info:name:zhangsaninfo:age:18info:sex:m
1002info:name:lisiinfo:age:26info:sex:m

```





