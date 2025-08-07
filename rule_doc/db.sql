-- =====================================================
-- 大数据质量管理系统 - 数据库设计脚本
-- 版本: v1.0
-- 创建日期: 2024-12-19
-- 数据库: MySQL 8.0+
-- =====================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS `rule_system` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `rule_system`;

-- =====================================================
-- 1. 用户和工作空间管理
-- =====================================================

-- 1.1 用户表
CREATE TABLE `users` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    `email` VARCHAR(100) UNIQUE NOT NULL COMMENT '邮箱',
    `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希',
    `full_name` VARCHAR(100) NOT NULL COMMENT '姓名',
    `avatar_url` VARCHAR(255) COMMENT '头像URL',
    `status` ENUM('active', 'inactive', 'suspended') DEFAULT 'active' COMMENT '用户状态',
    `last_login_at` TIMESTAMP NULL COMMENT '最后登录时间',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX `idx_username` (`username`),
    INDEX `idx_email` (`email`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 1.2 工作空间表
CREATE TABLE `workspaces` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '工作空间ID',
    `name` VARCHAR(100) NOT NULL COMMENT '工作空间名称',
    `description` TEXT COMMENT '工作空间描述',
    `type` ENUM('personal', 'team') DEFAULT 'personal' COMMENT '工作空间类型',
    `owner_id` BIGINT NOT NULL COMMENT '创建者ID',
    `status` ENUM('active', 'inactive', 'archived') DEFAULT 'active' COMMENT '工作空间状态',
    `settings` JSON COMMENT '工作空间配置(数据源等)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_owner_id` (`owner_id`),
    INDEX `idx_name` (`name`),
    INDEX `idx_status` (`status`),
    INDEX `idx_type` (`type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作空间表';

-- 1.3 工作空间成员表
CREATE TABLE `workspace_members` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '成员ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `role` ENUM('admin', 'editor', 'viewer', 'executor') DEFAULT 'viewer' COMMENT '角色',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    `invited_by` BIGINT COMMENT '邀请人ID',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`invited_by`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    UNIQUE KEY `uk_workspace_user` (`workspace_id`, `user_id`),
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_role` (`role`),
    INDEX `idx_joined_at` (`joined_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工作空间成员表';

-- =====================================================
-- 2. 数据表元数据管理
-- =====================================================

-- 2.1 数据源表
CREATE TABLE `data_sources` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '数据源ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `name` VARCHAR(100) NOT NULL COMMENT '数据源名称',
    `type` ENUM('mysql', 'postgresql', 'hive', 'clickhouse', 'kafka', 'mongodb') NOT NULL COMMENT '数据源类型',
    `connection_config` JSON NOT NULL COMMENT '连接配置',
    `status` ENUM('active', 'inactive', 'error') DEFAULT 'active' COMMENT '数据源状态',
    `last_connection_test` TIMESTAMP NULL COMMENT '最后连接测试时间',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据源表';

-- 2.2 数据表表
CREATE TABLE `data_tables` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '数据表ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `data_source_id` BIGINT NOT NULL COMMENT '数据源ID',
    `database_name` VARCHAR(100) NOT NULL COMMENT '数据库名',
    `table_name` VARCHAR(100) NOT NULL COMMENT '表名',
    `full_table_name` VARCHAR(200) NOT NULL COMMENT '完整表名(database.table)',
    `description` TEXT COMMENT '表描述',
    `row_count` BIGINT COMMENT '行数',
    `size_bytes` BIGINT COMMENT '大小(字节)',
    `last_updated` TIMESTAMP NULL COMMENT '最后更新时间',
    `schema_info` JSON COMMENT '表结构信息',
    `status` ENUM('active', 'inactive', 'archived') DEFAULT 'active' COMMENT '表状态',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`data_source_id`) REFERENCES `data_sources`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_workspace_full_table` (`workspace_id`, `full_table_name`),
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_data_source_id` (`data_source_id`),
    INDEX `idx_table_name` (`table_name`),
    INDEX `idx_database_name` (`database_name`),
    INDEX `idx_status` (`status`),
    INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据表表';

-- =====================================================
-- 3. 规则和模板管理
-- =====================================================

-- 3.1 规则模板表
CREATE TABLE `rule_templates` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '模板ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `name` VARCHAR(100) NOT NULL COMMENT '模板名称',
    `description` TEXT COMMENT '模板描述',
    `type` ENUM('uniqueness', 'format', 'range', 'completeness', 'consistency', 'accuracy', 'timeliness', 'custom_sql') NOT NULL COMMENT '规则类型',
    `category` VARCHAR(50) COMMENT '模板分类',
    `template_config` JSON NOT NULL COMMENT '模板配置',
    `parameters_schema` JSON COMMENT '参数模式定义',
    `usage_count` INT DEFAULT 0 COMMENT '使用次数',
    `is_public` BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    `status` ENUM('active', 'inactive', 'deprecated') DEFAULT 'active' COMMENT '模板状态',
    `created_by` BIGINT NOT NULL COMMENT '创建者ID',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_category` (`category`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_is_public` (`is_public`),
    INDEX `idx_usage_count` (`usage_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='规则模板表';

-- 3.2 数据质量规则表
CREATE TABLE `data_quality_rules` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '规则ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `table_id` BIGINT NOT NULL COMMENT '数据表ID',
    `template_id` BIGINT NULL COMMENT '模板ID(如果从模板创建)',
    `name` VARCHAR(100) NOT NULL COMMENT '规则名称',
    `description` TEXT COMMENT '规则描述',
    `type` ENUM('uniqueness', 'format', 'range', 'completeness', 'consistency', 'accuracy', 'timeliness', 'custom_sql') NOT NULL COMMENT '规则类型',
    `target_column` VARCHAR(100) COMMENT '目标字段',
    `rule_config` JSON NOT NULL COMMENT '规则配置',
    `parameters` JSON COMMENT '规则参数',
    `error_threshold` INT DEFAULT 0 COMMENT '错误阈值',
    `warning_threshold` INT DEFAULT 5 COMMENT '警告阈值',
    `execution_frequency` ENUM('hourly', 'daily', 'weekly', 'monthly') DEFAULT 'daily' COMMENT '执行频率',
    `priority` ENUM('high', 'medium', 'low') DEFAULT 'medium' COMMENT '优先级',
    `status` ENUM('draft', 'testing', 'active', 'paused', 'error') DEFAULT 'draft' COMMENT '规则状态',
    `version` INT DEFAULT 1 COMMENT '版本号',
    `parent_rule_id` BIGINT NULL COMMENT '父规则ID(用于版本控制)',
    `created_by` BIGINT NOT NULL COMMENT '创建者ID',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`table_id`) REFERENCES `data_tables`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`template_id`) REFERENCES `rule_templates`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`parent_rule_id`) REFERENCES `data_quality_rules`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_table_id` (`table_id`),
    INDEX `idx_template_id` (`template_id`),
    INDEX `idx_type` (`type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_parent_rule_id` (`parent_rule_id`),
    INDEX `idx_target_column` (`target_column`),
    INDEX `idx_execution_frequency` (`execution_frequency`),
    INDEX `idx_priority` (`priority`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据质量规则表';

-- =====================================================
-- 4. 规则执行和质量报告
-- =====================================================

-- 4.1 规则执行记录表
CREATE TABLE `rule_executions` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '执行记录ID',
    `rule_id` BIGINT NOT NULL COMMENT '规则ID',
    `execution_id` VARCHAR(50) UNIQUE NOT NULL COMMENT '执行ID',
    `status` ENUM('running', 'success', 'failed', 'timeout', 'cancelled') NOT NULL COMMENT '执行状态',
    `started_at` TIMESTAMP NOT NULL COMMENT '开始时间',
    `completed_at` TIMESTAMP NULL COMMENT '完成时间',
    `duration_seconds` DECIMAL(10,3) COMMENT '执行时长(秒)',
    `records_checked` BIGINT COMMENT '检查记录数',
    `records_failed` BIGINT DEFAULT 0 COMMENT '失败记录数',
    `records_warning` BIGINT DEFAULT 0 COMMENT '警告记录数',
    `error_message` TEXT COMMENT '错误信息',
    `execution_log` TEXT COMMENT '执行日志',
    `sample_data` JSON COMMENT '样本数据',
    `ge_result` JSON COMMENT 'Great Expectations执行结果',
    
    FOREIGN KEY (`rule_id`) REFERENCES `data_quality_rules`(`id`) ON DELETE CASCADE,
    INDEX `idx_rule_id` (`rule_id`),
    INDEX `idx_execution_id` (`execution_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_started_at` (`started_at`),
    INDEX `idx_completed_at` (`completed_at`),
    INDEX `idx_duration_seconds` (`duration_seconds`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='规则执行记录表';

-- 4.2 质量报告表
CREATE TABLE `quality_reports` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '报告ID',
    `workspace_id` BIGINT NOT NULL COMMENT '工作空间ID',
    `table_id` BIGINT NOT NULL COMMENT '数据表ID',
    `report_date` DATE NOT NULL COMMENT '报告日期',
    `report_hour` TINYINT NULL COMMENT '报告小时(用于小时级报告)',
    `overall_score` DECIMAL(5,2) COMMENT '整体质量评分',
    `total_rules` INT DEFAULT 0 COMMENT '总规则数',
    `passed_rules` INT DEFAULT 0 COMMENT '通过规则数',
    `failed_rules` INT DEFAULT 0 COMMENT '失败规则数',
    `warning_rules` INT DEFAULT 0 COMMENT '警告规则数',
    `report_data` JSON COMMENT '详细报告数据',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`table_id`) REFERENCES `data_tables`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_table_date_hour` (`table_id`, `report_date`, `report_hour`),
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_table_id` (`table_id`),
    INDEX `idx_report_date` (`report_date`),
    INDEX `idx_overall_score` (`overall_score`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='质量报告表';

-- 4.3 规则执行结果表
CREATE TABLE `rule_execution_results` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '结果ID',
    `execution_id` BIGINT NOT NULL COMMENT '执行记录ID',
    `rule_id` BIGINT NOT NULL COMMENT '规则ID',
    `result_status` ENUM('passed', 'failed', 'warning') NOT NULL COMMENT '结果状态',
    `records_checked` BIGINT COMMENT '检查记录数',
    `records_failed` BIGINT DEFAULT 0 COMMENT '失败记录数',
    `records_warning` BIGINT DEFAULT 0 COMMENT '警告记录数',
    `failure_rate` DECIMAL(5,4) COMMENT '失败率',
    `warning_rate` DECIMAL(5,4) COMMENT '警告率',
    `error_details` JSON COMMENT '错误详情',
    `sample_failures` JSON COMMENT '失败样本',
    `ge_validation_result` JSON COMMENT 'GE验证结果',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (`execution_id`) REFERENCES `rule_executions`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`rule_id`) REFERENCES `data_quality_rules`(`id`) ON DELETE CASCADE,
    INDEX `idx_execution_id` (`execution_id`),
    INDEX `idx_rule_id` (`rule_id`),
    INDEX `idx_result_status` (`result_status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='规则执行结果表';

-- =====================================================
-- 5. 系统管理
-- =====================================================

-- 5.1 系统配置表
CREATE TABLE `system_configs` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '配置ID',
    `config_key` VARCHAR(100) UNIQUE NOT NULL COMMENT '配置键',
    `config_value` TEXT COMMENT '配置值',
    `config_type` ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '配置类型',
    `description` TEXT COMMENT '配置描述',
    `is_system` BOOLEAN DEFAULT FALSE COMMENT '是否系统配置',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX `idx_config_key` (`config_key`),
    INDEX `idx_is_system` (`is_system`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 5.2 操作日志表
CREATE TABLE `operation_logs` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '日志ID',
    `user_id` BIGINT NULL COMMENT '用户ID',
    `workspace_id` BIGINT NULL COMMENT '工作空间ID',
    `operation_type` VARCHAR(50) NOT NULL COMMENT '操作类型',
    `resource_type` VARCHAR(50) NOT NULL COMMENT '资源类型',
    `resource_id` BIGINT NULL COMMENT '资源ID',
    `operation_details` JSON COMMENT '操作详情',
    `ip_address` VARCHAR(45) COMMENT 'IP地址',
    `user_agent` TEXT COMMENT '用户代理',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`workspace_id`) REFERENCES `workspaces`(`id`) ON DELETE SET NULL,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_workspace_id` (`workspace_id`),
    INDEX `idx_operation_type` (`operation_type`),
    INDEX `idx_resource_type` (`resource_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志表';

-- =====================================================
-- 6. 复合索引优化
-- =====================================================

-- 规则查询优化
CREATE INDEX `idx_rules_workspace_status` ON `data_quality_rules`(`workspace_id`, `status`);
CREATE INDEX `idx_rules_table_status` ON `data_quality_rules`(`table_id`, `status`);
CREATE INDEX `idx_rules_created_by_status` ON `data_quality_rules`(`created_by`, `status`);

-- 执行记录查询优化
CREATE INDEX `idx_executions_rule_date` ON `rule_executions`(`rule_id`, `started_at`);
CREATE INDEX `idx_executions_status_date` ON `rule_executions`(`status`, `started_at`);

-- 质量报告查询优化
CREATE INDEX `idx_reports_workspace_date` ON `quality_reports`(`workspace_id`, `report_date`);
CREATE INDEX `idx_reports_table_date` ON `quality_reports`(`table_id`, `report_date`);

-- 工作空间成员查询优化
CREATE INDEX `idx_members_workspace_role` ON `workspace_members`(`workspace_id`, `role`);

-- 数据表查询优化
CREATE INDEX `idx_tables_workspace_status` ON `data_tables`(`workspace_id`, `status`);

-- =====================================================
-- 7. 初始数据
-- =====================================================

-- 7.1 创建默认管理员用户
INSERT INTO `users` (`username`, `email`, `password_hash`, `full_name`, `status`) VALUES
('admin', 'admin@dataquality.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '系统管理员', 'active'),
('demo_user', 'demo@dataquality.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '演示用户', 'active');

-- 7.2 创建默认工作空间
INSERT INTO `workspaces` (`name`, `description`, `type`, `owner_id`, `status`) VALUES
('个人工作空间', '默认个人工作空间', 'personal', 1, 'active'),
('数据分析团队', '数据分析团队的工作空间', 'team', 1, 'active');

-- 7.3 添加工作空间成员
INSERT INTO `workspace_members` (`workspace_id`, `user_id`, `role`, `invited_by`) VALUES
(1, 1, 'admin', NULL),
(2, 1, 'admin', NULL),
(2, 2, 'editor', 1);

-- 7.4 创建默认数据源
INSERT INTO `data_sources` (`workspace_id`, `name`, `type`, `connection_config`, `status`) VALUES
(1, '本地MySQL', 'mysql', '{"host": "localhost", "port": 3306, "database": "analytics", "username": "root"}', 'active'),
(2, '生产Hive', 'hive', '{"host": "hive.example.com", "port": 10000, "database": "analytics"}', 'active');

-- 7.5 创建示例数据表
INSERT INTO `data_tables` (`workspace_id`, `data_source_id`, `database_name`, `table_name`, `full_table_name`, `description`, `row_count`, `size_bytes`, `schema_info`, `status`) VALUES
(1, 1, 'analytics', 'users', 'analytics.users', '用户基础信息表', 1234567, 2300000000, 
'{"columns": [{"name": "user_id", "type": "BIGINT", "nullable": false, "description": "用户ID"}, {"name": "email", "type": "VARCHAR", "nullable": false, "description": "邮箱地址"}, {"name": "name", "type": "VARCHAR", "nullable": true, "description": "用户姓名"}, {"name": "age", "type": "INT", "nullable": true, "description": "年龄"}, {"name": "created_at", "type": "TIMESTAMP", "nullable": false, "description": "创建时间"}]}', 'active'),
(1, 1, 'analytics', 'orders', 'analytics.orders', '订单信息表', 5678901, 4500000000, 
'{"columns": [{"name": "order_id", "type": "BIGINT", "nullable": false, "description": "订单ID"}, {"name": "user_id", "type": "BIGINT", "nullable": false, "description": "用户ID"}, {"name": "amount", "type": "DECIMAL", "nullable": false, "description": "订单金额"}, {"name": "status", "type": "VARCHAR", "nullable": false, "description": "订单状态"}, {"name": "created_at", "type": "TIMESTAMP", "nullable": false, "description": "创建时间"}]}', 'active');

-- 7.6 创建示例规则模板
INSERT INTO `rule_templates` (`workspace_id`, `name`, `description`, `type`, `category`, `template_config`, `parameters_schema`, `usage_count`, `is_public`, `created_by`) VALUES
(1, 'email_validation', '邮箱格式验证模板', 'format', 'validation', 
'{"regex_pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "description": "标准邮箱格式验证"}', 
'{"type": "object", "properties": {"field_name": {"type": "string", "description": "目标字段名"}}, "required": ["field_name"]}', 0, true, 1),
(1, 'id_unique', 'ID唯一性检查模板', 'uniqueness', 'integrity', 
'{"check_type": "unique", "case_sensitive": false, "description": "检查字段值唯一性"}', 
'{"type": "object", "properties": {"field_name": {"type": "string", "description": "目标字段名"}}, "required": ["field_name"]}', 0, true, 1),
(1, 'age_range', '年龄范围检查模板', 'range', 'business', 
'{"min_value": 0, "max_value": 150, "description": "检查年龄是否在合理范围内"}', 
'{"type": "object", "properties": {"field_name": {"type": "string", "description": "目标字段名"}, "min_value": {"type": "number", "description": "最小值"}, "max_value": {"type": "number", "description": "最大值"}}, "required": ["field_name"]}', 0, true, 1);

-- 7.7 创建示例规则
INSERT INTO `data_quality_rules` (`workspace_id`, `table_id`, `template_id`, `name`, `description`, `type`, `target_column`, `rule_config`, `parameters`, `error_threshold`, `warning_threshold`, `execution_frequency`, `priority`, `status`, `created_by`) VALUES
(1, 1, 2, 'user_id_unique', '检查用户ID唯一性', 'uniqueness', 'user_id', 
'{"check_type": "unique", "case_sensitive": false}', 
'{"field_name": "user_id"}', 0, 5, 'daily', 'high', 'active', 1),
(1, 1, 1, 'email_format', '检查邮箱格式', 'format', 'email', 
'{"regex_pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"}', 
'{"field_name": "email"}', 0, 10, 'daily', 'medium', 'active', 1),
(1, 1, 3, 'age_range_check', '检查年龄范围', 'range', 'age', 
'{"min_value": 0, "max_value": 150}', 
'{"field_name": "age", "min_value": 0, "max_value": 150}', 0, 20, 'daily', 'low', 'draft', 1);

-- 7.8 创建示例质量报告
INSERT INTO `quality_reports` (`workspace_id`, `table_id`, `report_date`, `overall_score`, `total_rules`, `passed_rules`, `failed_rules`, `warning_rules`, `report_data`) VALUES
(1, 1, CURDATE(), 85.2, 3, 2, 1, 0, 
'{"rule_results": [{"rule_id": 1, "status": "passed", "score": 100}, {"rule_id": 2, "status": "failed", "score": 60}, {"rule_id": 3, "status": "passed", "score": 95}]}');

-- 7.9 创建系统配置
INSERT INTO `system_configs` (`config_key`, `config_value`, `config_type`, `description`, `is_system`) VALUES
('system.name', 'Data Quality Management System', 'string', '系统名称', true),
('system.version', '1.0.0', 'string', '系统版本', true),
('ge.execution.timeout', '300', 'number', 'Great Expectations执行超时时间(秒)', true),
('notification.enabled', 'true', 'boolean', '是否启用通知', true),
('quality.score.threshold', '80', 'number', '质量评分阈值', true),
('rule.execution.max_retries', '3', 'number', '规则执行最大重试次数', true);

-- =====================================================
-- 8. 视图定义
-- =====================================================

-- 8.1 工作空间概览视图
CREATE VIEW `v_workspace_overview` AS
SELECT 
    w.id,
    w.name,
    w.description,
    w.type,
    w.owner_id,
    w.status,
    COUNT(DISTINCT dt.id) as table_count,
    COUNT(DISTINCT dqr.id) as rule_count,
    COUNT(DISTINCT rt.id) as template_count,
    AVG(qr.overall_score) as avg_quality_score,
    w.created_at,
    w.updated_at
FROM workspaces w
LEFT JOIN data_tables dt ON w.id = dt.workspace_id AND dt.status = 'active'
LEFT JOIN data_quality_rules dqr ON w.id = dqr.workspace_id AND dqr.status = 'active'
LEFT JOIN rule_templates rt ON w.id = rt.workspace_id AND rt.status = 'active'
LEFT JOIN quality_reports qr ON dt.id = qr.table_id AND qr.report_date = CURDATE()
GROUP BY w.id;

-- 8.2 规则执行统计视图
CREATE VIEW `v_rule_execution_stats` AS
SELECT 
    dqr.id as rule_id,
    dqr.name as rule_name,
    dqr.type as rule_type,
    dqr.status as rule_status,
    dt.table_name,
    dt.database_name,
    COUNT(re.id) as execution_count,
    SUM(CASE WHEN re.status = 'success' THEN 1 ELSE 0 END) as success_count,
    SUM(CASE WHEN re.status = 'failed' THEN 1 ELSE 0 END) as failed_count,
    AVG(re.duration_seconds) as avg_duration,
    MAX(re.started_at) as last_execution
FROM data_quality_rules dqr
JOIN data_tables dt ON dqr.table_id = dt.id
LEFT JOIN rule_executions re ON dqr.id = re.rule_id
GROUP BY dqr.id;

-- 8.3 质量评分趋势视图
CREATE VIEW `v_quality_score_trend` AS
SELECT 
    qr.table_id,
    dt.table_name,
    dt.database_name,
    qr.report_date,
    qr.overall_score,
    qr.total_rules,
    qr.passed_rules,
    qr.failed_rules,
    LAG(qr.overall_score) OVER (PARTITION BY qr.table_id ORDER BY qr.report_date) as prev_score,
    qr.overall_score - LAG(qr.overall_score) OVER (PARTITION BY qr.table_id ORDER BY qr.report_date) as score_change
FROM quality_reports qr
JOIN data_tables dt ON qr.table_id = dt.id
ORDER BY qr.table_id, qr.report_date;

-- =====================================================
-- 9. 存储过程
-- =====================================================

DELIMITER //

-- 9.1 创建规则执行存储过程
CREATE PROCEDURE `sp_execute_rule`(
    IN p_rule_id BIGINT,
    IN p_sample_size INT DEFAULT 1000,
    IN p_timeout_seconds INT DEFAULT 300
)
BEGIN
    DECLARE v_execution_id VARCHAR(50);
    DECLARE v_start_time TIMESTAMP;
    DECLARE v_end_time TIMESTAMP;
    DECLARE v_duration DECIMAL(10,3);
    DECLARE v_status ENUM('running', 'success', 'failed', 'timeout', 'cancelled');
    DECLARE v_error_message TEXT;
    
    -- 生成执行ID
    SET v_execution_id = CONCAT('exec_', UNIX_TIMESTAMP(), '_', FLOOR(RAND() * 1000000));
    SET v_start_time = NOW();
    SET v_status = 'running';
    
    -- 插入执行记录
    INSERT INTO rule_executions (rule_id, execution_id, status, started_at)
    VALUES (p_rule_id, v_execution_id, v_status, v_start_time);
    
    -- 这里应该调用Great Expectations执行逻辑
    -- 暂时模拟执行结果
    SET v_end_time = NOW();
    SET v_duration = TIMESTAMPDIFF(MICROSECOND, v_start_time, v_end_time) / 1000000;
    
    -- 模拟执行结果
    IF RAND() > 0.1 THEN
        SET v_status = 'success';
        SET v_error_message = NULL;
    ELSE
        SET v_status = 'failed';
        SET v_error_message = '模拟执行失败';
    END IF;
    
    -- 更新执行记录
    UPDATE rule_executions 
    SET status = v_status,
        completed_at = v_end_time,
        duration_seconds = v_duration,
        records_checked = p_sample_size,
        records_failed = CASE WHEN v_status = 'failed' THEN FLOOR(RAND() * 100) ELSE 0 END,
        error_message = v_error_message
    WHERE execution_id = v_execution_id;
    
    -- 返回执行ID
    SELECT v_execution_id as execution_id, v_status as status;
END //

-- 9.2 生成质量报告存储过程
CREATE PROCEDURE `sp_generate_quality_report`(
    IN p_table_id BIGINT,
    IN p_report_date DATE
)
BEGIN
    DECLARE v_workspace_id BIGINT;
    DECLARE v_total_rules INT;
    DECLARE v_passed_rules INT;
    DECLARE v_failed_rules INT;
    DECLARE v_warning_rules INT;
    DECLARE v_overall_score DECIMAL(5,2);
    
    -- 获取工作空间ID
    SELECT workspace_id INTO v_workspace_id FROM data_tables WHERE id = p_table_id;
    
    -- 统计规则执行结果
    SELECT 
        COUNT(*) as total_rules,
        SUM(CASE WHEN re.status = 'success' THEN 1 ELSE 0 END) as passed_rules,
        SUM(CASE WHEN re.status = 'failed' THEN 1 ELSE 0 END) as failed_rules,
        SUM(CASE WHEN re.status = 'timeout' THEN 1 ELSE 0 END) as warning_rules
    INTO v_total_rules, v_passed_rules, v_failed_rules, v_warning_rules
    FROM data_quality_rules dqr
    LEFT JOIN rule_executions re ON dqr.id = re.rule_id 
        AND DATE(re.started_at) = p_report_date
    WHERE dqr.table_id = p_table_id AND dqr.status = 'active';
    
    -- 计算质量评分
    IF v_total_rules > 0 THEN
        SET v_overall_score = (v_passed_rules / v_total_rules) * 100;
    ELSE
        SET v_overall_score = 0;
    END IF;
    
    -- 插入或更新质量报告
    INSERT INTO quality_reports (workspace_id, table_id, report_date, overall_score, total_rules, passed_rules, failed_rules, warning_rules)
    VALUES (v_workspace_id, p_table_id, p_report_date, v_overall_score, v_total_rules, v_passed_rules, v_failed_rules, v_warning_rules)
    ON DUPLICATE KEY UPDATE
        overall_score = v_overall_score,
        total_rules = v_total_rules,
        passed_rules = v_passed_rules,
        failed_rules = v_failed_rules,
        warning_rules = v_warning_rules,
        updated_at = NOW();
    
    SELECT v_overall_score as overall_score, v_total_rules as total_rules;
END //

DELIMITER ;

-- =====================================================
-- 10. 触发器
-- =====================================================

-- 10.1 规则状态变更触发器
DELIMITER //
CREATE TRIGGER `tr_rule_status_change` 
AFTER UPDATE ON `data_quality_rules`
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO operation_logs (user_id, workspace_id, operation_type, resource_type, resource_id, operation_details)
        VALUES (NEW.created_by, NEW.workspace_id, 'status_change', 'rule', NEW.id, 
                JSON_OBJECT('old_status', OLD.status, 'new_status', NEW.status, 'rule_name', NEW.name));
    EN