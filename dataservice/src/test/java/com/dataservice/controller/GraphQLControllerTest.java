package com.dataservice.controller;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.Matchers.greaterThan;

@QuarkusTest
class GraphQLControllerTest {

    @Test
    void testTablesQuery() {
        String query = """
            query {
                tables {
                    tableName
                    catalog
                    schema
                    tableType
                }
            }
            """;

        given()
            .contentType("application/json")
            .body("{\"query\": \"" + query.replace("\n", "\\n") + "\"}")
        .when()
            .post("/api/graphql")
        .then()
            .statusCode(200)
            .body("data.tables", notNullValue())
            .body("data.tables.size()", greaterThan(0))
            .body("data.tables[0].tableName", notNullValue());
    }

    @Test
    void testTableQuery() {
        String query = """
            query($name: String!) {
                table(name: $name) {
                    tableName
                    catalog
                    schema
                    tableType
                    columns {
                        name
                        type
                        nullable
                    }
                }
            }
            """;

        String variables = "{\"name\": \"users\"}";

        given()
            .contentType("application/json")
            .body("{\"query\": \"" + query.replace("\n", "\\n") + "\", \"variables\": " + variables + "}")
        .when()
            .post("/api/graphql")
        .then()
            .statusCode(200)
            .body("data.table.tableName", is("users"))
            .body("data.table.catalog", is("iceberg"))
            .body("data.table.schema", is("default"));
    }

    @Test
    void testQueryExecution() {
        String query = """
            query($sql: String!) {
                query(sql: $sql) {
                    rowCount
                    executionTime
                    data {
                        id
                        name
                    }
                }
            }
            """;

        String variables = "{\"sql\": \"SELECT 1 as id, 'test' as name\"}";

        given()
            .contentType("application/json")
            .body("{\"query\": \"" + query.replace("\n", "\\n") + "\", \"variables\": " + variables + "}")
        .when()
            .post("/api/graphql")
        .then()
            .statusCode(200)
            .body("data.query.rowCount", greaterThan(0))
            .body("data.query.executionTime", notNullValue());
    }

    @Test
    void testSchemasQuery() {
        String query = """
            query {
                schemas
            }
            """;

        given()
            .contentType("application/json")
            .body("{\"query\": \"" + query.replace("\n", "\\n") + "\"}")
        .when()
            .post("/api/graphql")
        .then()
            .statusCode(200)
            .body("data.schemas", notNullValue())
            .body("data.schemas.size()", greaterThan(0));
    }
} 