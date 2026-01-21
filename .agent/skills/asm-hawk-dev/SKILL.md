---
name: ASM-Hawk Development
description: Build, run, and troubleshoot ASM-Hawk development environment. Use when working with Docker containers, fixing port issues, running migrations, or debugging the application.
---

# ASM-Hawk Development Skill

This skill provides instructions for building, running, and troubleshooting the ASM-Hawk Attack Surface Management application.

## Project Overview

ASM-Hawk is a multi-service application using:
- **API**: NestJS (TypeScript) on port 3100
- **Web**: Next.js (TypeScript) on port 3101
- **Database**: PostgreSQL on port 5432
- **Cache**: Redis on port 6379
- **Recon Engine**: Go on port 8443
- **Tool Containers**: subfinder, httpx, nuclei, katana, etc.

## Quick Start Commands

### Start Development Environment
```bash
cd E:\MyProject\asm-hawk
docker-compose up -d
```

### Rebuild After Code Changes
```bash
# Rebuild specific service
docker-compose up -d --build api
docker-compose up -d --build web

# Force recreate (for config/env changes)
docker-compose up -d --force-recreate api web
```

### View Logs
```bash
docker logs asm-hawk-api --tail 50 -f
docker logs asm-hawk-web --tail 50 -f
```

### Database Operations
```bash
# Run migrations
docker exec asm-hawk-api npx prisma migrate deploy

# Seed database
docker exec asm-hawk-api npx prisma db seed

# Reset database (WARNING: deletes data)
docker exec asm-hawk-api npx prisma migrate reset --force
```

## Port Configuration

| Service | Host Port | Container Port | URL |
|---------|-----------|----------------|-----|
| API | 3100 | 3100 | http://localhost:3100/api |
| Web | 3101 | 3101 | http://localhost:3101 |
| Recon | 8443 | 8443 | - |
| PostgreSQL | 5432 | 5432 | - |
| Redis | 6379 | 6379 | - |

## Common Issues & Solutions

### Issue: "Failed to fetch" on Login/Register
**Cause**: Frontend can't reach API
**Fix**: 
1. Verify API is running: `docker logs asm-hawk-api`
2. Check `NEXT_PUBLIC_API_URL=http://localhost:3100` in docker-compose.yml
3. Ensure API has `PORT=3100` environment variable

### Issue: "relation does not exist"
**Cause**: Database not migrated
**Fix**:
```bash
docker exec asm-hawk-api npx prisma migrate deploy
docker exec asm-hawk-api npx prisma db seed
```

### Issue: Scan fails with "docker: not found"
**Cause**: API container missing Docker CLI
**Fix**: Ensure api.Dockerfile has:
```dockerfile
RUN apk add --no-cache openssl docker-cli
```
And docker-compose.yml has:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### Issue: Code changes not reflected
**Cause**: TypeScript cache
**Fix**:
```bash
# On Windows
Remove-Item -Recurse -Force api/dist
docker restart asm-hawk-api

# Or rebuild completely
docker-compose up -d --build --force-recreate api
```

### Issue: Port mismatch
**Cause**: Container listens on different port than mapped
**Fix**: Ensure these match:
- docker-compose.yml: `ports: "3100:3100"`
- Dockerfile: `EXPOSE 3100`
- main.ts: `process.env.PORT || 3100`
- Environment: `PORT=3100`

## Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Service orchestration |
| `docker/api.Dockerfile` | API container build |
| `docker/web.Dockerfile` | Web container build |
| `api/src/main.ts` | API entry point (port config) |
| `api/prisma/schema.prisma` | Database schema |
| `web/src/lib/api.ts` | Frontend API client |

## Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@asm-hawk.local | password123 |
| Analyst | analyst@asm-hawk.local | password123 |
| Viewer | viewer@asm-hawk.local | password123 |

## Container Status Check
```bash
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | Select-String "asm-hawk"
```

## Full Rebuild
```bash
docker-compose down
docker-compose up -d --build
docker exec asm-hawk-api npx prisma migrate deploy
docker exec asm-hawk-api npx prisma db seed
```
