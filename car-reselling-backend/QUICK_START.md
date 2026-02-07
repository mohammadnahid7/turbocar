# Quick Start Guide

## Port Configuration

| Service | Host Port | Container Port | Access URL |
|---------|-----------|----------------|------------|
| API | 3000 | 3000 | http://localhost:3000 |
| PostgreSQL | 15432 | 5432 | localhost:15432 |
| Redis | 16379 | 6379 | localhost:16379 |

## Quick Commands

### Start Everything
```bash
docker-compose up -d
```

### Stop Everything
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f api
```

### Test API
```bash
curl http://localhost:3000/health
```

### Connect to Database
```bash
psql -h localhost -p 15432 -U postgres -d car_reselling_db
```

### Connect to Redis
```bash
redis-cli -h localhost -p 16379
```

## Environment Setup

1. Copy environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your settings (ports are already configured)

3. Start services:
   ```bash
   docker-compose up -d
   ```

## Troubleshooting

### Port Already in Use
If you get port conflicts, check `PORTS.md` for alternative ports.

### Check What's Using a Port
```bash
lsof -i :PORT_NUMBER
# or
ss -tulpn | grep :PORT_NUMBER
```

### Reset Everything
```bash
docker-compose down -v  # Removes volumes too
docker-compose up -d
```

## Important Notes

- **Host ports** (3000, 15432, 16379) are what you use from your machine
- **Container ports** (3000, 5432, 6379) are internal to Docker network
- Internal services communicate using container names: `postgres:5432`, `redis:6379`
- External access uses host ports: `localhost:3000`, `localhost:15432`, `localhost:16379`

