using BLL.DTOs.Customer;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

// Using MVC ViewModels removed — using BLL DTOs directly
using System.Security.Claims;

namespace Customer.Mvc.Controllers
{
    [Authorize]
    public class ProfileController : Controller
    {
        private readonly ICustomerService _customerService;

        public ProfileController(ICustomerService customerService)
        {
            _customerService = customerService;
        }

        public async Task<IActionResult> Index()
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customer = await _customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            var model = new CustomerProfileDto
            {
                CustomerId = customer.CustomerId,
                Email = customer.Email,
                FullName = customer.FullName,
                PhoneNumber = customer.PhoneNumber,
                Points = customer.Points
            };

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Index(CustomerProfileDto model)
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customer = await _customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            if (!ModelState.IsValid)
            {
                model.Email = customer.Email;
                model.Points = customer.Points;
                return View(model);
            }

            await _customerService.UpdateProfileAsync(customer.CustomerId, model);
            TempData["SuccessMessage"] = "Profile updated successfully.";
            return RedirectToAction(nameof(Index));
        }

        public IActionResult ChangePassword()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ChangePassword(CustomerChangePasswordDto model)
        {
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            if (string.IsNullOrEmpty(email))
            {
                return RedirectToAction("Login", "Auth");
            }

            var customer = await _customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                return RedirectToAction("Login", "Auth");
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            await _customerService.SetPasswordAsync(customer.CustomerId, model.NewPassword);
            TempData["SuccessMessage"] = "Password changed successfully.";
            return RedirectToAction(nameof(Index));
        }
    }
}