# 数据模型设计 - 大数据质量管理系统

## 1. 数据库概述

### 1.1 数据库选择
- **主数据库**: MySQL 8.0+ (存储用户数据、规则配置、元数据)
- **缓存数据库**: Redis 6.0+ (存储会话、临时数据、缓存)
- **文件存储**: MinIO/S3 (存储质量报告、日志文件)

### 1.2 数据库命名规范
- 表名: 小写字母，下划线分隔，如 `workspaces`, `data_quality_rules`
- 字段名: 小写字母，下划线分隔，如 `workspace_name`, `created_at`
- 索引名: `idx_表名_字段名`，如 `idx_rules_workspace_id`

## 2. 核心数据表设计

### 2.1 用户和工作空间管理

#### 2.1.1 用户表 (users)
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    full_name VARCHAR(100) NOT NULL COMMENT '姓名',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active' COMMENT '用户状态',
    last_login_at TIMESTAMP NULL COMMENT '最后登录时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_status (status)
) COMMENT '用户表';
```

#### 2.1.2 工作空间表 (workspaces)
```sql
CREATE TABLE workspaces (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL COMMENT '工作空间名称',
    description TEXT COMMENT '工作空间描述',
    type ENUM('personal', 'team') DEFAULT 'personal' COMMENT '工作空间类型',
    owner_id BIGINT NOT NULL COMMENT '创建者ID',
    status ENUM('active', 'inactive', 'archived') DEFAULT 'active' COMMENT '工作空间状态',
    settings JSON COMMENT '工作空间配置(数据源等)',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner_id (owner_id),
    INDEX idx_name (name),
    INDEX idx_status (status)
) COMMENT '工作空间表';
```

#### 2.1.3 工作空间成员表 (workspace_members)
```sql
CREATE TABLE workspace_members (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    role ENUM('admin', 'editor', 'viewer', 'executor') DEFAULT 'viewer' COMMENT '角色',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    invited_by BIGINT COMMENT '邀请人ID',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY uk_workspace_user (workspace_id, user_id),
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role (role)
) COMMENT '工作空间成员表';
```

### 2.2 数据表元数据管理

#### 2.2.1 数据源表 (data_sources)
```sql
CREATE TABLE data_sources (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    name VARCHAR(100) NOT NULL COMMENT '数据源名称',
    type ENUM('mysql', 'postgresql', 'hive', 'clickhouse', 'kafka', 'mongodb') NOT NULL COMMENT '数据源类型',
    connection_config JSON NOT NULL COMMENT '连接配置',
    status ENUM('active', 'inactive', 'error') DEFAULT 'active' COMMENT '数据源状态',
    last_connection_test TIMESTAMP NULL COMMENT '最后连接测试时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_type (type),
    INDEX idx_status (status)
) COMMENT '数据源表';
```

#### 2.2.2 数据表表 (data_tables)
```sql
CREATE TABLE data_tables (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    data_source_id BIGINT NOT NULL COMMENT '数据源ID',
    database_name VARCHAR(100) NOT NULL COMMENT '数据库名',
    table_name VARCHAR(100) NOT NULL COMMENT '表名',
    full_table_name VARCHAR(200) NOT NULL COMMENT '完整表名(database.table)',
    description TEXT COMMENT '表描述',
    row_count BIGINT COMMENT '行数',
    size_bytes BIGINT COMMENT '大小(字节)',
    last_updated TIMESTAMP NULL COMMENT '最后更新时间',
    schema_info JSON COMMENT '表结构信息',
    status ENUM('active', 'inactive', 'archived') DEFAULT 'active' COMMENT '表状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    FOREIGN KEY (data_source_id) REFERENCES data_sources(id) ON DELETE CASCADE,
    UNIQUE KEY uk_workspace_full_table (workspace_id, full_table_name),
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_data_source_id (data_source_id),
    INDEX idx_table_name (table_name),
    INDEX idx_status (status)
) COMMENT '数据表表';
```

### 2.3 规则和模板管理

#### 2.3.1 规则模板表 (rule_templates)
```sql
CREATE TABLE rule_templates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    type ENUM('uniqueness', 'format', 'range', 'completeness', 'consistency', 'accuracy', 'timeliness', 'custom_sql') NOT NULL COMMENT '规则类型',
    category VARCHAR(50) COMMENT '模板分类',
    template_config JSON NOT NULL COMMENT '模板配置',
    parameters_schema JSON COMMENT '参数模式定义',
    usage_count INT DEFAULT 0 COMMENT '使用次数',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    status ENUM('active', 'inactive', 'deprecated') DEFAULT 'active' COMMENT '模板状态',
    created_by BIGINT NOT NULL COMMENT '创建者ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by)
) COMMENT '规则模板表';
```

#### 2.3.2 数据质量规则表 (data_quality_rules)
```sql
CREATE TABLE data_quality_rules (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    table_id BIGINT NOT NULL COMMENT '数据表ID',
    template_id BIGINT NULL COMMENT '模板ID(如果从模板创建)',
    name VARCHAR(100) NOT NULL COMMENT '规则名称',
    description TEXT COMMENT '规则描述',
    type ENUM('uniqueness', 'format', 'range', 'completeness', 'consistency', 'accuracy', 'timeliness', 'custom_sql') NOT NULL COMMENT '规则类型',
    target_column VARCHAR(100) COMMENT '目标字段',
    rule_config JSON NOT NULL COMMENT '规则配置',
    parameters JSON COMMENT '规则参数',
    error_threshold INT DEFAULT 0 COMMENT '错误阈值',
    warning_threshold INT DEFAULT 5 COMMENT '警告阈值',
    execution_frequency ENUM('hourly', 'daily', 'weekly', 'monthly') DEFAULT 'daily' COMMENT '执行频率',
    priority ENUM('high', 'medium', 'low') DEFAULT 'medium' COMMENT '优先级',
    status ENUM('draft', 'testing', 'active', 'paused', 'error') DEFAULT 'draft' COMMENT '规则状态',
    version INT DEFAULT 1 COMMENT '版本号',
    parent_rule_id BIGINT NULL COMMENT '父规则ID(用于版本控制)',
    created_by BIGINT NOT NULL COMMENT '创建者ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    FOREIGN KEY (table_id) REFERENCES data_tables(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES rule_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (parent_rule_id) REFERENCES data_quality_rules(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_table_id (table_id),
    INDEX idx_template_id (template_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_parent_rule_id (parent_rule_id)
) COMMENT '数据质量规则表';
```

### 2.4 规则执行和质量报告

#### 2.4.1 规则执行记录表 (rule_executions)
```sql
CREATE TABLE rule_executions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    rule_id BIGINT NOT NULL COMMENT '规则ID',
    execution_id VARCHAR(50) UNIQUE NOT NULL COMMENT '执行ID',
    status ENUM('running', 'success', 'failed', 'timeout', 'cancelled') NOT NULL COMMENT '执行状态',
    started_at TIMESTAMP NOT NULL COMMENT '开始时间',
    completed_at TIMESTAMP NULL COMMENT '完成时间',
    duration_seconds DECIMAL(10,3) COMMENT '执行时长(秒)',
    records_checked BIGINT COMMENT '检查记录数',
    records_failed BIGINT DEFAULT 0 COMMENT '失败记录数',
    records_warning BIGINT DEFAULT 0 COMMENT '警告记录数',
    error_message TEXT COMMENT '错误信息',
    execution_log TEXT COMMENT '执行日志',
    sample_data JSON COMMENT '样本数据',
    ge_result JSON COMMENT 'Great Expectations执行结果',
    
    FOREIGN KEY (rule_id) REFERENCES data_quality_rules(id) ON DELETE CASCADE,
    INDEX idx_rule_id (rule_id),
    INDEX idx_execution_id (execution_id),
    INDEX idx_status (status),
    INDEX idx_started_at (started_at),
    INDEX idx_completed_at (completed_at)
) COMMENT '规则执行记录表';
```

#### 2.4.2 质量报告表 (quality_reports)
```sql
CREATE TABLE quality_reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    workspace_id BIGINT NOT NULL COMMENT '工作空间ID',
    table_id BIGINT NOT NULL COMMENT '数据表ID',
    report_date DATE NOT NULL COMMENT '报告日期',
    report_hour TINYINT NULL COMMENT '报告小时(用于小时级报告)',
    overall_score DECIMAL(5,2) COMMENT '整体质量评分',
    total_rules INT DEFAULT 0 COMMENT '总规则数',
    passed_rules INT DEFAULT 0 COMMENT '通过规则数',
    failed_rules INT DEFAULT 0 COMMENT '失败规则数',
    warning_rules INT DEFAULT 0 COMMENT '警告规则数',
    report_data JSON COMMENT '详细报告数据',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
    FOREIGN KEY (table_id) REFERENCES data_tables(id) ON DELETE CASCADE,
    UNIQUE KEY uk_table_date_hour (table_id, report_date, report_hour),
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_table_id (table_id),
    INDEX idx_report_date (report_date),
    INDEX idx_overall_score (overall_score)
) COMMENT '质量报告表';
```

#### 2.4.3 规则执行结果表 (rule_execution_results)
```sql
CREATE TABLE rule_execution_results (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    execution_id BIGINT NOT NULL COMMENT '执行记录ID',
    rule_id BIGINT NOT NULL COMMENT '规则ID',
    result_status ENUM('passed', 'failed', 'warning') NOT NULL COMMENT '结果状态',
    records_checked BIGINT COMMENT '检查记录数',
    records_failed BIGINT DEFAULT 0 COMMENT '失败记录数',
    records_warning BIGINT DEFAULT 0 COMMENT '警告记录数',
    failure_rate DECIMAL(5,4) COMMENT '失败率',
    warning_rate DECIMAL(5,4) COMMENT '警告率',
    error_details JSON COMMENT '错误详情',
    sample_failures JSON COMMENT '失败样本',
    ge_validation_result JSON COMMENT 'GE验证结果',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (execution_id) REFERENCES rule_executions(id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES data_quality_rules(id) ON DELETE CASCADE,
    INDEX idx_execution_id (execution_id),
    INDEX idx_rule_id (rule_id),
    INDEX idx_result_status (result_status),
    INDEX idx_created_at (created_at)
) COMMENT '规则执行结果表';
```

### 2.5 系统管理

#### 2.5.1 系统配置表 (system_configs)
```sql
CREATE TABLE system_configs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(100) UNIQUE NOT NULL COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '配置类型',
    description TEXT COMMENT '配置描述',
    is_system BOOLEAN DEFAULT FALSE COMMENT '是否系统配置',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_config_key (config_key),
    INDEX idx_is_system (is_system)
) COMMENT '系统配置表';
```

#### 2.5.2 操作日志表 (operation_logs)
```sql
CREATE TABLE operation_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NULL COMMENT '用户ID',
    workspace_id BIGINT NULL COMMENT '工作空间ID',
    operation_type VARCHAR(50) NOT NULL COMMENT '操作类型',
    resource_type VARCHAR(50) NOT NULL COMMENT '资源类型',
    resource_id BIGINT NULL COMMENT '资源ID',
    operation_details JSON COMMENT '操作详情',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_workspace_id (workspace_id),
    INDEX idx_operation_type (operation_type),
    INDEX idx_resource_type (resource_type),
    INDEX idx_created_at (created_at)
) COMMENT '操作日志表';
```

## 3. 索引优化策略

### 3.1 查询优化索引
```sql
-- 规则查询优化
CREATE INDEX idx_rules_workspace_status ON data_quality_rules(workspace_id, status);
CREATE INDEX idx_rules_table_status ON data_quality_rules(table_id, status);
CREATE INDEX idx_rules_created_by_status ON data_quality_rules(created_by, status);

-- 执行记录查询优化
CREATE INDEX idx_executions_rule_date ON rule_executions(rule_id, started_at);
CREATE INDEX idx_executions_status_date ON rule_executions(status, started_at);

-- 质量报告查询优化
CREATE INDEX idx_reports_workspace_date ON quality_reports(workspace_id, report_date);
CREATE INDEX idx_reports_table_date ON quality_reports(table_id, report_date);
```

### 3.2 分区策略
```sql
-- 规则执行记录表按月分区
ALTER TABLE rule_executions PARTITION BY RANGE (YEAR(started_at) * 100 + MONTH(started_at)) (
    PARTITION p202401 VALUES LESS THAN (202402),
    PARTITION p202402 VALUES LESS THAN (202403),
    -- ... 更多分区
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- 质量报告表按月分区
ALTER TABLE quality_reports PARTITION BY RANGE (YEAR(report_date) * 100 + MONTH(report_date)) (
    PARTITION p202401 VALUES LESS THAN (202402),
    PARTITION p202402 VALUES LESS THAN (202403),
    -- ... 更多分区
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

## 4. 数据关系图

### 4.1 主要实体关系
```
用户 (users)
├── 工作空间 (workspaces) [1:N]
│   ├── 工作空间成员 (workspace_members) [1:N]
│   ├── 数据源 (data_sources) [1:N]
│   │   └── 数据表 (data_tables) [1:N]
│   ├── 规则模板 (rule_templates) [1:N]
│   └── 数据质量规则 (data_quality_rules) [1:N]
│       ├── 规则执行记录 (rule_executions) [1:N]
│       │   └── 规则执行结果 (rule_execution_results) [1:1]
│       └── 质量报告 (quality_reports) [1:N]
└── 操作日志 (operation_logs) [1:N]
```

### 4.2 规则创建流程数据流
```
1. 用户选择工作空间 → workspaces表
2. 搜索数据表 → data_tables表
3. 查看表详情 → data_tables.schema_info
4. 查看现有规则 → data_quality_rules表
5. 查看质量报告 → quality_reports表
6. 创建新规则 → data_quality_rules表
7. 测试规则 → rule_executions表
8. 发布规则 → 更新data_quality_rules.status
```

## 5. 数据迁移和备份策略

### 5.1 数据迁移
- 使用Flyway或Liquibase管理数据库版本
- 支持向前和向后兼容的迁移脚本
- 大数据量表的迁移策略

### 5.2 备份策略
- 每日全量备份
- 每小时增量备份
- 重要操作前的手动备份
- 跨地域备份存储

## 6. 性能优化建议

### 6.1 查询优化
- 使用适当的索引
- 避免全表扫描
- 使用分页查询
- 缓存热点数据

### 6.2 存储优化
- 定期清理过期数据
- 压缩历史数据
- 使用合适的字段类型
- 优化JSON字段存储

### 6.3 监控指标
- 查询响应时间
- 数据库连接数
- 磁盘使用率
- 慢查询日志 