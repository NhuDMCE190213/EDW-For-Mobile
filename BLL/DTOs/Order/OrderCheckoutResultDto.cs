namespace BLL.DTOs.Order
{
    public class OrderCheckoutResultDto
    {
        public OrderDto Order { get; set; } = new();
        public decimal Subtotal { get; set; }
        public decimal Discount { get; set; }
        public decimal Shipping { get; set; }
        public decimal Total { get; set; }
        public string PaymentStatus { get; set; } = "Unpaid";
    }
}