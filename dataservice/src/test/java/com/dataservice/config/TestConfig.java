package com.dataservice.config;

import com.dataservice.model.ColumnMetadata;
import com.dataservice.model.TableMetadata;
import com.dataservice.service.MetadataService;
import com.dataservice.service.QueryService;
import com.dataservice.service.ComplexQueryService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sql.DataSource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
public class TestConfig {

    private static final Logger logger = LoggerFactory.getLogger(TestConfig.class);

    @Produces
    @ApplicationScoped
    @jakarta.enterprise.inject.Alternative
    public MetadataService mockMetadataService(DataSource dataSource) {
        return new MockMetadataService();
    }

    @Produces
    @ApplicationScoped
    @jakarta.enterprise.inject.Alternative
    public QueryService mockQueryService(DataSource dataSource) {
        return new MockQueryService();
    }

    @Produces
    @ApplicationScoped
    @jakarta.enterprise.inject.Alternative
    public ComplexQueryService mockComplexQueryService(DataSource dataSource) {
        return new MockComplexQueryService();
    }

    // Mock implementations
    private static class MockMetadataService implements MetadataService {
        @Override
        public List<TableMetadata> getAllTables() {
            logger.info("Mock: Getting all tables");
            
            List<TableMetadata> tables = new ArrayList<>();
            
            // Mock table 1
            TableMetadata table1 = new TableMetadata();
            table1.setCatalog("iceberg");
            table1.setSchema("default");
            table1.setTableName("users");
            table1.setTableType("BASE TABLE");
            table1.setColumns(Arrays.asList(
                new ColumnMetadata("id", "bigint", "User ID", false),
                new ColumnMetadata("name", "varchar", "User name", true),
                new ColumnMetadata("email", "varchar", "User email", true),
                new ColumnMetadata("age", "integer", "User age", true)
            ));
            table1.setPartitions(Arrays.asList("id"));
            tables.add(table1);
            
            // Mock table 2
            TableMetadata table2 = new TableMetadata();
            table2.setCatalog("iceberg");
            table2.setSchema("default");
            table2.setTableName("orders");
            table2.setTableType("BASE TABLE");
            table2.setColumns(Arrays.asList(
                new ColumnMetadata("order_id", "bigint", "Order ID", false),
                new ColumnMetadata("user_id", "bigint", "User ID", false),
                new ColumnMetadata("amount", "decimal", "Order amount", true),
                new ColumnMetadata("status", "varchar", "Order status", true),
                new ColumnMetadata("order_date", "timestamp", "Order date", true)
            ));
            table2.setPartitions(Arrays.asList("order_date"));
            tables.add(table2);
            
            return tables;
        }

        @Override
        public TableMetadata getTableMetadata(String tableName) {
            return getTableMetadata("default", tableName);
        }

        @Override
        public TableMetadata getTableMetadata(String schema, String tableName) {
            logger.info("Mock: Getting table metadata for {}.{}", schema, tableName);
            
            if ("users".equals(tableName)) {
                TableMetadata table = new TableMetadata();
                table.setCatalog("iceberg");
                table.setSchema(schema);
                table.setTableName(tableName);
                table.setTableType("BASE TABLE");
                table.setColumns(Arrays.asList(
                    new ColumnMetadata("id", "bigint", "User ID", false),
                    new ColumnMetadata("name", "varchar", "User name", true),
                    new ColumnMetadata("email", "varchar", "User email", true),
                    new ColumnMetadata("age", "integer", "User age", true)
                ));
                table.setPartitions(Arrays.asList("id"));
                return table;
            } else if ("orders".equals(tableName)) {
                TableMetadata table = new TableMetadata();
                table.setCatalog("iceberg");
                table.setSchema(schema);
                table.setTableName(tableName);
                table.setTableType("BASE TABLE");
                table.setColumns(Arrays.asList(
                    new ColumnMetadata("order_id", "bigint", "Order ID", false),
                    new ColumnMetadata("user_id", "bigint", "User ID", false),
                    new ColumnMetadata("amount", "decimal", "Order amount", true),
                    new ColumnMetadata("status", "varchar", "Order status", true),
                    new ColumnMetadata("order_date", "timestamp", "Order date", true)
                ));
                table.setPartitions(Arrays.asList("order_date"));
                return table;
            }
            return null; // Return null for non-existent tables
        }

        @Override
        public List<String> getSchemas() {
            return Arrays.asList("default", "sales", "analytics");
        }
    }

    private static class MockQueryService implements QueryService {
        @Override
        public QueryService.QueryResult executeQuery(String sql) {
            logger.info("Mock: Executing query: {}", sql);
            
            List<Map<String, Object>> data = new ArrayList<>();
            
            if (sql.toLowerCase().contains("users")) {
                data.add(Map.of("id", 1L, "name", "John Doe", "email", "john@example.com", "age", 30));
                data.add(Map.of("id", 2L, "name", "Jane Smith", "email", "jane@example.com", "age", 25));
                data.add(Map.of("id", 3L, "name", "Bob Johnson", "email", "bob@example.com", "age", 35));
            } else if (sql.toLowerCase().contains("orders")) {
                data.add(Map.of("order_id", 1001L, "user_id", 1L, "amount", 150.50, "status", "completed"));
                data.add(Map.of("order_id", 1002L, "user_id", 2L, "amount", 75.25, "status", "pending"));
                data.add(Map.of("order_id", 1003L, "user_id", 1L, "amount", 200.00, "status", "completed"));
            } else {
                data.add(Map.of("result", "Mock query executed successfully", "sql", sql));
            }
            
            return new QueryService.QueryResult(data, 50L, sql);
        }

        @Override
        public QueryService.QueryResult executeTableQuery(String tableName, String whereClause, String orderBy, int limit) {
            return executeTableQuery("default", tableName, whereClause, orderBy, limit);
        }

        @Override
        public QueryService.QueryResult executeTableQuery(String schema, String tableName, String whereClause, String orderBy, int limit) {
            logger.info("Mock: Executing table query for {}.{}", schema, tableName);
            return executeQuery("SELECT * FROM " + schema + "." + tableName);
        }
    }

    private static class MockComplexQueryService implements ComplexQueryService {
        @Override
        public QueryService.QueryResult executeComplexQuery(String queryType, Map<String, Object> parameters) {
            logger.info("Mock: Executing complex query: {}", queryType);
            
            List<Map<String, Object>> data = new ArrayList<>();
            
            switch (queryType) {
                case "userWithOrders":
                    data.add(Map.of("user_id", 1L, "user_name", "John Doe", "order_count", 2, "total_amount", 350.50));
                    data.add(Map.of("user_id", 2L, "user_name", "Jane Smith", "order_count", 1, "total_amount", 75.25));
                    break;
                case "userOrderStats":
                    data.add(Map.of("user_id", 1L, "total_orders", 2, "total_amount", 350.50, "avg_amount", 175.25));
                    break;
                default:
                    data.add(Map.of("result", "Mock complex query executed", "type", queryType));
            }
            
            return new QueryService.QueryResult(data, 100L, "Mock complex query: " + queryType);
        }

        @Override
        public Map<String, QueryService.QueryResult> executeBatchQueries(Map<String, Map<String, Object>> queries) {
            logger.info("Mock: Executing batch queries");
            
            Map<String, QueryService.QueryResult> results = new HashMap<>();
            for (String queryName : queries.keySet()) {
                results.put(queryName, executeComplexQuery(queryName, queries.get(queryName)));
            }
            
            return results;
        }
    }
} 