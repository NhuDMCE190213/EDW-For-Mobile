using DAL.Models.Base;

namespace DAL.Models
{
    public class CartItem
    {
        public int CartItemId { get; set; }
        public int CustomerId { get; set; }
        public Guid ProductVariantId { get; set; }

        public int Quantity { get; set; }

        public virtual ProductVariant? ProductVariant { get; set; }

        public static CartItem Create(int customerId, Guid productVariantId, int quantity)
        {
            return new CartItem
            {
                CustomerId = customerId,
                ProductVariantId = productVariantId,
                Quantity = quantity
            };
        }

        public void UpdateQuantity(int quantity)
        {
            Quantity = quantity;
        }
    }
}
