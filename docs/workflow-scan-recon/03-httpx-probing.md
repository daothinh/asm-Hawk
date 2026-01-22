# HTTPX Probing Tool

Chi tiết công cụ HTTP probing để phát hiện live web servers.

---

## HTTPX

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-httpx-1` |
| **API Endpoint** | `POST /api/httpx/run` |
| **Database Table** | `httpx_scans` |
| **Source File** | `server/utils/liveWebServers.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-httpx-1 \
  httpx \
  -l /tmp/httpx-{scanID}/domains.txt \
  -ports 80,443,7547,8089,8085,8443,8080,4567,7170,8008,2083,8000,2082,8081,2087,2086,8888,8880,60000,40000,9080,5985,9100,2096,3000,1024,30005,81,21,5000,2095 \
  -json \
  -status-code \
  -title \
  -tech-detect \
  -server \
  -content-length \
  -no-color \
  -timeout 10 \
  -retries 2 \
  -rate-limit {rateLimit} \
  -mc 100,101,200,201,202,203,204,205,206,207,208,226,300,301,302,303,304,305,307,308,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,421,422,423,424,426,428,429,431,451,500,501,502,503,504,505,506,507,508,510,511 \
  [-H "User-Agent: {customUserAgent}"] \
  [-H "{customHeader}"] \
  -o /tmp/httpx-{scanID}/httpx-output.json
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-l {file}` | Input file chứa danh sách domains |
| `-ports {ports}` | Danh sách ports cần scan |
| `-json` | Output JSON format |
| `-status-code` | Hiển thị HTTP status code |
| `-title` | Extract page title |
| `-tech-detect` | Technology detection |
| `-server` | Hiển thị server header |
| `-content-length` | Hiển thị content length |
| `-no-color` | Không dùng color output |
| `-timeout 10` | Timeout 10 giây |
| `-retries 2` | Số lần retry |
| `-rate-limit {n}` | Rate limit (từ settings, default: 150) |
| `-mc {codes}` | Match các status codes |
| `-H {header}` | Custom HTTP header |
| `-o {file}` | Output file |

### Ports Scanned
```
80, 443, 7547, 8089, 8085, 8443, 8080, 4567, 7170, 8008, 
2083, 8000, 2082, 8081, 2087, 2086, 8888, 8880, 60000, 
40000, 9080, 5985, 9100, 2096, 3000, 1024, 30005, 81, 21, 
5000, 2095
```

### Request Body
```json
{
  "fqdn": "example.com"
}
```

### Go Code
```go
func ExecuteAndParseHttpxScan(scanID, domain string) {
    // Get rate limit from settings
    rateLimit := GetHttpxRateLimit()
    
    // Get custom HTTP settings
    customUserAgent, customHeader := GetCustomHTTPSettings()
    
    // Get consolidated subdomains
    rows, _ := dbPool.Query(ctx, 
        `SELECT subdomain FROM consolidated_subdomains WHERE scope_target_id = $1`,
        scopeTargetID)
    
    // Write domains to temp file
    domainsFile := filepath.Join(tempDir, "domains.txt")
    os.WriteFile(domainsFile, []byte(strings.Join(domainsToScan, "\n")), 0644)
    
    // Build ports list
    ports := []int{80, 443, 7547, 8089, 8085, 8443, 8080, 4567, 7170, 8008, 
                   2083, 8000, 2082, 8081, 2087, 2086, 8888, 8880, 60000, 
                   40000, 9080, 5985, 9100, 2096, 3000, 1024, 30005, 81, 21, 
                   5000, 2095}
    
    // Build docker command
    dockerCmd := []string{
        "docker", "exec",
        "ars0n-framework-v2-httpx-1",
        "httpx",
        "-l", filepath.Join("/tmp", fmt.Sprintf("httpx-%s", scanID), "domains.txt"),
        "-ports", portsFlag,
        "-json",
        "-status-code",
        "-title",
        "-tech-detect",
        "-server",
        "-content-length",
        "-no-color",
        "-timeout", "10",
        "-retries", "2",
        "-rate-limit", fmt.Sprintf("%d", rateLimit),
        "-mc", "100,101,200,201,...,511",
    }
    
    // Add custom headers
    if customUserAgent != "" {
        dockerCmd = append(dockerCmd, "-H", fmt.Sprintf("User-Agent: %s", customUserAgent))
    }
    if customHeader != "" {
        dockerCmd = append(dockerCmd, "-H", customHeader)
    }
    
    // Add output file
    dockerCmd = append(dockerCmd, "-o", outputPath)
    
    // Execute
    cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
    cmd.Run()
    
    // Process results
    result, _ := os.ReadFile(outputFile)
    
    // Update target URLs in database
    for _, line := range strings.Split(string(result), "\n") {
        var httpxResult map[string]interface{}
        json.Unmarshal([]byte(line), &httpxResult)
        UpdateTargetURLFromHttpx(scopeTargetID, httpxResult)
    }
}
```

---

## HTTPX Output Format

### JSON Output Fields
```json
{
  "url": "https://example.com",
  "status-code": 200,
  "title": "Example Domain",
  "webserver": "nginx",
  "content-length": 1256,
  "technologies": ["nginx", "PHP"],
  "host": "example.com",
  "port": "443",
  "scheme": "https"
}
```

### Database Storage (target_urls table)
```sql
CREATE TABLE target_urls (
    id UUID PRIMARY KEY,
    url VARCHAR(2048) NOT NULL,
    status_code INTEGER,
    title VARCHAR(512),
    web_server VARCHAR(256),
    technologies TEXT[],
    content_length INTEGER,
    newly_discovered BOOLEAN DEFAULT true,
    no_longer_live BOOLEAN DEFAULT false,
    scope_target_id UUID REFERENCES scope_targets(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    -- SSL/TLS flags
    has_deprecated_tls BOOLEAN DEFAULT false,
    has_expired_ssl BOOLEAN DEFAULT false,
    has_mismatched_ssl BOOLEAN DEFAULT false,
    has_revoked_ssl BOOLEAN DEFAULT false,
    has_self_signed_ssl BOOLEAN DEFAULT false,
    has_untrusted_root_ssl BOOLEAN DEFAULT false,
    has_wildcard_tls BOOLEAN DEFAULT false,
    -- Additional fields
    findings_json JSONB,
    http_response TEXT,
    http_response_headers JSONB,
    dns_a_records TEXT[],
    dns_aaaa_records TEXT[],
    dns_cname_records TEXT[],
    dns_mx_records TEXT[],
    dns_txt_records TEXT[],
    dns_ns_records TEXT[],
    dns_ptr_records TEXT[],
    dns_srv_records TEXT[],
    katana_results JSONB,
    ffuf_results JSONB,
    roi_score INTEGER DEFAULT 0
);
```

---

## Consolidation Process

### Mô tả
Trước khi chạy HTTPX, cần thực hiện consolidation để merge kết quả từ các subdomain discovery tools.

### Sources được consolidate
1. Amass subdomains
2. Sublist3r results
3. Assetfinder results
4. CTL results
5. Subfinder results
6. GAU results (extract hostname từ URLs)
7. ShuffleDNS results
8. ShuffleDNS Custom results
9. GoSpider results
10. Subdomainizer results

### Go Code
```go
func ConsolidateSubdomains(scopeTargetID string) ([]string, error) {
    uniqueSubdomains := make(map[string]bool)
    
    // Get from Amass
    amassQuery := `SELECT subdomain FROM subdomains WHERE scan_id IN 
                   (SELECT scan_id FROM amass_scans WHERE scope_target_id = $1 
                    AND status = 'success')`
    
    // Get from other tools (sublist3r, assetfinder, ctl, subfinder, etc.)
    queries := []struct{ query, table string }{
        {`SELECT result FROM sublist3r_scans WHERE scope_target_id = $1 AND status = 'completed'...`, "sublist3r"},
        {`SELECT result FROM assetfinder_scans WHERE scope_target_id = $1 AND status = 'success'...`, "assetfinder"},
        // ... more queries
    }
    
    for _, q := range queries {
        result := dbPool.QueryRow(ctx, q.query, scopeTargetID)
        // Parse and add to uniqueSubdomains
    }
    
    // Save to consolidated_subdomains table
    for subdomain := range uniqueSubdomains {
        tx.Exec(ctx, 
            `INSERT INTO consolidated_subdomains (scope_target_id, subdomain) 
             VALUES ($1, $2) ON CONFLICT DO NOTHING`,
            scopeTargetID, subdomain)
    }
    
    return consolidatedSubdomains, nil
}
```

---

## API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/httpx/run` | Start HTTPX scan |
| GET | `/api/httpx/{scanID}` | Get scan status |
| GET | `/api/scopetarget/{id}/scans/httpx` | Get all scans for target |
| GET | `/api/consolidate-subdomains/{id}` | Trigger consolidation |
| GET | `/api/consolidated-subdomains/{id}` | Get consolidated subdomains |

---

## Rate Limit Configuration

```go
func GetHttpxRateLimit() int {
    // Query from user_settings table
    // Default: 150
    var rateLimit int
    err := dbPool.QueryRow(ctx, 
        `SELECT httpx_rate_limit FROM user_settings LIMIT 1`).Scan(&rateLimit)
    if err != nil || rateLimit == 0 {
        return 150 // Default
    }
    return rateLimit
}
```
