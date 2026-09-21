namespace BLL.DTOs.CartItem
{
    public class CartItemCreateDTO
    {
        public int CartItemId { get; set; }
        public int CustomerId { get; set; }
        public Guid ProductVariantId { get; set; }
        public int Quantity { get; set; }
    }
}
