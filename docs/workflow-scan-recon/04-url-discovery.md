# URL Discovery Tools

Chi tiết các công cụ phát hiện URL trong ars0n-framework-v2.

---

## 1. Katana

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-katana-1` |
| **API Endpoint** | `POST /api/katana-url/run` |
| **Database Table** | `katana_url_scans` |
| **Source File** | `server/utils/urlScanUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-katana-1 \
  katana \
  -u {targetURL} \
  -d 5 \
  -jc \
  -kf all \
  -silent \
  -nc \
  -p 15
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-u {targetURL}` | Target URL |
| `-d 5` | Crawl depth 5 |
| `-jc` | JavaScript crawling |
| `-kf all` | Keep all forms |
| `-silent` | Silent mode |
| `-nc` | No color |
| `-p 15` | Parallelism 15 |

### Request Body
```json
{
  "url": "https://example.com"
}
```

### Go Code
```go
dockerCmd := []string{
    "docker", "exec",
    "ars0n-framework-v2-katana-1",
    "katana",
    "-u", targetURL,
    "-d", "5",
    "-jc",
    "-kf", "all",
    "-silent",
    "-nc",
    "-p", "15",
}
cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
```

---

## 2. Waybackurls

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-waybackurls-1` |
| **API Endpoint** | `POST /api/waybackurls/run` |
| **Database Table** | `waybackurls_scans` |
| **Source File** | `server/utils/urlScanUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-waybackurls-1 \
  waybackurls \
  {targetURL}
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `{targetURL}` | Target URL hoặc domain |

### Request Body
```json
{
  "url": "https://example.com"
}
```

### Go Code
```go
dockerCmd := []string{
    "docker", "exec",
    "ars0n-framework-v2-waybackurls-1",
    "waybackurls",
    targetURL,
}
cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
```

---

## 3. GAU (GetAllUrls) - URL Mode

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `sxcurity/gau:latest` |
| **API Endpoint** | `POST /api/gau-url/run` |
| **Database Table** | `gau_url_scans` |
| **Source File** | `server/utils/urlScanUtils.go` |

### Docker Command
```bash
docker run --rm \
  sxcurity/gau:latest \
  {domain} \
  --providers wayback,commoncrawl,otx \
  --json \
  --threads 10
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `{domain}` | Domain (extracted từ URL) |
| `--providers wayback,commoncrawl,otx` | Data providers |
| `--json` | JSON output |
| `--threads 10` | Số threads |

### Request Body
```json
{
  "url": "https://example.com"
}
```

### Go Code
```go
func ExecuteAndParseGAUURLScan(scanID, targetURL string) {
    // Extract domain from URL
    domain := strings.TrimPrefix(strings.TrimPrefix(targetURL, "https://"), "http://")
    domain = strings.Split(domain, "/")[0]
    
    dockerCmd := []string{
        "docker", "run", "--rm",
        "sxcurity/gau:latest",
        domain,
        "--providers", "wayback,commoncrawl,otx",
        "--json",
        "--threads", "10",
    }
    cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
}
```

---

## 4. LinkFinder

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-linkfinder-1` |
| **API Endpoint** | `POST /api/linkfinder-url/run` |
| **Database Table** | `linkfinder_url_scans` |
| **Source File** | `server/utils/urlScanUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-linkfinder-1 \
  python3 linkfinder.py \
  -i {targetURL} \
  -o cli
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-i {targetURL}` | Input URL |
| `-o cli` | Output to CLI |

### Request Body
```json
{
  "url": "https://example.com"
}
```

### Go Code
```go
dockerCmd := []string{
    "docker", "exec",
    "ars0n-framework-v2-linkfinder-1",
    "python3", "linkfinder.py",
    "-i", targetURL,
    "-o", "cli",
}
cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
```

---

## 5. FFUF (Fuzz Faster U Fool)

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-ffuf-1` |
| **API Endpoint** | `POST /api/ffuf-url/run` |
| **Database Table** | `ffuf_url_scans` |
| **Source File** | `server/utils/urlScanUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-ffuf-1 \
  ffuf \
  -w {wordlistPath} \
  -u {fuzzyURL} \
  -mc {matchCodes} \
  -o /tmp/ffuf-output.json \
  -of json \
  -ac \
  -c \
  -r \
  -t {threads} \
  -timeout 30
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-w {wordlistPath}` | Path đến wordlist (default: `/wordlists/ffuf-wordlist-5000.txt`) |
| `-u {fuzzyURL}` | URL với FUZZ marker |
| `-mc {matchCodes}` | Match status codes (default: `200-299,301,302,307,401,403,405,500`) |
| `-o {file}` | Output file |
| `-of json` | Output format JSON |
| `-ac` | Auto-calibrate |
| `-c` | Colorize output |
| `-r` | Follow redirects |
| `-t {threads}` | Số threads (default: 40) |
| `-timeout 30` | Timeout 30 giây |

### Request Body
```json
{
  "url": "https://example.com",
  "scope_target_id": "uuid-of-scope-target"
}
```

### Configuration Support
FFUF hỗ trợ custom configuration từ database:
```go
var config struct {
    WordlistID       string `json:"wordlistId"`
    Threads          int    `json:"threads"`
    MatchStatusCodes string `json:"matchStatusCodes"`
}
```

### Go Code
```go
func ExecuteAndParseFFUFURLScan(scanID, targetURL, scopeTargetID string) {
    // Get config from database
    var configJSON []byte
    dbPool.QueryRow(ctx, 
        `SELECT config FROM ffuf_configs WHERE scope_target_id = $1`, 
        scopeTargetID).Scan(&configJSON)
    
    // Default values
    wordlistPath := "/wordlists/ffuf-wordlist-5000.txt"
    threads := "40"
    matchCodes := "200-299,301,302,307,401,403,405,500"
    
    // Apply config if exists
    if config.Threads > 0 {
        threads = fmt.Sprintf("%d", config.Threads)
    }
    if config.MatchStatusCodes != "" {
        matchCodes = config.MatchStatusCodes
    }
    
    // Add FUZZ to URL if not present
    fuzzyURL := targetURL
    if !strings.Contains(fuzzyURL, "FUZZ") {
        fuzzyURL = strings.TrimSuffix(fuzzyURL, "/") + "/FUZZ"
    }
    
    dockerCmd := []string{
        "docker", "exec",
        "ars0n-framework-v2-ffuf-1",
        "ffuf",
        "-w", wordlistPath,
        "-u", fuzzyURL,
        "-mc", matchCodes,
        "-o", "/tmp/ffuf-output.json",
        "-of", "json",
        "-ac",
        "-c",
        "-r",
        "-t", threads,
        "-timeout", "30",
    }
    cmd := exec.Command(dockerCmd[0], dockerCmd[1:]...)
}
```

### FFUF Output Format
```json
{
  "results": [
    {
      "input": {"FUZZ": "admin"},
      "status": 200,
      "length": 1234,
      "words": 56,
      "lines": 12
    }
  ]
}
```

---

## API Endpoints Summary

| Method | Endpoint | Tool | Mô tả |
|--------|----------|------|-------|
| POST | `/api/katana-url/run` | Katana | Start Katana URL scan |
| GET | `/api/katana-url/status/{scan_id}` | Katana | Get scan status |
| POST | `/api/waybackurls/run` | Waybackurls | Start Waybackurls scan |
| GET | `/api/waybackurls/status/{scan_id}` | Waybackurls | Get scan status |
| POST | `/api/gau-url/run` | GAU | Start GAU URL scan |
| GET | `/api/gau-url/status/{scan_id}` | GAU | Get scan status |
| POST | `/api/linkfinder-url/run` | LinkFinder | Start LinkFinder scan |
| GET | `/api/linkfinder-url/status/{scan_id}` | LinkFinder | Get scan status |
| POST | `/api/ffuf-url/run` | FFUF | Start FFUF scan |
| GET | `/api/ffuf-url/status/{scan_id}` | FFUF | Get scan status |
| GET | `/api/scopetarget/{id}/scans/katana-url` | Katana | Get all Katana scans |
| GET | `/api/scopetarget/{id}/scans/waybackurls` | Waybackurls | Get all Waybackurls scans | 
| GET | `/api/scopetarget/{id}/scans/gau-url` | GAU | Get all GAU scans |
| GET | `/api/scopetarget/{id}/scans/linkfinder-url` | LinkFinder | Get all LinkFinder scans |
| GET | `/api/scopetarget/{id}/scans/ffuf-url` | FFUF | Get all FFUF scans |
