using DAL.Models.Base;

namespace DAL.Models
{
    public class Order : IBaseEntity
    {
        public Guid OrderId { get; set; }
        public int CustomerId { get; set; }
        public virtual Customer? Customer { get; set; }
        public int? PromotionId { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; }

        // Navigation properties
        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

        /// <summary>
        /// Factory method to create a new Order using builder pattern
        /// </summary>
        public static Order Create(int customerId, int? promotionId, decimal totalAmount, string status = "Pending")
        {
            return new Order
            {
                OrderId = Guid.NewGuid(),
                CustomerId = customerId,
                PromotionId = promotionId,
                TotalAmount = totalAmount,
                Status = status,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        /// <summary>
        /// Update order details
        /// </summary>
        public void Update(int? promotionId, decimal totalAmount, string status)
        {
            PromotionId = promotionId;
            TotalAmount = totalAmount;
            Status = status;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Update order status
        /// </summary>
        public void UpdateStatus(string status)
        {
            Status = status;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Soft delete order
        /// </summary>
        public void Delete()
        {
            IsDeleted = true;
            UpdatedAt = DateTime.UtcNow;
        }

        /// <summary>
        /// Add order items
        /// </summary>
        public void AddOrderItem(OrderItem orderItem)
        {
            OrderItems.Add(orderItem);
        }

        /// <summary>
        /// Remove order item
        /// </summary>
        public void RemoveOrderItem(OrderItem orderItem)
        {
            OrderItems.Remove(orderItem);
        }

        /// <summary>
        /// Calculate total amount from order items
        /// </summary>
        public void RecalculateTotalAmount()
        {
            TotalAmount = OrderItems.Sum(oi => oi.Quantity * oi.PriceAtPurchase);
            UpdatedAt = DateTime.UtcNow;
        }
    }
}
