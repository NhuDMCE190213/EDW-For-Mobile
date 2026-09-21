using BLL.DTOs.Order;

namespace BLL.Services.Interfaces
{
    public interface IOrderService
    {
        Task<List<OrderDto>> GetAllOrdersAsync();
        Task<OrderDto?> GetOrderByIdAsync(Guid orderId);
        Task<List<OrderDto>> GetOrdersByCustomerIdAsync(int customerId);
        Task<List<OrderDto>> GetOrdersByStatusAsync(string status);
        Task<OrderDto> CreateOrderAsync(OrderCreateDto orderCreateDto);
        Task<OrderCheckoutResultDto> CheckoutCartAsync(int customerId, IReadOnlyCollection<int> selectedCartItemIds);
        Task<bool> UpdateOrderAsync(OrderUpdateDto orderUpdateDto);
        Task<bool> UpdateOrderStatusAsync(Guid orderId, string status);
        Task<bool> DeleteOrderAsync(Guid orderId);
        Task<List<OrderDto>> SearchOrdersAsync(int? customerId, string? status, DateTime? fromDate, DateTime? toDate);
        Task<bool> CancelOrderAsync(Guid orderId);
    }
}
