using DAL.Enums;

namespace BLL.DTOs.CartItem
{
    public class CartItemDTO
    {
        public int CartItemId { get; set; }
        public int CustomerId { get; set; }
        public Guid ProductVariantId { get; set; }
        public int Quantity { get; set; }
        public decimal TotalPrice => Quantity * (ProductVariant?.GetPrice() ?? 0);

        // Thông tin bổ sung từ ProductVariant và Product để Client dễ hiển thị
        public CartItemProductVariantDto? ProductVariant { get; set; }
    }

    public class CartItemProductVariantDto
    {
        public Guid ProductVariantId { get; set; }
        public string Sku { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
        public string? Cpu { get; set; }
        public string? Ram { get; set; }
        public string? Storage { get; set; }
        public string? ScreenSize { get; set; }
        public decimal Price { get; set; }
        public Guid? PromotionId { get; set; }
        public DAL.Models.Promotion? Promotion { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }

        // Lấy thêm tên sản phẩm chính và thương hiệu từ bảng Product
        public string ProductName { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;

        public decimal GetPrice()
        {
            if (Promotion != null && Promotion.IsActive())
            {
                if (Promotion.PromotionType == PromotionTypeEnum.Percentage && Promotion.Percentage.HasValue)
                    return Price * (1 - Promotion.Percentage.Value / 100m);
                if (Promotion.PromotionType == PromotionTypeEnum.FixedAmount && Promotion.SalePrice.HasValue)
                    return Price - Promotion.SalePrice.Value;
            }
            return Price;
        }
    }
}
