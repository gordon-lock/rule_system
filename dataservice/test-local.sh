#!/bin/bash

echo "🚀 Iceberg GraphQL API - 本地测试脚本"
echo "======================================"

# 检查Java版本
echo "📋 检查Java版本..."
java -version
if [ $? -ne 0 ]; then
    echo "❌ Java未安装或未配置PATH"
    exit 1
fi

# 检查Maven版本
echo "📋 检查Maven版本..."
mvn -version
if [ $? -ne 0 ]; then
    echo "❌ Maven未安装或未配置PATH"
    exit 1
fi

echo ""
echo "🔧 选择测试方式:"
echo "1) 运行单元测试 (推荐)"
echo "2) 启动应用进行集成测试"
echo "3) 使用Docker Compose启动完整环境"
echo "4) 退出"
echo ""

read -p "请选择 (1-4): " choice

case $choice in
    1)
        echo "🧪 运行单元测试..."
        mvn clean test
        ;;
    2)
        echo "🚀 启动应用进行集成测试..."
        echo "注意: 这将启动应用但Trino连接会失败，您可以测试健康检查接口"
        mvn spring-boot:run -Dspring.profiles.active=test
        ;;
    3)
        echo "🐳 使用Docker Compose启动完整环境..."
        echo "注意: 需要安装Docker和Docker Compose"
        
        # 检查Docker
        docker --version
        if [ $? -ne 0 ]; then
            echo "❌ Docker未安装"
            exit 1
        fi
        
        # 检查Docker Compose
        docker-compose --version
        if [ $? -ne 0 ]; then
            echo "❌ Docker Compose未安装"
            exit 1
        fi
        
        echo "启动Docker环境..."
        docker-compose -f docker-compose-dev.yml up -d
        
        echo "等待服务启动..."
        sleep 30
        
        echo "测试健康检查..."
        curl -s http://localhost:8081/api/health | jq .
        
        echo "测试GraphQL接口..."
        curl -s -X POST http://localhost:8081/api/graphql \
            -H "Content-Type: application/json" \
            -d '{"query":"{ tables { tableName } }"}' | jq .
        
        echo ""
        echo "✅ 服务已启动!"
        echo "📊 GraphiQL界面: http://localhost:8081/api/graphiql"
        echo "🏥 健康检查: http://localhost:8081/api/health"
        echo "🔍 GraphQL端点: http://localhost:8081/api/graphql"
        ;;
    4)
        echo "👋 再见!"
        exit 0
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac 