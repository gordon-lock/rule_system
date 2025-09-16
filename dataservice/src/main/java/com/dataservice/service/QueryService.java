package com.dataservice.service;

import java.util.List;
import java.util.Map;

public interface QueryService {
    
    QueryResult executeQuery(String sql);
    
    QueryResult executeTableQuery(String tableName, String whereClause, String orderBy, int limit);
    
    QueryResult executeTableQuery(String schema, String tableName, String whereClause, String orderBy, int limit);

    class QueryResult {
        private final List<Map<String, String>> data;
        private final long executionTimeMs;
        private final String executedSql;

        public QueryResult(List<Map<String, String>> data, long executionTimeMs, String executedSql) {
            this.data = data;
            this.executionTimeMs = executionTimeMs;
            this.executedSql = executedSql;
        }

        public List<Map<String, String>> getData() {
            return data;
        }

        public long getExecutionTimeMs() {
            return executionTimeMs;
        }

        public String getExecutedSql() {
            return executedSql;
        }

        public int getRowCount() {
            return data != null ? data.size() : 0;
        }
    }
} 