package com.dataservice.model;

import org.eclipse.microprofile.graphql.Name;
import org.eclipse.microprofile.graphql.Description;

@Description("Column metadata information")
public class ColumnMetadata {
    @Name("name")
    @Description("Column name")
    private String columnName;
    
    @Name("type")
    @Description("Column data type")
    private String dataType;
    
    @Name("comment")
    @Description("Column comment")
    private String comment;
    
    @Name("nullable")
    @Description("Whether the column is nullable")
    private boolean nullable;
    
    @Name("isPartitionColumn")
    @Description("Whether the column is a partition column")
    private boolean isPartitionColumn;

    public ColumnMetadata() {}

    public ColumnMetadata(String columnName, String dataType, String comment, boolean nullable) {
        this.columnName = columnName;
        this.dataType = dataType;
        this.comment = comment;
        this.nullable = nullable;
    }

    // Getters and Setters
    public String getColumnName() {
        return columnName;
    }

    public void setColumnName(String columnName) {
        this.columnName = columnName;
    }

    public String getDataType() {
        return dataType;
    }

    public void setDataType(String dataType) {
        this.dataType = dataType;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }

    public boolean isNullable() {
        return nullable;
    }

    public void setNullable(boolean nullable) {
        this.nullable = nullable;
    }

    public boolean isPartitionColumn() {
        return isPartitionColumn;
    }

    public void setPartitionColumn(boolean partitionColumn) {
        isPartitionColumn = partitionColumn;
    }
} 