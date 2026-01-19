# 04 - Development Roadmap


Lộ trình phát triển ASM-Hawk theo 5 giai đoạn

> **Cập nhật lần cuối:** 2026-01-19

---

## Tổng Quan Tiến Độ

| Phase | Tên | Thời gian | Trạng thái |
|-------|-----|-----------|------------|
| 1 | Foundation | Month 1-2 | ✅ Hoàn thành (94%) |
| 2 | Core Scanning | Month 2-3 | ✅ In Progress (80%) |
| 3 | Threat Intelligence | Month 3-4 | ⏳ Chưa bắt đầu |
| 4 | Attack Verification | Month 4-5 | ⏳ Chưa bắt đầu |
| 5 | Production | Month 5-6 | ⏳ Chưa bắt đầu |

---

## Phase 1: Foundation

Xây dựng nền tảng cơ bản: database, API server, authentication và dashboard.

### Database Layer
- [x] Setup PostgreSQL database
- [x] Thiết kế Prisma schema (User, Asset, ReconResult, AttackResult, ExternalIntel, RiskTag)
- [x] Migrations và seed data
- [ ] Setup ClickHouse với PeerDB CDC

### API Server (NestJS)
- [x] Project structure và app module
- [x] Prisma service integration
- [x] JWT Authentication
- [x] Role-Based Access Control (RBAC)
- [x] Auth module (register, login, me)
- [x] Users module (CRUD, role management)
- [x] Assets module (CRUD, search, stats)
- [x] Swagger API documentation

### Web Dashboard (Next.js)
- [x] Project setup với Next.js 15
- [x] Authentication pages (login, register)
- [x] Dashboard layout với sidebar
- [x] Assets list page với pagination

### Infrastructure
- [x] Docker configurations (API, Recon, Workers, Web)
- [x] docker-compose.yml cho local dev
- [x] Nginx reverse proxy config
- [x] Redis config file
- [ ] Redis + BullMQ job queue integration (pending)

---

## Phase 2: Core Scanning ✅ 95% Complete

Engine quét và fingerprinting.

### Docker & Infrastructure ✅
- [x] 17 recon tools dockerized (subfinder, httpx, nuclei, katana, dnsx...)
- [x] Nginx config với timeout settings cho long-running scans
- [x] Network bridge và shared volumes

### API Scan Module ✅
- [x] Scan, ScanResult, ScanSettings Prisma models
- [x] ScansController với REST endpoints
- [x] ScansService với Docker exec integration

### Recon Engine (Go) ✅ Integrated from ars0n-framework
- [x] 38 utils files (subdomain, httpx, nuclei, katana, dnsx, gospider...)
- [x] database.go (1331 dòng SQL schema)
- [x] main.go (3568 dòng, 270+ API routes)
- [x] Docker service với PostgreSQL connection

### Schema Sync ✅ FULL (60+ Models)
- [x] ScopeTarget, AutoScanSession, TargetUrl
- [x] UserSearchPermission, UserScopeAccess (permissions)
- [x] 20+ Scan Tables (AmassScan, HttpxScan, SubfinderScan...)
- [x] IpPortScan, DiscoveredLiveIp, LiveWebServer
- [x] Config Tables (UserSettings, ApiKey, AutoScanConfig...)
- [x] Consolidated Results (Subdomain, NetworkRange, CompanyDomain)
- [x] ConsolidatedAttackSurfaceAsset + relationships
- [x] ThreatModel, NotableObject, SecurityControlNote
- [x] Prisma generate ✅
- [ ] Database migration (user action)

### Remaining
- [ ] Custom Go port scanner với goroutines (optional)

---

## User Permission System (Planned for Phase 5)

Cơ chế quản lý user chặt chẽ với quyền search:

### Permission Types
| Type | Description |
|------|-------------|
| `ALL_SCOPES` | Truy cập toàn bộ scope targets |
| `ASSIGNED_SCOPES` | Chỉ truy cập scopes được assign |
| `READ_ONLY` | Chỉ xem, không chạy scan |
| `CUSTOM` | Quyền tùy chỉnh theo JSON rules |

### UserSearchPermission Model
```prisma
model UserSearchPermission {
  permissionType   SearchPermissionType  // Loại quyền
  canRunScans      Boolean               // Được chạy scans
  canExportData    Boolean               // Được export data
  canViewSensitive Boolean               // Xem dữ liệu nhạy cảm
  maxScansPerDay   Int                   // Rate limit
  searchRules      Json                  // Custom rules
}
```

### UserScopeAccess Model
- Phân quyền theo từng scope target cụ thể
- canRead, canWrite, canRunScans, canDelete
- Audit trail: grantedAt, grantedById

---

## Phase 3: Threat Intelligence ⏳

Python workers tích hợp các nguồn TI bên ngoài.

### TI Workers
- [ ] VirusTotal integration worker
- [ ] URLScan.io integration worker
- [ ] Censys integration worker
- [ ] AbuseIPDB integration worker

### Risk Scoring
- [ ] Risk score calculation engine
- [ ] Multi-source correlation
- [ ] Confidence scoring

---

## Phase 4: Attack Verification ⏳

Engine xác thực exploit và hệ thống cảnh báo.

### Verification Engine
- [ ] Exploit verification module
- [ ] Safe exploitation checks
- [ ] Evidence collection

### Alerting System
- [ ] Alert generation logic
- [ ] Notification channels (Email, Slack, Webhook)
- [ ] Alert dashboard

### Analytics
- [ ] ClickHouse analytics queries
- [ ] Dashboard charts và reports
- [ ] Historical trend analysis

---

## Phase 5: Production ⏳

Tối ưu hóa, bảo mật và deploy production.

### Multi-tenancy
- [ ] Row-Level Security (RLS) implementation
- [ ] Tenant isolation
- [ ] Organization management

### Performance
- [ ] Database query optimization
- [ ] Caching strategies
- [ ] Load testing

### Documentation & Deployment
- [ ] API documentation hoàn chỉnh
- [ ] User guide
- [ ] Deployment scripts (Docker/K8s)
- [ ] CI/CD pipeline

---

## References

- [05 - Phase 1 Status](05-phase1-status.md) - Chi tiết implementation Phase 1
- [07 - API Reference](07-api-reference.md) - API endpoints documentation