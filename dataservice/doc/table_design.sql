CREATE TABLE table_registry (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL UNIQUE,
    datasource_type VARCHAR(50) NOT NULL DEFAULT 'TRINO',
    catalog_name VARCHAR(100),
    schema_name VARCHAR(100),
    description TEXT,
    business_owner VARCHAR(100),
    technical_owner VARCHAR(100),
    is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    registration_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (registration_status IN ('PENDING', 'APPROVED', 'REJECTED', 'DEPRECATED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_by VARCHAR(100) NOT NULL
);


CREATE TABLE codegen_tasks (
    task_id BIGSERIAL PRIMARY KEY,
    table_id BIGINT NOT NULL REFERENCES table_registry(id) ON DELETE CASCADE,
    schema_version INT NOT NULL,
    task_type VARCHAR(30) NOT NULL
        CHECK (task_type IN ('INITIAL', 'SCHEMA_CHANGE', 'CONFIG_CHANGE', 'MANUAL_TRIGGER')),
    trigger_source VARCHAR(30) NOT NULL
        CHECK (trigger_source IN ('API', 'SCHEDULED', 'WEBHOOK', 'MANUAL')),
    priority INT NOT NULL DEFAULT 50
        CHECK (priority BETWEEN 0 AND 100),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED')),
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    processed_by VARCHAR(100),
    timeout_seconds INT NOT NULL DEFAULT 300,
    current_retry_count INT NOT NULL DEFAULT 0,
    max_retry_count INT NOT NULL DEFAULT 3,
    UNIQUE(table_id, schema_version, task_type)
        WHERE status IN ('PENDING', 'PROCESSING')
);


CREATE TABLE codegen_task_details (
    detail_id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES codegen_tasks(task_id) ON DELETE CASCADE,
    generation_target VARCHAR(30) NOT NULL
        CHECK (generation_target IN ('TYPE_DEF', 'RESOLVER', 'DATA_FETCHER', 'SCHEMA', 'ALL')),
    artifact_type VARCHAR(20) NOT NULL
        CHECK (artifact_type IN ('GRAPHQL', 'JAVA', 'KOTLIN', 'SCALA')),
    source_template VARCHAR(100),
    output_path VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'SKIPPED')),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    error_message TEXT,
    artifact_content_hash VARCHAR(64),
    generated_artifact_path VARCHAR(500)
);


CREATE TABLE codegen_artifacts (
    artifact_id BIGSERIAL PRIMARY KEY,
    table_id BIGINT NOT NULL REFERENCES table_registry(id) ON DELETE CASCADE,
    version_tag VARCHAR(50) NOT NULL,
    task_id BIGINT REFERENCES codegen_tasks(task_id),
    artifact_type VARCHAR(20) NOT NULL
        CHECK (artifact_type IN ('TYPE_DEF', 'RESOLVER', 'DATA_FETCHER', 'SCHEMA')),
    artifact_path VARCHAR(500) NOT NULL,
    content_hash VARCHAR(64) NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generated_by VARCHAR(100) NOT NULL,
    UNIQUE(table_id, version_tag, artifact_type, artifact_path)
);

CREATE INDEX idx_codegen_artifacts_current ON codegen_artifacts(table_id, is_current);



CREATE TABLE task_execution_logs (
    log_id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL REFERENCES codegen_tasks(task_id) ON DELETE CASCADE,
    log_level VARCHAR(10) NOT NULL
        CHECK (log_level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    log_message TEXT NOT NULL,
    log_context JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_task_execution_logs_task ON task_execution_logs(task_id);
CREATE INDEX idx_task_execution_logs_time ON task_execution_logs(created_at);

CREATE TABLE schema_change_comparison (
    comparison_id BIGSERIAL PRIMARY KEY,
    table_id BIGINT NOT NULL REFERENCES table_registry(id) ON DELETE CASCADE,
    old_version_id BIGINT REFERENCES entity_versions(version_id),
    new_version_id BIGINT NOT NULL REFERENCES entity_versions(version_id),
    comparison_type VARCHAR(20) NOT NULL
        CHECK (comparison_type IN ('AUTO_GENERATED', 'MANUAL_REVIEW', 'SCHEDULED')),
    comparison_result JSONB NOT NULL,
    change_severity VARCHAR(20) NOT NULL
        CHECK (change_severity IN ('BREAKING', 'NON_BREAKING', 'PATCH')),
    detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detected_by VARCHAR(100) NOT NULL,
    comparison_duration_ms INT,
    UNIQUE(table_id, old_version_id, new_version_id)
);

CREATE TABLE field_change_details (
    detail_id BIGSERIAL PRIMARY KEY,
    comparison_id BIGINT NOT NULL REFERENCES schema_change_comparison(comparison_id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    change_type VARCHAR(20) NOT NULL
        CHECK (change_type IN ('ADDED', 'REMOVED', 'MODIFIED', 'MOVED')),
    old_field_type VARCHAR(100),
    new_field_type VARCHAR(100),
    old_nullable BOOLEAN,
    new_nullable BOOLEAN,
    old_default_value VARCHAR(500),
    new_default_value VARCHAR(500),
    old_annotations JSONB,
    new_annotations JSONB,
    is_breaking BOOLEAN NOT NULL,
    description TEXT
);

CREATE INDEX idx_field_change_comparison ON field_change_details(comparison_id);
CREATE INDEX idx_field_change_breaking ON field_change_details(is_breaking);


CREATE TABLE class_level_changes (
    change_id BIGSERIAL PRIMARY KEY,
    comparison_id BIGINT NOT NULL REFERENCES schema_change_comparison(comparison_id) ON DELETE CASCADE,
    change_category VARCHAR(50) NOT NULL
        CHECK (change_category IN ('ANNOTATION', 'INHERITANCE', 'ACCESS_MODIFIER', 'OTHER')),
    change_type VARCHAR(20) NOT NULL
        CHECK (change_type IN ('ADDED', 'REMOVED', 'MODIFIED')),
    old_value TEXT,
    new_value TEXT,
    is_breaking BOOLEAN NOT NULL,
    description TEXT
);

CREATE INDEX idx_class_change_comparison ON class_level_changes(comparison_id);

CREATE TABLE api_versions (
    version_id BIGSERIAL PRIMARY KEY,
    table_id BIGINT NOT NULL REFERENCES table_registry(id) ON DELETE CASCADE,
    version_tag VARCHAR(50) NOT NULL, -- v1, v2, etc.
    base_entity_version_id BIGINT NOT NULL REFERENCES entity_versions(version_id),
    graphql_schema_hash VARCHAR(64) NOT NULL,
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    is_deprecated BOOLEAN NOT NULL DEFAULT FALSE,
    deprecation_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    UNIQUE(table_id, version_tag)
);

CREATE INDEX idx_api_versions_current ON api_versions(table_id, is_current);


CREATE TABLE api_endpoints (
    endpoint_id BIGSERIAL PRIMARY KEY,
    version_id BIGINT NOT NULL REFERENCES api_versions(version_id) ON DELETE CASCADE,
    endpoint_path VARCHAR(500) NOT NULL,
    http_method VARCHAR(10) NOT NULL DEFAULT 'POST',
    operation_type VARCHAR(20) NOT NULL
        CHECK (operation_type IN ('QUERY', 'MUTATION', 'SUBSCRIPTION')),
    operation_name VARCHAR(255) NOT NULL,
    description TEXT,
    requires_authentication BOOLEAN NOT NULL DEFAULT TRUE,
    required_permissions JSONB, -- {"read": ["role1", "role2"], "write": ["admin"]}
    rate_limit_per_hour INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(version_id, operation_type, operation_name)
);

CREATE INDEX idx_api_endpoints_path ON api_endpoints(endpoint_path);
CREATE INDEX idx_api_endpoints_active ON api_endpoints(is_active);

CREATE TABLE api_version_changes (
    change_id BIGSERIAL PRIMARY KEY,
    version_id BIGINT NOT NULL REFERENCES api_versions(version_id) ON DELETE CASCADE,
    previous_version_id BIGINT REFERENCES api_versions(version_id),
    change_reason VARCHAR(50) NOT NULL
        CHECK (change_reason IN ('SCHEMA_CHANGE', 'CONFIG_CHANGE', 'BUG_FIX', 'FEATURE_ADD')),
    change_description TEXT NOT NULL,
    is_breaking_change BOOLEAN NOT NULL,
    comparison_id BIGINT REFERENCES schema_change_comparison(comparison_id),
    changed_by VARCHAR(100) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_version_changes ON api_version_changes(version_id);