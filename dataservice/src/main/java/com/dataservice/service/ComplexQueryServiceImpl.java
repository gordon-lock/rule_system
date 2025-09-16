package com.dataservice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
public class ComplexQueryServiceImpl implements ComplexQueryService {
    
    private static final Logger logger = LoggerFactory.getLogger(ComplexQueryServiceImpl.class);
    
    private final DataSource dataSource;

    @Inject
    public ComplexQueryServiceImpl(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public QueryService.QueryResult executeComplexQuery(String queryType, Map<String, String> parameters) {
        long startTime = System.currentTimeMillis();
        
        try (Connection conn = dataSource.getConnection()) {
            String sql = buildComplexQuery(queryType, parameters);
            logger.info("Executing complex query: {}", sql);
            
            List<Map<String, String>> results = new ArrayList<>();
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                
                while (rs.next()) {
                    Map<String, String> row = new HashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String columnName = metaData.getColumnName(i);
                        String value = rs.getObject(i).toString();
                        row.put(columnName, value);
                    }
                    results.add(row);
                }
            }
            
            long executionTime = System.currentTimeMillis() - startTime;
            return new QueryService.QueryResult(results, executionTime, sql);
            
        } catch (SQLException e) {
            long executionTime = System.currentTimeMillis() - startTime;
            logger.error("Complex query execution failed: {}", e.getMessage(), e);
            throw new RuntimeException("Complex query execution failed: " + e.getMessage(), e);
        }
    }

    /**
     * 构建复杂查询SQL
     */
    private String buildComplexQuery(String queryType, Map<String, String> parameters) {
        switch (queryType) {
            case "user_with_orders":
                return buildUserWithOrdersQuery(parameters);
            case "user_order_stats":
                return buildUserOrderStatsQuery(parameters);
            case "search_users_orders":
                return buildSearchUsersOrdersQuery(parameters);
            case "multi_table_aggregation":
                return buildMultiTableAggregationQuery(parameters);
            default:
                throw new IllegalArgumentException("Unknown query type: " + queryType);
        }
    }

    /**
     * 构建用户和订单关联查询
     */
    private String buildUserWithOrdersQuery(Map<String, String> params) {
        String userId = (String) params.get("userId");
        Integer limit = Integer.valueOf(params.getOrDefault("limit", "10"));
        
        return String.format(
            "SELECT u.id, u.name, u.email, u.age, " +
            "o.order_id, o.amount, o.status, o.order_date " +
            "FROM users u " +
            "LEFT JOIN orders o ON u.id = o.user_id " +
            "WHERE u.id = '%s' " +
            "ORDER BY o.order_date DESC " +
            "LIMIT %d", 
            userId, limit
        );
    }

    /**
     * 构建用户订单统计查询
     */
    private String buildUserOrderStatsQuery(Map<String, String> params) {
        String userId = (String) params.get("userId");
        
        return String.format(
            "SELECT " +
            "COUNT(*) as total_orders, " +
            "SUM(amount) as total_amount, " +
            "AVG(amount) as avg_amount, " +
            "MAX(order_date) as last_order_date, " +
            "MIN(order_date) as first_order_date " +
            "FROM orders " +
            "WHERE user_id = '%s'", 
            userId
        );
    }

    /**
     * 构建搜索用户和订单查询
     */
    private String buildSearchUsersOrdersQuery(Map<String, String> params) {
        String searchTerm = (String) params.get("searchTerm");
        Integer limit = Integer.valueOf(params.getOrDefault("limit", "20"));
        
        return String.format(
            "SELECT u.id, u.name, u.email, u.age, " +
            "o.order_id, o.amount, o.status, o.order_date " +
            "FROM users u " +
            "LEFT JOIN orders o ON u.id = o.user_id " +
            "WHERE u.name LIKE '%%%s%%' OR u.email LIKE '%%%s%%' " +
            "ORDER BY u.name, o.order_date DESC " +
            "LIMIT %d",
            searchTerm, searchTerm, limit
        );
    }

    /**
     * 构建多表聚合查询
     */
    private String buildMultiTableAggregationQuery(Map<String, String> params) {
        String groupBy = (String) params.getOrDefault("groupBy", "user_id");
        Integer limit = Integer.valueOf(params.getOrDefault("limit", "10"));
        
        return String.format(
            "SELECT u.name, u.email, " +
            "COUNT(o.order_id) as order_count, " +
            "SUM(o.amount) as total_spent, " +
            "AVG(o.amount) as avg_order_value " +
            "FROM users u " +
            "LEFT JOIN orders o ON u.id = o.user_id " +
            "GROUP BY u.id, u.name, u.email " +
            "ORDER BY total_spent DESC " +
            "LIMIT %d",
            limit
        );
    }

    @Override
    public Map<String, QueryService.QueryResult> executeBatchQueries(Map<String, Map<String, String>> queries) {
        Map<String, QueryService.QueryResult> results = new HashMap<>();
        
        for (Map.Entry<String, Map<String, String>> entry : queries.entrySet()) {
            String queryName = entry.getKey();
            Map<String, String> params = entry.getValue();
            
            try {
                QueryService.QueryResult result = executeComplexQuery(queryName, params);
                results.put(queryName, result);
            } catch (Exception e) {
                logger.error("Failed to execute query {}: {}", queryName, e.getMessage());
                // 可以选择继续执行其他查询或抛出异常
            }
        }
        
        return results;
    }
} 