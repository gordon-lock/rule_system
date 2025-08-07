# API接口设计 - 大数据质量管理系统

## 1. API概述

### 1.1 API设计原则
- **RESTful风格**: 遵循REST架构原则
- **版本控制**: 支持API版本管理
- **统一响应格式**: 标准化的响应结构
- **错误处理**: 完善的错误码和错误信息
- **认证授权**: 基于JWT的认证机制
- **限流控制**: 防止API滥用

### 1.2 基础信息
- **基础URL**: `https://api.dataquality.com/v1`
- **认证方式**: Bearer Token (JWT)
- **内容类型**: `application/json`
- **字符编码**: UTF-8

### 1.3 响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": "2024-12-19T14:30:00Z",
  "request_id": "req_123456789"
}
```

### 1.4 错误码定义
```json
{
  "code": 400,
  "message": "Bad Request",
  "error": {
    "code": "INVALID_PARAMETER",
    "details": "参数验证失败",
    "field": "rule_name"
  }
}
```

## 2. 认证相关API

### 2.1 用户登录
```http
POST /auth/login
Content-Type: application/json

{
  "username": "john.doe",
  "password": "password123"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "refresh_token_here",
    "expires_in": 3600,
    "user": {
      "id": 1,
      "username": "john.doe",
      "email": "john.doe@example.com",
      "full_name": "John Doe",
      "avatar_url": "https://example.com/avatar.jpg"
    }
  }
}
```

### 2.2 刷新Token
```http
POST /auth/refresh
Authorization: Bearer refresh_token_here
```

### 2.3 用户登出
```http
POST /auth/logout
Authorization: Bearer token_here
```

## 3. 工作空间管理API

### 3.1 获取工作空间列表
```http
GET /workspaces
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "workspaces": [
      {
        "id": 1,
        "name": "个人工作空间",
        "description": "我的个人工作空间",
        "type": "personal",
        "owner_id": 1,
        "status": "active",
        "rule_count": 15,
        "template_count": 3,
        "last_updated": "2024-12-19T12:30:00Z",
        "created_at": "2024-12-01T10:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10
  }
}
```

### 3.2 创建工作空间
```http
POST /workspaces
Authorization: Bearer token_here
Content-Type: application/json

{
  "name": "数据分析团队",
  "description": "数据分析团队的工作空间",
  "type": "team"
}
```

### 3.3 获取工作空间详情
```http
GET /workspaces/{workspace_id}
Authorization: Bearer token_here
```

### 3.4 更新工作空间
```http
PUT /workspaces/{workspace_id}
Authorization: Bearer token_here
Content-Type: application/json

{
  "name": "更新后的名称",
  "description": "更新后的描述"
}
```

## 4. 数据表管理API

### 4.1 搜索数据表
```http
GET /workspaces/{workspace_id}/tables?search=users&database=analytics&page=1&size=10
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "tables": [
      {
        "id": 1,
        "database_name": "analytics",
        "table_name": "users",
        "full_table_name": "analytics.users",
        "description": "用户基础信息表",
        "row_count": 1234567,
        "size_bytes": 2300000000,
        "last_updated": "2024-12-19T10:30:00Z",
        "rule_count": 3,
        "quality_score": 85.2
      }
    ],
    "total": 156,
    "page": 1,
    "size": 10
  }
}
```

### 4.2 获取表详情
```http
GET /workspaces/{workspace_id}/tables/{table_id}
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "database_name": "analytics",
    "table_name": "users",
    "full_table_name": "analytics.users",
    "description": "用户基础信息表",
    "row_count": 1234567,
    "size_bytes": 2300000000,
    "last_updated": "2024-12-19T10:30:00Z",
    "schema_info": {
      "columns": [
        {
          "name": "user_id",
          "type": "BIGINT",
          "nullable": false,
          "default_value": null,
          "description": "用户ID"
        },
        {
          "name": "email",
          "type": "VARCHAR",
          "nullable": false,
          "default_value": null,
          "description": "邮箱地址"
        }
      ]
    },
    "rules": [
      {
        "id": 1,
        "name": "user_id_unique",
        "type": "uniqueness",
        "target_column": "user_id",
        "status": "active",
        "last_execution": {
          "status": "success",
          "executed_at": "2024-12-19T14:00:00Z",
          "records_checked": 1234567,
          "records_failed": 0
        }
      }
    ],
    "quality_report": {
      "overall_score": 85.2,
      "total_rules": 3,
      "passed_rules": 2,
      "failed_rules": 1,
      "warning_rules": 0,
      "last_updated": "2024-12-19T14:00:00Z"
    }
  }
}
```

## 5. 规则管理API

### 5.1 获取规则列表
```http
GET /workspaces/{workspace_id}/rules?status=active&type=uniqueness&page=1&size=10
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "rules": [
      {
        "id": 1,
        "name": "user_id_unique",
        "description": "检查用户ID唯一性",
        "type": "uniqueness",
        "target_table": {
          "id": 1,
          "table_name": "users",
          "database_name": "analytics"
        },
        "target_column": "user_id",
        "status": "active",
        "priority": "medium",
        "execution_frequency": "daily",
        "last_execution": {
          "status": "success",
          "executed_at": "2024-12-19T14:00:00Z",
          "duration_seconds": 2.3,
          "records_checked": 1234567,
          "records_failed": 0
        },
        "created_by": {
          "id": 1,
          "username": "john.doe",
          "full_name": "John Doe"
        },
        "created_at": "2024-12-01T10:00:00Z",
        "updated_at": "2024-12-19T14:00:00Z"
      }
    ],
    "total": 15,
    "page": 1,
    "size": 10
  }
}
```

### 5.2 创建规则
```http
POST /workspaces/{workspace_id}/rules
Authorization: Bearer token_here
Content-Type: application/json

{
  "table_id": 1,
  "template_id": null,
  "name": "email_unique_check",
  "description": "检查邮箱唯一性",
  "type": "uniqueness",
  "target_column": "email",
  "rule_config": {
    "check_type": "unique",
    "case_sensitive": false
  },
  "parameters": {
    "error_threshold": 0,
    "warning_threshold": 5
  },
  "execution_frequency": "daily",
  "priority": "medium"
}
```

### 5.3 获取规则详情
```http
GET /workspaces/{workspace_id}/rules/{rule_id}
Authorization: Bearer token_here
```

### 5.4 更新规则
```http
PUT /workspaces/{workspace_id}/rules/{rule_id}
Authorization: Bearer token_here
Content-Type: application/json

{
  "name": "更新后的规则名称",
  "description": "更新后的描述",
  "rule_config": {
    "check_type": "unique",
    "case_sensitive": true
  }
}
```

### 5.5 删除规则
```http
DELETE /workspaces/{workspace_id}/rules/{rule_id}
Authorization: Bearer token_here
```

### 5.6 测试规则
```http
POST /workspaces/{workspace_id}/rules/{rule_id}/test
Authorization: Bearer token_here
Content-Type: application/json

{
  "sample_size": 1000,
  "timeout_seconds": 30
}
```

**响应**:
```json
{
  "code": 200,
  "message": "测试完成",
  "data": {
    "execution_id": "exec_123456789",
    "status": "success",
    "started_at": "2024-12-19T14:30:00Z",
    "completed_at": "2024-12-19T14:30:02Z",
    "duration_seconds": 2.3,
    "records_checked": 1000,
    "records_failed": 0,
    "records_warning": 0,
    "sample_data": {
      "passed_samples": [
        {"email": "user1@example.com"},
        {"email": "user2@example.com"}
      ],
      "failed_samples": []
    }
  }
}
```

### 5.7 发布规则
```http
POST /workspaces/{workspace_id}/rules/{rule_id}/publish
Authorization: Bearer token_here
Content-Type: application/json

{
  "publish_mode": "immediate",
  "environment": "production",
  "notifications": {
    "enabled": true,
    "channels": ["email", "feishu"]
  }
}
```

## 6. 模板管理API

### 6.1 获取模板列表
```http
GET /workspaces/{workspace_id}/templates?type=format&page=1&size=10
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "templates": [
      {
        "id": 1,
        "name": "email_validation",
        "description": "邮箱格式验证模板",
        "type": "format",
        "category": "validation",
        "usage_count": 5,
        "is_public": false,
        "status": "active",
        "created_by": {
          "id": 1,
          "username": "john.doe",
          "full_name": "John Doe"
        },
        "created_at": "2024-12-01T10:00:00Z",
        "updated_at": "2024-12-19T14:00:00Z"
      }
    ],
    "total": 3,
    "page": 1,
    "size": 10
  }
}
```

### 6.2 创建模板
```http
POST /workspaces/{workspace_id}/templates
Authorization: Bearer token_here
Content-Type: application/json

{
  "name": "phone_validation",
  "description": "手机号格式验证模板",
  "type": "format",
  "category": "validation",
  "template_config": {
    "regex_pattern": "^1[3-9]\\d{9}$",
    "description": "中国大陆手机号格式"
  },
  "parameters_schema": {
    "type": "object",
    "properties": {
      "field_name": {
        "type": "string",
        "description": "目标字段名"
      }
    },
    "required": ["field_name"]
  }
}
```

### 6.3 应用模板
```http
POST /workspaces/{workspace_id}/templates/{template_id}/apply
Authorization: Bearer token_here
Content-Type: application/json

{
  "table_id": 1,
  "parameters": {
    "field_name": "phone"
  },
  "rule_name": "phone_format_check",
  "rule_description": "检查手机号格式"
}
```

## 7. 质量报告API

### 7.1 获取质量报告
```http
GET /workspaces/{workspace_id}/reports?table_id=1&date=2024-12-19&page=1&size=10
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "reports": [
      {
        "id": 1,
        "table": {
          "id": 1,
          "table_name": "users",
          "database_name": "analytics"
        },
        "report_date": "2024-12-19",
        "overall_score": 85.2,
        "total_rules": 3,
        "passed_rules": 2,
        "failed_rules": 1,
        "warning_rules": 0,
        "trend": {
          "score_change": 2.1,
          "trend_direction": "up"
        },
        "created_at": "2024-12-19T14:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10
  }
}
```

### 7.2 获取规则执行历史
```http
GET /workspaces/{workspace_id}/rules/{rule_id}/executions?start_date=2024-12-01&end_date=2024-12-19&page=1&size=10
Authorization: Bearer token_here
```

### 7.3 获取执行详情
```http
GET /workspaces/{workspace_id}/executions/{execution_id}
Authorization: Bearer token_here
```

## 8. 外部服务API

### 8.1 获取表的正式规则
```http
GET /api/v1/tables/{table_id}/rules
Authorization: Bearer token_here
```

**响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "table": {
      "id": 1,
      "table_name": "users",
      "database_name": "analytics"
    },
    "rules": [
      {
        "id": 1,
        "name": "user_id_unique",
        "type": "uniqueness",
        "target_column": "user_id",
        "rule_config": {
          "check_type": "unique",
          "case_sensitive": false
        },
        "parameters": {
          "error_threshold": 0,
          "warning_threshold": 5
        },
        "execution_frequency": "daily",
        "priority": "medium",
        "status": "active"
      }
    ],
    "total": 3
  }
}
```

### 8.2 获取质量评分
```http
GET /api/v1/tables/{table_id}/quality-score?date=2024-12-19
Authorization: Bearer token_here
```

### 8.3 获取质量趋势
```http
GET /api/v1/tables/{table_id}/quality-trend?start_date=2024-12-01&end_date=2024-12-19
Authorization: Bearer token_here
```

## 9. 系统管理API

### 9.1 获取系统状态
```http
GET /system/status
Authorization: Bearer token_here
```

### 9.2 获取系统配置
```http
GET /system/configs
Authorization: Bearer token_here
```

### 9.3 更新系统配置
```http
PUT /system/configs/{config_key}
Authorization: Bearer token_here
Content-Type: application/json

{
  "config_value": "new_value"
}
```

## 10. Webhook API

### 10.1 注册Webhook
```http
POST /workspaces/{workspace_id}/webhooks
Authorization: Bearer token_here
Content-Type: application/json

{
  "name": "质量告警通知",
  "url": "https://example.com/webhook",
  "events": ["rule_failed", "quality_score_dropped"],
  "secret": "webhook_secret"
}
```

### 10.2 Webhook事件格式
```json
{
  "event": "rule_failed",
  "timestamp": "2024-12-19T14:30:00Z",
  "data": {
    "rule": {
      "id": 1,
      "name": "user_id_unique",
      "table": "analytics.users"
    },
    "execution": {
      "id": "exec_123456789",
      "records_failed": 5,
      "error_message": "发现重复的用户ID"
    }
  }
}
```

## 11. API限流和监控

### 11.1 限流规则
- **认证API**: 100次/分钟
- **查询API**: 1000次/分钟
- **写操作API**: 100次/分钟
- **批量操作API**: 10次/分钟

### 11.2 监控指标
- API调用次数
- 响应时间
- 错误率
- 并发用户数

### 11.3 健康检查
```http
GET /health
```

**响应**:
```json
{
  "status": "healthy",
  "timestamp": "2024-12-19T14:30:00Z",
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "great_expectations": "healthy"
  }
}
``` 