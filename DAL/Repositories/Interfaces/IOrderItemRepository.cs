using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IOrderItemRepository
    {
        Task<List<OrderItem>> GetAllOrderItemsAsync();
        Task<OrderItem?> GetOrderItemByIdAsync(int orderItemId);
        Task<List<OrderItem>> GetOrderItemsByOrderIdAsync(Guid orderId);
        Task<List<OrderItem>> GetOrderItemsWithProductVariantAsync(Guid orderId);
        Task<OrderItem> CreateOrderItemAsync(OrderItem orderItem);
        Task<bool> UpdateOrderItemAsync(OrderItem orderItem);
        Task<bool> DeleteOrderItemAsync(int orderItemId);
        Task<bool> DeleteOrderItemsByOrderIdAsync(Guid orderId);
    }
}
