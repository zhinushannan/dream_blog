```text
Redis Java客户端——Spring Data Redis
2022-10-18
数据库>Redis
```

# SpringDataRedis简介

SpringData是Spring中数据操作的模块，包含对各种数据库的集成，其中对Redis的集成模块就叫做SpringDataRedis，官网地址：[https://spring.io/projects/spring-data-redis](https://spring.io/projects/spring-data-redis)

- 提供了对不同Redis客户端的整合（Lettuce和Jedis）
- 提供了RedisTemplate统一API来操作Redis
- 支持Redis的发布订阅模型
- 支持Redis哨兵和Redis集群
- 支持基于Lettuce的响应式编程
- 支持基于JDK、JSON、字符串、Spring对象的数据序列化及反序列化
- 支持基于Redis的JDKCollection实现

SpringDataRedis中提供了RedisTemplate 工具类，其中封装了各种对Redis的操作。并且将不同数据类型的操作AP/封装到了不同的类型中：

|             API             |   返回值类型    |         说明          |
| :-------------------------: | :-------------: | :-------------------: |
| redisTemplate.opsForValue() | ValueOperations |  操作String类型数据   |
| redisTemplate.opsForHash()  | HashOperations  |   操作Hash类型数据    |
| redisTemplate.opsForList()  | ListOperations  |   操作List类型数据    |
|  redisTemplate.opsForSet()  |  SetOperations  |    操作Set类型数据    |
| redisTemplate.opsForZSet()  | ZSetOperations  | 操作SortedSet类型数据 |
|        redisTemplate        |                 |      通用的命令       |

# SpringDataRedis快速入门

导入依赖：

```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-pool2</artifactId>
        </dependency>
```

配置文件：

```properties
spring.redis.host=172.72.0.53
spring.redis.port=6379
# 最大连接
spring.redis.lettuce.pool.max-active=8
# 最大空闲连接
spring.redis.lettuce.pool.max-idle=8
# 最小空闲连接
spring.redis.lettuce.pool.min-idle=0
# 连接等待时间
spring.redis.jedis.pool.max-wait=100
```

Java代码编写：

```java
    @Autowired
    private RedisTemplate redisTemplate;

    @Test
    void setString() {
        redisTemplate.opsForValue().set("name", "zhangsan");
        Object name = redisTemplate.opsForValue().get("name");
        System.out.println(name);
    }
```

# SpringDataRedis序列化

在执行添加操作后，在Redis中真正存储的数据如下：

![image-20221018164857157](https://picgo.kwcoder.club/202208/202210181648182.png)

这是因为在使用RedisTemplate时，key和value默认都是Object类型，使用了Jdk的序列化工具，即ObjectOutputStream，导致出现这种情况，这种情况具有如下两种问题：

- 可读性差
- 空间占用大

因此为了更好的使用SpringDataRedis，我们可以自定义序列化方式：

导入依赖（如果没有引入Spring MVC）：

```xml
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>
```

编写配置类：

```java
package com.example.redisdemo.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializer;

/**
 * @author zhinushannan
 */
@Configuration
public class RedisConfig {

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory redisConnectionFactory) {
        // 创建RedisTemplate对象
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        // 设置连接工厂
        template.setConnectionFactory(redisConnectionFactory);

        // 设置key的序列化
        template.setKeySerializer(RedisSerializer.string());
        template.setHashKeySerializer(RedisSerializer.string());

        // 创建JSON序列化
        GenericJackson2JsonRedisSerializer jsonRedisSerializer = new GenericJackson2JsonRedisSerializer();
        // 设置Value的序列化
        template.setValueSerializer(jsonRedisSerializer);
        template.setHashValueSerializer(jsonRedisSerializer);

        return template;
    }

}
```

此时再次执行写入操作，观察RDM客户端：

![image-20221018170031035](https://picgo.kwcoder.club/202208/202210181700681.png)

而此时若直接存储对象：

```java
package com.example.redisdemo.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * @author zhinushannan
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class User {

    private String name;
    private Integer age;

}
```

```java
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    @Test
    void setString() {
        redisTemplate.opsForValue().set("user", new User("zhangsan", 18));
        Object user = redisTemplate.opsForValue().get("user");
        System.out.println(user);
    }
```

<img src="https://picgo.kwcoder.club/202208/202210212304938.png" alt="image-20221021230418699" style="zoom: 50%;" />

此时会发现在存储的字符串中有`@class`字段，该字段占据了大量的空间，甚至超过了对象属性本身占用的空间，这是由于自动序列化和自动反序列化造成的，这是我们不希望看到的，因此不推荐对对象进行自动序列化。

# StringRedisTemplate的使用

## StringRedisTemplate opsForValue

StringRedisTemplate是Spring提供的key和value都使用String序列化方式的类。对于对象的处理我们可以使用该类手动进行序列化和反序列化。

```java
    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Test
    void setString() {
        stringRedisTemplate.opsForValue().set("user", JSONUtil.toJsonStr(new User("zhangsan", 18)));
        String userStr = stringRedisTemplate.opsForValue().get("user");
        User user = JSONUtil.toBean(userStr, User.class);
        System.out.println(user);
    }
```

<img src="https://picgo.kwcoder.club/202208/202210212316284.png" alt="image-20221021231646629" style="zoom: 67%;" />

## StringRedisTemplate opsForHash

```java
    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Test
    void setHash() {
        stringRedisTemplate.opsForHash().put("user", "name", "zhangsan");
        stringRedisTemplate.opsForHash().put("user", "age", 18);

        Map<Object, Object> user = stringRedisTemplate.opsForHash().entries("user");
        System.out.println(user);
    }
```

<img src="https://picgo.kwcoder.club/202208/202210212322551.png" alt="image-20221021232200434" style="zoom: 50%;" />

