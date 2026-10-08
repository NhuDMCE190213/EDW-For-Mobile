using BLL.DTOs.Order;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace API.Controllers
{
    [ApiController]
    [Route("api/staff/orders")]
    public class StaffOrdersController : ControllerBase
    {
        private readonly IOrderService _orderService;

        public StaffOrdersController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public async Task<IActionResult> GetOrders()
        {
            var orders = await _orderService.GetAllOrdersAsync();
            return Ok(orders);
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard()
        {
            var orders = await _orderService.GetAllOrdersAsync();
            var totalOrders = orders.Count;
            var totalRevenue = orders.Where(o => o.Status == "Completed").Sum(o => o.TotalAmount);
            var pendingOrders = orders.Count(o => o.Status == "Pending");
            return Ok(new { TotalOrders = totalOrders, TotalRevenue = totalRevenue, PendingOrders = pendingOrders });
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] string status)
        {
            var result = await _orderService.UpdateOrderStatusAsync(id, status);
            if (!result) return BadRequest("Failed to update status.");
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetOrderById(Guid id)
        {
            var order = await _orderService.GetOrderByIdAsync(id);
            if (order == null) return NotFound();
            return Ok(order);
        }
    }
}
