# EDW - Electronic Device E-Commerce App
**Môn học:** PRM393 - Lập trình mobile
**Nhóm:** PRM393-G2  
**Học kỳ:** Fall 2026  

---

## 📝 Giới thiệu Dự án
Dự án **EDW (Electronic Device Workspace/Website)** là một hệ thống thương mại điện tử chuyên kinh doanh các sản phẩm công nghệ (Điện thoại, Laptop, Phụ kiện...). Hệ thống hỗ trợ quản lý sâu sắc thuộc tính sản phẩm công nghệ (RAM, CPU, Dung lượng, Màu sắc) thông qua mô hình Product-Variant, đồng thời tích hợp cổng thanh toán trực tuyến VNPAY.

### Hệ thống được chia làm 2 thành phần chính (Client - Server):
1. **Backend (ASP.NET Core Web API):** Hệ thống API cung cấp dữ liệu, xử lý nghiệp vụ, xác thực người dùng (JWT) và tích hợp cổng thanh toán VNPAY. Dành cho việc quản lý danh mục, sản phẩm, đơn hàng và cung cấp endpoint cho Frontend.
2. **Frontend Mobile App (Flutter):** Ứng dụng di động đa nền tảng (iOS/Android) giao tiếp qua RESTful API. Bao gồm các chức năng:
   * **Customer:** Xem sản phẩm, quản lý giỏ hàng, đặt hàng và thanh toán qua VNPAY.
   * **Admin/Staff (Tùy chọn trên App):** Quản lý trạng thái đơn hàng, cập nhật kho và kiểm tra doanh thu.

---

## 🏗️ Kiến trúc Hệ thống
Dự án áp dụng mô hình kiến trúc **Client - Server** kết hợp mô hình phân lớp chuẩn chỉ ở Backend để tách biệt mối quan tâm và tuân thủ các nguyên tắc SOLID:

* **Frontend (Flutter):** Quản lý trạng thái (State Management) và giao diện người dùng, gọi API thông qua HTTP client để đồng bộ dữ liệu.
* **Backend (ASP.NET Core API):**
  * **API Layer (Controllers):** Tiếp nhận HTTP Request từ ứng dụng Flutter và trả về dữ liệu định dạng JSON.
  * **BLL (Business Logic Layer):** Lớp xử lý nghiệp vụ, tính toán logic hệ thống. Tầng này độc lập hoàn toàn với API và CSDL.
  * **DAL (Data Access Layer):** Lớp kết nối Cơ sở dữ liệu. Sử dụng Entity Framework Core với Fluent API tách file cấu hình riêng (`IEntityTypeConfiguration`) và tự động chuẩn hóa tên bảng theo định dạng `snake_case`.

---

## 🛠️ Công nghệ Sử dụng (Tech Stack)
* **Frontend Mobile:** Flutter, Dart
* **Backend Server:** ASP.NET Core Web API (.NET 8), C#
* **ORM:** Entity Framework Core
* **Database:** SQL Server
* **Naming Convention:** `EFCore.NamingConventions` (snake_case)
* **Payment Gateway:** VNPAY Sandbox API

---

## 🚀 Hướng dẫn Cài đặt & Chạy Dự án (Dành cho thành viên nhóm)

### 1. Chuẩn bị môi trường
* Đảm bảo máy đã cài **.NET SDK (v8.0)** và **SQL Server**.
* Đảm bảo máy đã cài **Flutter SDK** và cấu hình Android Studio / Xcode / Máy ảo (Emulator).
* Clone dự án về máy: `git clone <url-repository>`

### 2. Cấu hình Backend API (Web API)
#### A. Tạo file cấu hình thanh toán VNPAY cá nhân
Do lý do bảo mật, file cấu hình VNPAY đã bị đưa vào `.gitignore`. Mỗi thành viên cần tạo một file tên là **`vnpay.json`** (hoặc cấu hình trực tiếp vào `appsettings.Development.json` tùy cấu trúc thư mục) tại project Web API:

```json
{
  "VNPAY": {
    "TmnCode": "EXAMPLET7",
    "HashSecret": "ABCDEFGHJKLMNOPQRSTUVWXYZABCDEFG",
    "BaseUrl": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html",
    "ReturnUrl": "https://localhost:7001/api/payment/vnpay-return" 
  }
}
```
*(Lưu ý: `ReturnUrl` trỏ về một endpoint của API để cập nhật trạng thái đơn hàng hoặc deep link về app Flutter).*

#### B. Cấu hình Chuỗi kết nối Database
Mở file `appsettings.json` ở project API và sửa lại `ConnectionStrings` cho khớp với SQL Server trên máy của bạn:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER_NAME;Database=EDW_ECommerceDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

#### C. Khởi tạo Cơ sở dữ liệu (Migrations)
Sử dụng CLI `dotnet-ef` hoặc Package Manager Console:
```bash
# Trỏ tới thư mục chứa project DAL và set WebAPI làm startup project
dotnet ef database update --project src/Project.DAL --startup-project src/Project.WebApi
```

Chạy server Backend:
```bash
cd src/Project.WebApi
dotnet run
```

### 3. Cấu hình & Chạy Frontend (Flutter App)
Mở terminal, di chuyển vào thư mục chứa code Flutter (ví dụ: `edw_mobile`):

```bash
cd edw_mobile

# Tải các thư viện / packages phụ thuộc
flutter pub get

# Chạy ứng dụng trên máy ảo hoặc thiết bị thật
flutter run
```
*(Lưu ý: Nhớ thay đổi biến `BASE_URL` trong code Flutter thành địa chỉ IP local của máy tính (ví dụ: `http://10.0.2.2:5000` cho Android Emulator) thay vì `localhost` để máy ảo có thể gọi được API backend).*

---

## 👥 Thành viên Thực hiện (Project Team)
- Đái Minh Như (Leader) - Email: nhudm.ce190213@gmail.com
- [Thêm tên các thành viên khác vào đây...]

> **Lưu ý:** Khi bạn thêm file cấu hình chứa secret (API keys, connection strings) vào repository cục bộ, tuyệt đối **không** commit các file này lên GitHub — hãy kiểm tra kỹ `.gitignore` trước khi push code.