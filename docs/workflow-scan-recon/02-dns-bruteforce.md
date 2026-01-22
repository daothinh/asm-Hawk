# DNS Brute-force Tools

Chi tiết các công cụ DNS brute-force trong ars0n-framework-v2.

---

## 1. ShuffleDNS

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-shuffledns-1` |
| **API Endpoint** | `POST /api/shuffledns/run` |
| **Database Table** | `shuffledns_scans` |
| **Source File** | `server/utils/bruteForceUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-shuffledns-1 \
  shuffledns \
  -d {domain} \
  -w /app/wordlists/all.txt \
  -r /app/wordlists/resolvers.txt \
  -silent \
  -massdns /usr/local/bin/massdns \
  -t {rateLimit} \
  -mode bruteforce
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-d {domain}` | Domain target |
| `-w /app/wordlists/all.txt` | Wordlist path |
| `-r /app/wordlists/resolvers.txt` | DNS resolvers file |
| `-silent` | Silent mode |
| `-massdns /usr/local/bin/massdns` | Path đến massdns binary |
| `-t {rateLimit}` | Rate limit (từ settings, default: 10000) |
| `-mode bruteforce` | Chế độ brute-force |

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
    "ars0n-framework-v2-shuffledns-1",
    "shuffledns",
    "-d", domain,
    "-w", "/app/wordlists/all.txt",
    "-r", "/app/wordlists/resolvers.txt",
    "-silent",
    "-massdns", "/usr/local/bin/massdns",
    "-t", fmt.Sprintf("%d", rateLimit),
    "-mode", "bruteforce",
)
```

### Rate Limit Configuration
Rate limit được lấy từ user settings:
```go
func GetShuffleDNSRateLimit() int {
    // Default: 10000
    // Lấy từ database: user_settings.shuffledns_rate_limit
}
```

---

## 2. ShuffleDNS với Custom Wordlist

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-shuffledns-1` |
| **API Endpoint** | `POST /api/cewl-wordlist/run` |
| **Database Table** | `shufflednscustom_scans` |
| **Source File** | `server/utils/bruteForceUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-shuffledns-1 \
  shuffledns \
  -d {domain} \
  -w /tmp/wordlist.txt \
  -r /app/wordlists/resolvers.txt \
  -silent \
  -massdns /usr/local/bin/massdns \
  -mode bruteforce
```

### Workflow
1. CeWL tạo wordlist từ live web servers
2. Wordlist được copy vào container
3. ShuffleDNS chạy với custom wordlist

---

## 3. CeWL (Custom Word List Generator)

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-cewl-1` |
| **API Endpoint** | `POST /api/cewl/run` |
| **Database Table** | `cewl_scans` |
| **Source File** | `server/utils/bruteForceUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-cewl-1 \
  timeout 600 \
  ruby /app/cewl.rb \
  {url} \
  -d 2 \
  -m 5 \
  -c \
  --with-numbers \
  [--ua {customUserAgent}]
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `timeout 600` | Timeout 600 giây |
| `{url}` | URL target |
| `-d 2` | Depth level 2 |
| `-m 5` | Minimum word length 5 |
| `-c` | Count words |
| `--with-numbers` | Include numbers in words |
| `--ua {customUserAgent}` | Custom User Agent (optional) |

### Request Body
```json
{
  "fqdn": "example.com",
  "auto_scan_session_id": "optional-session-id"
}
```

### Go Code
```go
cmdArgs := []string{
    "docker", "exec",
    "ars0n-framework-v2-cewl-1",
    "timeout", "600",
    "ruby", "/app/cewl.rb",
    cleanURL,
    "-d", "2",
    "-m", "5",
    "-c",
    "--with-numbers",
}

// Add custom user agent if specified
if customUserAgent != "" {
    cmdArgs = append(cmdArgs, "--ua", customUserAgent)
}

cmd := exec.Command(cmdArgs[0], cmdArgs[1:]...)
```

---

## CeWL + ShuffleDNS Combined Workflow

### Mô tả
CeWL tạo custom wordlist từ content của live web servers, sau đó ShuffleDNS sử dụng wordlist này để brute-force DNS.

### Workflow Steps:

```
1. Lấy kết quả HTTPX scan gần nhất
       ↓
2. Lặp qua từng live web server URL
       ↓
3. Chạy CeWL trên mỗi URL để extract words
       ↓
4. Clean và filter words:
   - Convert lowercase
   - Remove non-alphanumeric
   - Length 3-20 characters
   - Skip URLs và www
       ↓
5. Tạo combined wordlist (unique words)
       ↓
6. Copy wordlist vào ShuffleDNS container
       ↓
7. Chạy ShuffleDNS với custom wordlist
       ↓
8. Parse và lưu kết quả
```

### Go Code Flow
```go
func ExecuteAndParseCeWLScan(scanID, domain string) {
    // 1. Get HTTPX results
    httpxResults := getHttpxResults(scanID)
    
    // 2. Process each URL with CeWL
    wordSet := make(map[string]bool)
    for _, url := range urls {
        // Run CeWL
        cmd := exec.Command("docker", "exec", "cewl-container", ...)
        output := cmd.Run()
        
        // Extract and clean words
        for _, word := range words {
            word = cleanWord(word)
            if isValidWord(word) {
                wordSet[word] = true
            }
        }
    }
    
    // 3. Create wordlist file
    wordlistFile := createWordlistFile(wordSet)
    
    // 4. Copy to ShuffleDNS container
    exec.Command("docker", "cp", wordlistFile, "shuffledns-container:/tmp/wordlist.txt")
    
    // 5. Run ShuffleDNS with custom wordlist
    shuffleCmd := exec.Command("docker", "exec", "shuffledns-container",
        "shuffledns",
        "-d", domain,
        "-w", "/tmp/wordlist.txt",
        "-r", "/app/wordlists/resolvers.txt",
        "-silent",
        "-massdns", "/usr/local/bin/massdns",
        "-mode", "bruteforce",
    )
    shuffleCmd.Run()
    
    // 6. Save results
    UpdateShuffleDNSCustomScanStatus(scanID, "success", result, ...)
}
```

---

## Wordlist Files

### Container Paths
| File | Path | Mô tả |
|------|------|-------|
| Main wordlist | `/app/wordlists/all.txt` | Wordlist chính cho brute-force |
| Resolvers | `/app/wordlists/resolvers.txt` | DNS resolver servers |
| Custom wordlist | `/tmp/wordlist.txt` | CeWL-generated wordlist |

---

## API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/shuffledns/run` | Start ShuffleDNS scan |
| GET | `/api/shuffledns/{scan_id}` | Get scan status |
| GET | `/api/scopetarget/{id}/scans/shuffledns` | Get all scans for target |
| POST | `/api/cewl/run` | Start CeWL scan |
| GET | `/api/cewl/{scan_id}` | Get CeWL scan status |
| GET | `/api/scopetarget/{id}/scans/cewl` | Get all CeWL scans for target |
| POST | `/api/cewl-wordlist/run` | Start ShuffleDNS with custom wordlist |
