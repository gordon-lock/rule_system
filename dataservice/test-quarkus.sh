#!/bin/bash

# Quarkus Iceberg GraphQL API Test Script
# 用于本地测试 Quarkus 应用

set -e

echo "🚀 Quarkus Iceberg GraphQL API 测试脚本"
echo "========================================"

# 检查 Java 版本
echo "📋 检查 Java 版本..."
if ! command -v java &> /dev/null; then
    echo "❌ Java 未安装，请先安装 Java 17+"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "❌ Java 版本过低，需要 Java 17+，当前版本: $JAVA_VERSION"
    exit 1
fi
echo "✅ Java 版本检查通过: $(java -version 2>&1 | head -n 1)"

# 检查 Maven
echo "📋 检查 Maven..."
if ! command -v mvn &> /dev/null; then
    echo "❌ Maven 未安装，请先安装 Maven 3.6+"
    exit 1
fi
echo "✅ Maven 检查通过: $(mvn -version | head -n 1)"

# 显示菜单
echo ""
echo "请选择测试方式:"
echo "1) 运行单元测试"
echo "2) 启动开发模式 (热重载)"
echo "3) 启动 Docker 环境 (需要 Docker)"
echo "4) 退出"
echo ""

read -p "请输入选择 (1-4): " choice

case $choice in
    1)
        echo "🧪 运行单元测试..."
        mvn clean test
        echo "✅ 单元测试完成"
        ;;
    2)
        echo "🔥 启动 Quarkus 开发模式..."
        echo "📝 应用将在 http://localhost:8080 启动"
        echo "📝 GraphQL UI: http://localhost:8080/api/graphql-ui"
        echo "📝 健康检查: http://localhost:8080/api/health"
        echo "📝 按 Ctrl+C 停止服务"
        echo ""
        mvn quarkus:dev
        ;;
    3)
        echo "🐳 检查 Docker..."
        if ! command -v docker &> /dev/null; then
            echo "❌ Docker 未安装，请先安装 Docker"
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
            exit 1
        fi
        
        echo "✅ Docker 检查通过"
        echo "🐳 启动 Docker 环境..."
        echo "📝 这将在后台启动 Trino 和 API 服务"
        echo "📝 API 将在 http://localhost:8081 启动"
        echo "📝 Trino 将在 http://localhost:8080 启动"
        echo ""
        
        docker-compose -f docker-compose-dev.yml up -d
        
        echo "⏳ 等待服务启动..."
        sleep 30
        
        echo "🧪 测试健康检查..."
        if curl -f http://localhost:8081/api/health/info > /dev/null 2>&1; then
            echo "✅ API 服务启动成功"
            echo "📝 GraphQL UI: http://localhost:8081/api/graphql-ui"
            echo "📝 健康检查: http://localhost:8081/api/health"
        else
            echo "❌ API 服务启动失败"
        fi
        
        echo ""
        echo "📝 使用以下命令查看日志:"
        echo "   docker-compose -f docker-compose-dev.yml logs -f"
        echo ""
        echo "📝 使用以下命令停止服务:"
        echo "   docker-compose -f docker-compose-dev.yml down"
        ;;
    4)
        echo "👋 再见!"
        exit 0
        ;;
    *)
        echo "❌ 无效选择，请重新运行脚本"
        exit 1
        ;;
esac 