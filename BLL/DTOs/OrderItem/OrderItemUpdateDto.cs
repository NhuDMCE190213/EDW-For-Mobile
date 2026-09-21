namespace BLL.DTOs.OrderItem
{
    public class OrderItemUpdateDto
    {
        public int OrderItemId { get; set; }
        public int Quantity { get; set; }
        public decimal PriceAtPurchase { get; set; }
    }
}
