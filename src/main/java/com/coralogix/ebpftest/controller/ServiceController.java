package com.coralogix.ebpftest.controller;

import com.coralogix.ebpftest.config.ServiceConfig;
import com.coralogix.ebpftest.model.ServiceRequest;
import com.coralogix.ebpftest.model.ServiceResponse;
import com.coralogix.ebpftest.service.HttpClientService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@RestController
@RequestMapping("/api")
public class ServiceController {
    
    private static final Logger logger = LoggerFactory.getLogger(ServiceController.class);
    
    @Autowired
    private ServiceConfig serviceConfig;
    
    @Autowired
    private HttpClientService httpClientService;
    
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }
    
    @GetMapping("/info")
    public ResponseEntity<ServiceConfig> info() {
        return ResponseEntity.ok(serviceConfig);
    }
    
    @PostMapping("/process")
    public ResponseEntity<ServiceResponse> processRequest(@RequestBody ServiceRequest request) {
        long startTime = System.currentTimeMillis();
        String requestId = request.getRequestId() != null ? request.getRequestId() : UUID.randomUUID().toString();
        
        logger.info("Service {} processing request {} for operation {}", 
                    serviceConfig.getName(), requestId, request.getOperation());
        
        ServiceResponse response = new ServiceResponse(requestId, serviceConfig.getName());
        
        try {
            // Simulate some processing time
            simulateProcessing();
            
            // Add service-specific data based on service name
            addServiceSpecificData(response, request);
            
            // If not a leaf service, call the next service
            if (!serviceConfig.isLeaf() && serviceConfig.getNextServiceUrl() != null) {
                logger.info("Service {} calling downstream service at {}", 
                           serviceConfig.getName(), serviceConfig.getNextServiceUrl());
                
                ServiceRequest downstreamRequest = new ServiceRequest(requestId, request.getOperation(), serviceConfig.getName());
                downstreamRequest.setData(request.getData());
                
                ServiceResponse downstreamResponse = httpClientService.callDownstreamService(
                    serviceConfig.getNextServiceUrl(), downstreamRequest);
                
                response.getResult().put("downstream", downstreamResponse);
                logger.info("Service {} received response from downstream service", serviceConfig.getName());
            }
            
            long processingTime = System.currentTimeMillis() - startTime;
            response.setProcessingTimeMs(processingTime);
            
            logger.info("Service {} completed processing request {} in {}ms", 
                       serviceConfig.getName(), requestId, processingTime);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Service {} failed to process request {}: {}", 
                        serviceConfig.getName(), requestId, e.getMessage(), e);
            
            response.setStatus("error");
            response.getResult().put("error", e.getMessage());
            response.setProcessingTimeMs(System.currentTimeMillis() - startTime);
            
            return ResponseEntity.status(500).body(response);
        }
    }
    
    @GetMapping("/simulate/{operation}")
    public ResponseEntity<ServiceResponse> simulateOperation(@PathVariable String operation) {
        String requestId = UUID.randomUUID().toString();
        
        ServiceRequest request = new ServiceRequest(requestId, operation, "external");
        request.getData().put("timestamp", LocalDateTime.now().toString());
        request.getData().put("source", "simulation");
        
        return processRequest(request);
    }
    
    private void simulateProcessing() {
        // Simulate variable processing time based on service type
        int baseDelay = getBaseDelayForService();
        int variableDelay = ThreadLocalRandom.current().nextInt(0, 100);
        
        try {
            Thread.sleep(baseDelay + variableDelay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    private int getBaseDelayForService() {
        switch (serviceConfig.getName().toLowerCase()) {
            case "frontend":
                return 50; // Frontend is fast
            case "checkout":
                return 200; // Checkout has some business logic
            case "payment":
                return 300; // Payment is slower (external calls, validation)
            default:
                return 100;
        }
    }
    
    private void addServiceSpecificData(ServiceResponse response, ServiceRequest request) {
        switch (serviceConfig.getName().toLowerCase()) {
            case "frontend":
                response.getResult().put("sessionId", UUID.randomUUID().toString());
                response.getResult().put("userAgent", "eBPF-Test-Client/1.0");
                response.getResult().put("clientIp", "192.168.1.100");
                break;
                
            case "checkout":
                response.getResult().put("cartId", UUID.randomUUID().toString());
                response.getResult().put("itemCount", ThreadLocalRandom.current().nextInt(1, 10));
                response.getResult().put("totalAmount", ThreadLocalRandom.current().nextDouble(10.0, 500.0));
                break;
                
            case "payment":
                response.getResult().put("transactionId", UUID.randomUUID().toString());
                response.getResult().put("paymentMethod", "credit_card");
                response.getResult().put("authCode", "AUTH_" + ThreadLocalRandom.current().nextInt(100000, 999999));
                response.getResult().put("processorResponse", "approved");
                break;
                
            default:
                response.getResult().put("serviceType", "generic");
                response.getResult().put("version", "1.0.0");
        }
    }
} 