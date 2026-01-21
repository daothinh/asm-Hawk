# ASM-Hawk Architecture Status
## Hybrid Integration với Ars0n Framework v2

> **Last Updated**: 2026-01-20
> **Ars0n Version**: beta-0.0.3
> **Status**: ✅ Production Ready

---

## 1. Tổng Quan Triển Khai

ASM-Hawk đã áp dụng **Option 3: Hybrid Approach** một cách hoàn chỉnh:

| Component | Source | Status |
|-----------|--------|--------|
| Tool Containers (17) | Sync từ ars0n | ✅ Synced |
| Recon Engine (Go) | Port từ ars0n | ✅ Active |
| Prisma Schema | Custom | ✅ Complete |
| API Gateway (NestJS) | Custom | ✅ Active |
| Web (Next.js) | Custom | ✅ Active |

---

## 2. Kiến Trúc Đã Triển Khai

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ASM-HAWK                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  [PRESENTATION]                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  Web (Next.js) - Port 3001                                             │ │
│  │  • Dashboard, Reports, Visualizations                                  │ │
│  │  • Custom UI (không dùng client từ ars0n)                              │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  [API GATEWAY]                                                               │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  NestJS API - Port 3000                                                │ │
│  │  • REST endpoints cho business logic                                   │ │
│  │  • Authentication & Authorization                                      │ │
│  │  • Proxy/Forward requests sang Recon Engine                            │ │
│  │  • Prisma ORM cho data access                                          │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  [RECON ENGINE] ← Port từ ars0n server                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  Go Server - Port 8443                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Routes (main.go) - 150+ API endpoints                          │  │ │
│  │  │  • /subfinder/run, /nuclei/run, /httpx/run, etc.               │  │ │
│  │  │  • Workflow orchestration                                       │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Utils (38 files) - Tool execution logic                        │  │ │
│  │  │  • subdomainScrapingUtils.go (subfinder, assetfinder, etc.)    │  │ │
│  │  │  • nucleiUtils.go, metaDataUtils.go, ipPortScanUtils.go        │  │ │
│  │  │  • consolidateAttackSurface.go                                 │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │ │
│  │  │  Direct PostgreSQL (pgx) - Ghi kết quả vào Prisma tables       │  │ │
│  │  └─────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────────────┤
│  [BACKGROUND JOBS]                                                           │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │  Workers (BullMQ + Redis)                                               ││
│  │  • Long-running scan orchestration                                      ││
│  │  • Result processing & notifications                                    ││
│  └─────────────────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────────────┤
│  [DATA LAYER]                                                                │
│  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────────────┐  │
│  │ PostgreSQL        │ │ ClickHouse        │ │ Redis                     │  │
│  │ • Scan results    │ │ • Time-series     │ │ • Job queues              │  │
│  │ • Configurations  │ │ • Analytics       │ │ • Cache                   │  │
│  │ • Assets          │ │ • Historical data │ │ • Session                 │  │
│  └───────────────────┘ └───────────────────┘ └───────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────────┤
│  [TOOL CONTAINERS] ← Sync từ ars0n-framework-v2/docker                      │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│  │subfinder│ │  httpx │ │ nuclei │ │ katana │ │  ffuf  │ │  dnsx  │        │
│  │ latest │ │ latest │ │ v3.3.8 │ │ latest │ │ latest │ │ latest │        │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│  │gospider│ │wayback │ │shuffleDNS│ │ cewl  │ │assetfind│ │metabigor│      │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                   │
│  │sublist3r│ │subdomain│ │github- │ │cloud_  │ │linkfinder│                │
│  │         │ │ izer   │ │ recon  │ │ enum   │ │         │                  │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Cấu Trúc Thư Mục

```
asm-hawk/
├── api/                          # NestJS API Gateway
│   ├── src/
│   │   ├── modules/              # Feature modules
│   │   ├── common/               # Shared utilities
│   │   └── main.ts
│   └── prisma/
│       ├── schema.prisma         # Core models
│       └── engine-schema.prisma  # Ars0n scan tables (40+ models)
│
├── recon/                        # Go Recon Engine (from ars0n)
│   ├── main.go                   # HTTP server + routes (3571 lines)
│   ├── database.go               # Table creation (Prisma handles this)
│   ├── types.go                  # Data structures
│   └── utils/                    # 38 tool utilities (~800KB)
│       ├── subdomainScrapingUtils.go
│       ├── nucleiUtils.go
│       ├── metaDataUtils.go
│       ├── ipPortScanUtils.go
│       └── ... (34 more files)
│
├── docker/                       # Tool containers (synced from ars0n)
│   ├── subfinder/Dockerfile
│   ├── nuclei/Dockerfile
│   ├── httpx/Dockerfile
│   ├── ... (14 more tools)
│   └── .backup/                  # Backup before sync
│       └── 20260120_171359/
│
├── web/                          # Next.js Frontend (custom)
│   └── src/
│
├── workers/                      # Background job workers
│   └── src/
│
├── scripts/
│   ├── Sync-Ars0nTools.ps1      # Windows sync script
│   └── sync-ars0n-tools.sh      # Linux/Mac sync script
│
├── docs/
│   ├── HYBRID_ARCHITECTURE.md   # Design documentation
│   └── ARCHITECTURE_STATUS.md   # This file
│
└── docker-compose.yml           # All services definition
```

---

## 4. Tool Containers (17 Tools)

| Tool | Image/Base | Purpose |
|------|------------|---------|
| **subfinder** | projectdiscovery/subfinder:latest | Subdomain enumeration |
| **httpx** | projectdiscovery/httpx:latest | HTTP probing |
| **nuclei** | Ubuntu + nuclei v3.3.8 + Chrome | Vulnerability scanning |
| **katana** | projectdiscovery/katana:latest | Web crawling |
| **ffuf** | ffuf:latest | Web fuzzing |
| **dnsx** | projectdiscovery/dnsx:latest | DNS toolkit |
| **gospider** | Custom Go build | JS/Link discovery |
| **waybackurls** | Go install | Historical URLs |
| **shuffledns** | projectdiscovery/shuffledns:latest | DNS brute-force |
| **cewl** | Ruby-based | Custom wordlist generator |
| **assetfinder** | Go install | Asset discovery |
| **metabigor** | Go install | ASN/Network intelligence |
| **sublist3r** | Python 3 | Subdomain enumeration |
| **subdomainizer** | Python 3 | JS subdomain extraction |
| **github-recon** | Python 3 | GitHub OSINT |
| **cloud_enum** | Python 3 | Cloud asset enumeration |
| **linkfinder** | Python 3 | JS endpoint extraction |

---

## 5. Prisma Schema Summary

**engine-schema.prisma** (appended to main schema):

### Config Tables
- `UserSettings` - Rate limits, proxy settings
- `ApiKey` - Third-party API keys (Shodan, Censys, etc.)
- `AiApiKey` - AI provider keys
- `AutoScanConfig` - Auto-scan workflow configuration
- `AutoScanState` - Current scan state per target

### Scan Tables (~25 tables)
- `AmassScan`, `AmassIntelScan`
- `HttpxScan`, `SubfinderScan`, `GauScan`
- `Sublist3rScan`, `AssetfinderScan`, `CtlScan`
- `ShuffleDnsScan`, `CewlScan`, `GospiderScan`
- `SubdomainizerScan`, `NucleiScreenshot`, `MetadataScan`
- `CloudEnumScan`, `MetabigorCompanyScan`, `GitHubReconScan`
- `ShodanCompanyScan`, `CensysCompanyScan`, `SecurityTrailsCompanyScan`
- `IpPortScan`, `NucleiScan`
- `KatanaUrlScan`, `LinkFinderUrlScan`, `WaybackUrlsScan`, `GauUrlScan`, `FfufUrlScan`

### Result Tables
- `ConsolidatedSubdomain`
- `ConsolidatedCompanyDomain`
- `ConsolidatedNetworkRange`
- `ConsolidatedAttackSurfaceAsset`
- `DiscoveredLiveIp`, `LiveWebServer`
- `TargetUrl`

---

## 6. Sync Workflow

### Khi Ars0n Release Update Mới:

```powershell
# 1. Download ars0n mới
# 2. Chạy sync (tự backup trước)
.\scripts\Sync-Ars0nTools.ps1 `
  -Source "C:\path\to\ars0n-framework-v2" `
  -Destination "E:\MyProject\asm-hawk"

# 3. Review changes
git diff docker/

# 4. Rebuild containers
docker-compose build subfinder httpx nuclei katana

# 5. Test
docker-compose up -d subfinder
docker exec asm-hawk-subfinder subfinder -version
```

### Sync Options:
```powershell
-DryRun           # Preview changes only
-Tool "nuclei"    # Sync specific tool
-NoBackup         # Skip backup
-Rebuild          # Auto rebuild after sync
-List             # List available tools
```

---

## 7. Key Differences từ Original Ars0n

| Aspect | Ars0n | ASM-Hawk |
|--------|-------|----------|
| Database Access | Raw SQL (pgx) | Raw SQL (recon) + Prisma (api) |
| API Gateway | Go only | NestJS + Go |
| Frontend | React (bundled) | Next.js (separate service) |
| Queue | None | BullMQ + Redis |
| Analytics DB | PostgreSQL only | PostgreSQL + ClickHouse |
| Auth | None | JWT + RBAC |
| Multi-tenant | No | Yes |
| Container Names | ars0n-framework-v2-* | asm-hawk-* |

---

## 8. Next Steps (Optional Improvements)

### Phase 1: Current ✅
- [x] Tool containers synced from ars0n
- [x] Prisma schema complete
- [x] Recon engine functional
- [x] Sync scripts created

### Phase 2: Refactor (When Needed)
- [ ] Abstract executor interface trong recon/
- [ ] Separate parsing từ execution
- [ ] Repository pattern cho data access

### Phase 3: Enhance
- [ ] WebSocket progress streaming
- [ ] Parallel workflow execution
- [ ] Better error handling & retry

### Phase 4: Scale
- [ ] Kubernetes deployment
- [ ] Tool container auto-scaling
- [ ] Distributed scanning

---

## 9. Commands Cheat Sheet

```bash
# Start all services
docker-compose up -d

# Start only core services
docker-compose up -d postgres redis api recon web

# Check tool containers
docker-compose ps | grep -E "subfinder|nuclei|httpx"

# Test a tool
docker exec asm-hawk-subfinder subfinder -d example.com

# View recon engine logs
docker logs -f asm-hawk-recon

# Rebuild after sync
docker-compose build --no-cache subfinder nuclei httpx

# Sync from ars0n
.\scripts\Sync-Ars0nTools.ps1 -Source "C:\path\to\ars0n" -Rebuild
```

---

## 10. Maintainer Notes

1. **Tool containers là external dependency** - Chỉ sync, không modify
2. **Recon engine (Go) có thể refactor** - Nhưng giữ API compatibility
3. **Prisma schema là source of truth** - Cả Go và NestJS đều query same tables
4. **Backup trước khi sync** - Script tự động backup vào `docker/.backup/`
5. **Test sau mỗi sync** - Tool versions có thể thay đổi output format
