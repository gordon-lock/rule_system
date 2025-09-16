数据库表关系图

根据提供的文档1和文档2，我可以绘制出这些表之间的关系图。以下是主要表之间的关系：

核心表关系


table_registry (id)
├─┬ codegen_tasks (table_id)
│ ├── codegen_task_details (task_id)
│ ├── task_execution_logs (task_id)
│ └── codegen_artifacts (task_id)
│
├─┬ custom_queries (table_id)
│ ├── query_parameters (query_id)
│ ├── result_mappings (query_id)
│ └── graphql_endpoints (query_id)
│
├── schema_change_comparison (table_id)
│   ├── field_change_details (comparison_id)
│   └── class_level_changes (comparison_id)
│
└── api_versions (table_id)
├── api_endpoints (version_id)
└── api_version_changes (version_id)


详细关系说明

1. table_registry 是核心表，记录了所有注册的表信息
   • 与 codegen_tasks 是一对多关系（一个表可以有多个代码生成任务）

   • 与 custom_queries 是一对多关系（一个表可以有多个自定义查询）

   • 与 schema_change_comparison 是一对多关系（一个表可以有多次模式变更比较）

   • 与 api_versions 是一对多关系（一个表可以有多个API版本）

2. codegen_tasks 表
   • 与 codegen_task_details 是一对多关系（一个任务可以有多个生成细节）

   • 与 task_execution_logs 是一对多关系（一个任务可以有多个执行日志）

   • 与 codegen_artifacts 是一对多关系（一个任务可以生成多个工件）

3. custom_queries 表
   • 与 query_parameters 是一对多关系（一个查询可以有多个参数）

   • 与 result_mappings 是一对多关系（一个查询可以有多个结果映射）

   • 与 graphql_endpoints 是一对多关系（一个查询可以对应一个GraphQL端点）

4. schema_change_comparison 表
   • 与 field_change_details 是一对多关系（一个比较可以有多个字段变更细节）

   • 与 class_level_changes 是一对多关系（一个比较可以有多个类级别变更）

5. api_versions 表
   • 与 api_endpoints 是一对多关系（一个API版本可以有多个端点）

   • 与 api_version_changes 是一对多关系（一个API版本可以有多个变更记录）

外键关系总结

主表 主键 从表 外键 关系类型

table_registry id codegen_tasks table_id 一对多

table_registry id custom_queries table_id 一对多

table_registry id schema_change_comparison table_id 一对多

table_registry id api_versions table_id 一对多

codegen_tasks task_id codegen_task_details task_id 一对多

codegen_tasks task_id task_execution_logs task_id 一对多

codegen_tasks task_id codegen_artifacts task_id 一对多

custom_queries query_id query_parameters query_id 一对多

custom_queries query_id result_mappings query_id 一对多

custom_queries query_id graphql_endpoints query_id 一对多

schema_change_comparison comparison_id field_change_details comparison_id 一对多

schema_change_comparison comparison_id class_level_changes comparison_id 一对多

api_versions version_id api_endpoints version_id 一对多

api_versions version_id api_version_changes version_id 一对多

这个关系图展示了整个系统的数据模型，其中 table_registry 是核心表，其他表都直接或间接与之关联。