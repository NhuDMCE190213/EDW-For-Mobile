using DAL.Models;

namespace DAL.Utilities
{
    /// <summary>
    /// Factory Pattern - OrderBuilder class for building orders with fluent API
    /// Demonstrates builder pattern for complex object creation
    /// </summary>
    public class OrderBuilder
    {
        private Guid _orderId = Guid.NewGuid();
        private int _customerId;
        private int? _promotionId;
        private decimal _totalAmount;
        private string _status = "Pending";
        private readonly List<OrderItem> _orderItems = new();

        /// <summary>
        /// Set the order ID (optional - auto-generated if not set)
        /// </summary>
        public OrderBuilder WithOrderId(Guid orderId)
        {
            _orderId = orderId;
            return this;
        }

        /// <summary>
        /// Set the customer ID (required)
        /// </summary>
        public OrderBuilder WithCustomerId(int customerId)
        {
            _customerId = customerId;
            return this;
        }

        /// <summary>
        /// Set the promotion ID (optional)
        /// </summary>
        public OrderBuilder WithPromotionId(int? promotionId)
        {
            _promotionId = promotionId;
            return this;
        }

        /// <summary>
        /// Set the total amount (required)
        /// </summary>
        public OrderBuilder WithTotalAmount(decimal totalAmount)
        {
            _totalAmount = totalAmount;
            return this;
        }

        /// <summary>
        /// Set the order status
        /// </summary>
        public OrderBuilder WithStatus(string status)
        {
            _status = status;
            return this;
        }

        /// <summary>
        /// Add a single order item
        /// </summary>
        public OrderBuilder AddOrderItem(OrderItem orderItem)
        {
            _orderItems.Add(orderItem);
            return this;
        }

        /// <summary>
        /// Add multiple order items
        /// </summary>
        public OrderBuilder AddOrderItems(List<OrderItem> orderItems)
        {
            _orderItems.AddRange(orderItems);
            return this;
        }

        /// <summary>
        /// Build the Order object
        /// </summary>
        public Order Build()
        {
            if (_customerId <= 0)
                throw new InvalidOperationException("Customer ID must be set and greater than 0.");

            var order = Order.Create(_customerId, _promotionId, _totalAmount, _status);
            order.OrderId = _orderId;

            foreach (var item in _orderItems)
            {
                order.AddOrderItem(item);
            }

            return order;
        }
    }

    /// <summary>
    /// Factory Pattern - OrderItemBuilder class for building order items with fluent API
    /// </summary>
    public class OrderItemBuilder
    {
        private Guid _orderId;
        private Guid _productVariantId;
        private int _quantity;
        private decimal _priceAtPurchase;

        /// <summary>
        /// Set the order ID (required)
        /// </summary>
        public OrderItemBuilder WithOrderId(Guid orderId)
        {
            _orderId = orderId;
            return this;
        }

        /// <summary>
        /// Set the product variant ID (required)
        /// </summary>
        public OrderItemBuilder WithProductVariantId(Guid productVariantId)
        {
            _productVariantId = productVariantId;
            return this;
        }

        /// <summary>
        /// Set the quantity (required, must be > 0)
        /// </summary>
        public OrderItemBuilder WithQuantity(int quantity)
        {
            if (quantity <= 0)
                throw new InvalidOperationException("Quantity must be greater than 0.");
            _quantity = quantity;
            return this;
        }

        /// <summary>
        /// Set the price at purchase (required)
        /// </summary>
        public OrderItemBuilder WithPriceAtPurchase(decimal priceAtPurchase)
        {
            if (priceAtPurchase < 0)
                throw new InvalidOperationException("Price must be non-negative.");
            _priceAtPurchase = priceAtPurchase;
            return this;
        }

        /// <summary>
        /// Build the OrderItem object
        /// </summary>
        public OrderItem Build()
        {
            if (_orderId == Guid.Empty)
                throw new InvalidOperationException("Order ID must be set.");

            if (_productVariantId == Guid.Empty)
                throw new InvalidOperationException("Product Variant ID must be set.");

            if (_quantity <= 0)
                throw new InvalidOperationException("Quantity must be set and greater than 0.");

            return OrderItem.Create(_orderId, _productVariantId, _quantity, _priceAtPurchase);
        }
    }

    /// <summary>
    /// Factory Pattern - OrderFactory class for creating orders
    /// Encapsulates complex creation logic
    /// </summary>
    public static class OrderFactory
    {
        /// <summary>
        /// Create a new OrderBuilder instance
        /// </summary>
        public static OrderBuilder CreateBuilder()
        {
            return new OrderBuilder();
        }

        /// <summary>
        /// Create a new order with minimal required parameters
        /// </summary>
        public static Order CreateOrder(int customerId, decimal totalAmount, string status = "Pending", int? promotionId = null)
        {
            return Order.Create(customerId, promotionId, totalAmount, status);
        }

        /// <summary>
        /// Create a new order with items using builder pattern
        /// </summary>
        public static Order CreateOrderWithItems(int customerId, decimal totalAmount, List<OrderItem> items, string status = "Pending", int? promotionId = null)
        {
            var order = Order.Create(customerId, promotionId, totalAmount, status);
            foreach (var item in items)
            {
                order.AddOrderItem(item);
            }
            return order;
        }
    }

    /// <summary>
    /// Factory Pattern - OrderItemFactory class for creating order items
    /// </summary>
    public static class OrderItemFactory
    {
        /// <summary>
        /// Create a new OrderItemBuilder instance
        /// </summary>
        public static OrderItemBuilder CreateBuilder()
        {
            return new OrderItemBuilder();
        }

        /// <summary>
        /// Create a new order item with minimal required parameters
        /// </summary>
        public static OrderItem CreateOrderItem(Guid orderId, Guid productVariantId, int quantity, decimal priceAtPurchase)
        {
            return OrderItem.Create(orderId, productVariantId, quantity, priceAtPurchase);
        }
    }
}
