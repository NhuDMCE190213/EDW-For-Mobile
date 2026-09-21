using BLL.DTOs.CartItem;

namespace BLL.Services.Interfaces
{
    public interface ICartItemService
    {
        Task<List<CartItemDTO>> GetCartItemsByCustomerIdAsync(int customerId);
        Task<CartItemDTO?> GetCartItemByIdAsync(int cartItemId);
        Task<CartItemDTO> CreateCartItemAsync(CartItemCreateDTO cartItemCreateDto);
        Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity);
        Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity, int customerId);
        Task<bool> DeleteCartItemAsync(int cartItemId);
        Task<bool> DeleteCartItemAsync(int cartItemId,int customerId);
    }
}
