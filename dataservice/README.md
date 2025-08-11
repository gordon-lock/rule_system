# Iceberg GraphQL API

基于Quarkus和GraphQL的Iceberg数据访问系统，通过Trino连接器提供统一的数据查询接口。

## 功能特性

- 🚀 **GraphQL API**: 提供灵活的GraphQL查询接口
- 🗄️ **Trino集成**: 通过Trino连接器访问Iceberg数据
- 📊 **元数据管理**: 自动获取表结构和分区信息
- 🔍 **查询执行**: 支持SQL查询和表查询
- 📈 **性能监控**: 内置查询执行时间统计
- 🏥 **健康检查**: 提供系统状态监控

## 快速开始

### 环境要求

- Java 17+
- Maven 3.6+
- Trino集群 (可选，用于生产环境)
- Iceberg数据湖 (可选，用于生产环境)

### 测试方式

#### 方式1: 单元测试 (推荐)
```bash
# 运行所有测试
mvn clean test

# 运行特定测试
mvn test -Dtest=MetadataServiceTest
```

#### 方式2: 使用测试脚本
```bash
# 运行交互式测试脚本
./test-local.sh
```

#### 方式3: Docker环境 (需要Docker)
```bash
# 启动完整的Docker环境
docker-compose -f docker-compose-dev.yml up -d

# 访问服务
# GraphiQL: http://localhost:8081/api/graphiql
# 健康检查: http://localhost:8081/api/health
```

### 配置

1. 复制配置文件模板：
```bash
cp src/main/resources/application.properties src/main/resources/application-local.properties
```

2. 修改Trino连接配置：
```properties
quarkus.datasource.jdbc.url=jdbc:trino://your-trino-host:8080/iceberg/default
quarkus.datasource.username=your-username
quarkus.datasource.password=your-password

trino.catalog=iceberg
trino.schema=default
trino.server-url=http://your-trino-host:8080
```

### 运行

```bash
# 开发模式 (热重载)
mvn quarkus:dev

# 编译项目
mvn clean compile

# 生产模式运行
mvn quarkus:build
java -jar target/quarkus-app/quarkus-run.jar
```

### 访问接口

- **GraphQL端点**: http://localhost:8080/api/graphql
- **GraphQL界面**: http://localhost:8080/api/graphql-ui
- **健康检查**: http://localhost:8080/api/health
- **系统信息**: http://localhost:8080/api/health/info

## GraphQL查询示例

### 获取所有表
```graphql
query {
  tables {
    catalog
    schema
    tableName
    tableType
    columns {
      name
      type
      nullable
    }
    partitions
  }
}
```

### 获取特定表信息
```graphql
query {
  table(name: "users") {
    tableName
    columns {
      name
      type
      comment
    }
    partitions
  }
}
```

### 执行SQL查询
```graphql
query {
  query(sql: "SELECT * FROM users LIMIT 10") {
    data
    executionTime
    rowCount
    sql
  }
}
```

### 查询表数据
```graphql
query {
  queryTable(
    tableName: "users"
    whereClause: "age > 18"
    orderBy: "name ASC"
    limit: 100
  ) {
    data
    executionTime
    rowCount
  }
}
```

## 项目结构

```
src/main/java/com/dataservice/
├── IcebergGraphQLApplication.java    # 主应用类
├── config/                           # 配置类
│   ├── GraphQLConfig.java           # GraphQL配置
│   └── TrinoConfig.java             # Trino数据源配置
├── controller/                       # 控制器
│   ├── GraphQLController.java       # GraphQL查询控制器
│   └── HealthController.java        # 健康检查控制器
├── model/                           # 数据模型
│   ├── TableMetadata.java           # 表元数据模型
│   └── ColumnMetadata.java          # 列元数据模型
└── service/                         # 服务层
    ├── MetadataService.java         # 元数据服务
    └── QueryService.java            # 查询服务
```

## 配置说明

### 应用配置
- `server.port`: 服务端口 (默认: 8080)
- `server.servlet.context-path`: 上下文路径 (默认: /api)

### Trino配置
- `spring.datasource.trino.jdbc-url`: Trino JDBC连接URL
- `spring.datasource.trino.username`: 用户名
- `spring.datasource.trino.password`: 密码
- `trino.catalog`: 默认catalog
- `trino.schema`: 默认schema
- `trino.max-rows`: 最大返回行数 (默认: 10000)
- `trino.query-timeout`: 查询超时时间 (默认: 300秒)

### 连接池配置
- `spring.datasource.trino.hikari.maximum-pool-size`: 最大连接数 (默认: 20)
- `spring.datasource.trino.hikari.minimum-idle`: 最小空闲连接数 (默认: 5)

## 开发指南

### 添加新的查询类型

1. 在 `src/main/resources/graphql/schema.graphqls` 中定义新的类型
2. 在 `GraphQLController` 中添加对应的查询方法
3. 在相应的Service类中实现业务逻辑

### 扩展元数据功能

1. 在 `MetadataService` 中添加新的元数据查询方法
2. 在 `TableMetadata` 或 `ColumnMetadata` 中添加新的字段
3. 更新GraphQL Schema定义

### 性能优化

- 调整连接池配置
- 优化查询超时设置
- 添加查询缓存机制
- 实现分页查询

## 监控和日志

### 日志配置
- 应用日志级别: DEBUG
- GraphQL日志级别: DEBUG
- Trino日志级别: INFO

### 监控指标
- 查询执行时间
- 连接池状态
- 错误率统计
- 系统资源使用情况

## 故障排除

### 常见问题

1. **Trino连接失败**
   - 检查Trino服务状态
   - 验证连接配置
   - 确认网络连通性

2. **查询超时**
   - 调整查询超时设置
   - 优化SQL查询
   - 检查数据量大小

3. **内存不足**
   - 调整JVM内存参数
   - 减少查询结果集大小
   - 优化连接池配置

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！ 