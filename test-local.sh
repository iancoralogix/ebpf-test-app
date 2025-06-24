#!/bin/bash

# Local Test Script for eBPF Test App
set -e

echo "Testing eBPF Test App locally..."

# Build the application
echo "Building application..."
mvn clean package -P spring-boot-2 -DskipTests

# Check if JAR was created
if [ ! -f "target/ebpf-test-app-1.0.0.jar" ]; then
    echo "ERROR: JAR file not found!"
    exit 1
fi

echo "JAR file created successfully: target/ebpf-test-app-1.0.0.jar"

# Test different service configurations
echo ""
echo "Testing service configurations..."

# Test frontend service configuration
echo "Testing frontend service..."
SERVICE_NAME=frontend NEXT_SERVICE_URL=http://checkout:8080 java -Dserver.port=8080 -jar target/ebpf-test-app-1.0.0.jar &
FRONTEND_PID=$!
sleep 5

# Test health endpoint
if curl -f http://localhost:8080/api/health > /dev/null 2>&1; then
    echo "✓ Frontend service health check passed"
else
    echo "✗ Frontend service health check failed"
fi

# Test info endpoint
if curl -f http://localhost:8080/api/info > /dev/null 2>&1; then
    echo "✓ Frontend service info endpoint working"
else
    echo "✗ Frontend service info endpoint failed"
fi

# Stop frontend service
kill $FRONTEND_PID
sleep 2

# Test checkout service configuration
echo "Testing checkout service..."
SERVICE_NAME=checkout NEXT_SERVICE_URL=http://payment:8080 java -Dserver.port=8081 -jar target/ebpf-test-app-1.0.0.jar &
CHECKOUT_PID=$!
sleep 5

# Test health endpoint
if curl -f http://localhost:8081/api/health > /dev/null 2>&1; then
    echo "✓ Checkout service health check passed"
else
    echo "✗ Checkout service health check failed"
fi

# Stop checkout service
kill $CHECKOUT_PID
sleep 2

# Test payment service configuration
echo "Testing payment service..."
SERVICE_NAME=payment IS_LEAF_SERVICE=true java -Dserver.port=8082 -jar target/ebpf-test-app-1.0.0.jar &
PAYMENT_PID=$!
sleep 5

# Test health endpoint
if curl -f http://localhost:8082/api/health > /dev/null 2>&1; then
    echo "✓ Payment service health check passed"
else
    echo "✗ Payment service health check failed"
fi

# Test simulate endpoint (should work without downstream services)
if curl -f http://localhost:8082/api/simulate/purchase > /dev/null 2>&1; then
    echo "✓ Payment service simulate endpoint working"
else
    echo "✗ Payment service simulate endpoint failed"
fi

# Stop payment service
kill $PAYMENT_PID
sleep 2

echo ""
echo "Local testing completed!"
echo ""
echo "Next steps:"
echo "1. Build Docker image: ./build.sh"
echo "2. Deploy to Kubernetes: ./deploy.sh"
echo "3. Test full service chain in Kubernetes cluster" 