简化版自定义查询配置设计

1. 核心表结构

1.1 自定义查询主表 (custom_queries)

CREATE TABLE custom_queries (
    query_id BIGSERIAL PRIMARY KEY,
    query_name VARCHAR(255) NOT NULL UNIQUE,
    table_id BIGINT NOT NULL REFERENCES table_registry(id) ON DELETE CASCADE,
    description TEXT,
    sql_template TEXT NOT NULL,
    sql_engine VARCHAR(20) NOT NULL DEFAULT 'TRINO'
        CHECK (sql_engine IN ('TRINO', 'POSTGRES', 'MYSQL', 'GENERIC')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    cache_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    cache_ttl_seconds INT DEFAULT 300,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_by VARCHAR(100) NOT NULL
);

CREATE INDEX idx_custom_queries_table ON custom_queries(table_id);
CREATE INDEX idx_custom_queries_active ON custom_queries(is_active);


1.2 SQL参数配置表 (query_parameters)

CREATE TABLE query_parameters (
    param_id BIGSERIAL PRIMARY KEY,
    query_id BIGINT NOT NULL REFERENCES custom_queries(query_id) ON DELETE CASCADE,
    param_name VARCHAR(100) NOT NULL,
    param_type VARCHAR(50) NOT NULL
        CHECK (param_type IN ('STRING', 'INTEGER', 'FLOAT', 'BOOLEAN', 'DATE', 'TIMESTAMP')),
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    default_value VARCHAR(500),
    validation_regex VARCHAR(500),
    description TEXT,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(query_id, param_name)
);

CREATE INDEX idx_query_params_query ON query_parameters(query_id);
CREATE INDEX idx_query_params_name ON query_parameters(param_name);


1.3 结果映射配置表 (result_mappings)

CREATE TABLE result_mappings (
    mapping_id BIGSERIAL PRIMARY KEY,
    query_id BIGINT NOT NULL REFERENCES custom_queries(query_id) ON DELETE CASCADE,
    source_column VARCHAR(255) NOT NULL,
    target_field VARCHAR(255) NOT NULL,
    field_type VARCHAR(50) NOT NULL
        CHECK (field_type IN ('ID', 'STRING', 'INT', 'FLOAT', 'BOOLEAN', 'DATE', 'DATETIME', 'JSON')),
    transformation_type VARCHAR(30) DEFAULT 'DIRECT'
        CHECK (transformation_type IN ('DIRECT', 'FORMAT', 'CALCULATION', 'CUSTOM_FUNCTION')),
    transformation_expression TEXT,
    is_nullable BOOLEAN NOT NULL DEFAULT TRUE,
    default_value VARCHAR(500),
    description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(query_id, target_field)
);

CREATE INDEX idx_result_mapping_query ON result_mappings(query_id);
CREATE INDEX idx_result_mapping_source ON result_mappings(source_column);


1.4 GraphQL端点配置表 (graphql_endpoints)

CREATE TABLE graphql_endpoints (
    endpoint_id BIGSERIAL PRIMARY KEY,
    query_id BIGINT NOT NULL REFERENCES custom_queries(query_id) ON DELETE CASCADE,
    operation_name VARCHAR(255) NOT NULL UNIQUE,
    operation_type VARCHAR(20) NOT NULL DEFAULT 'QUERY'
        CHECK (operation_type IN ('QUERY', 'MUTATION')),
    description TEXT,
    requires_authentication BOOLEAN NOT NULL DEFAULT TRUE,
    rate_limit_per_hour INT DEFAULT 1000,
    max_rows_per_request INT DEFAULT 1000,
    timeout_ms INT DEFAULT 30000,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL
);

CREATE INDEX idx_graphql_endpoints_query ON graphql_endpoints(query_id);
CREATE INDEX idx_graphql_endpoints_active ON graphql_endpoints(is_active);


2. 示例数据

2.1 创建自定义查询

-- 创建查询定义
INSERT INTO custom_queries (
    query_name, table_id, description, sql_template, sql_engine, created_by, updated_by
) VALUES (
    'find_products_by_category',
    1,
    '根据类别查找产品',
    'SELECT id, name, price, category, created_at FROM products WHERE category = :category AND status = ''ACTIVE'' AND (:min_price IS NULL OR price >= :min_price)',
    'TRINO',
    'user123',
    'user123'
) RETURNING query_id;


2.2 配置参数

-- 添加参数配置
INSERT INTO query_parameters (
    query_id, param_name, param_type, is_required, default_value, description, position
) VALUES
(1, 'category', 'STRING', true, null, '产品类别', 1),
(1, 'min_price', 'FLOAT', false, null, '最低价格', 2);


2.3 配置结果映射

-- 添加结果映射
INSERT INTO result_mappings (
    query_id, source_column, target_field, field_type, transformation_type, description, sort_order
) VALUES
(1, 'id', 'productId', 'ID', 'DIRECT', '产品ID', 1),
(1, 'name', 'productName', 'STRING', 'DIRECT', '产品名称', 2),
(1, 'price', 'price', 'FLOAT', 'DIRECT', '产品价格', 3),
(1, 'category', 'category', 'STRING', 'DIRECT', '产品类别', 4),
(1, 'created_at', 'createdAt', 'DATETIME', 'FORMAT', '创建时间', 5);


2.4 配置GraphQL端点

-- 创建GraphQL端点
INSERT INTO graphql_endpoints (
    query_id, operation_name, operation_type, description, created_by
) VALUES (
    1, 'productsByCategory', 'QUERY', '根据类别查询产品', 'user123'
);


3. 视图设计

3.1 查询完整配置视图

CREATE VIEW v_custom_query_details AS
SELECT
    cq.query_id,
    cq.query_name,
    tr.table_name,
    cq.description,
    cq.sql_template,
    cq.sql_engine,
    cq.is_active,
    jsonb_agg(
        jsonb_build_object(
            'param_name', qp.param_name,
            'param_type', qp.param_type,
            'is_required', qp.is_required,
            'default_value', qp.default_value,
            'description', qp.description
        ) ORDER BY qp.position
    ) FILTER (WHERE qp.param_id IS NOT NULL) AS parameters,
    jsonb_agg(
        jsonb_build_object(
            'source_column', rm.source_column,
            'target_field', rm.target_field,
            'field_type', rm.field_type,
            'transformation_type', rm.transformation_type,
            'transformation_expression', rm.transformation_expression,
            'description', rm.description
        ) ORDER BY rm.sort_order
    ) FILTER (WHERE rm.mapping_id IS NOT NULL) AS result_mappings,
    jsonb_build_object(
        'operation_name', ge.operation_name,
        'operation_type', ge.operation_type,
        'requires_authentication', ge.requires_authentication
    ) AS graphql_endpoint,
    cq.created_by,
    cq.created_at,
    cq.updated_at
FROM custom_queries cq
JOIN table_registry tr ON cq.table_id = tr.id
LEFT JOIN query_parameters qp ON cq.query_id = qp.query_id
LEFT JOIN result_mappings rm ON cq.query_id = rm.query_id
LEFT JOIN graphql_endpoints ge ON cq.query_id = ge.query_id AND ge.is_active = TRUE
GROUP BY cq.query_id, tr.table_name, ge.operation_name, ge.operation_type, ge.requires_authentication;


4. 存储过程

4.1 创建完整查询配置

CREATE OR REPLACE PROCEDURE create_custom_query_with_mapping(
    p_table_name VARCHAR,
    p_query_name VARCHAR,
    p_description TEXT,
    p_sql_template TEXT,
    p_sql_engine VARCHAR,
    p_parameters JSONB DEFAULT NULL,
    p_mappings JSONB DEFAULT NULL,
    p_operation_name VARCHAR DEFAULT NULL,
    p_created_by VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_table_id BIGINT;
    v_query_id BIGINT;
BEGIN
    -- 获取表ID
    SELECT id INTO v_table_id FROM table_registry WHERE table_name = p_table_name;

    IF v_table_id IS NULL THEN
        RAISE EXCEPTION 'Table % not found', p_table_name;
    END IF;

    -- 创建查询
    INSERT INTO custom_queries (
        table_id, query_name, description, sql_template, sql_engine, created_by, updated_by
    ) VALUES (
        v_table_id, p_query_name, p_description, p_sql_template, p_sql_engine, p_created_by, p_created_by
    ) RETURNING query_id INTO v_query_id;

    -- 添加参数
    IF p_parameters IS NOT NULL THEN
        INSERT INTO query_parameters (
            query_id, param_name, param_type, is_required, default_value, description, position
        )
        SELECT
            v_query_id,
            value->>'name',
            value->>'type',
            COALESCE((value->>'required')::BOOLEAN, FALSE),
            value->>'defaultValue',
            value->>'description',
            COALESCE((value->>'position')::INT, 0)
        FROM jsonb_array_elements(p_parameters);
    END IF;

    -- 添加结果映射
    IF p_mappings IS NOT NULL THEN
        INSERT INTO result_mappings (
            query_id, source_column, target_field, field_type,
            transformation_type, transformation_expression, description, sort_order
        )
        SELECT
            v_query_id,
            value->>'sourceColumn',
            value->>'targetField',
            value->>'fieldType',
            COALESCE(value->>'transformationType', 'DIRECT'),
            value->>'transformationExpression',
            value->>'description',
            COALESCE((value->>'sortOrder')::INT, 0)
        FROM jsonb_array_elements(p_mappings);
    END IF;

    -- 添加GraphQL端点
    IF p_operation_name IS NOT NULL THEN
        INSERT INTO graphql_endpoints (
            query_id, operation_name, operation_type, description, created_by
        ) VALUES (
            v_query_id, p_operation_name, 'QUERY', p_description, p_created_by
        );
    END IF;

    COMMIT;
END;
$$;


4.2 获取查询配置

CREATE OR REPLACE FUNCTION get_query_config(p_query_name VARCHAR)
RETURNS TABLE (
    query_id BIGINT,
    sql_template TEXT,
    parameters JSONB,
    result_mappings JSONB,
    graphql_endpoint JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        cq.query_id,
        cq.sql_template,
        jsonb_agg(
            jsonb_build_object(
                'name', qp.param_name,
                'type', qp.param_type,
                'required', qp.is_required,
                'default_value', qp.default_value,
                'description', qp.description
            )
        ) FILTER (WHERE qp.param_id IS NOT NULL),
        jsonb_agg(
            jsonb_build_object(
                'source_column', rm.source_column,
                'target_field', rm.target_field,
                'field_type', rm.field_type,
                'transformation_type', rm.transformation_type,
                'transformation_expression', rm.transformation_expression
            )
        ) FILTER (WHERE rm.mapping_id IS NOT NULL),
        jsonb_build_object(
            'operation_name', ge.operation_name,
            'operation_type', ge.operation_type
        )
    FROM custom_queries cq
    LEFT JOIN query_parameters qp ON cq.query_id = qp.query_id
    LEFT JOIN result_mappings rm ON cq.query_id = rm.query_id
    LEFT JOIN graphql_endpoints ge ON cq.query_id = ge.query_id AND ge.is_active = TRUE
    WHERE cq.query_name = p_query_name
    GROUP BY cq.query_id, cq.sql_template, ge.operation_name, ge.operation_type;
END;
$$;


5. 使用示例

5.1 创建复杂查询

-- 调用存储过程创建完整配置
CALL create_custom_query_with_mapping(
    p_table_name := 'products',
    p_query_name := 'find_products_advanced',
    p_description := '高级产品查询',
    p_sql_template := 'SELECT id, name, price, category, created_at,
                       (price * 0.9) AS discounted_price
                       FROM products
                       WHERE category = :category
                       AND (:min_price IS NULL OR price >= :min_price)
                       AND (:max_price IS NULL OR price <= :max_price)
                       ORDER BY created_at DESC',
    p_sql_engine := 'TRINO',
    p_parameters := '[
        {"name": "category", "type": "STRING", "required": true, "description": "产品类别"},
        {"name": "min_price", "type": "FLOAT", "required": false, "description": "最低价格"},
        {"name": "max_price", "type": "FLOAT", "required": false, "description": "最高价格"}
    ]'::jsonb,
    p_mappings := '[
        {"sourceColumn": "id", "targetField": "id", "fieldType": "ID", "description": "产品ID"},
        {"sourceColumn": "name", "targetField": "name", "fieldType": "STRING", "description": "产品名称"},
        {"sourceColumn": "price", "targetField": "originalPrice", "fieldType": "FLOAT", "description": "原价格"},
        {"sourceColumn": "discounted_price", "targetField": "discountedPrice", "fieldType": "FLOAT", "description": "折扣价格"},
        {"sourceColumn": "category", "targetField": "category", "fieldType": "STRING", "description": "产品类别"},
        {"sourceColumn": "created_at", "targetField": "createdAt", "fieldType": "DATETIME", "transformationType": "FORMAT", "transformationExpression": "TO_CHAR(created_at, ''YYYY-MM-DD HH24:MI:SS'')", "description": "创建时间"}
    ]'::jsonb,
    p_operation_name := 'advancedProducts',
    p_created_by := 'user123'
);


5.2 查询配置信息

-- 查看查询配置
SELECT * FROM v_custom_query_details WHERE query_name = 'find_products_advanced';

-- 获取特定查询的配置
SELECT * FROM get_query_config('find_products_advanced');

-- 查看所有活跃查询
SELECT query_name, description, operation_name
FROM v_custom_query_details
WHERE is_active = TRUE;


这个简化设计专注于核心功能：
1. SQL模板：支持参数化查询
2. 参数配置：定义参数类型、必填性、默认值
3. 结果映射：字段映射和类型转换
4. GraphQL端点：自动生成GraphQL操作

用户只需要配置SQL和映射关系，系统会自动处理参数绑定和结果转换。