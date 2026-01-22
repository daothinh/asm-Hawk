# Quick Reference - Tất cả Docker Commands

Tổng hợp nhanh tất cả các Docker commands được sử dụng trong ars0n-framework-v2.

---

## Subdomain Discovery

### Sublist3r
```bash
docker exec ars0n-framework-v2-sublist3r-1 python /app/sublist3r.py -d {domain} -v -t 50 -o /dev/stdout
```

### Assetfinder
```bash
docker exec ars0n-framework-v2-assetfinder-1 assetfinder --subs-only {domain}
```

### Subfinder
```bash
docker exec ars0n-framework-v2-subfinder-1 subfinder -d {domain} -all
```

### GAU (GetAllUrls)
```bash
docker run --rm sxcurity/gau:latest {domain} --providers wayback --json --verbose --subs --threads 10 --timeout 60 --retries 2
```

---

## DNS Brute-force

### ShuffleDNS
```bash
docker exec ars0n-framework-v2-shuffledns-1 shuffledns -d {domain} -w /app/wordlists/all.txt -r /app/wordlists/resolvers.txt -silent -massdns /usr/local/bin/massdns -t 10000 -mode bruteforce
```

### CeWL
```bash
docker exec ars0n-framework-v2-cewl-1 timeout 600 ruby /app/cewl.rb {url} -d 2 -m 5 -c --with-numbers
```

---

## HTTP Probing

### HTTPX
```bash
docker exec ars0n-framework-v2-httpx-1 httpx -l /tmp/domains.txt -ports 80,443,8080,8443 -json -status-code -title -tech-detect -server -content-length -no-color -timeout 10 -retries 2 -rate-limit 150 -o /tmp/output.json
```

---

## URL Discovery

### Katana
```bash
docker exec ars0n-framework-v2-katana-1 katana -u {url} -d 5 -jc -kf all -silent -nc -p 15
```

### Waybackurls
```bash
docker exec ars0n-framework-v2-waybackurls-1 waybackurls {url}
```

### LinkFinder
```bash
docker exec ars0n-framework-v2-linkfinder-1 python3 linkfinder.py -i {url} -o cli
```

### FFUF
```bash
docker exec ars0n-framework-v2-ffuf-1 ffuf -w /wordlists/wordlist.txt -u {url}/FUZZ -mc 200-299,301,302,307,401,403,405,500 -o /tmp/ffuf-output.json -of json -ac -c -r -t 40 -timeout 30
```

---

## Web Scraping

### GoSpider
```bash
docker exec ars0n-framework-v2-gospider-1 timeout 300 gospider -s {url} -c 10 -d 3 -t 3 -k 1 -K 2 -m 30 --blacklist ".(jpg|jpeg|gif|css|png|ttf|woff|woff2|ico|svg)" -a -w -r --js --sitemap --robots --debug --json -v
```

### Subdomainizer
```bash
docker exec ars0n-framework-v2-subdomainizer-1 timeout 300 python3 SubDomainizer.py -u {url} -k -o /tmp/output.txt -sop /tmp/secrets.txt
```

---

## Vulnerability Scanning

### Nuclei Scan
```bash
docker exec ars0n-framework-v2-nuclei-1 nuclei -l /targets.txt -t nuclei-templates/ -json -o /output.jsonl
```

### Nuclei Screenshot
```bash
docker exec ars0n-framework-v2-nuclei-1 nuclei -l /targets.txt -headless -t /app/screenshot.yaml
```

### Nuclei Tech Detect
```bash
docker exec ars0n-framework-v2-nuclei-1 nuclei -l /targets.txt -t tech-detect/ -json -o /tech-output.json
```

---

## Container Names Summary

| Tool | Container Name |
|------|---------------|
| Sublist3r | `ars0n-framework-v2-sublist3r-1` |
| Assetfinder | `ars0n-framework-v2-assetfinder-1` |
| Subfinder | `ars0n-framework-v2-subfinder-1` |
| Amass | `ars0n-framework-v2-amass-1` |
| GAU | `sxcurity/gau:latest` (docker run) |
| ShuffleDNS | `ars0n-framework-v2-shuffledns-1` |
| CeWL | `ars0n-framework-v2-cewl-1` |
| HTTPX | `ars0n-framework-v2-httpx-1` |
| Katana | `ars0n-framework-v2-katana-1` |
| Waybackurls | `ars0n-framework-v2-waybackurls-1` |
| LinkFinder | `ars0n-framework-v2-linkfinder-1` |
| FFUF | `ars0n-framework-v2-ffuf-1` |
| GoSpider | `ars0n-framework-v2-gospider-1` |
| Subdomainizer | `ars0n-framework-v2-subdomainizer-1` |
| Nuclei | `ars0n-framework-v2-nuclei-1` |
| GitHub Recon | `ars0n-framework-v2-github-recon-1` |

---

## API Endpoints Summary

### Scan Initiation (POST)
| Tool | Endpoint |
|------|----------|
| Sublist3r | `/api/sublist3r/run` |
| Assetfinder | `/api/assetfinder/run` |
| Subfinder | `/api/subfinder/run` |
| Amass | `/api/amass/run` |
| GAU | `/api/gau/run` |
| CTL | `/api/ctl/run` |
| ShuffleDNS | `/api/shuffledns/run` |
| CeWL | `/api/cewl/run` |
| HTTPX | `/api/httpx/run` |
| Katana | `/api/katana-url/run` |
| Waybackurls | `/api/waybackurls/run` |
| LinkFinder | `/api/linkfinder-url/run` |
| FFUF | `/api/ffuf-url/run` |
| GoSpider | `/api/gospider/run` |
| Subdomainizer | `/api/subdomainizer/run` |
| Nuclei Screenshot | `/api/nuclei-screenshot/run` |
| Metadata | `/api/metadata/run` |

### Scan Status (GET)
Pattern: `/api/{tool}/{scan_id}`

### Scans for Target (GET)
Pattern: `/api/scopetarget/{id}/scans/{tool}`
