# Multi-stage Dockerfile for Spring Boot eBPF Test App
# Supports both Spring Boot 2.6.6 and 3.0.0

# Build stage
FROM amazoncorretto:17-alpine AS builder

# Install Maven
RUN apk add --no-cache maven

WORKDIR /app

# Copy POM file first for better layer caching
COPY pom.xml .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build argument to specify Spring Boot version
ARG SPRING_BOOT_VERSION=spring-boot-2
ENV SPRING_BOOT_PROFILE=${SPRING_BOOT_VERSION}

# Build the application
RUN mvn clean package -P${SPRING_BOOT_PROFILE} -DskipTests

# Runtime stage
FROM amazoncorretto:17-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create app user
RUN addgroup -g 1000 appuser && adduser -u 1000 -G appuser -s /bin/sh -D appuser

WORKDIR /app

# Copy the built JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Change ownership to app user
RUN chown appuser:appuser app.jar

# Switch to app user
USER appuser

# Environment variables with defaults
ENV SERVICE_NAME=frontend
ENV SERVER_PORT=8080
ENV NEXT_SERVICE_URL=""
ENV IS_LEAF_SERVICE=false
ENV JAVA_OPTS=""

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${SERVER_PORT}/api/health || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"] 