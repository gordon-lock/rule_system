# 大数据质量管理系统 (Big Data Quality Management System)

基于Great Expectations的企业级数据质量管理系统，为数据团队提供直观、高效、可扩展的数据质量规则管理平台。

## 项目概述

本项目旨在构建一个完整的数据质量管理系统，确保数据在进入数据仓库/数据湖/实时管道前后的准确性、完整性、一致性、及时性、唯一性和可审计性。

### 核心功能

1. **规则管理**: 用户可以增删改查质量检查规则
2. **规则测试**: 用户可以测试规则来看规则的检查结果是否正常
3. **规则验证**: 系统要能提前检查用户设置的规则是否是正确的
4. **模板管理**: 用户可以创建规则模板，一个规则模板可以应用到多个不同的表
5. **自定义规则**: 用户除了可以应用模板以外，依然可以为每一个表自定义规则
6. **冲突检测**: 系统检查规则之间是否有冲突，有冲突的时候无法发布
7. **预发布验证**: 新建和修改的规则在发布前要经过冲突检查和试运行，才允许发布
8. **自动保存**: 系统自动保存用户的规则编辑
9. **外部服务**: 系统提供外部服务，其他团队可以通过接口获得指定表的所有的正式的质量规则
10. **Great Expectations集成**: 系统UI要经过转化形成GE能识别并执行的规则，设计表结构来保存GE生成的质量报告

## 文档导航

- [产品需求文档 (PRD)](rule_system_prd.md) - 详细的产品设计文档
- [用户工作流程设计](user_workflow_design.md) - 详细的用户操作流程和页面设计
- [数据模型设计](data_model_design.md) - 数据库表结构和关系设计
- [设计系统规范](design_system.md) - UI/UX设计规范和组件库
- [主仪表板设计](dashboard_design.md) - 主仪表板页面详细设计
- [API接口设计](api_design.md) - RESTful API接口设计文档
- [原始需求文档](prd1.md) - 初始的产品需求文档

## 技术栈

- **前端**: React/Vue.js + TypeScript
- **后端**: Spring Boot/Node.js + Java/TypeScript
- **数据质量引擎**: Great Expectations
- **数据库**: MySQL + Redis
- **消息队列**: Kafka/RabbitMQ
- **容器化**: Docker + Kubernetes

## 快速开始

### 环境要求

- Java 11+
- Node.js 16+
- Python 3.8+
- MySQL 8.0+
- Redis 6.0+

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd rule_system
```

2. 安装依赖
```bash
# 后端依赖
cd backend
mvn install

# 前端依赖
cd frontend
npm install
```

3. 配置数据库
```bash
# 创建数据库
mysql -u root -p
CREATE DATABASE rule_system;
```

4. 启动服务
```bash
# 启动后端服务
cd backend
mvn spring-boot:run

# 启动前端服务
cd frontend
npm start
```

## 项目结构

```
rule_system/
├── docs/                    # 文档目录
│   ├── rule_system_prd.md   # 产品需求文档
│   └── prd1.md             # 原始需求文档
├── backend/                 # 后端服务
│   ├── src/
│   ├── pom.xml
│   └── README.md
├── frontend/                # 前端应用
│   ├── src/
│   ├── package.json
│   └── README.md
├── ge-engine/               # Great Expectations引擎
│   ├── src/
│   └── requirements.txt
├── docker/                  # Docker配置
├── k8s/                     # Kubernetes配置
└── README.md               # 项目说明
```

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 联系方式

- 项目负责人: [待填写]
- 邮箱: [待填写]
- 项目地址: [待填写]
