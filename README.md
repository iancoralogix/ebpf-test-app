# eBPF Test Application

A flexible Spring Boot application designed for testing eBPF instrumentation with OpenTelemetry. This single application can be configured to act as different services in a microservices chain (frontend → checkout → payment) without any OpenTelemetry instrumentation, making it perfect for testing eBPF-based observability.

## Features

- **Single Application, Multiple Services**: One Docker image that can be configured to act as frontend, checkout, or payment service
- **Spring Boot Version Support**: Supports both Spring Boot 2.6.6 and 3.0.0 via Maven profiles
- **No OpenTelemetry Instrumentation**: Clean application without any OTel dependencies for pure eBPF testing
- **Multiple HTTP Clients**: Uses both WebClient and Apache HttpClient for varied network patterns
- **Realistic Service Chain**: Simulates a real e-commerce flow with appropriate delays and business logic
- **Comprehensive Logging**: Structured logging for better observability

## Architecture

```
┌──────────┐    HTTP    ┌──────────┐    HTTP    ┌──────────┐
│ Frontend │ ────────→  │ Checkout │ ────────→  │ Payment  │
│ Service  │            │ Service  │            │ Service  │
└──────────┘            └──────────┘            └──────────┘
     │                       │                       │
     └─── Same Docker Image ─┴─── Different Config ─┘
```

## Quick Start

### 1. Build the Application

```bash
# Build only (no push)
./build.sh

# Build and push to ECR Public
PUSH=true ./build.sh

# Build with custom tag
TAG=v1.0.0 PUSH=true ./build.sh

# Build for Spring Boot 3.0.0
SPRING_BOOT_VERSION=spring-boot-3 ./build.sh

# Manual push (if needed)
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/w3s4j9x9
docker push public.ecr.aws/w3s4j9x9/ianbowers/ebpf-test-app:latest
```

### 2. Deploy to Kubernetes

```bash
# Deploy to default namespace
./deploy.sh

# Deploy to specific namespace
NAMESPACE=ebpf-test ./deploy.sh

# Deploy with custom image tag
TAG=v1.0.0 ./deploy.sh
```

### 3. Test the Application

```bash
# Port-forward to frontend service
kubectl port-forward svc/frontend 8080:8080

# Test health endpoint
curl http://localhost:8080/api/health

# Test service info
curl http://localhost:8080/api/info

# Simulate a purchase (triggers full service chain)
curl http://localhost:8080/api/simulate/purchase

# Generate continuous load
for i in {1..100}; do 
  curl -X GET http://localhost:8080/api/simulate/purchase
  sleep 1
done
```

### 4. Cleanup

```bash
# Remove all eBPF test app resources
./cleanup.sh

# Cleanup from specific namespace
NAMESPACE=ebpf-test ./cleanup.sh
```

## Configuration

The application behavior is controlled entirely through environment variables:

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `SERVICE_NAME` | `frontend` | Name of the service (frontend, checkout, payment) |
| `SERVER_PORT` | `8080` | Port the service listens on |
| `NEXT_SERVICE_URL` | `""` | URL of the downstream service |
| `IS_LEAF_SERVICE` | `false` | Whether this is the last service in the chain |
| `JAVA_OPTS` | `""` | Additional JVM options |

## Service Chain Configuration

### Frontend Service
```yaml
env:
- name: SERVICE_NAME
  value: "frontend"
- name: NEXT_SERVICE_URL
  value: "http://checkout:8080"
- name: IS_LEAF_SERVICE
  value: "false"
```

### Checkout Service
```yaml
env:
- name: SERVICE_NAME
  value: "checkout"
- name: NEXT_SERVICE_URL
  value: "http://payment:8080"
- name: IS_LEAF_SERVICE
  value: "false"
```

### Payment Service
```yaml
env:
- name: SERVICE_NAME
  value: "payment"
- name: NEXT_SERVICE_URL
  value: ""
- name: IS_LEAF_SERVICE
  value: "true"
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check endpoint |
| `/api/info` | GET | Service configuration info |
| `/api/process` | POST | Process a service request |
| `/api/simulate/{operation}` | GET | Simulate an operation (triggers service chain) |

## Service-Specific Behavior

Each service adds different data and has different processing times to simulate realistic behavior:

### Frontend Service
- **Processing Time**: ~50-150ms
- **Adds**: Session ID, User Agent, Client IP
- **Behavior**: Fast response, lightweight processing

### Checkout Service  
- **Processing Time**: ~200-300ms
- **Adds**: Cart ID, Item Count, Total Amount
- **Behavior**: Business logic simulation, moderate processing time

### Payment Service
- **Processing Time**: ~300-400ms  
- **Adds**: Transaction ID, Payment Method, Auth Code
- **Behavior**: External service simulation, longer processing time

## eBPF Testing

This application is specifically designed for eBPF testing:

1. **No OpenTelemetry Dependencies**: Clean application without any OTel instrumentation
2. **Multiple HTTP Libraries**: Uses both WebClient and Apache HttpClient for diverse network patterns
3. **Realistic Traffic Patterns**: Simulates real service-to-service communication
4. **Rich Metadata**: Generates meaningful logs and HTTP headers for correlation

### Expected eBPF Observability

When monitored with eBPF instrumentation, you should see:

- **HTTP Requests**: GET and POST requests between services
- **Network Latency**: Service-to-service communication timing
- **Service Discovery**: Automatic detection of the three services
- **Request Correlation**: Headers like `X-Request-ID` for tracing requests
- **Error Handling**: HTTP error codes and retry patterns

## Development

### Project Structure
```
ebpf-test-app/
├── src/main/java/com/coralogix/ebpftest/
│   ├── EbpfTestApplication.java          # Main application class
│   ├── config/ServiceConfig.java         # Service configuration
│   ├── controller/ServiceController.java # REST endpoints
│   ├── model/                            # Request/Response models
│   └── service/HttpClientService.java    # HTTP client implementations
├── src/main/resources/
│   └── application.yml                   # Application configuration
├── k8s/                                  # Kubernetes manifests
├── Dockerfile                           # Multi-stage Docker build
├── pom.xml                              # Maven configuration with profiles
├── build.sh                            # Build script
└── deploy.sh                           # Deployment script
```

### Building Locally

```bash
# Build with Spring Boot 2.6.6
mvn clean package -P spring-boot-2

# Build with Spring Boot 3.0.0  
mvn clean package -P spring-boot-3

# Run locally
java -jar target/ebpf-test-app-1.0.0.jar
```

### Testing Locally

```bash
# Start as frontend
SERVICE_NAME=frontend NEXT_SERVICE_URL=http://localhost:8081 java -jar target/ebpf-test-app-1.0.0.jar

# Start as checkout (in another terminal)
SERVICE_NAME=checkout SERVER_PORT=8081 NEXT_SERVICE_URL=http://localhost:8082 java -jar target/ebpf-test-app-1.0.0.jar

# Start as payment (in another terminal)  
SERVICE_NAME=payment SERVER_PORT=8082 IS_LEAF_SERVICE=true java -jar target/ebpf-test-app-1.0.0.jar
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**: Ensure ECR repository exists and credentials are configured
2. **Service Discovery**: Verify Kubernetes DNS is working (`nslookup checkout` from frontend pod)
3. **Health Check Failures**: Check if the application is binding to the correct port
4. **Network Policies**: Ensure pods can communicate between services

### Debugging

```bash
# Check pod logs
kubectl logs -f deployment/frontend
kubectl logs -f deployment/checkout  
kubectl logs -f deployment/payment

# Check service endpoints
kubectl get endpoints

# Test service connectivity from within cluster
kubectl run debug --image=curlimages/curl -it --rm -- sh
# Then: curl http://frontend:8080/api/health
```

## License

This project is for testing purposes and is provided as-is. 