using DAL.Enums;
namespace BLL.DTOs.ProductVariant.Customer
{
    public class ProductVariantCustomerDto
    {
        public Guid ProductVariantId { get; set; }
        public string Sku { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
        public string? Cpu { get; set; }
        public string? Ram { get; set; }
        public string? Storage { get; set; }
        public string? ScreenSize { get; set; }
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public int ProductId { get; set; }
        public Guid? PromotionId { get; set; }
        public DAL.Models.Promotion? Promotion { get; set; }


        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public decimal GetPrice()
        {
            if (Promotion != null && Promotion.IsActive())
            {
                if (Promotion.PromotionType == PromotionTypeEnum.Percentage && Promotion.Percentage.HasValue)
                {
                    return Price * (1 - Promotion.Percentage.Value / 100m);
                }
                else if (Promotion.PromotionType == PromotionTypeEnum.FixedAmount && Promotion.SalePrice.HasValue)
                {
                    return Price - Promotion.SalePrice.Value;
                }
            }

            return Price;
        }
    }
}
