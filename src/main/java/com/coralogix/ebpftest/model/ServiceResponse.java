package com.coralogix.ebpftest.model;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.HashMap;

public class ServiceResponse {
    private String requestId;
    private String status;
    private Map<String, Object> result;
    private LocalDateTime timestamp;
    private String serviceName;
    private long processingTimeMs;
    
    public ServiceResponse() {
        this.result = new HashMap<>();
        this.timestamp = LocalDateTime.now();
        this.status = "success";
    }
    
    public ServiceResponse(String requestId, String serviceName) {
        this();
        this.requestId = requestId;
        this.serviceName = serviceName;
    }
    
    // Getters and setters
    public String getRequestId() {
        return requestId;
    }
    
    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public Map<String, Object> getResult() {
        return result;
    }
    
    public void setResult(Map<String, Object> result) {
        this.result = result;
    }
    
    public LocalDateTime getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getServiceName() {
        return serviceName;
    }
    
    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }
    
    public long getProcessingTimeMs() {
        return processingTimeMs;
    }
    
    public void setProcessingTimeMs(long processingTimeMs) {
        this.processingTimeMs = processingTimeMs;
    }
} 