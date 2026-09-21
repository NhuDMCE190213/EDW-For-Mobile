namespace BLL.DTOs.ProductVariant.Staff
{
    public class ProductVariantStaffUpdateDto
    {
        public Guid ProductVariantId { get; set; }
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
    }
}
