package com.dataservice.config;

import io.agroal.api.AgroalDataSource;
import io.quarkus.agroal.DataSource;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

@ApplicationScoped
public class TrinoConfig {

    @Inject
    AgroalDataSource dataSource;

    @ConfigProperty(name = "trino.catalog", defaultValue = "iceberg")
    String catalog;

    @ConfigProperty(name = "trino.schema", defaultValue = "default")
    String schema;

    @ConfigProperty(name = "trino.server-url", defaultValue = "http://localhost:8080")
    String serverUrl;

    @ConfigProperty(name = "trino.query-timeout", defaultValue = "300")
    int queryTimeout;

    @ConfigProperty(name = "trino.max-rows", defaultValue = "10000")
    int maxRows;

    public AgroalDataSource getDataSource() {
        return dataSource;
    }

    public String getCatalog() {
        return catalog;
    }

    public String getSchema() {
        return schema;
    }

    public String getServerUrl() {
        return serverUrl;
    }

    public int getQueryTimeout() {
        return queryTimeout;
    }

    public int getMaxRows() {
        return maxRows;
    }
} 