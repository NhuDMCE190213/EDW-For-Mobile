using BLL.DTOs.CartItem;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Customer.Mvc.Controllers
{
    [Authorize]
    public class CartController : Controller
    {
        private int CustomerId => int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        private readonly ICartItemService _cartItemService;
        private readonly IProductVariantService _productVariantService;
        private readonly IProductService _productService;

        public CartController(
            IProductVariantService productVariantService,
            IProductService productService,
            ICartItemService cartItemService)
        {
            _productVariantService = productVariantService;
            _productService = productService;
            _cartItemService = cartItemService;
        }

        // View Cart Page
        public async Task<IActionResult> Index()
        {
            var cart = await _cartItemService.GetCartItemsByCustomerIdAsync(CustomerId);
            return View(cart);
        }

        // Fetch variants for quick selector modal on homepage
        [HttpGet]
        public async Task<IActionResult> GetProductVariants(int productId)
        {
            var product = await _productService.GetProductByIdAsync(productId);
            if (product == null)
            {
                return NotFound("Product not found");
            }

            var variants = await _productVariantService.GetVariantsByProductIdAsync(productId);
            var activeVariants = variants.Where(v => !v.IsDeleted).ToList();

            return Json(new
            {
                productId = product.ProductId,
                productName = product.ProductName,
                brand = product.Brand,
                variants = activeVariants.Select(v => new
                {
                    productVariantId = v.ProductVariantId,
                    sku = v.Sku,
                    color = v.Color,
                    cpu = v.Cpu,
                    ram = v.Ram,
                    storage = v.Storage,
                    screenSize = v.ScreenSize,
                    price = v.Price,
                    finalPrice = v.GetPrice(),
                    isOnSale = v.GetPrice() < v.Price,
                    stockQuantity = v.StockQuantity,
                    imageUrl = v.ImageUrl
                })
            });
        }

        // Add item to cart (AJAX or standard form post)
        [HttpPost]
        public async Task<IActionResult> AddToCart(Guid variantId, int quantity = 1)
        {
            try
            {
                var createDto = new CartItemCreateDTO
                {
                    ProductVariantId = variantId,
                    Quantity = quantity,
                    CustomerId = CustomerId
                };

                await _cartItemService.CreateCartItemAsync(createDto);

                var cartItems = await _cartItemService.GetCartItemsByCustomerIdAsync(CustomerId);
                var totalCount = cartItems.Sum(i => i.Quantity);

                var addedVariant = cartItems.FirstOrDefault(i => i.ProductVariantId == variantId)?.ProductVariant;

                bool promotionSoldOut = addedVariant != null
                    && addedVariant.PromotionId.HasValue
                    && (addedVariant.Promotion == null || !addedVariant.Promotion.IsActive());

                string? warning = promotionSoldOut
                    ? "Product promotion has ended or sold out."
                    : null;

                return Json(new { success = true, message = "Product added to cart!", totalCount, warning });
            }
            catch (ArgumentException ex) { return Json(new { success = false, message = ex.Message }); }
            catch (InvalidOperationException ex) { return Json(new { success = false, message = ex.Message }); }
            catch (Exception ex) { return Json(new { success = false, message = "An unexpected error occurred: " + ex.Message }); }
        }

        [HttpPost]
        public async Task<IActionResult> UpdateQuantity(int cartItemId, int quantity)
        {
            try
            {
                await _cartItemService.UpdateCartItemQuantityAsync(cartItemId, quantity, CustomerId);
                var cartItems = await _cartItemService.GetCartItemsByCustomerIdAsync(CustomerId);
                var updatedItem = cartItems.FirstOrDefault(i => i.CartItemId == cartItemId);
                var totalCount = cartItems.Sum(i => i.Quantity);
                var cartTotal = cartItems.Sum(i => i.Quantity * (i.ProductVariant?.GetPrice() ?? 0));
                var totalPrice = (updatedItem?.Quantity ?? 0) * (updatedItem?.ProductVariant?.GetPrice() ?? 0);

                var variant = updatedItem?.ProductVariant;

                bool promotionSoldOut = variant != null
                    && variant.PromotionId.HasValue
                    && (variant.Promotion == null || !variant.Promotion.IsActive());

                string? warning = promotionSoldOut
                    ? "Sản phẩm đã hết số lượng ưu đãi, giá được tính theo giá gốc."
                    : null;

                return Json(new { success = true, totalCount, totalPrice, cartTotal });
            }
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (Exception ex) when (ex is ArgumentException || ex is InvalidOperationException)
            {
                return Json(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Can not update item quantity: " + ex.Message });
            }
        }

        // Remove item from cart
        [HttpPost]
        public async Task<IActionResult> Remove(int cartItemId)
        {
            try
            {
                await _cartItemService.DeleteCartItemAsync(cartItemId, CustomerId);

                var cartItems = await _cartItemService.GetCartItemsByCustomerIdAsync(CustomerId);
                var totalCount = cartItems.Sum(i => i.Quantity);
                var cartTotal = cartItems.Sum(i => i.Quantity * (i.ProductVariant?.Price ?? 0));

                return Json(new { success = true, totalCount, cartTotal });
            } 
            catch (UnauthorizedAccessException)
            {
                return Forbid();
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Can not remove item: " + ex.Message });
            }
        }
    }
}
