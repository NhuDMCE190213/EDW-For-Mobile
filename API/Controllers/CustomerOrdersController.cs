using BLL.DTOs.CartItem;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/customer/orders")]
    public class CustomerOrdersController : ControllerBase
    {
        private readonly IOrderService _orderService;
        private readonly ICartItemService _cartItemService;

        public CustomerOrdersController(IOrderService orderService, ICartItemService cartItemService)
        {
            _orderService = orderService;
            _cartItemService = cartItemService;
        }

        [HttpGet("{customerId}")]
        public async Task<IActionResult> GetMyOrders(int customerId)
        {
            var orders = await _orderService.GetOrdersByCustomerIdAsync(customerId);
            return Ok(orders);
        }

        [HttpGet("order/{id}")]
        public async Task<IActionResult> GetOrderById(Guid id)
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order == null) return NotFound();
            return Ok(order);
        }

        [HttpPost("{id}/cancel")]
        public async Task<IActionResult> CancelOrder(Guid id)
        {
            var result = await _orderService.CancelOrderAsync(id);
            if (!result) return BadRequest(new { success = false, message = "Failed to cancel order." });
            return Ok(new { success = true, message = "Order cancelled successfully." });
        }

        [HttpPost("{id}/transfer")]
        public async Task<IActionResult> TransferToCart(Guid id, [FromBody] int customerId)
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order == null) return NotFound(new { success = false, message = "Order not found." });

            int transferred = 0;
            var errors = new List<string>();
            foreach (var item in order.OrderItems)
            {
                try
                {
                    var createDto = new CartItemCreateDTO
                    {
                        CustomerId = customerId,
                        ProductVariantId = item.ProductVariantId,
                        Quantity = item.Quantity
                    };
                    await _cartItemService.CreateCartItemAsync(createDto);
                    transferred++;
                }
                catch (Exception ex)
                {
                    errors.Add($"{item.ProductName}: {ex.Message}");
                }
            }
            
            if (transferred == 0) return BadRequest(new { success = false, message = "No items could be transferred." });
            return Ok(new { success = true, transferred = transferred, total = order.OrderItems.Count, errors = errors });
        }
    }
}
