using BLL.DTOs.CartItem;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/customer/cart")]
    public class CustomerCartController : ControllerBase
    {
        private readonly ICartItemService _cartItemService;

        public CustomerCartController(ICartItemService cartItemService)
        {
            _cartItemService = cartItemService;
        }

        [HttpGet("{customerId}")]
        public async Task<IActionResult> GetCart(int customerId)
        {
            var cart = await _cartItemService.GetCartItemsByCustomerIdAsync(customerId);
            return Ok(cart);
        }

        [HttpDelete("{cartItemId}")]
        public async Task<IActionResult> RemoveFromCart(int cartItemId, [FromQuery] int customerId)
        {
            try
            {
                await _cartItemService.DeleteCartItemAsync(cartItemId, customerId);
                return Ok(new { success = true, message = "Item removed from cart." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }
    }
}
