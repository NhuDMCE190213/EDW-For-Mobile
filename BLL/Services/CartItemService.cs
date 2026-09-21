using AutoMapper;
using BLL.DTOs.CartItem;
using BLL.Services.Interfaces;
using DAL.Models;
using DAL.Repositories.Interfaces;

namespace BLL.Services
{
    public class CartItemService : ICartItemService
    {
        private readonly ICartItemRepository _cartItemRepository;
        private readonly IProductVariantRepository _productVariantRepository;
        private readonly IMapper _mapper;

        public CartItemService(ICartItemRepository cartItemRepository,
            IProductVariantRepository productVariantRepository,
            IMapper mapper)
        {
            _cartItemRepository = cartItemRepository;
            _productVariantRepository = productVariantRepository;
            _mapper = mapper;
        }

        public async Task<CartItemDTO> CreateCartItemAsync(CartItemCreateDTO cartItemCreateDto)
        {
            var variant = await _productVariantRepository.GetProductVariantByIdAsync(cartItemCreateDto.ProductVariantId);
            if (variant == null)
            {
                throw new ArgumentException($"Product variant with ID {cartItemCreateDto.ProductVariantId} does not exist.");
            }

            var existingCartItem = await _cartItemRepository.GetCartItemByCustomerIdAndVariantIdAsync(cartItemCreateDto.CustomerId, cartItemCreateDto.ProductVariantId);

            if (existingCartItem != null)
            {
                int newQuantity = existingCartItem.Quantity + cartItemCreateDto.Quantity;

                if (newQuantity > variant.StockQuantity)
                {
                    throw new InvalidOperationException($"Cannot add {cartItemCreateDto.Quantity} items to the cart. Only {variant.StockQuantity - existingCartItem.Quantity} items are available in stock.");
                }

                existingCartItem.UpdateQuantity(newQuantity);
                var updatedCartItem = await _cartItemRepository.UpdateCartItemAsync(existingCartItem);

                return _mapper.Map<CartItemDTO>(existingCartItem);
            }

            if (cartItemCreateDto.Quantity > variant.StockQuantity)
            {
                throw new InvalidOperationException($"Cannot add {cartItemCreateDto.Quantity} items to the cart. Only {variant.StockQuantity} items are available in stock.");
            }

            var newCartItem = CartItem.Create(
                cartItemCreateDto.CustomerId,
                cartItemCreateDto.ProductVariantId,
                cartItemCreateDto.Quantity
                );

            var respone = await _cartItemRepository.CreateCartItemAsync(newCartItem);
            return _mapper.Map<CartItemDTO>(respone);
        }

        public async Task<bool> DeleteCartItemAsync(int cartItemId)
        {
            return await _cartItemRepository.DeleteCartItemAsync(cartItemId);
        }

        public async Task<bool> DeleteCartItemAsync(int cartItemId, int customerId)
        {
            var cartItem = await _cartItemRepository.GetCartItemByIdAsync(cartItemId);
            if (cartItem == null) return false;
            if (cartItem.CustomerId != customerId)
                throw new UnauthorizedAccessException("You do not have any permission to perform this action.");

            return await _cartItemRepository.DeleteCartItemAsync(cartItemId);
        }

        public async Task<CartItemDTO?> GetCartItemByIdAsync(int cartItemId)
        {
            var cartItem = await _cartItemRepository.GetCartItemByIdAsync(cartItemId);
            if (cartItem == null)
            {
                return null;
            }
            
            return _mapper.Map<CartItemDTO>(cartItem);
        }

        public async Task<List<CartItemDTO>> GetCartItemsByCustomerIdAsync(int customerId)
        {
            var cartItems = await _cartItemRepository.GetCartItemsByCustomerIdAsync(customerId);
            
            return _mapper.Map<List<CartItemDTO>>(cartItems);
        }

        public async Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity)
        {
            var cartItem = await _cartItemRepository.GetCartItemByIdAsync(cartItemId);
            if (cartItem == null)
                throw new ArgumentException($"Cart item with ID {cartItemId} does not exist.");

            if (cartItem.ProductVariant != null)
            {
                var stockQuantity = cartItem.ProductVariant.StockQuantity;
                if (quantity > stockQuantity)
                    throw new InvalidOperationException($"Cannot update cart item quantity to {quantity}. Only {stockQuantity} items are available in stock.");
            }

            return await _cartItemRepository.UpdateCartItemQuantityAsync(cartItemId, quantity);
        }

        public async Task<bool> UpdateCartItemQuantityAsync(int cartItemId, int quantity, int customerId)
        {
            var cartItem = await _cartItemRepository.GetCartItemByIdAsync(cartItemId);
            if (cartItem == null)
                throw new ArgumentException($"Cart item with ID {cartItemId} does not exist.");
            if (cartItem.CustomerId != customerId)
                throw new UnauthorizedAccessException("You do not have any permission to perform this action.");

            if (cartItem.ProductVariant != null)
            {
                var stockQuantity = cartItem.ProductVariant.StockQuantity;
                if (quantity > stockQuantity)
                    throw new InvalidOperationException($"Cannot update cart item quantity to {quantity}. Only {stockQuantity} items are available in stock.");
            }

            return await _cartItemRepository.UpdateCartItemQuantityAsync(cartItemId, quantity);
        }
    }
}
