# ASM-Hawk Hybrid Architecture
## Tích hợp Ars0n Framework v2 Tools với Minimal Coupling

> **Philosophy**: Giữ nguyên tool containers từ ars0n, tự build orchestration layer phù hợp với Prisma.

---

## 1. Kiến Trúc Tổng Thể

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ASM-HAWK v2                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 1: Presentation]                                                     │
│  ┌──────────────┐                                                           │
│  │ Web (Next.js)│ ←── Dashboard, Reports, Visualizations                    │
│  └──────────────┘                                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 2: API Gateway]                                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  NestJS API (:3000)                                                  │   │
│  │  - REST/GraphQL endpoints                                            │   │
│  │  - Authentication & Authorization                                    │   │
│  │  - Request validation                                                │   │
│  │  - Proxy to Recon Engine                                             │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 3: Orchestration]                                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │              RECON ENGINE (Go) - Port 8443                              ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  Workflow Orchestrator                                          │   ││
│  │  │  - Company Discovery Workflow                                   │   ││
│  │  │  - Wildcard Subdomain Workflow                                  │   ││
│  │  │  - URL Attack Surface Workflow                                  │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  Tool Executors (docker exec wrappers)                          │   ││
│  │  │  - SubfinderExecutor, NucleiExecutor, HttpxExecutor, etc.       │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  Result Parsers & Normalizers                                   │   ││
│  │  │  - Parse JSON/text output → Structured data                     │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  └─────────────────────────────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 4: Background Jobs]                                                  │
│  ┌──────────────────────────────────┐ ┌────────────────────────────────────┐│
│  │ BullMQ Workers                   │ │ Scheduled Jobs (Cron)               ││
│  │ - Long-running scans             │ │ - Auto-discovery                   ││
│  │ - Result processing              │ │ - Periodic re-scans                ││
│  │ - Notification dispatch          │ │ - Data cleanup                     ││
│  └──────────────────────────────────┘ └────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 5: Data]                                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────────────┐│
│  │ PostgreSQL      │ │ ClickHouse      │ │ Redis                           ││
│  │ + Prisma ORM    │ │ (Analytics/TSDB)│ │ (Cache/Queue)                   ││
│  │ - Scan results  │ │ - Historical    │ │ - Job queues                    ││
│  │ - Configs       │ │ - Metrics       │ │ - Session cache                 ││
│  └─────────────────┘ └─────────────────┘ └─────────────────────────────────┘│
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 6: Tool Containers] (from ars0n-framework)                           │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │subfinder│ │  httpx │ │ nuclei │ │ katana │ │  ffuf  │ │  dnsx  │         │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘         │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐         │
│  │gospider│ │wayback │ │shuffledns│ │ cewl  │ │metabigor│ │cloud_enum│      │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Sync Strategy với Ars0n Upstream

### 2.1. Thư Mục Được Đồng Bộ (SYNC)
Các thư mục này copy trực tiếp từ ars0n khi có update:

```
ars0n-framework-v2/
└── docker/                    → asm-hawk/docker/
    ├── subfinder/
    ├── nuclei/
    ├── httpx/
    ├── katana/
    ├── ffuf/
    ├── dnsx/
    ├── gospider/
    ├── waybackurls/
    ├── shuffledns/
    ├── cewl/
    ├── assetfinder/
    ├── metabigor/
    ├── sublist3r/
    ├── subdomainizer/
    ├── github-recon/
    ├── cloud_enum/
    └── linkfinder/
```

### 2.2. Thư Mục Tham Khảo (REFERENCE)
Logic có thể khác nhau, chỉ tham khảo updates:

```
ars0n-framework-v2/
└── server/
    ├── utils/                  # Reference: Scan logic, parsing patterns
    ├── database.go             # Reference: Schema changes
    └── types.go                # Reference: Type definitions
```

### 2.3. Script Tự Động Sync

Tạo file `scripts/sync-ars0n-tools.sh`:

```bash
#!/bin/bash
# Sync tool containers from ars0n-framework-v2

ARS0N_PATH="/path/to/ars0n-framework-v2"
ASM_HAWK_PATH="/path/to/asm-hawk"

TOOLS=(
  "subfinder" "httpx" "nuclei" "katana" "ffuf" "dnsx"
  "gospider" "waybackurls" "shuffledns" "cewl" "assetfinder"
  "metabigor" "sublist3r" "subdomainizer" "github-recon"
  "cloud_enum" "linkfinder"
)

echo "🔄 Syncing ars0n tool containers..."

for tool in "${TOOLS[@]}"; do
  if [ -d "$ARS0N_PATH/docker/$tool" ]; then
    echo "  ✓ Syncing $tool..."
    rsync -av --delete "$ARS0N_PATH/docker/$tool/" "$ASM_HAWK_PATH/docker/$tool/"
  fi
done

echo "✅ Sync complete!"
echo "⚠️  Remember to rebuild containers: docker-compose build"
```

---

## 3. Recon Engine Architecture

### 3.1. Hiện Tại (Port từ ars0n)
```
recon/
├── main.go              # HTTP routes + handlers
├── database.go          # Direct PostgreSQL (pgx)
├── types.go             # Data structures
└── utils/               # 38 utility files
    ├── amassUtils.go
    ├── subfinderUtils.go
    └── ... (tool-specific)
```

### 3.2. Đề Xuất Refactor (Clean Architecture)
```
recon/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── api/
│   │   ├── routes.go
│   │   ├── middleware.go
│   │   └── handlers/
│   │       ├── scan_handler.go
│   │       └── config_handler.go
│   ├── executor/                    # Tool execution layer
│   │   ├── interface.go             # ToolExecutor interface
│   │   ├── docker_executor.go       # docker exec wrapper
│   │   └── tools/
│   │       ├── subfinder.go
│   │       ├── nuclei.go
│   │       ├── httpx.go
│   │       └── ...
│   ├── parser/                      # Output parsing
│   │   ├── interface.go
│   │   └── parsers/
│   │       ├── json_parser.go
│   │       ├── line_parser.go
│   │       └── tool_specific/
│   ├── repository/                  # Data access (Prisma-compatible)
│   │   ├── interface.go
│   │   └── postgres_repository.go
│   ├── workflow/                    # Workflow orchestration
│   │   ├── company_workflow.go
│   │   ├── wildcard_workflow.go
│   │   └── url_workflow.go
│   └── config/
│       └── config.go
├── pkg/
│   └── models/
│       └── scan_models.go
└── go.mod
```

---

## 4. Tool Executor Interface

### 4.1. Base Interface

```go
// internal/executor/interface.go
package executor

import "context"

type ScanRequest struct {
    ScopeTargetID string
    Target        string    // domain, ip, url depending on tool
    Options       map[string]interface{}
    Timeout       time.Duration
}

type ScanResult struct {
    ScanID        string
    Status        string    // "pending", "running", "completed", "failed"
    RawOutput     string
    ParsedResult  interface{}
    Error         error
    ExecutionTime time.Duration
    Command       string
}

type ToolExecutor interface {
    Name() string
    ContainerName() string
    Execute(ctx context.Context, req ScanRequest) (*ScanResult, error)
    ParseOutput(raw string) (interface{}, error)
    Validate(req ScanRequest) error
}
```

### 4.2. Docker Executor Base

```go
// internal/executor/docker_executor.go
package executor

import (
    "context"
    "fmt"
    "os/exec"
    "time"
)

type DockerExecutor struct {
    containerName string
}

func (d *DockerExecutor) DockerExec(ctx context.Context, args []string) (string, string, error) {
    cmdArgs := append([]string{"exec", d.containerName}, args...)
    cmd := exec.CommandContext(ctx, "docker", cmdArgs...)
    
    stdout, err := cmd.Output()
    if exitErr, ok := err.(*exec.ExitError); ok {
        return string(stdout), string(exitErr.Stderr), err
    }
    return string(stdout), "", err
}
```

### 4.3. Example: Subfinder Executor

```go
// internal/executor/tools/subfinder.go
package tools

import (
    "context"
    "strings"
    "time"
    
    "asm-hawk/recon/internal/executor"
)

type SubfinderExecutor struct {
    *executor.DockerExecutor
}

func NewSubfinderExecutor() *SubfinderExecutor {
    return &SubfinderExecutor{
        DockerExecutor: &executor.DockerExecutor{
            containerName: "asm-hawk-subfinder",
        },
    }
}

func (s *SubfinderExecutor) Name() string { return "subfinder" }
func (s *SubfinderExecutor) ContainerName() string { return "asm-hawk-subfinder" }

func (s *SubfinderExecutor) Execute(ctx context.Context, req executor.ScanRequest) (*executor.ScanResult, error) {
    start := time.Now()
    
    args := []string{"subfinder", "-d", req.Target, "-silent"}
    
    // Add rate limit if configured
    if rateLimit, ok := req.Options["rateLimit"].(int); ok {
        args = append(args, "-rate-limit", fmt.Sprintf("%d", rateLimit))
    }
    
    stdout, stderr, err := s.DockerExec(ctx, args)
    
    result := &executor.ScanResult{
        ScanID:        uuid.New().String(),
        Status:        "completed",
        RawOutput:     stdout,
        ExecutionTime: time.Since(start),
        Command:       strings.Join(args, " "),
    }
    
    if err != nil {
        result.Status = "failed"
        result.Error = err
    } else {
        parsed, _ := s.ParseOutput(stdout)
        result.ParsedResult = parsed
    }
    
    return result, nil
}

func (s *SubfinderExecutor) ParseOutput(raw string) (interface{}, error) {
    subdomains := []string{}
    for _, line := range strings.Split(raw, "\n") {
        if trimmed := strings.TrimSpace(line); trimmed != "" {
            subdomains = append(subdomains, trimmed)
        }
    }
    return subdomains, nil
}

func (s *SubfinderExecutor) Validate(req executor.ScanRequest) error {
    if req.Target == "" {
        return errors.New("target domain is required")
    }
    return nil
}
```

---

## 5. Prisma-Compatible Repository

```go
// internal/repository/postgres_repository.go
package repository

import (
    "context"
    "time"
    
    "github.com/jackc/pgx/v5/pgxpool"
)

type ScanRepository interface {
    // Generic scan operations
    CreateScan(ctx context.Context, tableName string, scan *ScanRecord) error
    UpdateScanStatus(ctx context.Context, tableName, scanID, status string) error
    UpdateScanResult(ctx context.Context, tableName, scanID string, result *ScanResult) error
    GetScan(ctx context.Context, tableName, scanID string) (*ScanRecord, error)
    ListScans(ctx context.Context, tableName, scopeTargetID string) ([]ScanRecord, error)
}

// ScanRecord matches Prisma schema structure
type ScanRecord struct {
    ID                string     `json:"id"`
    ScanID            string     `json:"scan_id"`
    ScopeTargetID     *string    `json:"scope_target_id"`
    Domain            string     `json:"domain,omitempty"`
    URL               string     `json:"url,omitempty"`
    CompanyName       string     `json:"company_name,omitempty"`
    Status            string     `json:"status"`
    Result            *string    `json:"result"`
    Error             *string    `json:"error"`
    Stdout            *string    `json:"stdout"`
    Stderr            *string    `json:"stderr"`
    Command           *string    `json:"command"`
    ExecutionTime     *string    `json:"execution_time"`
    CreatedAt         time.Time  `json:"created_at"`
    AutoScanSessionID *string    `json:"auto_scan_session_id"`
}

type PostgresRepository struct {
    pool *pgxpool.Pool
}

func (r *PostgresRepository) CreateScan(ctx context.Context, tableName string, scan *ScanRecord) error {
    // Dynamic query based on table name to match Prisma schema
    query := fmt.Sprintf(`
        INSERT INTO %s (scan_id, scope_target_id, domain, status, created_at)
        VALUES ($1, $2, $3, $4, NOW())
        RETURNING id
    `, tableName)
    
    return r.pool.QueryRow(ctx, query, 
        scan.ScanID, scan.ScopeTargetID, scan.Domain, scan.Status,
    ).Scan(&scan.ID)
}
```

---

## 6. Workflow Orchestration

```go
// internal/workflow/wildcard_workflow.go
package workflow

import (
    "context"
    "asm-hawk/recon/internal/executor/tools"
    "asm-hawk/recon/internal/repository"
)

type WildcardWorkflow struct {
    repo       repository.ScanRepository
    subfinder  *tools.SubfinderExecutor
    assetfinder *tools.AssetfinderExecutor
    httpx      *tools.HttpxExecutor
    // ... other tools
}

type WorkflowStep struct {
    Name      string
    Tool      executor.ToolExecutor
    DependsOn []string
    Enabled   bool
}

func (w *WildcardWorkflow) Execute(ctx context.Context, scopeTargetID, domain string) error {
    steps := []WorkflowStep{
        {Name: "subfinder", Tool: w.subfinder, Enabled: true},
        {Name: "assetfinder", Tool: w.assetfinder, DependsOn: []string{}, Enabled: true},
        {Name: "consolidate_round1", Tool: w.httpx, DependsOn: []string{"subfinder", "assetfinder"}, Enabled: true},
        // ... more steps
    }
    
    for _, step := range steps {
        if !step.Enabled {
            continue
        }
        
        // Wait for dependencies
        // Execute tool
        // Save results to Prisma via repository
    }
    
    return nil
}
```

---

## 7. Migration Path

### Phase 1: Foundation (Current)
- [x] Tool containers synced from ars0n
- [x] Prisma schema with all scan models
- [x] Basic recon engine (ported from ars0n)

### Phase 2: Refactor (Next Sprint)
- [ ] Abstract executor interface
- [ ] Separate parsing from execution
- [ ] Clean repository pattern

### Phase 3: Enhance (Future)
- [ ] Parallel workflow execution
- [ ] Better error handling & retry
- [ ] Progress streaming via WebSocket
- [ ] Result deduplication

### Phase 4: Scale (Production)
- [ ] Kubernetes deployment
- [ ] Tool container auto-scaling
- [ ] Distributed scanning across regions

---

## 8. Updating From Ars0n Upstream

When ars0n releases updates:

1. **Check Release Notes** - Identify what changed
2. **Sync Tool Containers** - Run `scripts/sync-ars0n-tools.sh`
3. **Review Logic Changes** - Compare `server/utils/*.go` 
4. **Update Schema if Needed** - Add new fields to `engine-schema.prisma`
5. **Test** - Run integration tests
6. **Rebuild Containers** - `docker-compose build`

---

## 9. Key Differences from Ars0n

| Aspect | Ars0n | ASM-Hawk |
|--------|-------|----------|
| ORM | Raw SQL (pgx) | Prisma |
| Language | Go only | Go + TypeScript |
| Frontend | React (bundled) | Next.js (separate) |
| Queue | None | BullMQ + Redis |
| Analytics | PostgreSQL | ClickHouse |
| Auth | None | JWT + RBAC |
| Multi-tenant | No | Yes |

---

## 10. Best Practices

1. **Never modify tool containers** - Sync-only from ars0n
2. **Keep parsing logic separate** - Easy to update when tool output changes
3. **Use interfaces everywhere** - Mock for testing
4. **Version your scans** - Track which tool version produced results
5. **Log everything** - Debugging distributed scans is hard
