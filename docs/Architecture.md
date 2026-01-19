# ASM-Hawk Architecture

Kiến trúc kỹ thuật Hybrid cho nền tảng ASM-Hawk.

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | React/Next.js | Web Dashboard |
| **API** | NestJS + Prisma | REST API, WebSocket, RBAC |
| **Core Engine** | Go | Port Scanner, JARM, Attack Verify |
| **TI Workers** | Python | VirusTotal, Censys, ML Scoring |
| **Job Queue** | Redis + BullMQ | Async job scheduling |
| **Primary DB** | PostgreSQL | Transactional data |
| **Analytics DB** | ClickHouse | Time-series analytics |

## System Architecture

```mermaid
flowchart TB
    subgraph Frontend ["Frontend Layer"]
        UI[React/Next.js Dashboard]
    end
    
    subgraph API ["API Layer - NestJS"]
        A1[REST API]
        A2[WebSocket]
        A3[Auth/JWT + RBAC]
        A4[Prisma ORM]
    end
    
    subgraph Queue ["Message Queue"]
        Q1[Redis + BullMQ]
    end
    
    subgraph Core ["Core Engine - Go"]
        C1[OSINT Scanner]
        C2[Port Scanner]
        C3[JARM Fingerprint]
        C4[Attack Verifier]
    end
    
    subgraph Workers ["TI Workers - Python"]
        W1[VirusTotal]
        W2[URLScan.io]
        W3[Censys]
        W4[Risk Scorer ML]
    end
    
    subgraph Data ["Data Layer"]
        DB1[(PostgreSQL)]
        DB2[(ClickHouse)]
        CDC[PeerDB CDC]
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

## Inter-Service Communication

| Pattern | Protocol | Use Case |
|---------|----------|----------|
| API → Workers | Redis Queue (BullMQ) | Async job scheduling |
| Workers → API | Redis Pub/Sub | Real-time notifications |
| Go ↔ NestJS | gRPC (optional) | High-perf sync calls |
| PostgreSQL → ClickHouse | CDC (PeerDB) | Real-time data sync |

## Key Libraries

| Component | Library | Purpose |
|-----------|---------|---------|
| Go Port Scanner | `gopacket`, `net` | SYN/TCP scans |
| Go JARM | `hdm/jarm-go` | TLS fingerprinting |
| Python TI | `vt-py`, `censys-python` | API clients |
| DB Sync | PeerDB / ClickPipes | CDC replication |



## Related Docs
- [Database](Database.md)
- [Workflow](Workflow.md)
- [Sequence](Sequence.md)
