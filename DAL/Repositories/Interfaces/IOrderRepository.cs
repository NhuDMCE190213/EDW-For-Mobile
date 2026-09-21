using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface IOrderRepository
    {
        Task<List<Order>> GetAllOrdersAsync();
        Task<Order?> GetOrderByIdAsync(Guid orderId);
        Task<List<Order>> GetOrdersByCustomerIdAsync(int customerId);
        Task<List<Order>> GetOrdersByStatusAsync(string status);
        Task<List<Order>> GetOrdersWithItemsAsync();
        Task<Order?> GetOrderWithItemsByIdAsync(Guid orderId);
        Task<Order> CreateOrderAsync(Order order);
        Task<bool> UpdateOrderAsync(Order order);
        Task<bool> DeleteOrderAsync(Guid orderId);
        Task<List<Order>> SearchOrdersAsync(int? customerId, string? status, DateTime? fromDate, DateTime? toDate);
    }
}
