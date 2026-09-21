namespace BLL.DTOs.Promotion
{
    public class PromotionDto
    {
        public Guid PromotionId { get; set; }
        public string? Name { get; set; } = string.Empty;
        public DAL.Enums.PromotionTypeEnum PromotionType { get; set; } // true: percentage, false: fixed amount
        public decimal? SalePrice { get; set; }
        public decimal? ThresholdPrice { get; set; }
        public byte? Percentage { get; set; }
        public bool IsReservedStock { get; set; }
        public int? MaxReservedStock { get; set; }
        public bool IsLimitedTime { get; set; }
        public DateTime? StartAt { get; set; }
        public DateTime? EndAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDisabled { get; set; }
    }
}