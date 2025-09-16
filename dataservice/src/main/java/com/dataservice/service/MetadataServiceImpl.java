package com.dataservice.service;

import com.dataservice.model.ColumnMetadata;
import com.dataservice.model.TableMetadata;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@ApplicationScoped
public class MetadataServiceImpl implements MetadataService {
    
    private static final Logger logger = LoggerFactory.getLogger(MetadataServiceImpl.class);
    
    private final DataSource dataSource;

    @Inject
    public MetadataServiceImpl(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public List<TableMetadata> getAllTables() {
        try (Connection conn = dataSource.getConnection()) {
            String sql = "SELECT table_catalog, table_schema, table_name, table_type " +
                        "FROM information_schema.tables " +
                        "WHERE table_schema NOT IN ('information_schema', 'sys') " +
                        "ORDER BY table_schema, table_name";

            logger.info("Executing SQL: {}", sql);

            List<TableMetadata> tables = new ArrayList<>();
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {
                    TableMetadata table = new TableMetadata();
                    table.setCatalog(rs.getString("table_catalog"));
                    table.setSchema(rs.getString("table_schema"));
                    table.setTableName(rs.getString("table_name"));
                    table.setTableType(rs.getString("table_type"));
                    tables.add(table);
                }
            }

            return tables;

        } catch (SQLException e) {
            logger.error("Failed to get all tables: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to get all tables: " + e.getMessage(), e);
        }
    }

    @Override
    public TableMetadata getTableMetadata(String tableName) {
        return getTableMetadata("default", tableName);
    }

    @Override
    public TableMetadata getTableMetadata(String schema, String tableName) {
        try (Connection conn = dataSource.getConnection()) {
            String sql = "SELECT table_catalog, table_schema, table_name, table_type " +
                        "FROM information_schema.tables " +
                        "WHERE table_schema = ? AND table_name = ?";

            logger.info("Executing SQL: {} with params: schema={}, tableName={}", sql, schema, tableName);

            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, schema);
                stmt.setString(2, tableName);

                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        TableMetadata table = new TableMetadata();
                        table.setCatalog(rs.getString("table_catalog"));
                        table.setSchema(rs.getString("table_schema"));
                        table.setTableName(rs.getString("table_name"));
                        table.setTableType(rs.getString("table_type"));

                        table.setColumns(getTableColumns(conn, schema, tableName));
                        table.setPartitions(getTablePartitions(conn, schema, tableName));

                        return table;
                    }
                }
            }

            return null;

        } catch (SQLException e) {
            logger.error("Failed to get table metadata for {}.{}: {}", schema, tableName, e.getMessage(), e);
            throw new RuntimeException("Failed to get table metadata: " + e.getMessage(), e);
        }
    }

    @Override
    public List<String> getSchemas() {
        try (Connection conn = dataSource.getConnection()) {
            String sql = "SELECT DISTINCT table_schema " +
                        "FROM information_schema.tables " +
                        "WHERE table_schema NOT IN ('information_schema', 'sys') " +
                        "ORDER BY table_schema";

            logger.info("Executing SQL: {}", sql);

            List<String> schemas = new ArrayList<>();
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {

                while (rs.next()) {
                    schemas.add(rs.getString("table_schema"));
                }
            }

            return schemas;

        } catch (SQLException e) {
            logger.error("Failed to get schemas: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to get schemas: " + e.getMessage(), e);
        }
    }

    private List<ColumnMetadata> getTableColumns(Connection conn, String schema, String tableName) throws SQLException {
        String sql = "SELECT column_name, data_type, is_nullable, column_default, column_comment " +
                    "FROM information_schema.columns " +
                    "WHERE table_schema = ? AND table_name = ? " +
                    "ORDER BY ordinal_position";

        List<ColumnMetadata> columns = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, schema);
            stmt.setString(2, tableName);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    ColumnMetadata column = new ColumnMetadata();
                    column.setColumnName(rs.getString("column_name"));
                    column.setDataType(rs.getString("data_type"));
                    column.setNullable("YES".equalsIgnoreCase(rs.getString("is_nullable")));
                    column.setComment(rs.getString("column_comment"));
                    columns.add(column);
                }
            }
        }

        return columns;
    }
//
    private List<String> getTablePartitions(Connection conn, String schema, String tableName) throws SQLException {
        try {
            // For Iceberg tables, we can query partition information
            String sql = "SELECT DISTINCT partition_column " +
                        "FROM information_schema.table_partitions " +
                        "WHERE table_schema = ? AND table_name = ?";

            List<String> partitions = new ArrayList<>();
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, schema);
                stmt.setString(2, tableName);

                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        partitions.add(rs.getString("partition_column"));
                    }
                }
            }

            return partitions;

        } catch (SQLException e) {
            logger.warn("Failed to get partitions for {}.{}: {}", schema, tableName, e.getMessage());
            return new ArrayList<>();
        }
    }
} 