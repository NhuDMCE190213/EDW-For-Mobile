using BLL.DTOs.OrderItem;

namespace BLL.DTOs.Order
{
    public class OrderCreateDto
    {
        public int CustomerId { get; set; }
        public int? PromotionId { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = "Pending";
        public List<OrderItemCreateDto> OrderItems { get; set; } = new();
    }
}
