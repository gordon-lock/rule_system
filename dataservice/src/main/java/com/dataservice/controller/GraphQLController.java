package com.dataservice.controller;

import com.dataservice.model.TableMetadata;
import com.dataservice.service.MetadataService;
import com.dataservice.service.QueryService;
import com.dataservice.service.ComplexQueryService;
import org.eclipse.microprofile.graphql.*;

import jakarta.inject.Inject;
import java.util.List;
import java.util.Map;

@GraphQLApi
public class GraphQLController {

    private final MetadataService metadataService;
    private final QueryService queryService;
    private final ComplexQueryService complexQueryService;

    @Inject
    public GraphQLController(MetadataService metadataService, QueryService queryService, ComplexQueryService complexQueryService) {
        this.metadataService = metadataService;
        this.queryService = queryService;
        this.complexQueryService = complexQueryService;
    }

    @Query("tables")
    @Description("Get all tables metadata")
    public List<TableMetadata> tables() {
        return metadataService.getAllTables();
    }

    @Query("table")
    @Description("Get table metadata by name")
    public TableMetadata table(@Name("name") String name) {
        return metadataService.getTableMetadata(name);
    }

    @Query("tableWithSchema")
    @Description("Get table metadata by schema and name")
    public TableMetadata tableWithSchema(@Name("schema") String schema, @Name("name") String name) {
        return metadataService.getTableMetadata(schema, name);
    }

    @Query("schemas")
    @Description("Get all schemas")
    public List<String> schemas() {
        return metadataService.getSchemas();
    }

    @Query("query")
    @Description("Execute raw SQL query")
    public QueryService.QueryResult query(@Name("sql") String sql) {
        return queryService.executeQuery(sql);
    }

    @Query("queryTable")
    @Description("Query table with conditions")
    public QueryService.QueryResult queryTable(@Name("tableName") String tableName, 
                                              @Name("whereClause") String whereClause, 
                                              @Name("orderBy") String orderBy, 
                                              @Name("limit") Integer limit) {
        int queryLimit = limit != null ? limit : 1000;
        return queryService.executeTableQuery(tableName, whereClause, orderBy, queryLimit);
    }

    @Query("queryTableWithSchema")
    @Description("Query table with schema and conditions")
    public QueryService.QueryResult queryTableWithSchema(@Name("schema") String schema,
                                                        @Name("tableName") String tableName, 
                                                        @Name("whereClause") String whereClause, 
                                                        @Name("orderBy") String orderBy, 
                                                        @Name("limit") Integer limit) {
        int queryLimit = limit != null ? limit : 1000;
        return queryService.executeTableQuery(schema, tableName, whereClause, orderBy, queryLimit);
    }

    @Query("getUserOrders")
    @Description("Get user orders")
    public QueryService.QueryResult getUserOrders(@Name("limit") Integer limit, @Name("userId") String userId) {
        String sql = String.format("SELECT * FROM orders WHERE user_id = '%s' LIMIT %d", userId, limit != null ? limit : 10);
        return queryService.executeQuery(sql);
    }

    @Query("getUserInfo")
    @Description("Get user information")
    public QueryService.QueryResult getUserInfo(@Name("userId") String userId) {
        String sql = String.format("SELECT id, name, email, age FROM users WHERE id = %s", userId);
        return queryService.executeQuery(sql);
    }

    @Query("getUserWithOrders")
    @Description("Get user with orders (complex join)")
    public QueryService.QueryResult getUserWithOrders(@Name("userId") String userId, @Name("orderLimit") Integer orderLimit) {
        String sql = String.format(
            "SELECT u.id, u.name, u.email, u.age, " +
            "o.order_id, o.amount, o.status, o.order_date " +
            "FROM users u " +
            "LEFT JOIN orders o ON u.id = o.user_id " +
            "WHERE u.id = '%s' " +
            "ORDER BY o.order_date DESC " +
            "LIMIT %d", 
            userId, orderLimit != null ? orderLimit : 10
        );
        return queryService.executeQuery(sql);
    }

    @Query("getUserOrderStats")
    @Description("Get user order statistics")
    public QueryService.QueryResult getUserOrderStats(@Name("userId") String userId) {
        String sql = String.format(
            "SELECT " +
            "COUNT(*) as total_orders, " +
            "SUM(amount) as total_amount, " +
            "AVG(amount) as avg_amount, " +
            "MAX(order_date) as last_order_date " +
            "FROM orders " +
            "WHERE user_id = '%s'", 
            userId
        );
        return queryService.executeQuery(sql);
    }

    @Query("searchUsersAndOrders")
    @Description("Search users and orders")
    public QueryService.QueryResult searchUsersAndOrders(@Name("searchTerm") String searchTerm, @Name("limit") Integer limit) {
        String sql = String.format(
            "SELECT u.id, u.name, u.email, " +
            "o.order_id, o.amount, o.status " +
            "FROM users u " +
            "LEFT JOIN orders o ON u.id = o.user_id " +
            "WHERE u.name LIKE '%%%s%%' OR u.email LIKE '%%%s%%' " +
            "ORDER BY u.name, o.order_date DESC " +
            "LIMIT %d",
            searchTerm, searchTerm, limit != null ? limit : 20
        );
        return queryService.executeQuery(sql);
    }

    // Schema mappings for nested fields
    public List<String> getColumns(TableMetadata table) {
        return table.getColumns().stream()
                .map(column -> String.format("{\"name\":\"%s\",\"type\":\"%s\",\"nullable\":%s,\"comment\":\"%s\"}", 
                        column.getColumnName(),
                        column.getDataType(),
                        column.isNullable(),
                        column.getComment() != null ? column.getComment() : ""))
                .toList();
    }

    public List<String> getPartitions(TableMetadata table) {
        return table.getPartitions();
    }

    public List<String> getData(QueryService.QueryResult result) {
        return result.getData().stream()
                .map(row -> row.toString())
                .toList();
    }

    public long getExecutionTime(QueryService.QueryResult result) {
        return result.getExecutionTimeMs();
    }

    public String getSql(QueryService.QueryResult result) {
        return result.getExecutedSql();
    }

    public int getRowCount(QueryService.QueryResult result) {
        return result.getRowCount();
    }
} 