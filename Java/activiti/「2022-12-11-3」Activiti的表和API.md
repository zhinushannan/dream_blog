```text
Activiti的表和API
2022-12-11
Java > Activiti
```

# 表

## 表的规则

表的开头都是`act`，即`Activiti`。

- `act_evt_`表示事件相关，`act_procdef_`表示变更信息相关
- `act_ge_`表示通用相关
- `act_hi_`表示历史相关
- `act_re_`表示流程定义相关
- `act_ru_`表示流程运行相关

## 25张表

- `act_evt_`
  - `act_evt_log`：事件日志表
- `act_ge_`
  - `act_ge_bytearray`：存放资源文件的二进制，如图片、xml等
  - `act_ge_property`：属性数据表，用来存储系统的一些基本属性
- `act_hi_`
  - `act_hi_actinst`：历史节点表
  - `act_hi_aattachment`：历史附件表
  - `act_hi_comment`：历史意见表
  - `act_hi_detail`：历史详情表，提供历史变量查询
  - `act_hi_identitylink`：历史流程人员表，每个节点对应的处理人员信息
  - `act_hi_procinst`：历史流程实例表
  - `act_hi_taskinst`：历史任务实例表
  - `act_hi_vatinst`：历史变量表
- `act_procedf_`
  - `act_procdef_info`：流程定义动态变量
- `act_re_`
  - `act_re_deployment`：部署信息表
  - `act_re_model`：流程设计模型基本信息表
  - `act_re_procdef`：流程定义数据表
- `act_ru_`
  - `act_ru_deadletter_job`：作业死亡信息表（作业超过指定次数，就会写到这张表）
  - `act_ru_event_subscr`：时间监听信息表
  - `act_ru_identitylink`：运行时流程办理人员表
  - `act_ru_integration`：运行时积分表
  - `act_ru_job`：定时异步任务数据
  - `act_ru_suspended_job`：运行时作业暂停表
  - `act_ru_task`：运行时任务节点表
  - `act_ru_timer_job`：运行时定时器作业表
  - `act_ru_variable`：正在运行时的流程变量数据表

> 注意，在Activiti的M4以上版本，部署流程定义时，报错如下：
>
> `MySQLSyntaxErrorException: Unknown column 'VERSION_' in field list`
>
> 解决方案是，添加
>
> ```sql
> ALTER TABLE ACT_RE_DEPLOYMENT ADD COLUMN VERSION_ VARCHAR(255);
> ALTER TABLE ACT_RE_DEPLOYMENT ADD COLUMN PROJECT_RELESE_VERSION_ VARCHAR(255);
> ```
>
> 在Activiti7.1.0.M6中已经得到解决。

# API服务接口

## Process Engine API 和 服务

引擎API是与Activiti交互的最常见的方式。

可以从ProcessEngine中获取包含工作流/BPM方法的各种服务。

ProcessEngine和服务对象是线程安全的。因此，可以为整个服务器保留对其中之一的引用。

Service是工作流引擎提供用于进行工作流部署、执行、管理的服务接口，我们使用对应的Service接口可以操作对应的数据表。

![image-20221211182055525](https://picgo.kwcoder.club/202208/202212111820859.png)

|    Service接口     |                             说明                             |
| :----------------: | :----------------------------------------------------------: |
|   RuntimeService   |  运行时Service，可以处理所有正在运行状态的流程实例和任务等   |
| RepositoryService  | 流程仓库Service，主要用户管理流程仓库，比如流程定义的控制管理（部署、删除、挂起、激活......） |
| DynamicBpmnService | RepositoryService可以用来部署流程定义（使用xml形式定义好的），一旦部署到Activiti（解析后保存到DB），那么流程定义就不会再变了，除了修改xml定义文件内容；而DynamicBpmnService就允许我们在程序运行过程中去修改流程定义，例如：修改流程定义中的分配角色、优先级、流程流传的条件...... |
|    TaskService     |     任务Service，用于管理和查询任务，例如：签收、办理等      |
|   HistoryService   | 历史Service，可以查询所有历史数据，例如：流程实例信息、参与者信息、完成时间...... |
| ManagementService  | 引擎管理Service，和具体业务无关，主要用于对Activiti流程引擎的管理和维护。 |

其中RuntimeService、RepositoryService、TaskService、HistoryService是经常使用的四个服务类，非常不建议使用DynamicBpmnService。

## 核心Service接口的获取

![image-20221211183438533](https://picgo.kwcoder.club/202208/202212111834596.png)







