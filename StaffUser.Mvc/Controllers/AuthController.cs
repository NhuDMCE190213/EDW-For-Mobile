using BLL.DTOs.Auth;
using BLL.DTOs.Customer;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using System;
using Microsoft.AspNetCore.Authorization;
// Removed MVC ViewModels; using BLL DTOs for set-new-password flow

namespace Customer.Mvc.Controllers
{
    public class AuthController : Controller
    {
        /*
         MVC AuthController
         - Handles Login/Logout/Register/ForgotPassword/SetNewPassword for customers (site users)
         - Uses ICustomerService to validate credentials, create users, and reset passwords
         - Uses cookie authentication via HttpContext.SignInAsync / SignOutAsync
         - Note: ForgotPassword uses a simplified dev flow (redirect to SetNewPassword).
             In production, use a token emailed to the user instead.
        */
        private readonly ICustomerService _customerService;

        public AuthController(ICustomerService customerService)
        {
            _customerService = customerService;
        }

        [AllowAnonymous]
        public IActionResult Login()
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        public async Task<IActionResult> Login(LoginDto loginDto)
        {
            // POST /Auth/Login
            // - Validate model, call BLL ValidateLoginAsync which checks hashed password
            // - On success create claims + cookie via SignInAsync
            // - AuthProperties control persistence (RememberMe)
            if (!ModelState.IsValid)
            {
                return View(loginDto);
            }

            var customer = await _customerService.ValidateLoginAsync(loginDto.Email, loginDto.Password);
            if (customer == null)
            {
                ModelState.AddModelError("", "Invalid email or password");
                return View(loginDto);
            }

            // Create claims and sign in with cookie authentication
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, customer.CustomerId.ToString()),
                new Claim(ClaimTypes.Name, customer.FullName ?? customer.Email),
                new Claim(ClaimTypes.Email, customer.Email),
                new Claim(ClaimTypes.Role, customer.Role.ToString())
            };

            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            var authProperties = new AuthenticationProperties
            {
                IsPersistent = loginDto.RememberMe,
                ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, authProperties);

            return RedirectToAction("Index", "Home");
        }

        public IActionResult Logout()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout(string returnUrl = null!)
        {
            // POST /Auth/Logout
            // Signs the user out by removing the authentication cookie
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            return RedirectToAction("Index", "Home");
        }

        [AllowAnonymous]
        public IActionResult ForgotPassword()
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(string email)
        {
            // POST /Auth/ForgotPassword
            // - Verify the email exists using ICustomerService.GetByEmailAsync
            // - DEV flow: redirect to SetNewPassword with email. Production: send email token.
            if (string.IsNullOrWhiteSpace(email))
            {
                ModelState.AddModelError("", "Please provide your email address.");
                return View();
            }

            // Verify the email exists before allowing reset
            var customer = await _customerService.GetByEmailAsync(email);
            if (customer == null)
            {
                ModelState.AddModelError("", "Email address not found.");
                return View();
            }

            // For a simplified dev flow, redirect the user to a page
            // where they can set a new password. In production use a secure token+email.
            return RedirectToAction("SetNewPassword", new { email });
        }

        [AllowAnonymous]
        public IActionResult SetNewPassword(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return RedirectToAction("ForgotPassword");
            var model = new CustomerSetPasswordDto { Email = email };
            return View(model);
        }

        [AllowAnonymous]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SetNewPassword(CustomerSetPasswordDto model)
        {
            // POST /Auth/SetNewPassword
            // - Validate passwords match, lookup user by email, and call SetPasswordAsync
            // - BLL SetPasswordAsync will hash the new password before updating repository
            if (!ModelState.IsValid)
            {
                return View(model);
            }
            var customer = await _customerService.GetByEmailAsync(model.Email);
            if (customer == null)
            {
                // Don't reveal whether the email exists. Redirect to login with no details.
                return RedirectToAction("Login");
            }

            await _customerService.SetPasswordAsync(customer.CustomerId, model.Password);
            return RedirectToAction("Login");
        }

        [AllowAnonymous]
        public IActionResult AccessDenied()
        {
            return View();
        }

        [AllowAnonymous]
        public IActionResult Register()
        {
            return View();
        }

        [AllowAnonymous]
        [HttpPost]
        public async Task<IActionResult> Register(CustomerRegisterDto registerDto)
        {
            // POST /Auth/Register
            // - Check if email already exists using GetByEmailAsync
            // - Create user via ICustomerService.CreateAsync which hashes password
            if (!ModelState.IsValid)
            {
                return View(registerDto);
            }

            var existingCustomer = await _customerService.GetByEmailAsync(registerDto.Email);
            if (existingCustomer != null)
            {
                ModelState.AddModelError("", "Email already registered");
                return View(registerDto);
            }

            await _customerService.CreateAsync(new CustomerCreateDto
            {
                FullName = registerDto.FullName,
                Email = registerDto.Email,
                PhoneNumber = registerDto.PhoneNumber,
                Password = registerDto.Password,
                Role = DAL.Enums.RoleEnum.Customer,
                Points = 0
            });
            return RedirectToAction("Login", "Auth");
        }
    }
}