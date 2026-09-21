using BLL.DTOs.Auth;
using BLL.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace Staff.Razor.Pages.Auth
{
    public class LoginModel : PageModel
    {
        private readonly IStaffService _staffService;

        public LoginModel(IStaffService staffService)
        {
            _staffService = staffService;
        }

        [BindProperty]
        public LoginDto Input { get; set; } = default!;

        public string? ReturnUrl { get; set; }

        public void OnGet(string? returnUrl = null)
        {
            ReturnUrl = returnUrl;
        }

        public async Task<IActionResult> OnPostAsync(string? returnUrl = null)
        {
            ReturnUrl = returnUrl ?? Url.Page("/Index");

            if (!ModelState.IsValid)
            {
                return Page();
            }

            // Validate credentials via BLL (checks hashed password)
            var staff = await _staffService.ValidateLoginAsync(Input.Email, Input.Password);
            if (staff == null)
            {
                ModelState.AddModelError(string.Empty, "Invalid login attempt.");
                return Page();
            }

            // Create claims to represent the authenticated staff user
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, staff.StaffId.ToString()),
                new Claim(ClaimTypes.Name, staff.FullName),
                new Claim(ClaimTypes.Email, staff.Email),
                new Claim(ClaimTypes.Role, staff.Role.ToString())
            };

            // Create identity/principal and sign in (issue auth cookie)
            var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

            // Redirect back to return URL or homepage
            return LocalRedirect(ReturnUrl ?? "/Index");
        }
    }
}