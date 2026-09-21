using BLL.DTOs.OrderItem;

namespace BLL.DTOs.Order
{
    public class OrderDto
    {
        public Guid OrderId { get; set; }
        public int CustomerId { get; set; }
        public string CustomerName { get; set; }
        public int? PromotionId { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public List<OrderItemDto> OrderItems { get; set; } = new();
    }
}
