using BLL.DTOs.Order;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Staff.Razor.Pages.Orders
{
    [Authorize]
    public class IndexModel : PageModel
    {
        private readonly IOrderService _orderService;

        public IndexModel(IOrderService orderService)
        {
            _orderService = orderService;
        }

        public List<OrderDto> Orders { get; set; } = new();

        public int TotalOrders => Orders.Count;
        public int PendingOrders => Orders.Count(order => order.Status == "Pending");
        public int ProcessingOrders => Orders.Count(order => order.Status == "Processing");
        public int CompletedOrders => Orders.Count(order => order.Status == "Completed");
        public int CancelledOrders => Orders.Count(order => order.Status == "Cancelled");
        public decimal TotalRevenue => Orders.Sum(order => order.TotalAmount);

        public async Task OnGetAsync()
        {
            Orders = await _orderService.GetAllOrdersAsync();
        }

        public async Task<IActionResult> OnPostUpdateStatusAsync(Guid orderId, string status)
        {
            if (orderId == Guid.Empty || string.IsNullOrWhiteSpace(status))
            {
                TempData["ErrorMessage"] = "Invalid order status request.";
                return RedirectToPage();
            }

            var updated = await _orderService.UpdateOrderStatusAsync(orderId, status);
            TempData[updated ? "SuccessMessage" : "ErrorMessage"] = updated
                ? "Order status updated successfully."
                : "Failed to update order status.";

            return RedirectToPage();
        }

        public string GetStatusBadgeClass(string status)
        {
            return status switch
            {
                "Pending" => "bg-warning-subtle text-warning",
                "Processing" => "bg-info-subtle text-info",
                "Completed" => "bg-success-subtle text-success",
                "Cancelled" => "bg-danger-subtle text-danger",
                _ => "bg-secondary-subtle text-secondary"
            };
        }

        public IReadOnlyList<string> StatusOptions { get; } = new[] { "Pending", "Processing", "Completed", "Cancelled" };
    }
}