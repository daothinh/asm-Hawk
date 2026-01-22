# Ars0n-Framework-v2 Recon Scan Workflow Documentation

Tài liệu này ghi lại chi tiết workflow và command của từng loại scan được triển khai trong repository `ars0n-framework-v2`.

## 📁 Cấu Trúc Tài Liệu

| File | Mô Tả |
|------|-------|
| [01-subdomain-discovery.md](./01-subdomain-discovery.md) | Các tool khám phá subdomain (Sublist3r, Assetfinder, Subfinder, GAU, CTL) |
| [02-dns-bruteforce.md](./02-dns-bruteforce.md) | DNS brute-force tools (ShuffleDNS, CeWL) |
| [03-httpx-probing.md](./03-httpx-probing.md) | HTTP probing và live web server detection |
| [04-url-discovery.md](./04-url-discovery.md) | URL discovery tools (Katana, Waybackurls, GAU, LinkFinder, FFUF) |
| [05-web-scraping.md](./05-web-scraping.md) | Web scraping tools (GoSpider, Subdomainizer) |
| [06-nuclei-scanning.md](./06-nuclei-scanning.md) | Nuclei vulnerability scanning và screenshot |
| [07-workflow-orchestration.md](./07-workflow-orchestration.md) | Auto-scan orchestration workflow |
| [08-quick-reference.md](./08-quick-reference.md) | Quick reference - Tất cả Docker commands |

---

## 🔧 Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────────────────────────────┐
│  SCAN EXECUTION ARCHITECTURE                                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Frontend (React)          Backend (Go)            Docker Container│
│   ────────────────          ────────────            ────────────────│
│                                                                     │
│   initiate*Scan.js  ──POST──►  Run*Scan()  ──exec.Command──► Tool   │
│   (API call)                   (handler)        (docker exec)       │
│        │                           │                   │            │
│        │                           ▼                   ▼            │
│        │                    Create scan record    Execute tool      │
│        │                     (PostgreSQL)         (async goroutine) │
│        │                           │                   │            │
│        ▼                           ▼                   ▼            │
│   monitor*Status.js ◄──GET── Get*ScanStatus() ◄── Update DB result │
│   (polling 5s)               (query DB)                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Danh Sách Tools Theo Thứ Tự Thực Thi

### Phase 1: Subdomain Enumeration
1. **Amass** - Active và passive subdomain enumeration
2. **Sublist3r** - Subdomain enumeration sử dụng search engines
3. **Assetfinder** - Asset discovery
4. **GAU** - GetAllUrls - URL discovery từ archives
5. **CTL** - Certificate Transparency Logs
6. **Subfinder** - Passive subdomain discovery

### Phase 2: Consolidation & Probing (Round 1)
7. **Consolidate** - Merge kết quả từ các tools
8. **HTTPX** - HTTP probing để tìm live web servers

### Phase 3: DNS Brute-force
9. **ShuffleDNS** - DNS brute-force với wordlist
10. **CeWL + ShuffleDNS Custom** - Custom wordlist generation

### Phase 4: Consolidation & Probing (Round 2)
11. **Consolidate Round 2** - Merge subdomain mới
12. **HTTPX Round 2** - HTTP probing cho subdomain mới

### Phase 5: JavaScript Analysis
13. **GoSpider** - Web spidering và link extraction
14. **Subdomainizer** - Subdomain extraction từ JavaScript

### Phase 6: Final Consolidation & Probing
15. **Consolidate Round 3** - Final merge
16. **HTTPX Round 3** - Final HTTP probing

### Phase 7: Vulnerability Assessment
17. **Nuclei Screenshot** - Screenshot capture
18. **Metadata** - Technology detection và metadata extraction

---

## 🐳 Docker Containers

| Container Name | Tool | Purpose |
|---------------|------|---------|
| `ars0n-framework-v2-sublist3r-1` | Sublist3r | Subdomain enumeration |
| `ars0n-framework-v2-assetfinder-1` | Assetfinder | Asset discovery |
| `ars0n-framework-v2-subfinder-1` | Subfinder | Subdomain enumeration |
| `ars0n-framework-v2-amass-1` | Amass | Subdomain enumeration |
| `ars0n-framework-v2-httpx-1` | HTTPX | HTTP probing |
| `ars0n-framework-v2-shuffledns-1` | ShuffleDNS | DNS brute-force |
| `ars0n-framework-v2-cewl-1` | CeWL | Wordlist generation |
| `ars0n-framework-v2-gospider-1` | GoSpider | Web spidering |
| `ars0n-framework-v2-subdomainizer-1` | Subdomainizer | JS subdomain extraction |
| `ars0n-framework-v2-nuclei-1` | Nuclei | Vulnerability scanning |
| `ars0n-framework-v2-katana-1` | Katana | Web crawling |
| `ars0n-framework-v2-linkfinder-1` | LinkFinder | JS endpoint extraction |
| `ars0n-framework-v2-waybackurls-1` | Waybackurls | Archive URL fetching |
| `ars0n-framework-v2-ffuf-1` | FFUF | Content discovery |
| `sxcurity/gau:latest` | GAU | Archive URL fetching |

---

## 📚 Nguồn Code

- **Backend (Go)**: `ars0n-framework-v2/server/utils/`
  - `subdomainScrapingUtils.go` - Sublist3r, Assetfinder, Subfinder, GAU, CTL
  - `bruteForceUtils.go` - ShuffleDNS, CeWL
  - `liveWebServers.go` - HTTPX, Consolidation
  - `javaScriptLinkDiscovery.go` - GoSpider, Subdomainizer
  - `urlScanUtils.go` - Katana, LinkFinder, Waybackurls, FFUF
  - `screenshotUtils.go` - Nuclei Screenshot
  - `nucleiUtils.go` - Nuclei vulnerability scanning
  - `metaDataUtils.go` - Metadata extraction

- **Frontend (React)**: `ars0n-framework-v2/client/src/utils/`
  - `autoScanSteps.js` - Định nghĩa các bước auto-scan
  - `wildcardAutoScan.js` - Orchestration và state management
  - `initiate*.js` - Khởi tạo từng loại scan
