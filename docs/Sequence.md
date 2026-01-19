# ASM-Hawk Project Sequence Diagram

Sơ đồ trình tự thực thi giữa các hợp phần trong hệ thống ASM-Hawk.

```mermaid
sequenceDiagram
    autonumber
    actor User as User / Scheduler
    participant OSINT as OSINT Module
    participant DB as Data Layer (DB)
    participant Recon as Recon Module
    participant TI as Threat Intel Module
    participant Attack as Attack Verification
    participant Risk as Risk Scorer
    participant Alerts as Alerting / Dashboard

    User->>OSINT: Yêu cầu quét (Seed/Domain)
    OSINT->>OSINT: Thu thập & Normalize dữ liệu
    OSINT->>DB: Cập nhật Asset Inventory
    
    par Parallel Processing
        DB->>Recon: Scan Port & Services
        DB->>TI: Query VirusTotal/URLScan/JARM
    end

    Recon->>DB: Lưu kết quả Recon (Port/Service)
    TI->>DB: Lưu kết quả Intel (Reputation/C2 Tags)

    DB->>Attack: Kích hoạt xác thực (Nếu có nghi ngờ)
    Attack->>Attack: Thực thi Exploit/Verify
    Attack->>DB: Lưu kết quả xác thực

    DB->>Risk: Tổng hợp dữ liệu (Recon + Intel + Attack)
    Risk->>Risk: Tính toán Risk Score & Gắn nhãn
    Risk->>DB: Cập nhật Risk Score cuối cùng

    Risk->>Alerts: Gửi cảnh báo (Nếu rủi ro cao)
    Alerts->>User: Hiển thị Dashboard / Notify SIEM

    opt Continuous Loop
        Risk->>Recon: Trigger Re-scan (Dựa trên rủi ro)
        Risk->>OSINT: Trigger Refesh OSINT (Nếu asset quan trọng)
    end
```

## Giải thích luồng thực thi

1.  **Trigger:** Quy trình bắt đầu từ yêu cầu của người dùng hoặc lịch quét định kỳ.
2.  **Paralell (Xử lý song song):** Sau khi có danh sách tài sản từ OSINT, hệ thống đồng thời thực hiện quét kỹ thuật (Recon) và làm giàu dữ liệu từ bên ngoài (Threat Intel) để tối ưu thời gian.
3.  **Lớp dữ liệu (DB):** Đóng vai trò trung tâm để các module trao đổi thông tin và lưu trữ lịch sử.
4.  **Xác thực (Attack Verification):** Chỉ được kích hoạt cho các mục tiêu có dấu hiệu khả nghi từ kết quả Recon/TI để tiết kiệm tài nguyên.
5.  **Risk Scorer:** Là bước cuối cùng trước khi ra quyết định cảnh báo, đảm bảo các phát hiện được đối soát chéo (Correlate) từ nhiều nguồn.
