# 02 - System Architecture

## Hybrid Architecture

```mermaid
flowchart TB
    subgraph Frontend ["Frontend Layer"]
        UI[React/Next.js Dashboard]
    end
    
    subgraph API ["API Layer - NestJS"]
        A1[REST API]
        A2[WebSocket Notifications]
        A3[Auth/JWT + RBAC]
        A4[Prisma ORM]
    end
    
    subgraph Queue ["Message Queue"]
        Q1[Redis + BullMQ]
        Q2[Job Scheduler]
    end
    
    subgraph Core ["Core Engine - Go"]
        C1[OSINT Scanner]
        C2[Port Scanner - goroutines]
        C3[JARM Fingerprint - hdm/jarm-go]
        C4[Attack Verifier]
    end
    
    subgraph Workers ["TI Workers - Python"]
        W1[VirusTotal - vt-py]
        W2[URLScan.io]
        W3[Censys - censys-python]
        W4[Risk Scorer ML]
    end
    
    subgraph Data ["Data Layer"]
        DB1[(PostgreSQL - Primary)]
        DB2[(ClickHouse - Analytics)]
        CDC[PeerDB CDC Sync]
    end
    
    UI --> A1
    A1 --> A4 --> DB1
    A1 --> Q1
    Q1 --> Core
    Q1 --> Workers
    Core --> DB2
    Workers --> DB1
    DB1 --> CDC --> DB2
```

---

## Inter-Service Communication

| Pattern | Protocol | Use Case |
|---------|----------|----------|
| API → Workers | Redis Queue (BullMQ) | Async job scheduling |
| Workers → API | Redis Pub/Sub | Real-time notifications |
| Go ↔ NestJS | gRPC (optional) | High-perf sync calls |
| PostgreSQL → ClickHouse | CDC (PeerDB) | Real-time data sync |

---

## Key Libraries

| Component | Library | Purpose |
|-----------|---------|---------|
| Go Port Scanner | `gopacket`, `net` | SYN/TCP scans |
| Go JARM | `hdm/jarm-go` | TLS fingerprinting |
| Python TI | `vt-py`, `censys-python` | API clients |
| DB Sync | PeerDB / ClickPipes | CDC replication |
| Job Queue | BullMQ (NestJS) | Reliable job management |

---

## Project Structure

```
asm-hawk/
├── api/                    # NestJS API Server
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/       # JWT + RBAC
│   │   │   ├── users/      # User management
│   │   │   ├── assets/     # Asset CRUD
│   │   │   ├── scans/      # Scan orchestration
│   │   │   ├── alerts/     # Alert management
│   │   │   └── dashboard/  # Analytics endpoints
│   │   ├── jobs/           # BullMQ processors
│   │   └── prisma/         # DB service
│   ├── prisma/schema.prisma
│   └── package.json
│
├── scanner/                # Go Core Engine
│   ├── cmd/scanner/main.go
│   ├── internal/
│   │   ├── osint/
│   │   ├── portscan/
│   │   ├── jarm/
│   │   ├── attack/
│   │   └── queue/
│   └── go.mod
│
├── workers/                # Python TI Workers
│   ├── src/
│   │   ├── virustotal/
│   │   ├── urlscan/
│   │   ├── censys/
│   │   ├── risk_scorer/
│   │   └── common/
│   └── requirements.txt
│
├── web/                    # React/Next.js Frontend
│   └── src/
│
├── docker/                 # Dockerfiles
├── nginx/                  # Reverse proxy
├── redis/                  # Redis config
└── docs/                   # Documentation
```
