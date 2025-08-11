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
public class QueryServiceImpl implements QueryService {
    
    private static final Logger logger = LoggerFactory.getLogger(QueryServiceImpl.class);
    
    private final DataSource dataSource;

    @Inject
    public QueryServiceImpl(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public QueryResult executeQuery(String sql) {
        long startTime = System.currentTimeMillis();
        
        try (Connection conn = dataSource.getConnection()) {
            logger.info("Executing SQL: {}", sql);
            
            List<Map<String, Object>> results = new ArrayList<>();
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String columnName = metaData.getColumnName(i);
                        Object value = rs.getObject(i);
                        row.put(columnName, value);
                    }
                    results.add(row);
                }
            }
            
            long executionTime = System.currentTimeMillis() - startTime;
            return new QueryResult(results, executionTime, sql);
            
        } catch (SQLException e) {
            long executionTime = System.currentTimeMillis() - startTime;
            logger.error("Query execution failed: {}", e.getMessage(), e);
            throw new RuntimeException("Query execution failed: " + e.getMessage(), e);
        }
    }

    @Override
    public QueryResult executeTableQuery(String tableName, String whereClause, String orderBy, int limit) {
        return executeTableQuery("default", tableName, whereClause, orderBy, limit);
    }

    @Override
    public QueryResult executeTableQuery(String schema, String tableName, String whereClause, String orderBy, int limit) {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT * FROM ").append(schema).append(".").append(tableName);
        
        if (whereClause != null && !whereClause.trim().isEmpty()) {
            sql.append(" WHERE ").append(whereClause);
        }
        
        if (orderBy != null && !orderBy.trim().isEmpty()) {
            sql.append(" ORDER BY ").append(orderBy);
        }
        
        sql.append(" LIMIT ").append(limit);
        
        return executeQuery(sql.toString());
    }
} 