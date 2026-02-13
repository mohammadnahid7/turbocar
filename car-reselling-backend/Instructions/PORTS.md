# Port Configuration Guide

This document tracks all ports used by the Car Reselling Backend project to avoid conflicts.

## Port Allocation Strategy

We use a consistent port mapping strategy:
- **Host ports** (what you access from your machine): Use non-standard ports to avoid conflicts
- **Container ports** (internal Docker network): Use standard ports

## Port Assignments

### Development/Testing Ports

| Service | Host Port | Container Port | Purpose | Notes |
|---------|-----------|----------------|---------|-------|
| **API Server** | `3000` | `3000` | Main API endpoint | Access via http://localhost:3000 |
| **PostgreSQL** | `15432` | `5432` | Database | Standard PostgreSQL port in container |
| **Redis** | `16379` | `6379` | Cache/Sessions | Standard Redis port in container |

### Why These Ports?

- **3000**: Common development port, rarely conflicts
- **15432**: PostgreSQL alternative (5432 + 10000), avoids conflicts with local PostgreSQL
- **16379**: Redis alternative (6379 + 10000), avoids conflicts with local Redis

## Port Conflict Resolution

If you encounter port conflicts:

1. **Check what's using the port:**
   ```bash
   lsof -i :PORT_NUMBER
   # or
   ss -tulpn | grep :PORT_NUMBER
   ```

2. **Stop conflicting service** (if it's safe to do so)

3. **Or change the port** in:
   - `docker-compose.yml` (host port mapping)
   - `.env` file (if connecting to external services)

## Configuration Files

Ports are configured in:
- `docker-compose.yml` - Docker port mappings
- `.env.example` / `.env` - Environment variables for connections
- `internal/config/config.go` - Application configuration

## Production Deployment

For production, ports will be managed by:
- **Cloud platforms** (AWS, GCP, Azure): Use their load balancer/ingress
- **Kubernetes**: Use Service definitions
- **Docker Swarm**: Use overlay network
- **Standalone**: Use reverse proxy (nginx, Traefik) on port 80/443

**Important:** Never expose database/Redis ports directly in production. Use:
- Private networks/VPCs
- VPN connections
- SSH tunnels
- Managed database services

## Testing Port Availability

```bash
# Test if port is available
nc -zv localhost 3000
nc -zv localhost 15432
nc -zv localhost 16379
```

## Port Change Checklist

If you need to change ports:

- [ ] Update `docker-compose.yml` port mappings
- [ ] Update `.env.example` with new ports
- [ ] Update `.env` (if exists)
- [ ] Update `SETUP.md` documentation
- [ ] Update `API_DOCUMENTATION.md` base URL
- [ ] Test all services can connect
- [ ] Update this PORTS.md file

## Reserved Ports (Do Not Use)

These ports are commonly used and should be avoided:
- `80` - HTTP (production)
- `443` - HTTPS (production)
- `3306` - MySQL
- `5432` - PostgreSQL (standard, conflicts with local)
- `6379` - Redis (standard, conflicts with local)
- `27017` - MongoDB
- `3000` - Common development (we use 3000 instead)
- `9000` - PHP-FPM
- `9200` - Elasticsearch

