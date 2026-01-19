# ASM-Hawk Project Workflow

Luồng vận hành ASM tiêu chuẩn: Tự động hóa trinh sát, đối soát Threat Intel và xác thực rủi ro liên tục.

## 1. Sơ đồ quy trình (Mermaid Diagram)

```mermaid
flowchart TD
    %% ========= INPUT & TRIGGER =========
    A1(User / On-demand Request) --> B1(Start / Seed Identified)

    %% ========= OSINT MODULE =========
    B1 --> C1(Collect OSINT Data)
    C1 --> C2(Normalize OSINT Results)
    C2 --> C3(Store/Update Asset DB)

    %% ========= RECON & ENRICHMENT (PARALLEL) =========
    C3 --> R1(Scan Port & Services)
    C3 --> E1(External Intel Enrichment)
    
    subgraph Enrichment [Threat Intel Enrichment]
        E1 --> E2(Query VirusTotal/URLScan/Censys/AbuseIPDB)
        E2 --> E3(Analyze C2 Behaviors & JARM Fingerprints)
        E3 --> E4(Normalize Intel Results)
    end

    R1 --> R2(Classify Vulnerabilities & Services)
    R2 --> R3(Tag C2 & Risk Indicators)
    R3 --> R4(Store Recon Results)
    E4 --> E5(Store Intel Results)

    %% ========= ATTACK VERIFICATION =========
    R4 --> T1(Perform Attack Verification)
    T1 --> T2(Evaluate Exploitability)
    T2 --> T3(Store Attack Results)

    %% ========= DATA LAYER (OPTIMIZED) =========
    C3 --> D1(DB: Asset Inventory)
    R4 --> D2(DB: Recon History)
    T3 --> D3(DB: Attack History)
    E5 --> D4(DB: External Intel & C2 Tags)

    D1 & D2 & D3 & D4 --> DD1(Correlate & Compare Scans)
    DD1 --> U1(Update Risk Scores)

    %% ========= ALERTING & INTEGRATION =========
    U1 --> N1(Generate Alerts / Findings)
    N1 --> U2(SIEM / Dashboard / Ticketing)

    %% ========= CONTINUOUS SCAN LOOP =========
    U1 -->|Trigger New Recon| R1
    U1 -->|Source Update| C1
```

## 2. Chi tiết các Module Tối ưu

### A. Threat Intel Enrichment (Module mới)
Module này chạy song song với Recon nội bộ để làm giàu thông tin về tài sản mà không cần tương tác trực tiếp:
*   **VirusTotal:** Kiểm tra độ danh tiếng (reputation), tỉ lệ detection và lịch sử liên kết với mã độc.
*   **URLScan.io:** Kiểm tra hành vi trang web, các lần redirect ẩn và chụp ảnh màn hình (screenshot) để nhận diện trang giả mạo (Phishing) hoặc C2 Panel.
*   **Censys/Shodan/JARM:** Sử dụng vân tay JARM để định danh các server C2 (như Cobalt Strike, Metasploit) ngay cả khi chúng cố tình ẩn mình hoặc thay đổi IP.

### B. Tối ưu hóa lưu trữ DB
Để tránh làm phình bảng Asset chính và hỗ trợ truy vấn lịch sử nhanh chóng, dữ liệu được chia tách:
1.  **Asset Inventory:** Lưu thông tin gốc (Domain, IP, IP Owner).
2.  **External Intel:** Lưu trữ dữ liệu thô (JSON) từ các API TI. Có cơ chế **Caching 24h** để tiết kiệm chi phí/limit API.
3.  **Risk Tags:** Lưu các marker cụ thể như `C2-Suspected`, `JARM-Match-CobaltStrike`, `High-Abuse-Report`.

### C. Quy trình Xác thực C2 (C2 Verification)
Hệ thống sử dụng cơ chế **Correlate (Đối soát chéo)**:
*   Nếu `Port Scan` thấy port lạ (ví dụ: 50050) + `JARM` khớp với Cobalt Strike + `VirusTotal` báo Malicious -> Tự động gắn nhãn **Confirmed C2** và đẩy cảnh báo mức **Critical**.
*   Các trường hợp còn lại sẽ được đưa vào hàng đợi `Attack Verification` để kiểm tra độ sâu hơn.

## 3. Vòng lặp liên tục
*   Tự động kích hoạt lại OSINT khi có sự thay đổi về dải IP hoặc tên miền con mới.
*   Tự động điều chỉnh tần suất quét (Frequency) dựa trên `Risk Score`: Tài sản có điểm rủi ro cao sẽ được Enrichment và Recon thường xuyên hơn.

## 4. Hybrid Scan

### Sơ đồ Kiến trúc Hệ thống

```mermaid
flowchart TB
    %% ========= FRONTEND LAYER =========
    subgraph Frontend["Frontend Layer"]
        FE[React/Next.js Dashboard]
    end

    %% ========= API LAYER - NestJS =========
    subgraph APILayer["API Layer - NestJS"]
        API[REST API]
        API --> WS[WebSocket Notifications]
        API --> AUTH[Auth/JWT + RBAC]
        API --> PRISMA[Prisma ORM]
    end

    %% ========= MESSAGE QUEUE =========
    subgraph MQ["Message Queue"]
        REDIS[Redis + BullMQ]
        REDIS --> SCHEDULER[Job Scheduler]
    end

    %% ========= TI WORKERS - PYTHON =========
    subgraph TIWorkers["TI Workers - Python"]
        VT[VirusTotal - vt-py]
        URL[URLScan.io]
        CENSYS[Censys - censys-python]
        RISK[Risk Scorer ML]
    end

    %% ========= DATA LAYER =========
    subgraph DataLayer["Data Layer"]
        PG[(PostgreSQL - Primary)]
    end

    %% ========= CORE ENGINE - GO =========
    subgraph CoreEngine["Core Engine - Go"]
        OSINT[OSINT Scanner]
        PORT[Port Scanner - goroutines]
        JARM[JARM Fingerprint - hdm/jarm]
        ATTACK[Attack Verifier]
    end

    %% ========= CDC & ANALYTICS =========
    PEERDB[PeerDB CDC Sync]
    CH[(ClickHouse - Analytics)]

    %% ========= MAIN CONNECTIONS =========
    FE --> API
    API --> REDIS

    %% TI Workers receive jobs from Redis
    REDIS --> TIWorkers

    %% TI Workers write to PostgreSQL
    TIWorkers --> PG

    %% Job Scheduler triggers Core Engine
    SCHEDULER --> CoreEngine

    %% Core Engine writes to PostgreSQL
    CoreEngine --> PG

    %% Prisma ORM connects to PostgreSQL
    PRISMA --> PG

    %% CDC Sync from PostgreSQL to ClickHouse
    PG --> PEERDB
    PEERDB --> CH

    %% Core Engine also writes to ClickHouse
    CoreEngine --> CH
```

