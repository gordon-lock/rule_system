package com.dataservice.service;

import java.util.List;
import java.util.Map;

public interface ComplexQueryService {
    
    QueryService.QueryResult executeComplexQuery(String queryType, Map<String, String> parameters);
    
    Map<String, QueryService.QueryResult> executeBatchQueries(Map<String, Map<String, String>> queries);
} 