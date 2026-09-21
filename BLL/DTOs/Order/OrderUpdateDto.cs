namespace BLL.DTOs.Order
{
    public class OrderUpdateDto
    {
        public Guid OrderId { get; set; }
        public int? PromotionId { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
