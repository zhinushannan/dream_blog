```text
Redis Java客户端——Jedis
2022-10-18
数据库>Redis
```

# Redis Java客户端

- Jedis：以Redis命令作为方法名称，学习成本低，简单实用。但是Jedis实例是线程不安全的，多线程环境下需要基于连接池来使用
- lettuce：Lettuce是基于Netty实现的，支持同步、异步和响应式编程方式，并且是线程安全的。支持Redis的哨兵模式、集群模式和管道模式。
- Redisson：Redisson是一个基于Redis实现的分布式、可伸缩的 Java数据结构集合。包含了诸如Map、Queue、 Lock、 Semaphore、 AtomicLong等强大功能。

# Jedis

官网：[https://github.com/redis/jedis](https://github.com/redis/jedis)

# 普通连接

```java
Jedis jedis = new Jedis("ip", port);
jedis.auth("登录密码");
jedis.select(数据库编号);
jedis.[类似于命令的方法函数];
jedis.close();
```

# 连接池

```java
public class JedisConnectionFactory {
  
  private static final JedisPool jedisPool;
  
  static {
    // 配置连接池
    JedisPoolConfig poolConfig = new JedisPoolConfig();
    // 设置连接池最大数量
    poolConfig.setMaxTotal(8);
    // 设置连接池最大空闲数量
    poolConfig.setMaxIdle(0);
    // 设置连接池最小空闲数量
    poolConfig.setMinIdle(0);
    // 设置最大等待毫秒数
    poolConfig.setMaxWaitMillis(1000);
    jedisPool = new JedisPool(poolConfig, "ip", port, timeout, password);
  }
  
  public static Jedis getJedis() {
    return jedisPool.getResouce();
  }
  
}
```

