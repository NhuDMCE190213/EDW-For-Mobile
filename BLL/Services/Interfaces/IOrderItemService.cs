using BLL.DTOs.OrderItem;

namespace BLL.Services.Interfaces
{
    public interface IOrderItemService
    {
        Task<List<OrderItemDto>> GetAllOrderItemsAsync();
        Task<OrderItemDto?> GetOrderItemByIdAsync(int orderItemId);
        Task<List<OrderItemDto>> GetOrderItemsByOrderIdAsync(Guid orderId);
        Task<OrderItemDto> CreateOrderItemAsync(Guid orderId, OrderItemCreateDto orderItemCreateDto);
        Task<bool> UpdateOrderItemAsync(OrderItemUpdateDto orderItemUpdateDto);
        Task<bool> DeleteOrderItemAsync(int orderItemId);
        Task<bool> DeleteOrderItemsByOrderIdAsync(Guid orderId);
    }
}
