FROM golang:1.24-bookworm AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y git ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy go mod files first for better caching
COPY go.mod go.sum ./

# Verify go.mod and go.sum are present
RUN test -f go.mod && test -f go.sum || (echo "go.mod or go.sum missing" && exit 1)

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main cmd/api/main.go

# Final stage
FROM debian:bookworm-slim

WORKDIR /root/

# Install ca-certificates for HTTPS requests
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/main .

# Copy migrations for auto-migration on startup
COPY --from=builder /app/migrations ./migrations

# Expose port
EXPOSE 3000

# Run the application
CMD ["./main"]

