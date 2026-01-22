# Web Scraping Tools

Chi tiết các công cụ web scraping để tìm thêm subdomains từ JavaScript và web content.

---

## 1. GoSpider

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-gospider-1` |
| **API Endpoint** | `POST /api/gospider/run` |
| **Database Table** | `gospider_scans` |
| **Source File** | `server/utils/javaScriptLinkDiscovery.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-gospider-1 \
  timeout 300 \
  gospider \
  -s {url} \
  -c 10 \
  -d 3 \
  -t 3 \
  -k 1 \
  -K 2 \
  -m 30 \
  --blacklist ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|svg)" \
  -a \
  -w \
  -r \
  --js \
  --sitemap \
  --robots \
  --debug \
  --json \
  -v \
  [--user-agent {customUserAgent}] \
  [--header {customHeader}]
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `timeout 300` | Timeout 300 giây |
| `-s {url}` | Starting URL |
| `-c 10` | Concurrency 10 |
| `-d 3` | Depth 3 |
| `-t 3` | Threads 3 |
| `-k 1` | Keep-alive connections |
| `-K 2` | Keep-alive timeout |
| `-m 30` | Max URLs to crawl |
| `--blacklist {regex}` | Blacklist file extensions |
| `-a` | Include all links |
| `-w` | Include links in wayback |
| `-r` | Follow redirects |
| `--js` | Include JavaScript files |
| `--sitemap` | Parse sitemap |
| `--robots` | Parse robots.txt |
| `--debug` | Debug mode |
| `--json` | JSON output |
| `-v` | Verbose output |
| `--user-agent {ua}` | Custom User Agent |
| `--header {header}` | Custom HTTP header |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Workflow
1. Lấy kết quả HTTPX scan gần nhất để có danh sách live URLs
2. Chạy GoSpider trên mỗi URL
3. Extract subdomains từ output
4. Deduplicate và sort kết quả

### Go Code
```go
func executeAndParseGoSpiderScan(scanID, domain string) {
    // Get custom HTTP settings
    customUserAgent, customHeader := GetCustomHTTPSettings()
    
    // Get HTTPX results
    var httpxResults string
    dbPool.QueryRow(ctx, 
        `SELECT result FROM httpx_scans 
         WHERE scope_target_id = (SELECT scope_target_id FROM gospider_scans WHERE scan_id = $1)
         AND status = 'success'
         ORDER BY created_at DESC 
         LIMIT 1`, scanID).Scan(&httpxResults)
    
    urls := strings.Split(httpxResults, "\n")
    
    var allSubdomains []string
    seen := make(map[string]bool)
    
    for _, urlLine := range urls {
        var httpxResult struct{ URL string `json:"url"` }
        json.Unmarshal([]byte(urlLine), &httpxResult)
        
        if httpxResult.URL == "" {
            continue
        }
        
        cmd := exec.Command(
            "docker", "exec",
            "ars0n-framework-v2-gospider-1",
            "timeout", "300",
            "gospider",
            "-s", httpxResult.URL,
            "-c", "10",
            "-d", "3",
            "-t", "3",
            "-k", "1",
            "-K", "2",
            "-m", "30",
            "--blacklist", ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|ico|svg)",
            "-a",
            "-w",
            "-r",
            "--js",
            "--sitemap",
            "--robots",
            "--debug",
            "--json",
            "-v",
        )
        
        // Add custom user agent if specified
        if customUserAgent != "" {
            cmd.Args = append(cmd.Args, "--user-agent", customUserAgent)
        }
        
        // Add custom header if specified
        if customHeader != "" {
            cmd.Args = append(cmd.Args, "--header", customHeader)
        }
        
        var stdout, stderr bytes.Buffer
        cmd.Stdout = &stdout
        cmd.Stderr = &stderr
        cmd.Run()
        
        // Parse output and extract subdomains
        lines := strings.Split(stdout.String(), "\n")
        for _, line := range lines {
            parsedURL, err := url.Parse(line)
            if err == nil {
                hostname := parsedURL.Hostname()
                if strings.Contains(hostname, domain) && !seen[hostname] {
                    seen[hostname] = true
                    allSubdomains = append(allSubdomains, hostname)
                }
            }
        }
    }
    
    sort.Strings(allSubdomains)
    result := strings.Join(allSubdomains, "\n")
    
    updateGoSpiderScanStatus(scanID, "success", result, ...)
}
```

---

## 2. Subdomainizer

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-subdomainizer-1` |
| **API Endpoint** | `POST /api/subdomainizer/run` |
| **Database Table** | `subdomainizer_scans` |
| **Source File** | `server/utils/javaScriptLinkDiscovery.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-subdomainizer-1 \
  timeout 300 \
  python3 SubDomainizer.py \
  -u {url} \
  -k \
  -o /tmp/subdomainizer-mounts/output.txt \
  -sop /tmp/subdomainizer-mounts/secrets.txt
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `timeout 300` | Timeout 300 giây |
| `-u {url}` | Target URL |
| `-k` | Keep file (không delete output) |
| `-o {file}` | Output file cho subdomains |
| `-sop {file}` | Output file cho secrets |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Workflow
1. Tạo mount directory trong container
2. Lấy kết quả HTTPX scan để có danh sách URLs
3. Chạy Subdomainizer trên mỗi URL
4. Đọc kết quả từ output file
5. Collect và deduplicate subdomains
6. Cleanup files

### Go Code
```go
func executeAndParseSubdomainizerScan(scanID, domain string) {
    // Create mount directory in container
    mkdirCmd := exec.Command(
        "docker", "exec",
        "ars0n-framework-v2-subdomainizer-1",
        "mkdir", "-p", "/tmp/subdomainizer-mounts",
    )
    mkdirCmd.Run()
    
    // Set permissions
    chmodCmd := exec.Command(
        "docker", "exec",
        "ars0n-framework-v2-subdomainizer-1",
        "chmod", "777", "/tmp/subdomainizer-mounts",
    )
    chmodCmd.Run()
    
    // Get HTTPX results
    var httpxResults string
    dbPool.QueryRow(ctx, 
        `SELECT result FROM httpx_scans 
         WHERE scope_target_id = (SELECT scope_target_id FROM subdomainizer_scans WHERE scan_id = $1)
         AND status = 'success'
         ORDER BY created_at DESC 
         LIMIT 1`, scanID).Scan(&httpxResults)
    
    urls := strings.Split(httpxResults, "\n")
    
    var allSubdomains []string
    seen := make(map[string]bool)
    
    for _, urlLine := range urls {
        var httpxResult struct{ URL string `json:"url"` }
        json.Unmarshal([]byte(urlLine), &httpxResult)
        
        if httpxResult.URL == "" {
            continue
        }
        
        cmd := exec.Command(
            "docker", "exec",
            "ars0n-framework-v2-subdomainizer-1",
            "timeout", "300",
            "python3", "SubDomainizer.py",
            "-u", httpxResult.URL,
            "-k",
            "-o", "/tmp/subdomainizer-mounts/output.txt",
            "-sop", "/tmp/subdomainizer-mounts/secrets.txt",
        )
        
        cmd.Run()
        
        // Read output file
        catCmd := exec.Command(
            "docker", "exec",
            "ars0n-framework-v2-subdomainizer-1",
            "cat", "/tmp/subdomainizer-mounts/output.txt",
        )
        
        var outputContent bytes.Buffer
        catCmd.Stdout = &outputContent
        catCmd.Run()
        
        // Parse and collect subdomains
        lines := strings.Split(outputContent.String(), "\n")
        for _, line := range lines {
            line = strings.TrimSpace(line)
            if line != "" && strings.Contains(line, domain) && !seen[line] {
                seen[line] = true
                allSubdomains = append(allSubdomains, line)
            }
        }
    }
    
    // Cleanup
    cleanupCmd := exec.Command(
        "docker", "exec",
        "ars0n-framework-v2-subdomainizer-1",
        "rm", "-rf", "/tmp/subdomainizer-mounts",
    )
    cleanupCmd.Run()
    
    sort.Strings(allSubdomains)
    result := strings.Join(allSubdomains, "\n")
    
    updateSubdomainizerScanStatus(scanID, "success", result, ...)
}
```

---

## Subdomain Extraction Logic

### GoSpider
```go
// Extract từ parsed URL
parsedURL, err := url.Parse(line)
if err == nil {
    hostname := parsedURL.Hostname()
    if strings.Contains(hostname, domain) {
        allSubdomains = append(allSubdomains, hostname)
    }
}

// Fallback với regex
urlRegex := regexp.MustCompile(`https?://[^\s<>"']+|[^\s<>"']+\.[^\s<>"']+`)
matches := urlRegex.FindAllString(line, -1)
for _, match := range matches {
    if !strings.HasPrefix(match, "http") {
        match = "https://" + match
    }
    if matchURL, err := url.Parse(match); err == nil {
        hostname := matchURL.Hostname()
        if strings.Contains(hostname, domain) {
            allSubdomains = append(allSubdomains, hostname)
        }
    }
}
```

### Subdomainizer
Subdomainizer tự động extract subdomains từ JavaScript files và output vào file. Server chỉ cần đọc output file.

---

## API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/gospider/run` | Start GoSpider scan |
| GET | `/api/gospider/{scan_id}` | Get scan status |
| GET | `/api/scopetarget/{id}/scans/gospider` | Get all scans for target |
| POST | `/api/subdomainizer/run` | Start Subdomainizer scan |
| GET | `/api/subdomainizer/{scan_id}` | Get scan status |
| GET | `/api/scopetarget/{id}/scans/subdomainizer` | Get all scans for target |

---

## Database Schema

```sql
CREATE TABLE gospider_scans (
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

CREATE TABLE subdomainizer_scans (
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
