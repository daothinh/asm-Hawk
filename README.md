# ASM-Hawk
*Nền tảng ASM tự động hóa quy trình trinh sát và xác thực rủi ro dựa trên Threat Intelligence.*
*Automated Attack Surface Management platform for reconnaissance and risk validation based on Threat Intelligence.*

## Tổng quan
ASM-Hawk là giải pháp tự động hóa quá trình theo dõi, phân tích và đánh giá rủi ro cho các tài sản số công khai. Hệ thống giúp rút ngắn khoảng cách giữa việc phát hiện dữ liệu thô (OSINT) và xác thực khả năng bị tấn công thực tế, hỗ trợ đội ngũ bảo mật ưu tiên xử lý các mối đe dọa trọng yếu.

## Tính năng trọng tâm
- **Phát hiện tài sản (Discovery):** Tự động hóa việc mapping subdomain, IP và các tài sản số liên quan từ các nguồn dữ liệu công khai.
- **Định danh chuyên sâu:** Sử dụng vân tay JARM và phân tích Service Fingerprinting để nhận diện sớm các hạ tầng nghi ngờ (C2, Phishing).
- **Làm giàu dữ liệu (Enrichment):** Kết hợp dữ liệu thời gian thực từ VirusTotal, URLScan.io, Censys và AbuseIPDB để tăng độ chính xác của phân tích.
- **Xác thực tự động (Validation):** Cơ chế kiểm tra khả năng khai thác lỗi giúp loại bỏ gánh nặng về cảnh báo giả (False Positive).
- **Đánh giá rủi ro (Risk Scoring):** Mô hình tính điểm ưu tiên dựa trên sự tương quan giữa thông tin trinh sát nội bộ và dữ liệu Threat Intel bên ngoài.

## Documentation
- [Quy trình vận hành (Workflow)](docs/Workflow.md)
- [Luồng thực thi hệ thống (Sequence)](docs/Sequence.md)
