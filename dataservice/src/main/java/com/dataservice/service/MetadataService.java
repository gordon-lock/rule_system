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
import java.util.Map;

public interface MetadataService {
    
    List<TableMetadata> getAllTables();
    
    TableMetadata getTableMetadata(String tableName);
    
    TableMetadata getTableMetadata(String schema, String tableName);
    
    List<String> getSchemas();
} 