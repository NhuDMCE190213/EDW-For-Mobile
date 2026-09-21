using System;
using System.Collections.Generic;

namespace DAL.Utilities
{
    public class SkuGenerator
    {
        public static string Generate(int productId, string color, string? cpu, string? ram, string? storage, string? screenSize)
        {
            if (productId <= 0)
                throw new ArgumentException("Product ID must be a positive integer.", nameof(productId));

            if (string.IsNullOrWhiteSpace(color))
                throw new ArgumentException("Color cannot be empty.", nameof(color));

            // 1. Chuẩn hóa mã sản phẩm và màu sắc (Xóa khoảng trắng, viết hoa)
            string cleanCode = productId.ToString().PadLeft(9, '0');
            string cleanColor = color.Replace(" ", "").ToUpper();

            // Mẹo giữ nguyên của bạn: Lấy 3 chữ cái đầu của màu để SKU ngắn gọn (Ví dụ: SILVER -> SIL)
            if (cleanColor.Length > 3)
                cleanColor = cleanColor.Substring(0, 3);

            // Khởi tạo danh sách các phân đoạn của SKU
            var segments = new List<string> { cleanCode, cleanColor };

            // 2. Kiểm tra các thuộc tính nullable, nếu có thì xóa khoảng trắng, viết hoa và đưa vào danh sách
            if (!string.IsNullOrWhiteSpace(cpu))
                segments.Add(cpu.Replace(" ", "").ToUpper());

            if (!string.IsNullOrWhiteSpace(ram))
                segments.Add(ram.Replace(" ", "").ToUpper());

            if (!string.IsNullOrWhiteSpace(storage))
                segments.Add(storage.Replace(" ", "").ToUpper());

            // 3. BỔ SUNG: Kiểm tra và chuẩn hóa kích thước màn hình (Ví dụ: "14 inch" -> "14INCH" hoặc "15.6" -> "15.6")
            if (!string.IsNullOrWhiteSpace(screenSize))
            {
                // Xóa khoảng trắng và dấu nháy kép (nếu Admin quen tay gõ ví dụ 14")
                string cleanScreen = screenSize.Replace(" ", "").Replace("\"", "").ToUpper();
                segments.Add(cleanScreen);
            }

            // Nối các phần tử lại bằng dấu gạch ngang (-). 
            // Kết quả dạng: IP15PP-BLA-ULTRA5-16GB-1TB-14INCH
            return string.Join("-", segments);
        }
    }
}