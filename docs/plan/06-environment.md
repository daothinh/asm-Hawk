# 06 - Environment & Configuration

## Environment Variables

### API Server (.env)

```bash
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/asm_hawk?schema=public"

# JWT Authentication
JWT_SECRET="asm-hawk-super-secret-jwt-key-change-in-production"
JWT_EXPIRES_IN="7d"

# Redis
REDIS_HOST="localhost"
REDIS_PORT="6379"

# API Server
PORT="3000"
CORS_ORIGIN="http://localhost:3001"

# ClickHouse (Analytics)
CLICKHOUSE_HOST="localhost"
CLICKHOUSE_PORT="8123"
CLICKHOUSE_DATABASE="asm_hawk_analytics"

# Threat Intelligence APIs
VIRUSTOTAL_API_KEY=""
URLSCAN_API_KEY=""
CENSYS_API_ID=""
CENSYS_API_SECRET=""
ABUSEIPDB_API_KEY=""
SHODAN_API_KEY=""
```

---

## Docker Compose Services

| Service | Port | Image |
|---------|------|-------|
| postgres | 5432 | postgres:16-alpine |
| clickhouse | 8123, 9000 | clickhouse/clickhouse-server:latest |
| redis | 6379 | redis:alpine |
| nginx | 80, 443 | nginx:alpine |
| api | 3000 | Built from docker/api.Dockerfile |
| scanner | - | Built from docker/scanner.Dockerfile |
| workers | - | Built from docker/workers.Dockerfile |
| web | 3001 | Built from docker/web.Dockerfile |

---

## Required Dependencies

### API (NestJS)
```json
{
  "@nestjs/common": "^11.x",
  "@nestjs/config": "^4.x",
  "@nestjs/jwt": "^11.x",
  "@nestjs/passport": "^11.x",
  "@nestjs/bullmq": "^11.x",
  "@nestjs/mapped-types": "^2.x",
  "prisma": "^7.x",
  "@prisma/client": "^7.x",
  "passport-jwt": "^4.x",
  "bcryptjs": "^2.x",
  "class-validator": "^0.14.x",
  "class-transformer": "^0.5.x"
}
```

### Go Scanner
```
go 1.22+
github.com/go-redis/redis/v8
github.com/hdm/jarm-go
```

### Python Workers
```
redis>=5.0
rq>=1.16
vt-py>=0.19
censys>=2.2
requests>=2.31
```

---

## Prisma 7 Configuration

### prisma.config.ts
```typescript
import path from 'node:path';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: path.join(__dirname, 'prisma', 'schema.prisma'),
});
```

### Notes
- Prisma 7 moved `url` from schema.prisma to runtime config
- Database URL now comes from `DATABASE_URL` env var
- Must have PostgreSQL running before starting API

---

## Starting Development Environment

### Option 1: Docker Compose (Recommended)
```bash
# Start all infrastructure
docker-compose up -d postgres redis clickhouse nginx

# Run migrations
cd api && npx prisma migrate dev --name init

# Start API in dev mode
npm run start:dev
```

### Option 2: Local Services
```bash
# 1. Start PostgreSQL
docker run -d --name asm-postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=asm_hawk \
  -p 5432:5432 postgres:16

# 2. Start Redis
docker run -d --name asm-redis -p 6379:6379 redis:alpine

# 3. Setup API
cd api
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```
