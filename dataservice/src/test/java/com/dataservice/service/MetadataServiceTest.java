package com.dataservice.service;

import com.dataservice.model.TableMetadata;
import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@QuarkusTest
class MetadataServiceTest {

    @Inject
    private MetadataService metadataService;

    @Test
    void testGetAllTables() {
        List<TableMetadata> tables = metadataService.getAllTables();
        
        assertNotNull(tables);
        assertFalse(tables.isEmpty());
        
        // Check if we have the expected mock tables
        boolean hasUsersTable = tables.stream()
                .anyMatch(table -> "users".equals(table.getTableName()));
        boolean hasOrdersTable = tables.stream()
                .anyMatch(table -> "orders".equals(table.getTableName()));
        
        assertTrue(hasUsersTable, "Should contain users table");
        assertTrue(hasOrdersTable, "Should contain orders table");
    }

    @Test
    void testGetTableMetadata() {
        TableMetadata usersTable = metadataService.getTableMetadata("users");
        
        assertNotNull(usersTable);
        assertEquals("users", usersTable.getTableName());
        assertEquals("iceberg", usersTable.getCatalog());
        assertEquals("default", usersTable.getSchema());
        
        // Check columns
        assertNotNull(usersTable.getColumns());
        assertFalse(usersTable.getColumns().isEmpty());
        
        // Check if it has expected columns
        boolean hasIdColumn = usersTable.getColumns().stream()
                .anyMatch(col -> "id".equals(col.getColumnName()));
        boolean hasNameColumn = usersTable.getColumns().stream()
                .anyMatch(col -> "name".equals(col.getColumnName()));
        
        assertTrue(hasIdColumn, "Should have id column");
        assertTrue(hasNameColumn, "Should have name column");
    }

    @Test
    void testGetSchemas() {
        List<String> schemas = metadataService.getSchemas();
        
        assertNotNull(schemas);
        assertFalse(schemas.isEmpty());
        assertTrue(schemas.contains("default"), "Should contain default schema");
    }

    @Test
    void testGetTableMetadataNotFound() {
        // In mock mode, this should return null instead of throwing exception
        TableMetadata result = metadataService.getTableMetadata("nonexistent_table");
        assertNull(result, "Should return null for non-existent table");
    }
} 