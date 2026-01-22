# Subdomain Discovery Tools

Chi tiết các công cụ khám phá subdomain trong ars0n-framework-v2.

---

## 1. Sublist3r

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-sublist3r-1` |
| **API Endpoint** | `POST /api/sublist3r/run` |
| **Database Table** | `sublist3r_scans` |
| **Source File** | `server/utils/subdomainScrapingUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-sublist3r-1 \
  python /app/sublist3r.py \
  -d {domain} \
  -v \
  -t 50 \
  -o /dev/stdout
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-d {domain}` | Domain target |
| `-v` | Verbose mode |
| `-t 50` | Số threads (50) |
| `-o /dev/stdout` | Output ra stdout |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Go Code
```go
cmd := exec.Command(
    "docker", "exec",
    "ars0n-framework-v2-sublist3r-1",
    "python", "/app/sublist3r.py",
    "-d", domain,
    "-v",
    "-t", "50",
    "-o", "/dev/stdout",
)
```

---

## 2. Assetfinder

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-assetfinder-1` |
| **API Endpoint** | `POST /api/assetfinder/run` |
| **Database Table** | `assetfinder_scans` |
| **Source File** | `server/utils/subdomainScrapingUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-assetfinder-1 \
  assetfinder \
  --subs-only \
  {domain}
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `--subs-only` | Chỉ output subdomains |
| `{domain}` | Domain target |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Go Code
```go
cmd := exec.Command(
    "docker", "exec",
    "ars0n-framework-v2-assetfinder-1",
    "assetfinder",
    "--subs-only",
    domain,
)
```

---

## 3. Subfinder

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-subfinder-1` |
| **API Endpoint** | `POST /api/subfinder/run` |
| **Database Table** | `subfinder_scans` |
| **Source File** | `server/utils/subdomainScrapingUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-subfinder-1 \
  subfinder \
  -d {domain} \
  -all
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-d {domain}` | Domain target |
| `-all` | Sử dụng tất cả sources |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

---

## 4. GAU (GetAllUrls)

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `sxcurity/gau:latest` (docker run) |
| **API Endpoint** | `POST /api/gau/run` |
| **Database Table** | `gau_scans` |
| **Source File** | `server/utils/subdomainScrapingUtils.go` |

### Docker Command (Attempt 1)
```bash
docker run --rm \
  sxcurity/gau:latest \
  {domain} \
  --providers wayback \
  --json \
  --verbose \
  --subs \
  --threads 10 \
  --timeout 60 \
  --retries 2
```

### Docker Command (Attempt 2 - Fallback)
```bash
docker run --rm \
  sxcurity/gau:latest \
  {domain} \
  --providers wayback,otx,urlscan \
  --subs \
  --threads 5 \
  --timeout 30 \
  --retries 3
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `{domain}` | Domain target |
| `--providers wayback` | Sử dụng Wayback Machine |
| `--json` | Output JSON format |
| `--verbose` | Verbose mode |
| `--subs` | Include subdomains |
| `--threads 10` | Số threads |
| `--timeout 60` | Timeout (giây) |
| `--retries 2` | Số lần retry |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Go Code
```go
dockerCmd := []string{
    "docker", "run", "--rm",
    "sxcurity/gau:latest",
    domain,
    "--providers", "wayback",
    "--json",
    "--verbose",
    "--subs",
    "--threads", "10",
    "--timeout", "60",
    "--retries", "2",
}
cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
```

---

## 5. CTL (Certificate Transparency Logs)

### Thông tin
| Property | Value |
|----------|-------|
| **API Endpoint** | `POST /api/ctl/run` |
| **Database Table** | `ctl_scans` |
| **Source File** | `server/utils/subdomainScrapingUtils.go` |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Mô tả
CTL scan sử dụng Certificate Transparency Logs để tìm subdomain thông qua SSL certificates.

---

## Workflow Execution Pattern

Mỗi tool tuân theo pattern sau:

```go
// 1. HTTP Handler - Nhận request từ frontend
func Run*Scan(w http.ResponseWriter, r *http.Request) {
    // Parse domain từ request body
    var requestData struct { FQDN string `json:"fqdn"` }
    json.NewDecoder(r.Body).Decode(&requestData)
    
    // Generate scan ID
    scanID := uuid.New().String()
    
    // Insert vào database với status "pending"
    dbPool.Exec(ctx, 
        `INSERT INTO *_scans (scan_id, domain, status, scope_target_id) 
         VALUES ($1, $2, $3, $4)`,
        scanID, domain, "pending", scopeTargetID)
    
    // Chạy scan trong goroutine (async)
    go ExecuteAndParse*Scan(scanID, domain)
    
    // Return scan_id cho frontend polling
    json.NewEncoder(w).Encode(map[string]string{"scan_id": scanID})
}

// 2. Executor - Thực thi Docker command
func ExecuteAndParse*Scan(scanID, domain string) {
    startTime := time.Now()
    
    // Build docker command
    cmd := exec.Command("docker", "exec", container, tool, args...)
    
    // Execute và capture output
    var stdout, stderr bytes.Buffer
    cmd.Stdout = &stdout
    cmd.Stderr = &stderr
    err := cmd.Run()
    
    // Parse và xử lý kết quả
    result := stdout.String()
    
    // Update database
    Update*ScanStatus(scanID, "success", result, ...)
}

// 3. Status Update
func Update*ScanStatus(scanID, status, result, stderr string) {
    dbPool.Exec(ctx,
        `UPDATE *_scans 
         SET status = $1, result = $2, stderr = $3 
         WHERE scan_id = $4`,
        status, result, stderr, scanID)
}
```

---

## Database Schema

```sql
CREATE TABLE sublist3r_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    result TEXT,
    error TEXT,
    stdout TEXT,
    stderr TEXT,
    command TEXT,
    execution_time VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    scope_target_id UUID REFERENCES scope_targets(id),
    auto_scan_session_id UUID
);
```
