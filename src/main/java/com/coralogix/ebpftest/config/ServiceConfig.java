package com.coralogix.ebpftest.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.service")
public class ServiceConfig {
    
    private String name = "frontend";
    private String nextServiceUrl;
    private int port = 8080;
    private boolean isLeaf = false;
    
    // Getters and setters
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getNextServiceUrl() {
        return nextServiceUrl;
    }
    
    public void setNextServiceUrl(String nextServiceUrl) {
        this.nextServiceUrl = nextServiceUrl;
    }
    
    public int getPort() {
        return port;
    }
    
    public void setPort(int port) {
        this.port = port;
    }
    
    public boolean isLeaf() {
        return isLeaf;
    }
    
    public void setLeaf(boolean isLeaf) {
        this.isLeaf = isLeaf;
    }
} 