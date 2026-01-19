# 04 - Development Roadmap

## Timeline: 5-6 Months

---

## Phase 1: Foundation (Month 1-2) ✅ IN PROGRESS

### Objectives
- [x] Setup PostgreSQL + Prisma 7
- [x] NestJS API với JWT Auth, RBAC
- [ ] Run migrations với PostgreSQL
- [ ] Basic React Dashboard
- [x] Redis + BullMQ job queue

### Deliverables
- NestJS API server with Auth, Users, Assets modules
- Database schema with 7 models
- Docker configs for all services

### Blockers
- Prisma 7.2.0 requires PostgreSQL running with `DATABASE_URL`

---

## Phase 2: Core Scanning (Month 2-3)

### Objectives
- [ ] Go Port Scanner với goroutines
- [ ] Go JARM Fingerprinting (hdm/jarm-go)
- [ ] OSINT Module (subdomain enumeration)
- [ ] Integration with Redis queue

### Key Components
```go
// scanner/internal/portscan/scanner.go
type Scanner struct {
    workers   int
    timeout   time.Duration
    resultCh  chan ScanResult
}

// scanner/internal/jarm/fingerprint.go
type JARMFingerprint struct {
    Hash      string
    Signature string
}
```

---

## Phase 3: Threat Intelligence (Month 3-4)

### Objectives
- [ ] Python VirusTotal worker
- [ ] Python URLScan/Censys workers
- [ ] Risk Score calculation
- [ ] Caching layer (24h TTL)

### Key Components
```python
# workers/src/virustotal/worker.py
class VirusTotalWorker:
    async def check_domain(self, domain: str) -> dict:
        # Query VT API
        # Cache response
        # Return reputation data

# workers/src/risk_scorer/scorer.py
class RiskScorer:
    def calculate_score(self, asset: Asset, intel: List[Intel]) -> float:
        # ML-based scoring algorithm
```

---

## Phase 4: Attack Verification (Month 4-5)

### Objectives
- [ ] Attack verification engine
- [ ] Alert & notification system
- [ ] Dashboard analytics với ClickHouse
- [ ] Real-time WebSocket updates

### Key Features
- Automated exploit verification
- False positive elimination
- Alert thresholds and escalation

---

## Phase 5: Production (Month 5-6)

### Objectives
- [ ] Multi-tenant isolation (RLS)
- [ ] Performance optimization
- [ ] End-to-end testing
- [ ] Documentation & deployment
- [ ] CI/CD pipelines

### Production Checklist
- [ ] Kubernetes deployment configs
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Logging (ELK stack)
- [ ] Backup strategy
- [ ] Security audit

---

## Milestones

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| API Foundation | End Month 1 | ✅ Complete |
| Go Scanner MVP | End Month 2 | 🔲 Pending |
| TI Integration | End Month 3 | 🔲 Pending |
| Full Platform | End Month 5 | 🔲 Pending |
| Production Ready | End Month 6 | 🔲 Pending |
