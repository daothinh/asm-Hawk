# 01 - Project Overview

## Mục tiêu
ASM-Hawk là nền tảng Attack Surface Management tự động hóa quy trình:
- Trinh sát (Reconnaissance)
- Xác thực rủi ro (Risk Validation)
- Threat Intelligence Integration

## Core Features

### 1. Phát hiện tài sản (Discovery)
- Subdomain enumeration
- IP mapping
- CNAME resolution

### 2. Định danh chuyên sâu
- JARM fingerprinting
- Service detection
- C2/Phishing identification

### 3. Làm giàu dữ liệu (Enrichment)
- VirusTotal integration
- URLScan.io integration
- Censys integration
- AbuseIPDB integration

### 4. Xác thực tự động (Validation)
- Exploit verification
- False positive elimination

### 5. Đánh giá rủi ro (Risk Scoring)
- ML-based scoring
- TI correlation

---

## Decisions Made

| Category | Decision | Rationale |
|----------|----------|-----------|
| Primary DB | PostgreSQL | ACID, JSON support, full-text search |
| Analytics DB | ClickHouse | Time-series, high-performance |
| DB Sync | PeerDB CDC | Real-time replication |
| Retention | 12 months (Recon), 24 months (Attack) | Balance storage/compliance |
| Multi-tenant | Row-Level Security | Built-in PostgreSQL feature |
| Architecture | Hybrid (NestJS + Go + Python) | Best tool for each job |
| Build Approach | From scratch | Full control, no legacy |
