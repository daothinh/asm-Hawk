# 03 - Database Schema

## PostgreSQL Schema (Prisma 7)

### Overview

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `users` | Authentication & RBAC | JWT, roles |
| `assets` | Domain/IP inventory | Risk scores, metadata |
| `recon_results` | Scan results | Partitioned by month |
| `attack_results` | Attack verification | Evidence storage |
| `external_intel` | TI cache | 24h TTL |
| `risk_tags` | C2/malware markers | Confidence scores |
| `search_history` | Audit logs | Full-text indexed |

---

### Models

#### User
```prisma
model User {
  id            String    @id @default(uuid())
  email         String    @unique
  passwordHash  String    @map("password_hash")
  fullName      String?   @map("full_name")
  role          Role      @default(VIEWER)  // ADMIN, ANALYST, VIEWER
  isActive      Boolean   @default(true)
  lastLoginAt   DateTime?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
}
```

#### Asset
```prisma
model Asset {
  id          String      @id @default(uuid())
  domain      String
  ipAddress   String?
  ipOwner     String?
  assetType   AssetType   @default(DOMAIN)  // DOMAIN, SUBDOMAIN, IP, CNAME
  status      AssetStatus @default(ACTIVE)   // ACTIVE, INACTIVE, SUSPICIOUS, CONFIRMED_MALICIOUS
  riskScore   Decimal     @default(0)
  firstSeenAt DateTime    @default(now())
  lastSeenAt  DateTime    @default(now())
  metadata    Json?
  
  // Relations
  reconResults    ReconResult[]
  attackResults   AttackResult[]
  externalIntels  ExternalIntel[]
  riskTags        RiskTag[]
}
```

#### ReconResult
```prisma
model ReconResult {
  id              String    @id @default(uuid())
  assetId         String
  scanType        ScanType  // PORT_SCAN, SERVICE_DETECT, VULN_SCAN, JARM_FINGERPRINT
  port            Int?
  protocol        String?
  service         String?
  version         String?
  vulnerabilities Json?
  rawOutput       Json?
  scannedAt       DateTime  @default(now())
}
```

#### ExternalIntel
```prisma
model ExternalIntel {
  id              String      @id @default(uuid())
  assetId         String
  source          IntelSource // VIRUSTOTAL, URLSCAN, CENSYS, ABUSEIPDB, SHODAN
  queryHash       String
  responseData    Json
  reputationScore Decimal?
  isMalicious     Boolean     @default(false)
  fetchedAt       DateTime    @default(now())
  expiresAt       DateTime    // 24h TTL
}
```

#### RiskTag
```prisma
model RiskTag {
  id          String      @id @default(uuid())
  assetId     String
  tagName     String      // e.g., "CobaltStrike", "Phishing"
  tagCategory TagCategory // C2, PHISHING, MALWARE, SUSPICIOUS, VERIFIED_CLEAN
  confidence  Decimal     // 0.00 - 1.00
  evidenceIds String[]
  createdAt   DateTime    @default(now())
}
```

---

### Indexes & Optimization

```prisma
// Asset indexes
@@index([domain])
@@index([riskScore(sort: Desc)])

// ReconResult indexes  
@@index([assetId, scannedAt])

// ExternalIntel indexes
@@index([expiresAt])
@@index([isMalicious])
```

---

### Retention Policy

| Table | Strategy | Retention |
|-------|----------|-----------|
| `recon_results` | Monthly partitions | 12 months |
| `attack_results` | Monthly partitions | 24 months |
| `external_intel` | TTL cleanup | 24 hours |

---

### Storage Estimation

| Entity | Records/Month | Monthly Storage |
|--------|---------------|-----------------|
| Assets | 50,000 | ~100 MB |
| Recon Results | 500,000 | ~500 MB |
| Attack Results | 50,000 | ~250 MB |
| External Intel | 100,000 | ~1 GB (cached) |
| **Total** | | **~2 GB/month** |
