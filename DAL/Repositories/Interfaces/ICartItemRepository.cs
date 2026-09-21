using DAL.Models;

namespace DAL.Repositories.Interfaces
{
    public interface ICartItemRepository
    {
        Task<List<CartItem>> GetCartItemsByCustomerIdAsync(int customerId);
        Task<CartItem?> GetCartItemByIdAsync(int cartItemId);
        Task<CartItem> CreateCartItemAsync(CartItem cartItem);
        Task<bool> UpdateCartItemAsync(CartItem cartItem);
        Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity);
        Task<bool> DeleteCartItemAsync(int cartItemId);
        Task<bool> DeleteCartItemsAsync(IEnumerable<int> cartItemIds);
        Task<CartItem?> GetCartItemByCustomerIdAndVariantIdAsync(int customerId, Guid productVariantId);
    }
}
