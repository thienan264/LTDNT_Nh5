# Quản lý thiết bị cho thuê

Flutter/Dart + SQLite trên điện thoại; REST API C# .NET 10 + SQL Server 2022.
Backend viết SQL bằng Dapper theo cấu trúc bài mẫu `MultiplePlatform /WebApp`.

## Chạy trên máy hiện tại

```sh
cd /Users/thienan/Desktop/LTDNT/equipment_rental
./scripts/start_backend.sh
```

Mở terminal khác:

```sh
cd /Users/thienan/Desktop/LTDNT/equipment_rental/mobile
flutter pub get
flutter run
```

- API: http://127.0.0.1:5055
- SQL Server Docker: `127.0.0.1,14330`, database `EquipmentRentalDb`.
- Tài khoản SQL phát triển: `sa` / `Rental@123456` (cấu hình trong compose và appsettings).
- Admin ứng dụng: `admin@rental.com` / `Admin@123`.
- Member ứng dụng: `member@rental.com` / `Member@123`.
- Điện thoại thật: `flutter run --dart-define=API_HOST=http://IP_LAN_CUA_MAC:5055`.

Đọc [hướng dẫn chạy](docs/RUN_GUIDE.md), [đối chiếu cách thầy dạy](docs/TEACHER_STYLE.md),
[và trạng thái yêu cầu](docs/TRACEABILITY_MATRIX.md).

`legacy/` giữ bản Dart/PostgreSQL, bản EF và tài liệu cũ để tham khảo; không dùng để chạy/nộp backend mới.
Không có bước chuyển dữ liệu từ PostgreSQL: database SQL Server được tạo mới với tài khoản và thiết bị mẫu.
Các container PostgreSQL của dự án khác trên máy được giữ nguyên.
