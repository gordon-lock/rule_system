package com.dataservice.model;

public class ColumnMetadata {
    private String columnName;
    private String dataType;
    private String comment;
    private boolean nullable;
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