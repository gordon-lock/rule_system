package com.dataservice.controller;

import com.dataservice.service.QueryService;
import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Readiness;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.HashMap;
import java.util.Map;

@Path("/api/health")
@ApplicationScoped
public class HealthController {

    private final QueryService queryService;

    @Inject
    public HealthController(QueryService queryService) {
        this.queryService = queryService;
    }

    @GET
    @Path("/info")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getHealthInfo() {
        Map<String, Object> healthInfo = new HashMap<>();
        healthInfo.put("status", "UP");
        healthInfo.put("timestamp", System.currentTimeMillis());
        healthInfo.put("version", "1.0.0");
        healthInfo.put("framework", "Quarkus");
        
        return Response.ok(healthInfo).build();
    }

    @GET
    @Path("/trino")
    @Produces(MediaType.APPLICATION_JSON)
    public Response checkTrinoConnection() {
        try {
            // Try to execute a simple query to check Trino connection
            QueryService.QueryResult result = queryService.executeQuery("SELECT 1 as test");
            
            Map<String, Object> response = new HashMap<>();
            response.put("status", "UP");
            response.put("trino_connection", "OK");
            response.put("execution_time_ms", result.getExecutionTimeMs());
            
            return Response.ok(response).build();
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "DOWN");
            response.put("trino_connection", "FAILED");
            response.put("error", e.getMessage());
            
            return Response.status(Response.Status.SERVICE_UNAVAILABLE)
                    .entity(response)
                    .build();
        }
    }

    @Readiness
    @ApplicationScoped
    public static class TrinoHealthCheck implements HealthCheck {

        private final QueryService queryService;

        @Inject
        public TrinoHealthCheck(QueryService queryService) {
            this.queryService = queryService;
        }

        @Override
        public HealthCheckResponse call() {
            try {
                // Try to execute a simple query
                QueryService.QueryResult result = queryService.executeQuery("SELECT 1 as test");
                
                return HealthCheckResponse.up("trino-connection");
                        
            } catch (Exception e) {
                return HealthCheckResponse.down("trino-connection");
            }
        }
    }
} 