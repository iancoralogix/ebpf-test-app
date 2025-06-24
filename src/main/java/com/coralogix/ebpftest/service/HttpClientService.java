package com.coralogix.ebpftest.service;

import com.coralogix.ebpftest.model.ServiceRequest;
import com.coralogix.ebpftest.model.ServiceResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.util.EntityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.concurrent.ThreadLocalRandom;

@Service
public class HttpClientService {
    
    private static final Logger logger = LoggerFactory.getLogger(HttpClientService.class);
    
    @Autowired
    private WebClient webClient;
    
    @Autowired
    private CloseableHttpClient httpClient;
    
    @Autowired
    private ObjectMapper objectMapper;
    
    public ServiceResponse callDownstreamService(String url, ServiceRequest request) {
        // Randomly choose between different HTTP clients to create variety in network calls
        boolean useWebClient = ThreadLocalRandom.current().nextBoolean();
        
        if (useWebClient) {
            return callWithWebClient(url, request);
        } else {
            return callWithApacheHttpClient(url, request);
        }
    }
    
    private ServiceResponse callWithWebClient(String url, ServiceRequest request) {
        logger.info("Making downstream call to {} using WebClient", url);
        
        try {
            Mono<ServiceResponse> responseMono = webClient
                .post()
                .uri(url + "/api/process")
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .header("X-Request-ID", request.getRequestId())
                .header("X-Source-Service", request.getSourceService())
                .bodyValue(request)
                .retrieve()
                .bodyToMono(ServiceResponse.class)
                .timeout(Duration.ofSeconds(30));
            
            ServiceResponse response = responseMono.block();
            logger.info("WebClient call to {} completed successfully", url);
            return response;
            
        } catch (Exception e) {
            logger.error("WebClient call to {} failed: {}", url, e.getMessage(), e);
            ServiceResponse errorResponse = new ServiceResponse(request.getRequestId(), "downstream-error");
            errorResponse.setStatus("error");
            errorResponse.getResult().put("error", "Downstream service call failed: " + e.getMessage());
            return errorResponse;
        }
    }
    
    private ServiceResponse callWithApacheHttpClient(String url, ServiceRequest request) {
        logger.info("Making downstream call to {} using Apache HttpClient", url);
        
        try {
            HttpPost httpPost = new HttpPost(url + "/api/process");
            httpPost.setHeader("Content-Type", "application/json");
            httpPost.setHeader("X-Request-ID", request.getRequestId());
            httpPost.setHeader("X-Source-Service", request.getSourceService());
            
            String requestBody = objectMapper.writeValueAsString(request);
            httpPost.setEntity(new StringEntity(requestBody));
            
            HttpResponse httpResponse = httpClient.execute(httpPost);
            HttpEntity entity = httpResponse.getEntity();
            
            if (entity != null) {
                String responseBody = EntityUtils.toString(entity);
                ServiceResponse response = objectMapper.readValue(responseBody, ServiceResponse.class);
                logger.info("Apache HttpClient call to {} completed successfully", url);
                return response;
            } else {
                throw new RuntimeException("Empty response from downstream service");
            }
            
        } catch (Exception e) {
            logger.error("Apache HttpClient call to {} failed: {}", url, e.getMessage(), e);
            ServiceResponse errorResponse = new ServiceResponse(request.getRequestId(), "downstream-error");
            errorResponse.setStatus("error");
            errorResponse.getResult().put("error", "Downstream service call failed: " + e.getMessage());
            return errorResponse;
        }
    }
} 