namespace BLL.DTOs.OrderItem
{
    public class OrderItemDto
    {
        public int OrderItemId { get; set; }
        public Guid OrderId { get; set; }
        public Guid ProductVariantId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string ProductVariantDetails { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal PriceAtPurchase { get; set; }
        public decimal Subtotal => Quantity * PriceAtPurchase;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
