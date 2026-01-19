# ASM-Hawk
*Nền tảng ASM tự động hóa quy trình trinh sát và xác thực rủi ro dựa trên Threat Intelligence.*
*Automated Attack Surface Management platform for reconnaissance and risk validation based on Threat Intelligence.*

## Tổng quan
ASM-Hawk là giải pháp tự động hóa quá trình theo dõi, phân tích và đánh giá rủi ro cho các tài sản số công khai. Hệ thống giúp rút ngắn khoảng cách giữa việc phát hiện dữ liệu thô (OSINT) và xác thực khả năng bị tấn công thực tế, hỗ trợ đội ngũ bảo mật ưu tiên xử lý các mối đe dọa trọng yếu.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React/Next.js |
| API | NestJS + Prisma |
| Core Engine | Go |
| TI Workers | Python |
| Queue | Redis + BullMQ |
| Database | PostgreSQL + ClickHouse |

## Documentation
- [Kiến trúc hệ thống (Architecture)](docs/Architecture.md)
- [Database Schema](docs/Database.md)
- [Quy trình vận hành (Workflow)](docs/Workflow.md)
- [Luồng thực thi (Sequence)](docs/Sequence.md)

