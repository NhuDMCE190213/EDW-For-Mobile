using DAL.Models;
using DAL.Utilities;

namespace DAL.Extensions
{
    /// <summary>
    /// Extension methods for Order management
    /// Provides convenient helper methods using builder and factory patterns
    /// </summary>
    public static class OrderExtensions
    {
        /// <summary>
        /// Create a new order using fluent builder pattern
        /// Example:
        /// var order = Order.CreateBuilder()
        ///     .WithCustomerId(123)
        ///     .WithTotalAmount(99.99m)
        ///     .WithStatus("Pending")
        ///     .Build();
        /// </summary>
        public static OrderBuilder CreateBuilder(this Order _)
        {
            return OrderFactory.CreateBuilder();
        }

        /// <summary>
        /// Get order items that are not deleted
        /// </summary>
        public static IEnumerable<OrderItem> GetActiveOrderItems(this Order order)
        {
            return order.OrderItems.Where(oi => !oi.IsDeleted);
        }

        /// <summary>
        /// Calculate subtotal for all active items
        /// </summary>
        public static decimal GetActiveItemsTotal(this Order order)
        {
            return order.GetActiveOrderItems().Sum(oi => oi.GetSubtotal());
        }

        /// <summary>
        /// Check if order can be cancelled
        /// </summary>
        public static bool CanBeCancelled(this Order order)
        {
            return !order.IsDeleted && order.Status != "Completed" && order.Status != "Cancelled";
        }

        /// <summary>
        /// Cancel order
        /// </summary>
        public static void Cancel(this Order order)
        {
            if (order.CanBeCancelled())
            {
                order.UpdateStatus("Cancelled");
            }
        }
    }

    /// <summary>
    /// Extension methods for OrderItem management
    /// </summary>
    public static class OrderItemExtensions
    {
        /// <summary>
        /// Create a new order item using fluent builder pattern
        /// </summary>
        public static OrderItemBuilder CreateBuilder(this OrderItem _)
        {
            return OrderItemFactory.CreateBuilder();
        }

        /// <summary>
        /// Check if item quantity is valid
        /// </summary>
        public static bool IsValidQuantity(this OrderItem item)
        {
            return item.Quantity > 0;
        }

        /// <summary>
        /// Check if price is valid
        /// </summary>
        public static bool IsValidPrice(this OrderItem item)
        {
            return item.PriceAtPurchase >= 0;
        }

        /// <summary>
        /// Check if item is valid for order processing
        /// </summary>
        public static bool IsValid(this OrderItem item)
        {
            return item.IsValidQuantity() && item.IsValidPrice() && item.ProductVariantId != Guid.Empty;
        }
    }
}
