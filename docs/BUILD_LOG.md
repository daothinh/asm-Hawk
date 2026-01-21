# ASM-Hawk Build & Deployment Log

This document records the build process, issues encountered, and solutions applied during development.

---

## Session: 2026-01-21

### Initial State
- Docker Compose stack configured but not fully functional
- Web UI not accessible
- Login/Register showing "Failed to fetch" errors
- ClickHouse container unhealthy

---

## Issue #1: Web UI Not Accessible

**Symptom**: Cannot access http://localhost:3001

**Root Cause**: 
- Web Dockerfile was exposing port 3000 but Next.js was configured to run on port 3001 in package.json
- Mismatch between container port and exposed port

**Solution**:
Updated `docker/web.Dockerfile`:
```dockerfile
ENV PORT=3000
EXPOSE 3000
CMD ["npx", "next", "dev", "-p", "3000", "-H", "0.0.0.0"]
```

**Status**: ✅ Resolved

---

## Issue #2: "Failed to fetch" on Login

**Symptom**: Login form shows "Failed to fetch" error when submitting

**Root Cause**: 
- `NEXT_PUBLIC_API_URL` was set to `http://api:3000` (Docker internal network)
- This URL is not accessible from browser (runs on user's machine, not in Docker)

**Solution**:
Updated `docker-compose.yml`:
```yaml
web:
  environment:
    - NEXT_PUBLIC_API_URL=http://localhost:3000
```

**Status**: ✅ Resolved

---

## Issue #3: Database Tables Not Found

**Symptom**: API returns "relation does not exist" errors

**Root Cause**: 
- Prisma migrations not applied to database
- Database was empty

**Solution**:
```bash
docker exec asm-hawk-api npx prisma migrate deploy
docker exec asm-hawk-api npx prisma db seed
```

**Status**: ✅ Resolved

---

## Issue #4: Login Returns accessToken but Frontend Expects access_token

**Symptom**: Login API returns success but frontend doesn't redirect

**Root Cause**: 
- API returns `{ accessToken: "..." }` (camelCase)
- Frontend expected `{ access_token: "..." }` (snake_case)

**Solution**:
Updated `web/src/lib/api.ts` and login/register pages to use `accessToken`:
```typescript
// Before
const token = data.access_token;

// After
const token = data.accessToken;
```

**Status**: ✅ Resolved

---

## Issue #5: Scans Table Does Not Exist

**Symptom**: Creating scan returns "relation public.scans does not exist"

**Root Cause**: 
- Scan model exists in schema but migration not run

**Solution**:
```bash
docker exec asm-hawk-api npx prisma migrate dev --name add_scans
```

**Status**: ✅ Resolved

---

## Issue #6: Scan Execution Fails - "docker: not found"

**Symptom**: Scan starts but immediately fails with "docker: not found"

**Root Cause**: 
- API container doesn't have Docker CLI installed
- Cannot execute `docker exec` to run tool containers

**Solution**:
1. Updated `docker/api.Dockerfile`:
```dockerfile
RUN apk add --no-cache openssl docker-cli
```

2. Ensure Docker socket is mounted in `docker-compose.yml`:
```yaml
api:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

**Status**: ✅ Resolved

---

## Issue #7: Port Configuration Migration (3000 → 3100)

**Requirement**: Change ports to start from 3100 for consistency

**Changes Made**:

1. **docker-compose.yml**:
```yaml
api:
  environment:
    - PORT=3100
  ports:
    - "3100:3100"

web:
  environment:
    - NEXT_PUBLIC_API_URL=http://localhost:3100
  ports:
    - "3101:3101"
```

2. **docker/api.Dockerfile**:
```dockerfile
EXPOSE 3100
```

3. **docker/web.Dockerfile**:
```dockerfile
ENV PORT=3101
EXPOSE 3101
CMD ["npx", "next", "dev", "-p", "3101", "-H", "0.0.0.0"]
```

4. **api/src/main.ts**:
```typescript
const port = process.env.PORT || 3100;
origin: process.env.CORS_ORIGIN || 'http://localhost:3101',
```

5. **web/src/lib/api.ts**:
```typescript
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3100';
```

6. **.env.example**:
```
API_PORT=3100
NEXT_PUBLIC_API_URL=http://localhost:3100
```

**Status**: ✅ Resolved

---

## Issue #8: TypeScript Cache Shows Old Port

**Symptom**: After code changes, logs still show old port 3000

**Root Cause**: 
- Volume mount copies old compiled `dist/` folder from host
- TypeScript watch mode uses cached compilation

**Solution**:
```bash
# Delete dist folder on host
Remove-Item -Recurse -Force api/dist

# Restart container
docker restart asm-hawk-api
```

Or rebuild completely:
```bash
docker-compose up -d --build --force-recreate api
```

**Status**: ✅ Resolved

---

## Final Configuration Summary

### Ports
| Service | Port |
|---------|------|
| API | 3100 |
| Web | 3101 |
| Recon | 8443 |
| PostgreSQL | 5432 |
| Redis | 6379 |

### URLs
- **Web UI**: http://localhost:3101
- **API**: http://localhost:3100/api

### Default Users
- admin@asm-hawk.local / password123

---

## Lessons Learned

1. **Always use environment variables for ports** - Don't hardcode ports in code
2. **Browser-side API calls need external URLs** - Docker internal network names don't work
3. **Check all files when changing ports** - main.ts, api.ts, docker-compose.yml, Dockerfiles
4. **Volume mounts can cache old compiled code** - Delete dist/ when making changes to main.ts
5. **Docker CLI needed in API container** - For executing scans in tool containers
