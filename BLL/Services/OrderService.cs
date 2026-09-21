using BLL.DTOs.Order;
using BLL.DTOs.OrderItem;
using BLL.Services.Interfaces;
using DAL.Data;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BLL.Services
{
    /// <summary>
    /// Service for managing orders
    /// Implements Dependency Inversion Principle: depends on IOrderRepository abstraction
    /// Uses factory pattern via Order.Create() static method
    /// </summary>
    public class OrderService : IOrderService
    {
        private readonly IOrderRepository _orderRepository;
        private readonly IOrderItemRepository _orderItemRepository;
        private readonly ICartItemRepository _cartItemRepository;
        private readonly AppDbContext _context;
        private readonly IProductVariantRepository _productVariantRepository;

        public OrderService(
            IOrderRepository orderRepository,
            IOrderItemRepository orderItemRepository,
            ICartItemRepository cartItemRepository,
            AppDbContext context,
            IProductVariantRepository productVariantRepository)
        {
            _orderRepository = orderRepository;
            _orderItemRepository = orderItemRepository;
            _cartItemRepository = cartItemRepository;
            _context = context;
            _productVariantRepository = productVariantRepository;
        }

        /// <summary>
        /// Get all orders with mapping from entity to DTO
        /// </summary>
        public async Task<List<OrderDto>> GetAllOrdersAsync()
        {
            var orders = await _orderRepository.GetOrdersWithItemsAsync();
            return MapOrdersToDto(orders);
        }

        /// <summary>
        /// Get order by ID
        /// </summary>
        public async Task<OrderDto?> GetOrderByIdAsync(Guid orderId)
        {
            var order = await _orderRepository.GetOrderWithItemsByIdAsync(orderId);
            if (order == null)
                return null;

            return MapOrderToDto(order);
        }

        /// <summary>
        /// Get orders by customer ID
        /// </summary>
        public async Task<List<OrderDto>> GetOrdersByCustomerIdAsync(int customerId)
        {
            var orders = await _orderRepository.GetOrdersByCustomerIdAsync(customerId);
            return MapOrdersToDto(orders);
        }

        /// <summary>
        /// Get orders by status
        /// </summary>
        public async Task<List<OrderDto>> GetOrdersByStatusAsync(string status)
        {
            var orders = await _orderRepository.GetOrdersByStatusAsync(status);
            return MapOrdersToDto(orders);
        }

        /// <summary>
        /// Create a new order using factory pattern
        /// </summary>
        public async Task<OrderDto> CreateOrderAsync(OrderCreateDto orderCreateDto)
        {
            // Factory pattern: Use Order.Create() to instantiate new order
            var newOrder = Order.Create(
                orderCreateDto.CustomerId,
                orderCreateDto.PromotionId,
                orderCreateDto.TotalAmount,
                orderCreateDto.Status);

            // Add order items
            foreach (var itemDto in orderCreateDto.OrderItems)
            {
                var orderItem = OrderItem.Create(
                    newOrder.OrderId,
                    itemDto.ProductVariantId,
                    itemDto.Quantity,
                    itemDto.PriceAtPurchase);

                newOrder.AddOrderItem(orderItem);
            }

            // Save to database
            var createdOrder = await _orderRepository.CreateOrderAsync(newOrder);
            return MapOrderToDto(createdOrder);
        }

        public async Task<OrderCheckoutResultDto> CheckoutCartAsync(int customerId, IReadOnlyCollection<int> selectedCartItemIds)
        {
            if (customerId <= 0)
            {
                throw new ArgumentException("Customer is invalid.", nameof(customerId));
            }

            var uniqueSelectedIds = selectedCartItemIds.Distinct().ToList();
            if (!uniqueSelectedIds.Any())
            {
                throw new ArgumentException("At least one cart item must be selected.", nameof(selectedCartItemIds));
            }

            var cartItems = await _cartItemRepository.GetCartItemsByCustomerIdAsync(customerId);
            var selectedCartItems = cartItems.Where(item => uniqueSelectedIds.Contains(item.CartItemId)).ToList();

            if (selectedCartItems.Count != uniqueSelectedIds.Count)
            {
                throw new InvalidOperationException("One or more selected cart items are invalid or no longer available.");
            }

            await using var transaction = await _context.Database.BeginTransactionAsync();

            decimal subtotal = 0m;
            decimal discount = 0m;
            decimal shipping = 0m;
            var orderItems = new List<OrderItem>();

            foreach (var cartItem in selectedCartItems)
            {
                var variant = cartItem.ProductVariant;
                if (variant == null)
                {
                    throw new InvalidOperationException($"Product variant for cart item {cartItem.CartItemId} could not be loaded.");
                }

                if (variant.IsDeleted)
                {
                    throw new InvalidOperationException($"Product variant {variant.ProductVariantId} is no longer available.");
                }

                if (variant.Product == null || variant.Product.IsDeleted)
                {
                    throw new InvalidOperationException($"Product for variant {variant.ProductVariantId} is no longer available.");
                }

                if (cartItem.Quantity <= 0)
                {
                    throw new InvalidOperationException($"Quantity for cart item {cartItem.CartItemId} must be greater than zero.");
                }

                if (cartItem.Quantity > variant.StockQuantity)
                {
                    throw new InvalidOperationException($"Only {variant.StockQuantity} units are available for variant {variant.ProductVariantId}.");
                }

                var originalPrice = variant.Price;
                var unitPrice = variant.GetPrice(); // giá sau khuyến mãi (nếu Promotion active)

                if (unitPrice < 0)
                {
                    throw new InvalidOperationException($"Price for variant {variant.ProductVariantId} is invalid.");
                }

                subtotal += originalPrice * cartItem.Quantity;
                discount += (originalPrice - unitPrice) * cartItem.Quantity;

                orderItems.Add(OrderItem.Create(
                    Guid.Empty,
                    variant.ProductVariantId,
                    cartItem.Quantity,
                    unitPrice)); // lưu giá THỰC KHÁCH TRẢ (đã giảm) vào PriceAtPurchase
            }

            var total = subtotal - discount + shipping;
            if (total < 0)
            {
                total = 0;
            }


            try
            {
                var order = Order.Create(customerId, null, total, "Pending");

                foreach (var orderItem in orderItems)
                {
                    var orderItemWithOrderId = OrderItem.Create(
                        order.OrderId,
                        orderItem.ProductVariantId,
                        orderItem.Quantity,
                        orderItem.PriceAtPurchase);

                    orderItemWithOrderId.ProductVariant = selectedCartItems
                        .First(ci => ci.ProductVariant!.ProductVariantId == orderItem.ProductVariantId)
                        .ProductVariant;

                    order.AddOrderItem(orderItemWithOrderId);
                }

                // === Trừ kho + trừ promotion (mới thêm) ===
                foreach (var cartItem in selectedCartItems)
                {
                    var variant = cartItem.ProductVariant!;

                    variant.StockQuantity -= cartItem.Quantity;
                    if (variant.StockQuantity < 0)
                        variant.StockQuantity = 0;

                    if (variant.Promotion != null
                        && variant.Promotion.IsActive()
                        && variant.Promotion.IsReservedStock
                        && variant.Promotion.MaxReservedStock.HasValue)
                    {
                        variant.Promotion.MaxReservedStock -= 1; // giảm số lượng reserved stock còn lại
                        if (variant.Promotion.MaxReservedStock < 0)
                            variant.Promotion.MaxReservedStock = 0;
                    }
                }
                await _context.SaveChangesAsync();
                // === Hết đoạn thêm ===

                var createdOrder = await _orderRepository.CreateOrderAsync(order);
                await _cartItemRepository.DeleteCartItemsAsync(uniqueSelectedIds);
                await transaction.CommitAsync();

                return new OrderCheckoutResultDto
                {
                    Order = MapOrderToDto(createdOrder),
                    Subtotal = subtotal,
                    Discount = discount,
                    Shipping = shipping,
                    Total = total,
                    PaymentStatus = "Unpaid"
                };
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        /// <summary>
        /// Update an existing order
        /// </summary>
        public async Task<bool> UpdateOrderAsync(OrderUpdateDto orderUpdateDto)
        {
            var order = await _orderRepository.GetOrderByIdAsync(orderUpdateDto.OrderId);
            if (order == null)
                return false;

            order.Update(orderUpdateDto.PromotionId, orderUpdateDto.TotalAmount, orderUpdateDto.Status);
            return await _orderRepository.UpdateOrderAsync(order);
        }

        /// <summary>
        /// Update order status only
        /// </summary>
        public async Task<bool> UpdateOrderStatusAsync(Guid orderId, string status)
        {
            var order = await _orderRepository.GetOrderByIdAsync(orderId);
            if (order == null)
                return false;

            if (order.Status != "Cancelled" && status == "Cancelled")
                await CancelOrderAsync(orderId); // Cancel order if status is being changed to "Cancelled"

            order.UpdateStatus(status);
            return await _orderRepository.UpdateOrderAsync(order);
        }

        /// <summary>
        /// Delete order (soft delete)
        /// </summary>
        public async Task<bool> DeleteOrderAsync(Guid orderId)
        {
            return await _orderRepository.DeleteOrderAsync(orderId);
        }

        /// <summary>
        /// Search orders with multiple criteria
        /// </summary>
        public async Task<List<OrderDto>> SearchOrdersAsync(int? customerId, string? status, DateTime? fromDate, DateTime? toDate)
        {
            var orders = await _orderRepository.SearchOrdersAsync(customerId, status, fromDate, toDate);
            return MapOrdersToDto(orders);
        }

        // OrderService
        public async Task<bool> CancelOrderAsync(Guid orderId)
        {
            var order = await _orderRepository.GetOrderWithItemsByIdAsync(orderId);
            if (order == null) return false;
            if (order.Status is "Completed" or "Cancelled")
                throw new InvalidOperationException($"Cannot cancel an order with status '{order.Status}'.");

            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                foreach (var item in order.OrderItems)
                {
                    var variant = await _productVariantRepository.GetProductVariantByIdAsync(item.ProductVariantId);
                    if (variant == null) continue;

                    variant.StockQuantity += item.Quantity; // hoàn kho

                    if (variant.Promotion != null && item.PriceAtPurchase < variant.Price
                        && variant.Promotion.IsReservedStock && variant.Promotion.MaxReservedStock.HasValue)
                    {
                        variant.Promotion.MaxReservedStock += 1; // hoàn 1 slot promotion (đoán đã dùng dựa vào giá)
                    }
                }
                await _context.SaveChangesAsync();

                order.UpdateStatus("Cancelled");
                await _orderRepository.UpdateOrderAsync(order);
                await transaction.CommitAsync();
                return true;
            }
            catch { await transaction.RollbackAsync(); throw; }
        }

        #region Mapping Helpers

        /// <summary>
        /// Map Order entity to OrderDto
        /// </summary>
        private OrderDto MapOrderToDto(Order order)
        {
            return new OrderDto
            {
                OrderId = order.OrderId,
                CustomerId = order.CustomerId,
                CustomerName = order.Customer?.FullName ?? "",
                PromotionId = order.PromotionId,
                TotalAmount = order.TotalAmount,
                Status = order.Status,
                CreatedAt = order.CreatedAt,
                UpdatedAt = order.UpdatedAt,
                OrderItems = order.OrderItems.Select(oi => MapOrderItemToDto(oi)).ToList()
            };
        }

        /// <summary>
        /// Map OrderItem entity to OrderItemDto
        /// </summary>
        private OrderItemDto MapOrderItemToDto(OrderItem orderItem)
        {
            var productName = orderItem.ProductVariant?.Product?.ProductName ?? "N/A";
            var variantDetails = $"{orderItem.ProductVariant?.Color ?? ""} {orderItem.ProductVariant?.Storage ?? ""}".Trim();

            return new OrderItemDto
            {
                OrderItemId = orderItem.OrderItemId,
                OrderId = orderItem.OrderId,
                ProductVariantId = orderItem.ProductVariantId,
                ProductName = productName,
                ProductVariantDetails = variantDetails,
                Quantity = orderItem.Quantity,
                PriceAtPurchase = orderItem.PriceAtPurchase,
                CreatedAt = orderItem.CreatedAt,
                UpdatedAt = orderItem.UpdatedAt
            };
        }

        /// <summary>
        /// Map list of Order entities to OrderDtos
        /// </summary>
        private List<OrderDto> MapOrdersToDto(List<Order> orders)
        {
            return orders.Select(MapOrderToDto).ToList();
        }

        #endregion
    }
}
