```text
Java序列化与Hadoop序列化
大数据>Hadoop
2022-07-08
https://picgo.kwcoder.club/202206/202206261620161.png
```





# 序列化

## 什么是序列化

在程序运行的过程中，对象是存储在内存当中的，一旦断电或程序停止，对象就会消失，而且内存中的对象无法通过网络进行传输。

序列化可以将对象转换成字节序列，这些字节序列允许持久化和网络传输。

反序列化是指将持久化的对象或网络传输的对象转换成为内存中的对象。

# Java序列化

在Java中，通过实现`Serializable`接口实现序列化。
该接口是一个标记接口，没有提供任何方法，只是表明该类可以序列化。

## Java中的序列化与反序列化

实体类：

```java
class Person implements Serializable {
	
	private String name;
	private Integer age;
	
	public Person(String name, Integer age) {
		this.name = name;
		this.age = age;
	}
	
	@Override
	public String toString() {
		return "[name=" + name + ", age=" + age + "]";
	}
	
}

```

测试代码：

```java
public static void main(String[] args) throws FileNotFoundException, IOException, ClassNotFoundException {

    Person person = new Person("xiaoming", 14);
    
    System.out.println("=====开始序列化=====");
    ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("person.obj"));
    oos.writeObject(person);
    oos.close();
    System.out.println("=====序列化结束=====");
    
    System.out.println("=====使用字节输入流读取序列化文件内容=====");
    FileInputStream fis = new FileInputStream("person.obj");
    byte[] bytes = new byte[1024];
    int len;
    while ((len = fis.read(bytes)) != -1) {
        System.out.println(new String(bytes, 0, len));
    }
    fis.close();
    
    System.out.println("=====使用对象输入流读取序列化文件内容=====");
    ObjectInputStream ois = new ObjectInputStream(new FileInputStream("person.obj"));
    Object obj = ois.readObject();
    System.out.println(obj instanceof Person);
    System.out.println(obj);
    ois.close();
    ois.close();

}

```

输出结果：

```text
=====开始序列化=====
=====序列化结束=====
=====使用字节输入流读取序列化文件内容=====
��srtest.Personm�|���~bLagetLjava/lang/Integer;LnametLjava/lang/String;xpsrjava.lang.Integer⠤���8Ivaluexrjava.lang.Number������xptxiaoming
=====使用对象输入流读取序列化文件内容=====
true
[name=xiaoming, age=14]
```

## `serialVersionUID`变量有什么作用

`serialVersionUID`代表序列化的版本。
在开发中，有时实体类的属性会发生变化，此时如果直接从旧的字节序列中反序列化对象，会抛出异常。

### 不写`serialVersionUID`的情况

在上一步骤中的Person中新增sex属性，模拟类升级。

```java
class Person implements Serializable {
	
	// public static final long serialVersionUID = 7910709680672767586L;
	
	private String name;
	private Integer age;
	private String sex;
	
	public Person(String name, Integer age, String sex) {
		this.name = name;
		this.age = age;
		this.sex = sex;
	}
	
	@Override
	public String toString() {
		return "[name=" + name + ", age=" + age + ", sex=" + sex + "]";
	}
	
}

```


对升级前的序列化序列进行反序列化：

```java
public static void main(String[] args) throws FileNotFoundException, IOException, ClassNotFoundException {

    ObjectInputStream ois = new ObjectInputStream(new FileInputStream("person.obj"));
    Object obj = ois.readObject();
    System.out.println(obj instanceof Person);
    System.out.println(obj);
    ois.close();
    
}

```


输出结果：

```text
Exception in thread "main" java.io.InvalidClassException: test.Person; local class incompatible: stream classdesc serialVersionUID = 7910709680672767586, local class serialVersionUID = 3318208494005057728
	at java.io.ObjectStreamClass.initNonProxy(ObjectStreamClass.java:699)
	at java.io.ObjectInputStream.readNonProxyDesc(ObjectInputStream.java:2028)
	at java.io.ObjectInputStream.readClassDesc(ObjectInputStream.java:1875)
	at java.io.ObjectInputStream.readOrdinaryObject(ObjectInputStream.java:2209)
	at java.io.ObjectInputStream.readObject0(ObjectInputStream.java:1692)
	at java.io.ObjectInputStream.readObject(ObjectInputStream.java:508)
	at java.io.ObjectInputStream.readObject(ObjectInputStream.java:466)
	at test.Test04.main(Test04.java:16)
```


### 写`serialVersionUID`的情况

在类升级前后保证`serialVersionUID`相同，重复上一步骤，输出的结构为：

```text
true
[name=xiaoming, age=14, sex=null]
```

> Java自带的序列化比较重，因此在大多数框架中都有自己的序列化机制，如在JavaWeb中通常使用JSON作为序列化，在Hadoop中，也有自己的一套序列化接口。


# Hadoop序列化

## Hadoop序列化的特点

- 紧凑：高效实用存储空间
- 快速：读写数据的额外开销小
- 可扩展：跟随通信协议的升级而可升级
- 互操作：支持多语言的交互

## Hadoop与Java类型对应关系



|  Java   |     Hadoop      |
| :-----: | :-------------: |
| Boolean | BooleanWritable |
|  Byte   |  ByteWritable   |
| Integer |   IntWritable   |
|  Float  |  FloatWritable  |
|  Long   |  LongWritable   |
| Double  | DoubleWritable  |
| String  |      Text       |
|   Map   |   MapWritable   |
|  数组   |  ArrayWritable  |


## 使用Hadoop序列化编写实体类

在Java中，通过实现`Serializable`接口实现序列化。
在Hadoop中通过实现`Writable`或`WritableComparable`接口进行实现。其本质是相同的，区别在于实现`WritableComparable`的类支持排序。

步骤：

1. 实现`Writable`或`WritableComparable`接口
2. 空参构造（反序列化时需要反射调用空参构造）
3. 重写序列化方法 - `public void write(Dataoutput out)`
4. 重写反序列化方法 - `public void readFields(DataInput in)`

```java

import org.apache.hadoop.io.WritableComparable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class Student implements WritableComparable<Student> {

    private Integer id;

    private String name;

    private Float score;
    
    // 省略空构造、满构造、setter/getter、hashcode、equals

    @Override
    public void write(DataOutput dataOutput) throws IOException {
        // hadoop序列化
        dataOutput.writeInt(this.id);
        dataOutput.writeUTF(this.name);
        dataOutput.writeFloat(this.score);
    }

    @Override
    public void readFields(DataInput dataInput) throws IOException {
        // hadoop反序列化
        this.id = dataInput.readInt();
        this.name = dataInput.readUTF();
        this.score = dataInput.readFloat();
    }

    @Override
    public int compareTo(Student o) {
        if (null == o) {
            return 1;
        }
        return -Float.compare(this.score, o.score);
    }

}

```

> 注意：Hadoop的序列化与反序列化遵守FIFO原则，即序列化的顺序必须和反序列化的顺序相同。



