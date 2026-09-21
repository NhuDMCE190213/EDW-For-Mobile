using DAL.Data;
using DAL.Models;
using DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DAL.Repositories
{
    public class CartItemRepository : ICartItemRepository
    {
        private readonly AppDbContext _context;

        public CartItemRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<CartItem> CreateCartItemAsync(CartItem cartItem)
        {
            _context.CartItems.Add(cartItem);
            await _context.SaveChangesAsync();
            return cartItem;
        }

        public async Task<bool> DeleteCartItemAsync(int cartItemId)
        {
            var cartItem = await _context.CartItems.FirstOrDefaultAsync(ci => ci.CartItemId == cartItemId);
            if (cartItem == null)
            {
                return false;
            }

            _context.CartItems.Remove(cartItem);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteCartItemsAsync(IEnumerable<int> cartItemIds)
        {
            var ids = cartItemIds.Distinct().ToList();
            if (!ids.Any())
            {
                return true;
            }

            var cartItems = await _context.CartItems
                .Where(ci => ids.Contains(ci.CartItemId))
                .ToListAsync();

            if (!cartItems.Any())
            {
                return false;
            }

            _context.CartItems.RemoveRange(cartItems);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<CartItem?> GetCartItemByIdAsync(int cartItemId)
        {
            return await _context.CartItems
                .Include(ci => ci.ProductVariant)
                    .ThenInclude(pv => pv!.Promotion)
                .FirstOrDefaultAsync(ci => ci.CartItemId == cartItemId); ;
        }

        public async Task<List<CartItem>> GetCartItemsByCustomerIdAsync(int customerId)
        {
            var cartItems = await _context.CartItems
                .Include(ci => ci.ProductVariant)
                    .ThenInclude(pv => pv!.Promotion)
                .Include(ci => ci.ProductVariant)
                    .ThenInclude(pv => pv!.Product)
                .Where(ci => ci.CustomerId == customerId)
                .ToListAsync();
            return cartItems;
        }

        public async Task<bool> UpdateCartItemAsync(CartItem cartItem)
        {
            var existingCartItem = await _context.CartItems.FirstOrDefaultAsync(ci => ci.CartItemId == cartItem.CartItemId);
            if (existingCartItem == null)
            {
                return false;
            }
            existingCartItem.Quantity = cartItem.Quantity;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity)
        {
            var cartItem = await _context.CartItems.FirstOrDefaultAsync(ci => ci.CartItemId == cartItemId);
            if (cartItem == null)
            {
                return false;
            }

            cartItem.Quantity = quantity;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<CartItem?> GetCartItemByCustomerIdAndVariantIdAsync(int customerId, Guid productVariantId)
        {
            return await _context.CartItems.FirstOrDefaultAsync(ci => ci.CustomerId == customerId && ci.ProductVariantId == productVariantId);
        }
    }
}
