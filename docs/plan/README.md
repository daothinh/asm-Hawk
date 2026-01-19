# ASM-Hawk Development Plan

Comprehensive development plan for Attack Surface Management platform.

## Table of Contents
- [01 - Overview](01-overview.md) - Project objectives and decisions
- [02 - Architecture](02-architecture.md) - System design and structure  
- [03 - Database Schema](03-database.md) - Prisma models and optimization
- [04 - Development Roadmap](04-roadmap.md) - 5-phase timeline
- [05 - Phase 1 Status](05-phase1-status.md) - Current implementation status
- [06 - Environment](06-environment.md) - Configuration and setup
- [07 - API Reference](07-api-reference.md) - Complete endpoint documentation

---

## Quick Reference

### Tech Stack
| Layer | Technology |
|-------|------------|
| Frontend | React/Next.js |
| API | NestJS + Prisma 7 |
| Core Engine | Go |
| TI Workers | Python |
| Queue | Redis + BullMQ |
| Database | PostgreSQL + ClickHouse |

### Project Structure
```
asm-hawk/
├── api/          # NestJS API Server
├── scanner/      # Go Core Engine
├── workers/      # Python TI Workers
├── web/          # React/Next.js Frontend
├── docker/       # Dockerfiles
├── nginx/        # Reverse proxy
├── redis/        # Redis config
└── docs/         # Documentation
```

### Development Status
- [x] Phase 1: Foundation (API Complete, needs DB)
- [ ] Phase 2: Core Scanning
- [ ] Phase 3: Threat Intelligence
- [ ] Phase 4: Attack Verification
- [ ] Phase 5: Production

---

## Quick Start

```bash
# 1. Start PostgreSQL
docker run -d --name asm-postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=asm_hawk \
  -p 5432:5432 postgres:16

# 2. Setup API
cd api
npm install
npx prisma migrate dev --name init
npm run start:dev

# 3. Test
curl http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"password123"}'
```

