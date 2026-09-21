using DAL.Models.Base;

namespace DAL.Models
{
    public class OrderItem : IBaseEntity
    {
        public int OrderItemId { get; set; }
        public Guid OrderId { get; set; }
        public Guid ProductVariantId { get; set; }
        public int Quantity { get; set; }
        public decimal PriceAtPurchase { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        // Navigation properties
        public virtual Order? Order { get; set; }
        public virtual ProductVariant? ProductVariant { get; set; }

        /// <summary>
        /// Factory method to create a new OrderItem using builder pattern
        /// </summary>
        public static OrderItem Create(Guid orderId, Guid productVariantId, int quantity, decimal priceAtPurchase)
        {
            return new OrderItem
            {
                OrderId = orderId,
                ProductVariantId = productVariantId,
                Quantity = quantity,
                PriceAtPurchase = priceAtPurchase,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        /// <summary>
        /// Update order item
        /// </summary>
        public void Update(int quantity, decimal priceAtPurchase)
        {
            Quantity = quantity;
            PriceAtPurchase = priceAtPurchase;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Soft delete order item
        /// </summary>
        public void Delete()
        {
            IsDeleted = true;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Get subtotal of this order item
        /// </summary>
        public decimal GetSubtotal()
        {
            return Quantity * PriceAtPurchase;
        }
    }
}
