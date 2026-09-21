using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Customer.Mvc.Models;
using System.Security.Claims;

namespace StaffUser.Mvc.Controllers
{
    [Authorize]
    public class OrdersController : Controller
    {
        private readonly ICustomerService _customerService;
        private readonly IOrderService _orderService;

        public OrdersController(ICustomerService customerService, IOrderService orderService)
        {
            _customerService = customerService;
            _orderService = orderService;
        }

        public async Task<IActionResult> Index()
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrWhiteSpace(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customer = await _customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var orders = await _orderService.GetOrdersByCustomerIdAsync(customer.CustomerId);
            var orderedOrders = orders
                .OrderByDescending(order => order.CreatedAt)
                .ToList();

            var model = new MyOrdersViewModel
            {
                CustomerName = customer.FullName,
                TotalOrders = orderedOrders.Count,
                TotalSpent = orderedOrders.Sum(order => order.TotalAmount),
                Orders = orderedOrders
            };

            return View(model);
        }
    }
}