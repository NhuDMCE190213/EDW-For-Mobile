namespace BLL.DTOs.OrderItem
{
    public class OrderItemCreateDto
    {
        public Guid ProductVariantId { get; set; }
        public int Quantity { get; set; }
        public decimal PriceAtPurchase { get; set; }
    }
}
