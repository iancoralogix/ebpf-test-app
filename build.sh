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
docker build --build-arg SPRING_BOOT_VERSION=spring-boot-2 -t ${ECR_REPO}:${TAG}-sb2 .

# Build for Spring Boot 3.0.0
echo "Building Spring Boot 3.0.0 version..."
docker build --build-arg SPRING_BOOT_VERSION=spring-boot-3 -t ${ECR_REPO}:${TAG}-sb3 .

# Tag the default version (Spring Boot 2) as latest
docker tag ${ECR_REPO}:${TAG}-sb2 ${ECR_REPO}:${TAG}

echo "Build completed successfully!"
echo "Images built:"
echo "  - ${ECR_REPO}:${TAG} (Spring Boot 2.6.6 - default)"
echo "  - ${ECR_REPO}:${TAG}-sb2 (Spring Boot 2.6.6)"
echo "  - ${ECR_REPO}:${TAG}-sb3 (Spring Boot 3.0.0)"

# Push to ECR if PUSH=true
if [ "$PUSH" = "true" ]; then
    echo "Pushing images to ECR..."
    
    # Login to ECR
    aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $ECR_REPO
    
    # Push all images
    docker push ${ECR_REPO}:${TAG}
    docker push ${ECR_REPO}:${TAG}-sb2
    docker push ${ECR_REPO}:${TAG}-sb3
    
    echo "Images pushed successfully!"
fi

echo "Done!" 