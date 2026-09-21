using BLL.DTOs.OrderItem;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;

namespace BLL.Services
{
    /// <summary>
    /// Service for managing order items
    /// Implements Dependency Inversion Principle: depends on IOrderItemRepository abstraction
    /// Uses factory pattern via OrderItem.Create() static method
    /// </summary>
    public class OrderItemService : IOrderItemService
    {
        private readonly IOrderItemRepository _orderItemRepository;
        private readonly IOrderRepository _orderRepository;

        public OrderItemService(
            IOrderItemRepository orderItemRepository,
            IOrderRepository orderRepository)
        {
            _orderItemRepository = orderItemRepository;
            _orderRepository = orderRepository;
        }

        /// <summary>
        /// Get all order items with mapping from entity to DTO
        /// </summary>
        public async Task<List<OrderItemDto>> GetAllOrderItemsAsync()
        {
            var orderItems = await _orderItemRepository.GetAllOrderItemsAsync();
            return MapOrderItemsToDto(orderItems);
        }

        /// <summary>
        /// Get order item by ID
        /// </summary>
        public async Task<OrderItemDto?> GetOrderItemByIdAsync(int orderItemId)
        {
            var orderItem = await _orderItemRepository.GetOrderItemByIdAsync(orderItemId);
            if (orderItem == null)
                return null;

            return MapOrderItemToDto(orderItem);
        }

        /// <summary>
        /// Get order items by order ID
        /// </summary>
        public async Task<List<OrderItemDto>> GetOrderItemsByOrderIdAsync(Guid orderId)
        {
            var orderItems = await _orderItemRepository.GetOrderItemsWithProductVariantAsync(orderId);
            return MapOrderItemsToDto(orderItems);
        }

        /// <summary>
        /// Create a new order item using factory pattern
        /// </summary>
        public async Task<OrderItemDto> CreateOrderItemAsync(Guid orderId, OrderItemCreateDto orderItemCreateDto)
        {
            // Factory pattern: Use OrderItem.Create() to instantiate new order item
            var newOrderItem = OrderItem.Create(
                orderId,
                orderItemCreateDto.ProductVariantId,
                orderItemCreateDto.Quantity,
                orderItemCreateDto.PriceAtPurchase);

            // Save to database
            var createdOrderItem = await _orderItemRepository.CreateOrderItemAsync(newOrderItem);

            // Recalculate order total
            var order = await _orderRepository.GetOrderByIdAsync(orderId);
            if (order != null)
            {
                order.RecalculateTotalAmount();
                await _orderRepository.UpdateOrderAsync(order);
            }

            return MapOrderItemToDto(createdOrderItem);
        }

        /// <summary>
        /// Update an existing order item
        /// </summary>
        public async Task<bool> UpdateOrderItemAsync(OrderItemUpdateDto orderItemUpdateDto)
        {
            var orderItem = await _orderItemRepository.GetOrderItemByIdAsync(orderItemUpdateDto.OrderItemId);
            if (orderItem == null)
                return false;

            var orderId = orderItem.OrderId;
            orderItem.Update(orderItemUpdateDto.Quantity, orderItemUpdateDto.PriceAtPurchase);
            
            var updateResult = await _orderItemRepository.UpdateOrderItemAsync(orderItem);

            // Recalculate order total
            if (updateResult)
            {
                var order = await _orderRepository.GetOrderByIdAsync(orderId);
                if (order != null)
                {
                    order.RecalculateTotalAmount();
                    await _orderRepository.UpdateOrderAsync(order);
                }
            }

            return updateResult;
        }

        /// <summary>
        /// Delete order item (soft delete)
        /// </summary>
        public async Task<bool> DeleteOrderItemAsync(int orderItemId)
        {
            var orderItem = await _orderItemRepository.GetOrderItemByIdAsync(orderItemId);
            if (orderItem == null)
                return false;

            var orderId = orderItem.OrderId;
            var deleteResult = await _orderItemRepository.DeleteOrderItemAsync(orderItemId);

            // Recalculate order total
            if (deleteResult)
            {
                var order = await _orderRepository.GetOrderByIdAsync(orderId);
                if (order != null)
                {
                    order.RecalculateTotalAmount();
                    await _orderRepository.UpdateOrderAsync(order);
                }
            }

            return deleteResult;
        }

        /// <summary>
        /// Delete all order items for an order (soft delete)
        /// </summary>
        public async Task<bool> DeleteOrderItemsByOrderIdAsync(Guid orderId)
        {
            return await _orderItemRepository.DeleteOrderItemsByOrderIdAsync(orderId);
        }

        #region Mapping Helpers

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
        /// Map list of OrderItem entities to OrderItemDtos
        /// </summary>
        private List<OrderItemDto> MapOrderItemsToDto(List<OrderItem> orderItems)
        {
            return orderItems.Select(MapOrderItemToDto).ToList();
        }

        #endregion
    }
}
