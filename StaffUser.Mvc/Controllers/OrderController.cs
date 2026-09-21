using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Customer.Mvc.Controllers
{
    [Authorize]
    public class OrderController : Controller
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Checkout(List<int> selectedCartItemIds)
        {
            var customerIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(customerIdValue, out var customerId) || customerId <= 0)
            {
                return RedirectToAction("Login", "Auth");
            }

            if (selectedCartItemIds == null || selectedCartItemIds.Count == 0)
            {
                TempData["CheckoutError"] = "Please select at least one item to proceed.";
                return RedirectToAction("Index", "Cart");
            }

            try
            {
                var result = await _orderService.CheckoutCartAsync(customerId, selectedCartItemIds);
                return View("CheckoutSuccess", result);
            }
            catch (Exception ex)
            {
                TempData["CheckoutError"] = ex.Message;
                return RedirectToAction("Index", "Cart");
            }
        }
    }
}