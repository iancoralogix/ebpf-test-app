package com.coralogix.ebpftest.model;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.HashMap;

public class ServiceRequest {
    private String requestId;
    private String operation;
    private Map<String, Object> data;
    private LocalDateTime timestamp;
    private String sourceService;
    
    public ServiceRequest() {
        this.data = new HashMap<>();
        this.timestamp = LocalDateTime.now();
    }
    
    public ServiceRequest(String requestId, String operation, String sourceService) {
        this();
        this.requestId = requestId;
        this.operation = operation;
        this.sourceService = sourceService;
    }
    
    // Getters and setters
    public String getRequestId() {
        return requestId;
    }
    
    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }
    
    public String getOperation() {
        return operation;
    }
    
    public void setOperation(String operation) {
        this.operation = operation;
    }
    
    public Map<String, Object> getData() {
        return data;
    }
    
    public void setData(Map<String, Object> data) {
        this.data = data;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getSourceService() {
        return sourceService;
    }
    
    public void setSourceService(String sourceService) {
        this.sourceService = sourceService;
    }
} 