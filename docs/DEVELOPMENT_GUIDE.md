# ASM-Hawk Development Guide

## Quick Start

### Prerequisites
- Docker Desktop (with Docker Compose v2)
- Node.js 20+ (for local development)
- Git

### 1. Clone and Start

```bash
# Clone the repository
git clone <repository-url>
cd asm-hawk

# Start all services
docker-compose up -d
```

### 2. Access the Application

| Service | URL | Description |
|---------|-----|-------------|
| **Web UI** | http://localhost:3101 | Next.js Frontend |
| **API** | http://localhost:3100/api | NestJS Backend |
| **PostgreSQL** | localhost:5432 | Database |
| **Redis** | localhost:6379 | Cache/Queue |

### 3. Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@asm-hawk.local | password123 |
| Analyst | analyst@asm-hawk.local | password123 |
| Viewer | viewer@asm-hawk.local | password123 |

---

## Port Configuration

The project uses ports starting from 3100:

| Service | Host Port | Container Port |
|---------|-----------|----------------|
| API (NestJS) | 3100 | 3100 |
| Web (Next.js) | 3101 | 3101 |
| Recon Engine | 8443 | 8443 |
| PostgreSQL | 5432 | 5432 |
| Redis | 6379 | 6379 |
| ClickHouse HTTP | 8123 | 8123 |
| ClickHouse Native | 9000 | 9000 |

---

## Development Workflow

### Starting Development Servers

```bash
# Start core services (postgres, redis)
docker-compose up -d postgres redis

# Start API and Web in dev mode
docker-compose up -d api web

# View logs
docker-compose logs -f api web
```

### Rebuilding After Code Changes

```bash
# Rebuild specific service
docker-compose up -d --build api
docker-compose up -d --build web

# Force recreate (for config changes)
docker-compose up -d --force-recreate api web

# Full rebuild (clean)
docker-compose down
docker-compose up -d --build
```

### Database Operations

```bash
# Run migrations
docker exec asm-hawk-api npx prisma migrate deploy

# Seed database
docker exec asm-hawk-api npx prisma db seed

# Reset database (WARNING: deletes all data)
docker exec asm-hawk-api npx prisma migrate reset --force

# Open Prisma Studio
docker exec -it asm-hawk-api npx prisma studio
```

---

## Troubleshooting Guide

### Issue: "Failed to fetch" on Login/Register

**Cause**: Frontend cannot reach API

**Solutions**:
1. Check API is running: `docker logs asm-hawk-api`
2. Verify `NEXT_PUBLIC_API_URL=http://localhost:3100` in docker-compose.yml
3. Ensure API container has `PORT=3100` environment variable

### Issue: "relation does not exist" Database Error

**Cause**: Database migrations not applied

**Solution**:
```bash
docker exec asm-hawk-api npx prisma migrate deploy
docker exec asm-hawk-api npx prisma db seed
```

### Issue: Scan fails with "docker: not found"

**Cause**: API container missing Docker CLI

**Solution**: Ensure docker-compose.yml has:
```yaml
api:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

And api.Dockerfile includes:
```dockerfile
RUN apk add --no-cache openssl docker-cli
```

### Issue: Web UI not accessible

**Cause**: Port mapping or container port mismatch

**Solution**: Verify in docker-compose.yml:
```yaml
web:
  ports:
    - "3101:3101"  # host:container must match
```

And in web.Dockerfile:
```dockerfile
CMD ["npx", "next", "dev", "-p", "3101", "-H", "0.0.0.0"]
```

### Issue: API shows old port in logs after code change

**Cause**: TypeScript cache not cleared

**Solution**:
```bash
# Clear dist folder and restart
docker exec asm-hawk-api rm -rf /app/dist
docker restart asm-hawk-api
```

Or rebuild completely:
```bash
docker-compose up -d --build --force-recreate api
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Network                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   Web UI    │────▶│   API       │────▶│   Postgres  │       │
│  │  (Next.js)  │     │  (NestJS)   │     │             │       │
│  │   :3101     │     │   :3100     │     │   :5432     │       │
│  └─────────────┘     └──────┬──────┘     └─────────────┘       │
│                             │                                   │
│                             │ Docker Socket                     │
│                             ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Tool Containers                        │   │
│  │  subfinder │ httpx │ nuclei │ katana │ dnsx │ ...       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐       │
│  │   Redis     │     │   Workers   │     │ ClickHouse  │       │
│  │   :6379     │     │  (Python)   │     │ :8123/:9000 │       │
│  └─────────────┘     └─────────────┘     └─────────────┘       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Available Scan Tools

| Tool | Purpose | Container |
|------|---------|-----------|
| Subfinder | Subdomain Discovery | asm-hawk-subfinder |
| HTTPX | HTTP Probing | asm-hawk-httpx |
| Nuclei | Vulnerability Scanning | asm-hawk-nuclei |
| Katana | Web Crawling | asm-hawk-katana |
| DNSX | DNS Toolkit | asm-hawk-dnsx |
| GoSpider | JS/Link Discovery | asm-hawk-gospider |
| Wayback URLs | Historical URLs | asm-hawk-waybackurls |
| Assetfinder | Asset Discovery | asm-hawk-assetfinder |
| Sublist3r | Subdomain Enumeration | asm-hawk-sublist3r |

---

## File Structure

```
asm-hawk/
├── api/                    # NestJS Backend
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/       # Authentication
│   │   │   ├── assets/     # Asset management
│   │   │   └── scans/      # Scan orchestration
│   │   └── main.ts         # Entry point (port 3100)
│   └── prisma/
│       └── schema.prisma   # Database schema
├── web/                    # Next.js Frontend
│   └── src/
│       └── app/
│           ├── login/
│           ├── register/
│           └── dashboard/
│               └── scans/  # Scans feature
├── docker/                 # Dockerfiles
│   ├── api.Dockerfile
│   ├── web.Dockerfile
│   └── workers.Dockerfile
├── recon/                  # Go Recon Engine
├── workers/                # Python Workers
└── docker-compose.yml      # Service orchestration
```

---

## Environment Variables

Create `.env` from `.env.example`:

```bash
cp .env.example .env
```

Key variables:
- `DATABASE_URL`: PostgreSQL connection string
- `NEXT_PUBLIC_API_URL`: Frontend API endpoint (http://localhost:3100)
- `PORT`: API port (3100)
- `JWT_SECRET`: Token signing key

---

## Common Commands

```bash
# View all container status
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# View specific service logs
docker logs asm-hawk-api --tail 50 -f
docker logs asm-hawk-web --tail 50 -f

# Execute command in container
docker exec -it asm-hawk-api sh
docker exec -it asm-hawk-web sh

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```
