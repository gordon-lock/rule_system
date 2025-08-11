package com.dataservice;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
public class IcebergGraphQLApplicationTests {

    @Test
    public void testHealthEndpoint() {
        given()
          .when().get("/api/health/info")
          .then()
             .statusCode(200)
             .body("status", is("UP"));
    }

    @Test
    public void testTrinoHealthEndpoint() {
        given()
          .when().get("/api/health/trino")
          .then()
             .statusCode(200)
             .body("status", is("UP"));
    }
} 