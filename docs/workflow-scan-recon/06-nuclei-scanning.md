# Nuclei Vulnerability Scanning

Chi tiết công cụ Nuclei cho vulnerability scanning và screenshot capture.

---

## 1. Nuclei Vulnerability Scan

### Thông tin
| Property | Value |
|----------|-------|
| **Container** | `ars0n-framework-v2-nuclei-1` |
| **API Endpoint** | `POST /api/scopetarget/{id}/scans/nuclei/start` |
| **Database Table** | `nuclei_scans` |
| **Source File** | `server/utils/nucleiUtils.go` |

### Docker Command
```bash
docker exec ars0n-framework-v2-nuclei-1 \
  nuclei \
  -l /targets.txt \
  -t nuclei-templates/ \
  -json \
  -o /output.jsonl
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-l /targets.txt` | Input file với danh sách targets |
| `-t nuclei-templates/` | Template directory |
| `-json` | JSON output format |
| `-o /output.jsonl` | Output file |

---

## 2. Nuclei Screenshot

### Docker Command
```bash
docker exec ars0n-framework-v2-nuclei-1 \
  nuclei \
  -l /targets.txt \
  -headless \
  -t /app/screenshot.yaml
```

### Arguments
| Argument | Mô tả |
|----------|-------|
| `-l /targets.txt` | Input file với danh sách URLs |
| `-headless` | Headless browser mode |
| `-t /app/screenshot.yaml` | Screenshot template |

---

## 3. Metadata Scan

### Docker Command
```bash
docker exec ars0n-framework-v2-nuclei-1 \
  nuclei \
  -l /targets.txt \
  -t tech-detect/ \
  -json \
  -o /tech-output.json
```

---

## API Endpoints

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/api/scopetarget/{id}/scans/nuclei/start` | Start Nuclei scan |
| GET | `/api/nuclei-scan/{scan_id}/status` | Get scan status |
| POST | `/api/nuclei-screenshot/run` | Start screenshot scan |
| POST | `/api/metadata/run` | Start metadata scan |
