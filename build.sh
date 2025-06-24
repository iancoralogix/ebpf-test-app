#!/bin/bash

# eBPF Test App Build Script
set -e

# Configuration
ECR_REPO="${ECR_REPO:-public.ecr.aws/w3s4j9x9/ianbowers/ebpf-test-app}"
SPRING_BOOT_VERSION="${SPRING_BOOT_VERSION:-spring-boot-2}"
TAG="${TAG:-latest}"

echo "Building eBPF Test App..."
echo "ECR Repository: $ECR_REPO"
echo "Spring Boot Version: $SPRING_BOOT_VERSION"
echo "Tag: $TAG"

# Build for Spring Boot 2.6.6 (default)
echo "Building Spring Boot 2.6.6 version..."
docker build --build-arg SPRING_BOOT_VERSION=spring-boot-2 -t ianbowers/ebpf-test-app:${TAG}-sb2 .

# Build for Spring Boot 3.0.0
echo "Building Spring Boot 3.0.0 version..."
docker build --build-arg SPRING_BOOT_VERSION=spring-boot-3 -t ianbowers/ebpf-test-app:${TAG}-sb3 .

# Tag the default version (Spring Boot 2) as latest
docker tag ianbowers/ebpf-test-app:${TAG}-sb2 ianbowers/ebpf-test-app:${TAG}

# Tag for ECR Public
docker tag ianbowers/ebpf-test-app:${TAG} ${ECR_REPO}:${TAG}
docker tag ianbowers/ebpf-test-app:${TAG}-sb2 ${ECR_REPO}:${TAG}-sb2
docker tag ianbowers/ebpf-test-app:${TAG}-sb3 ${ECR_REPO}:${TAG}-sb3

echo "Build completed successfully!"
echo "Images built:"
echo "  Local images:"
echo "    - ianbowers/ebpf-test-app:${TAG} (Spring Boot 2.6.6 - default)"
echo "    - ianbowers/ebpf-test-app:${TAG}-sb2 (Spring Boot 2.6.6)"
echo "    - ianbowers/ebpf-test-app:${TAG}-sb3 (Spring Boot 3.0.0)"
echo "  ECR Public images:"
echo "    - ${ECR_REPO}:${TAG} (Spring Boot 2.6.6 - default)"
echo "    - ${ECR_REPO}:${TAG}-sb2 (Spring Boot 2.6.6)"
echo "    - ${ECR_REPO}:${TAG}-sb3 (Spring Boot 3.0.0)"

# Push to ECR Public if PUSH=true
if [ "$PUSH" = "true" ]; then
    echo "Pushing images to ECR Public..."
    
    # Authenticate with ECR Public (us-east-1 region for ECR Public)
    echo "Authenticating with ECR Public..."
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/w3s4j9x9
    
    # Push all images
    echo "Pushing ${ECR_REPO}:${TAG}..."
    docker push ${ECR_REPO}:${TAG}
    
    echo "Pushing ${ECR_REPO}:${TAG}-sb2..."
    docker push ${ECR_REPO}:${TAG}-sb2
    
    echo "Pushing ${ECR_REPO}:${TAG}-sb3..."
    docker push ${ECR_REPO}:${TAG}-sb3
    
    echo "Images pushed successfully to ECR Public!"
fi

echo "Done!"
echo ""
echo "To push manually, run:"
echo "  aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/w3s4j9x9"
echo "  docker push ${ECR_REPO}:${TAG}"
echo "  docker push ${ECR_REPO}:${TAG}-sb2"
echo "  docker push ${ECR_REPO}:${TAG}-sb3" 