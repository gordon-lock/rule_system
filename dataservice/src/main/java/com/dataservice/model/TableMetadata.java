package com.dataservice.model;

import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Description;
import java.util.List;

@Description("Table metadata information")
public class TableMetadata {
    @Name("catalog")
    @Description("Database catalog name")
    private String catalog;
    
    @Name("schema")
    @Description("Database schema name")
    private String schema;
    
    @Name("tableName")
    @Description("Table name")
    private String tableName;
    
    @Name("tableType")
    @Description("Table type (BASE TABLE, VIEW, etc.)")
    private String tableType;
    
    @Name("columns")
    @Description("List of table columns")
    private List<ColumnMetadata> columns;
    
    @Name("partitions")
    @Description("List of partition columns")
    private List<String> partitions;

    public TableMetadata() {}

    public TableMetadata(String catalog, String schema, String tableName, String tableType) {
        this.catalog = catalog;
        this.schema = schema;
        this.tableName = tableName;
        this.tableType = tableType;
    }

    // Getters and Setters
    public String getCatalog() {
        return catalog;
    }

    public void setCatalog(String catalog) {
        this.catalog = catalog;
    }

    public String getSchema() {
        return schema;
    }

    public void setSchema(String schema) {
        this.schema = schema;
    }

    public String getTableName() {
        return tableName;
    }

    public void setTableName(String tableName) {
        this.tableName = tableName;
    }

    public String getTableType() {
        return tableType;
    }

    public void setTableType(String tableType) {
        this.tableType = tableType;
    }

    public List<ColumnMetadata> getColumns() {
        return columns;
    }

    public void setColumns(List<ColumnMetadata> columns) {
        this.columns = columns;
    }

    public List<String> getPartitions() {
        return partitions;
    }

    public void setPartitions(List<String> partitions) {
        this.partitions = partitions;
    }

    public String getFullTableName() {
        return String.format("%s.%s.%s", catalog, schema, tableName);
    }
} 